#!/bin/bash
set -euo pipefail

# ============================================================
# process-samples.sh
# Processes raw miRNA-seq FASTQs through to collapsed FASTAs
# Steps: lane merge → adapter trim → FASTA convert → collapse
#
# Usage: bash process-samples.sh
# ============================================================

# ── Configuration ───────────────────────────────────────────
PROJECT="projects/matrx"
RAW_DATA="${PROJECT}/raw-data/"
ADAPTER="AGATCGGAAGAGCACACGTCTGAACTCCAGTCA"
MIN_QUAL=20
MIN_LEN=15
# ────────────────────────────────────────────────────────────

# ── Output directories (created by this script) ─────────────
MERGED="${PROJECT}/intermediates/01_merged"
TRIMMED="${PROJECT}/intermediates/02_trimmed"
REPORTS="${TRIMMED}/reports"
FASTA="${PROJECT}/intermediates/03_fasta"
COLLAPSED="${PROJECT}/intermediates/04_collapsed"
LOG_DIR="${PROJECT}/logs"

mkdir -p "$MERGED" "$TRIMMED" "$REPORTS" "$FASTA" "$COLLAPSED" "$LOG_DIR"
# ────────────────────────────────────────────────────────────

# ── Logging ──────────────────────────────────────────────────
DATE=$(date +"%Y-%m-%d")
LOG="${LOG_DIR}/process-samples_${DATE}.txt"
exec > >(tee "$LOG") 2>&1
echo "Log: $LOG"
# ────────────────────────────────────────────────────────────

# ── Step 1: Merge lanes ──────────────────────────────────────
echo "======================================"
echo " Step 1: Merging lanes"
echo "======================================"

samples=$(ls "$RAW_DATA"/*_R1_001.fastq.gz \
    | xargs -n1 basename \
    | sed -E 's/_L00[0-9]_R1_001\.fastq\.gz//' \
    | sort -u)

for sample in $samples; do
    echo "  Merging: $sample"
    cat "$RAW_DATA/${sample}"*_R1_001.fastq.gz > "$MERGED/${sample}_R1.merged.fastq.gz"
done

echo "  Done. Merged FASTQs in $MERGED"
# ────────────────────────────────────────────────────────────

# ── Step 2: Adapter trimming ─────────────────────────────────
echo "======================================"
echo " Step 2: Adapter trimming"
echo "======================================"

for fq in "$MERGED"/*_R1.merged.fastq.gz; do
    [ -e "$fq" ] || continue
    sample=$(basename "$fq" _R1.merged.fastq.gz)
    echo "  Trimming: $sample"

    fastp \
        -i "$fq" \
        -o "$TRIMMED/${sample}_R1.clean.fastq.gz" \
        --adapter_sequence "$ADAPTER" \
        --html "$REPORTS/${sample}.fastp.html" \
        --json "$REPORTS/${sample}.fastp.json" \
        -q "$MIN_QUAL" \
        -l "$MIN_LEN" \
        --disable_quality_filtering \
        2>> "$REPORTS/${sample}.fastp.log"
done

echo "  Done. Trimmed FASTQs and reports in $TRIMMED"
# ────────────────────────────────────────────────────────────

# ── Step 3: Convert to FASTA ─────────────────────────────────
echo "======================================"
echo " Step 3: Converting to FASTA"
echo "======================================"

for fq in "$TRIMMED"/*_R1.clean.fastq.gz; do
    [ -e "$fq" ] || continue
    sample=$(basename "$fq" _R1.clean.fastq.gz)
    echo "  Converting: $sample"

    zcat "$fq" \
        | awk 'NR%4==1 {print ">" substr($0,2)} NR%4==2 {print}' \
        > "$FASTA/${sample}.fasta"
done

echo "  Done. FASTA files in $FASTA"
# ────────────────────────────────────────────────────────────

# ── Step 4: Collapse FASTA ───────────────────────────────────
echo "======================================"
echo " Step 4: Collapsing FASTA"
echo "======================================"

for f in "$FASTA"/*.fasta; do
    [ -e "$f" ] || continue
    sample=$(basename "$f" .fasta)
    echo "  Collapsing: $sample"

    awk '
        /^>/ { header = $0; next }
        {
            count[$0]++
        }
        END {
            i = 1
            for (seq in count) {
                printf ">read_%d_x%d\n%s\n", i, count[seq], seq
                i++
            }
        }
    ' "$f" > "$COLLAPSED/${sample}.collapsed.fasta"

    original=$(grep -c "^>" "$f")
    collapsed=$(grep -c "^>" "$COLLAPSED/${sample}.collapsed.fasta")
    echo "    ${original} reads → ${collapsed} unique sequences"
done

echo "  Done. Collapsed FASTAs in $COLLAPSED"
echo ""
echo "======================================"
echo " process-samples.sh complete"
echo "======================================"
# ────────────────────────────────────────────────────────────
