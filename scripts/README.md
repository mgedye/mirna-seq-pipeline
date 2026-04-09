# README of pipeline for miRNA RNAseq analysis

Each project directory needs the following directory created manually:
- raw-data/

Raw microRNA sequencing data from the supplier should then be placed in this directory.

Pathways in all scripts can then be modified based on the project.


Only pathways in the # ── Configuration ─────────────────────────────────────────── block should ever need to be modified based on the project and database intended to be used.

Run scripts in the following order:
1. verify-checksums.sh
2. process-samples.sh
- check-adapters.sh (if desired)
3. build-database.sh (may not be required if database already exists)
4. quantify.sh
5. count-mirna.pl

