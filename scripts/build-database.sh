#!/bin/bash
set -euo pipefail

# ============================================================
# build-database.sh
# Downloads miRNA reference sequences and builds BLAST database
# Supported sources: miRBase, MirGeneDB
#
# Usage: bash build-database.sh
# NOTE: Run once per reference database. Not part of the
#       per-project pipeline.
# ============================================================

# ── Configuration ───────────────────────────────────────────
SOURCE="miRbase"          # miRBase or MirGeneDB
SPECIES="human"             # mouse or human
DB_DIR="databases"
# ────────────────────────────────────────────────────────────

# ── Species lookup ───────────────────────────────────────────
case "$SPECIES" in
    mouse) MIRBASE_GREP="Mus musculus"
           MIRGENEDB_PREFIX="mmu" ;;
    human) MIRBASE_GREP="Homo sapiens"
           MIRGENEDB_PREFIX="hsa" ;;
    *)     echo "ERROR: unsupported species: $SPECIES"; exit 1 ;;
esac
# ────────────────────────────────────────────────────────────

# ── Logging ──────────────────────────────────────────────────
LOG_DIR="${DB_DIR}/logs"
mkdir -p "$LOG_DIR"
DATE=$(date +"%Y-%m-%d")
LOG="$(realpath "$LOG_DIR")/build-database_${SPECIES}_${SOURCE}_${DATE}.txt"
exec > >(tee "$LOG") 2>&1
echo "Log: $LOG"
# ────────────────────────────────────────────────────────────

# ── Build database ───────────────────────────────────────────
echo "======================================"
echo " Building BLAST database"
echo " Source:  $SOURCE"
echo " Species: $SPECIES"
echo "======================================"

case "$SOURCE" in

    miRbase)
        OUT_DIR="${DB_DIR}/miRbase"
        mkdir -p "$OUT_DIR"
        cd "$OUT_DIR"

        if [[ -f "mirbase_${MIRGENEDB_PREFIX}_mature.nin" ]]; then
            echo "  Database already exists, skipping build."
        else
            if [[ ! -f "mature.fa" ]]; then
                echo "ERROR: mature.fa not found in ${OUT_DIR}. Please place it there manually."
                exit 1
            fi

            echo "  Extracting ${SPECIES} sequences..."
            grep -A1 "$MIRBASE_GREP" mature.fa > mirbase_${MIRGENEDB_PREFIX}_mature.fa

            echo "  Building BLAST index..."
            makeblastdb \
                -in mirbase_${MIRGENEDB_PREFIX}_mature.fa \
                -dbtype nucl \
                -out mirbase_${MIRGENEDB_PREFIX}_mature
        fi
        ;;

    MirGeneDB)
        OUT_DIR="${DB_DIR}/MirGeneDB"
        mkdir -p "$OUT_DIR"
        cd "$OUT_DIR"

        if [[ -f "MirGeneDB_${SPECIES}_mature.nin" ]]; then
            echo "  Database already exists, skipping download and build."
        else
            echo "  Downloading MirGeneDB mature sequences..."
            wget https://mirgenedb.org/static/data/${MIRGENEDB_PREFIX}/${MIRGENEDB_PREFIX}-mature.fas

            echo "  Building BLAST index..."
            makeblastdb \
                -in ${MIRGENEDB_PREFIX}-mature.fas \
                -dbtype nucl \
                -out MirGeneDB_${SPECIES}_mature
        fi
        ;;

    *)
        echo "ERROR: unsupported source: $SOURCE"
        echo "Valid options: miRBase, MirGeneDB"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo " build-database.sh complete"
echo " Database: ${OUT_DIR}"
echo "======================================"
# ────────────────────────────────────────────────────────────
