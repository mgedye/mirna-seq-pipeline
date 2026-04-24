#!/bin/bash
set -euo pipefail

# ============================================================
# quantify.sh
# Runs BLAST against miRNA database and generates count matrix
# Steps: BLAST → count matrix (via Perl)
#
# Usage: bash quantify.sh
# ============================================================

# ── Configuration ───────────────────────────────────────────
CONFIG="$(dirname "$0")/../config.sh"
[[ -f "$CONFIG" ]] || { echo "ERROR: config.sh not found. Copy config.sh.example to config.sh and fill in your values."; exit 1; }
source "$CONFIG"
SCRIPTS="scripts"
# ────────────────────────────────────────────────────────────

# ── Directories ──────────────────────────────────────────────
COLLAPSED="${PROJECT}/intermediates/04_collapsed"
BLAST="${PROJECT}/intermediates/05_blast"
RESULTS="${PROJECT}/results"
LOG_DIR="${PROJECT}/logs"

mkdir -p "$BLAST" "$RESULTS" "$LOG_DIR"
# ────────────────────────────────────────────────────────────

# ── Logging ──────────────────────────────────────────────────
DATE=$(date +"%Y-%m-%d")
LOG="$(realpath "$LOG_DIR")/quantify_${DATE}.txt"
exec > >(tee "$LOG") 2>&1
echo "Log: $LOG"
# ────────────────────────────────────────────────────────────

# ── Step 1: BLAST ────────────────────────────────────────────
echo "======================================"
echo " Step 1: Running BLAST"
echo " Database: $DB"
echo "======================================"

# Sanity checks
[[ -d "$COLLAPSED" ]] || { echo "ERROR: collapsed FASTA directory not found: $COLLAPSED"; exit 1; }
[[ -f "${DB}.nin" ]]  || { echo "ERROR: BLAST database not found: $DB"; exit 1; }

shopt -s nullglob
files=("$COLLAPSED"/*.collapsed.fasta)

if (( ${#files[@]} == 0 )); then
    echo "ERROR: no collapsed FASTA files found in $COLLAPSED"
    exit 1
fi

for f in "${files[@]}"; do
    base=$(basename "$f" .collapsed.fasta)
    echo "  BLASTing: $base"

    blastn \
        -task blastn \
        -query "$f" \
        -db "$DB" \
        -word_size "$WORD_SIZE" \
        -outfmt 6 \
        -out "$BLAST/${base}_blast.txt"
done

echo "  Done. BLAST results in $BLAST"
# ────────────────────────────────────────────────────────────

# ── Step 2: Count matrix ─────────────────────────────────────
echo "======================================"
echo " Step 2: Building count matrix"
echo "======================================"

BLAST_FILES=("$BLAST"/*_blast.txt)

if (( ${#BLAST_FILES[@]} == 0 )); then
    echo "ERROR: no BLAST result files found in $BLAST"
    exit 1
fi

SAMPLE_ID_FIELDS="$SAMPLE_ID_FIELDS" perl "${SCRIPTS}/count-mirna.pl" "${BLAST_FILES[@]}" \
    > "${RESULTS}/count-matrix.csv"

echo "  Done. Count matrix written to ${RESULTS}/count-matrix.csv"
echo ""
echo "======================================"
echo " quantify.sh complete"
echo "======================================"
# ────────────────────────────────────────────────────────────
