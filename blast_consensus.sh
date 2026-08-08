#!/usr/bin/env bash

set -euo pipefail

# Tonny Kinene (Tonny.Kinene@dpird.wa.gov.au)

#-----------------------------------------------------------------------
# DPIRD DIagnostics and Laboratory Services
# Sustainability and Biosecurity 
# Department of Primary Industries and Regional Development
# 31 Cedric Street, Stirling WA 6021
# ----------------------------------------------------------------------

# Copyright (c) 2026 Tonny Kinene
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#------------------------------------------------------------------------

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
