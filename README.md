# Amplicon Sorter Workflow
## Overview

This workflow automates the processing of Oxford Nanopore demultiplexed amplicon sequencing data. Starting from demultiplexed barcode folders, the pipeline:

1. Concatenates reads belonging to each barcode.
2. Renames concatenated reads using sample names from a metadata file.
3. Generates consensus sequences using Amplicon_sorter.
4. Identifies consensus sequences using BLAST.
5. Produces individual BLAST reports for each sample.

## Metadata File

The workflow requires a CSV metadata file.

Example:
```
barcode,sample
barcode01,SampleA
barcode02,SampleB
barcode03,SampleC
barcode04,Negative_Control
```
Each concatenated FASTQ is processed using Amplicon_sorter.

Example command:
```
python3 amplicon_sorter.py \
    -i SampleA_barcode01.fastq \
    -o SampleA_barcode01_sorted \
    -np 16 \
    -min 150 \
    -max 1250 \
    -maxr 400000
```
    Step 3 – BLAST Identification

Each consensus sequence is searched against a nucleotide BLAST database.

Example command:
```
blastn \
    -query consensussequences.fasta \
    -db DATABASE \
    -out SampleA_barcode01.blast.tsv \
    -outfmt "6 qseqid stitle sscinames sacc pident qcovs length evalue" \
    -max_target_seqs 10 \
    -num_threads 16
```
Each consensus sequence is queried independently.

## Running the Workflow
Step 1 – Concatenate reads and generate consensus
```
./amp_sorterflow.sh metadata.csv fastq_pass/
```
Step 2 – BLAST consensus sequences
```
./blast_consensus.sh concatbarcode /path/to/blast_database
```
## Citation

If you use this workflow in a publication, please cite:
This repository together with the following: 
### Amplicon_sorter
* Vierstraete, A. R., & Braeckman, B. P. (2022). Amplicon_sorter: A tool for reference-free amplicon sorting based on sequence similarity and for building consensus sequences. Ecology and Evolution, 12, e8603. https://doi.org/10.1002/ece3.8603
