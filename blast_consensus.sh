#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Usage:
#
# ./blast_consensus.sh /path/to/concatbarcode /path/to/blast_database
#
# Example:
#
# ./blast_consensus.sh ./concatbarcode /home/user/blastdb/nt
#
###############################################################################

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 concatbarcode_directory blast_database"
    exit 1
fi

CONCATDIR="$1"
DB="$2"

OUTDIR="${CONCATDIR}/blast_results"
mkdir -p "$OUTDIR"

echo
echo "========================================"
echo "Searching Amplicon_sorter outputs..."
echo "========================================"

for SORTDIR in "${CONCATDIR}"/*_sorted
do

    [[ -d "$SORTDIR" ]] || continue

    SAMPLE=$(basename "$SORTDIR")
    SAMPLE=${SAMPLE%_sorted}

    FASTA=$(find "$SORTDIR" -type f -name "*consensussequences.fasta" | head -n 1)

    if [[ -z "$FASTA" ]]; then
        echo "No consensus sequence found in:"
        echo "  $SORTDIR"
        continue
    fi

    OUTFILE="${OUTDIR}/${SAMPLE}.blast.tsv"

    echo
    echo "----------------------------------------"
    echo "Sample : $SAMPLE"
    echo "Query  : $(basename "$FASTA")"
    echo "Output : $(basename "$OUTFILE")"

echo -e "Query Sequence\tDescription\tOrganism\tAccession\tPercent Identity\tQuery Coverage\tSequence Length\tE-value" > "$OUTFILE"

blastn \
    -query "$FASTA" \
    -db "$DB" \
    -outfmt "6 qseqid stitle sscinames sacc pident qcovs length evalue" \
    -max_target_seqs 10 \
    -num_threads 16 >> "$OUTFILE"

done

echo
echo "Finished!"
echo "Results written to:"
echo "  $OUTDIR"
