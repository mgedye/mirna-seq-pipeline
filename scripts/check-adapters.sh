#!/bin/bash
set -euo pipefail

# ============================================================
# check-adapters.sh
# Verifies adapter trimming from fastp JSON reports.
# Compares configured adapter to fastp-detected adapter,
# and reports trimming rate and mean read length change
# per sample.
#
# Usage: bash check-adapters.sh
# NOTE: Run after process-samples.sh (requires fastp JSONs)
# ============================================================

# ── Configuration ───────────────────────────────────────────
CONFIG="$(dirname "$0")/../config.sh"
[[ -f "$CONFIG" ]] || { echo "ERROR: config.sh not found. Copy config.sh.example to config.sh and fill in your values."; exit 1; }
source "$CONFIG"
REPORTS="${PROJECT}/intermediates/02_trimmed/reports"
# ────────────────────────────────────────────────────────────

# ── Logging ──────────────────────────────────────────────────
LOG_DIR="${PROJECT}/logs"
mkdir -p "$LOG_DIR"
DATE=$(date +"%Y-%m-%d")
LOG="${LOG_DIR}/check-adapters_${DATE}.txt"
exec > >(tee "$LOG") 2>&1
echo "Log: $LOG"
# ────────────────────────────────────────────────────────────

echo "======================================"
echo " Adapter QC"
echo " Project:  $PROJECT"
echo " Expected: $ADAPTER"
echo "======================================"
echo ""

pass=0
warn=0
fail=0

for json in "$REPORTS"/*.fastp.json; do
    [ -e "$json" ] || continue
    sample=$(basename "$json" .fastp.json)

    python3 - "$json" "$ADAPTER" "$sample" <<'PYEOF'
import json, sys

json_path, expected_adapter, sample = sys.argv[1], sys.argv[2], sys.argv[3]

with open(json_path) as f:
    d = json.load(f)

summary   = d.get("summary", {})
before    = summary.get("before_filtering", {})
after     = summary.get("after_filtering", {})
ac        = d.get("adapter_cutting", {})

detected        = ac.get("read1_adapter_sequence", "NOT FOUND")
trimmed_reads   = ac.get("adapter_trimmed_reads", 0)
total_reads     = before.get("total_reads", 1)
trim_pct        = trimmed_reads / total_reads * 100
len_before      = before.get("read1_mean_length", 0)
len_after       = after.get("read1_mean_length", 0)
len_delta       = len_before - len_after

# Adapter match check (fastp may report a prefix if it auto-detected)
adapter_ok = expected_adapter.startswith(detected) or detected.startswith(expected_adapter)

# Trimming rate warning thresholds (miRNA-seq: expect most reads trimmed)
if not adapter_ok:
    status = "FAIL"
elif trim_pct < 1.0:
    status = "WARN"
else:
    status = "PASS"

print(f"  Sample:   {sample}")
print(f"  Detected: {detected}  {'[OK]' if adapter_ok else '[MISMATCH]'}")
print(f"  Trimmed:  {trimmed_reads:,} / {total_reads:,} reads  ({trim_pct:.1f}%)")
print(f"  Length:   {len_before} bp → {len_after} bp  (Δ {len_delta} bp)")
print(f"  Status:   {status}")
if not adapter_ok:
    print(f"  ! Detected adapter does not match configured adapter.")
if trim_pct < 1.0:
    print(f"  ! Very few reads trimmed — adapter may not be present or already removed.")
print()

# Exit code encodes status for bash counter
sys.exit(0 if status == "PASS" else (1 if status == "WARN" else 2))
PYEOF

    rc=$?
    if   [[ $rc -eq 0 ]]; then ((pass++)) || true
    elif [[ $rc -eq 1 ]]; then ((warn++)) || true
    elif [[ $rc -eq 2 ]]; then ((fail++)) || true
    fi
done

echo "======================================"
echo " Summary"
echo "   PASS: $pass"
echo "   WARN: $warn"
echo "   FAIL: $fail"
echo "======================================"
