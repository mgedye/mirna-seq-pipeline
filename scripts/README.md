# README of pipeline for miRNA RNAseq analysis

Project directory needs the following directory created manually:
- raw-data/

Raw RNAseq data from the supplier should then be copied into this directory.
All scripts can then be modified with this file directory in place of AGRFXXXX

Run scripts in the following order:
1. verify-checksums.sh
2. process-samples.sh
- check-adapters.sh (if desired)
3. build-database.sh (may not be required if database already exists)
4. quanitify.sh
5. count-mirna.pl

Only pathways in the # ── Configuration ─────────────────────────────────────────── block should ever need to be modified based on the project and database intended to be used.
