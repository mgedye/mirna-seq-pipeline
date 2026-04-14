#!/bin/bash
set -euo pipefail

# ============================================================
# verify-checksums.sh
# Verifies md5 checksums of raw sequencing files
#
# Usage: bash verify-checksums.sh
# ============================================================

# ── Configuration ───────────────────────────────────────────
CONFIG="$(dirname "$0")/../config.sh"
[[ -f "$CONFIG" ]] || { echo "ERROR: config.sh not found. Copy config.sh.example to config.sh and fill in your values."; exit 1; }
source "$CONFIG"
RAW_DATA="${PROJECT}/raw-data/"
LOG_DIR="${PROJECT}/logs"
# ────────────────────────────────────────────────────────────

DATE=$(date +"%Y-%m-%d")
mkdir -p "$LOG_DIR"
LOG="$(realpath "$LOG_DIR")/checksum-results_${DATE}.txt"

echo "======================================"
echo " Verifying checksums"
echo " Reference file: ${CHECKSUM_FILE}"
echo " Log: ${LOG}"
echo "======================================"

cd "$RAW_DATA"

if md5sum -c "$CHECKSUM_FILE" | tee "$LOG"; then
    echo ""
    echo "======================================"
    echo " All files OK"
    echo "======================================"
else
    echo ""
    echo "======================================"
    echo " WARNING: one or more checksums failed"
    echo " Check log: ${LOG}"
    echo "======================================"
    exit 1
fi
