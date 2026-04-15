# README of pipeline for miRNA RNAseq analysis

## Dependencies

- [fastp](https://github.com/opengene/fastp) — adapter trimming and QC
- [BLAST+](https://blast.ncbi.nlm.nih.gov/doc/blast-help/downloadblastdata.html) — sequence alignment
- Perl — count matrix generation
- Python 3 — adapter QC reporting

## Setup

Copy `config.sh.example` to `config.sh` and fill in your values:

```bash
cp config.sh.example config.sh
```

`config.sh` is gitignored and will not be committed.
Edit it to set your project directory, adapter sequence, database path, and R1 filename suffix.
This is the only file that should need to change between projects.

**`R1_SUFFIX`** must match the suffix of your R1 FASTQ filenames after the sample name, so that sample names can be derived correctly. Two common patterns:

| Convention | Example filename | `R1_SUFFIX` value |
|---|---|---|
| Standard Illumina (BCL2Fastq) | `SAMPLE_L001_R1_001.fastq.gz` | `_L001_R1_001.fastq.gz` |
| AGRF / barcode-in-name | `SAMPLE_BARCODE_L007_R1.fastq.gz` | `_L007_R1.fastq.gz` |

Each project directory needs the following directory created manually:
- raw-data/

Raw microRNA sequencing data from the supplier should then be placed in this directory.

Run scripts in the following order:
1. verify-checksums.sh
2. process-samples.sh
- check-adapters.sh (if desired)
3. build-database.sh (may not be required if database already exists)
4. quantify.sh
- Before running quantify.sh, set $ID_FIELDS in count-mirna.pl to match the number of underscore-delimited fields that make up the sample IDs.
