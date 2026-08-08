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
# ./amp_sorterflow.sh metadata.csv /path/to/fastq_pass
#
###############################################################################

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 metadata.csv demultiplex_folder"
    exit 1
fi

METADATA="$1"
DEMUX="$2"

if [[ ! -f "$METADATA" ]]; then
    echo "ERROR: Cannot find metadata file:"
    echo "  $METADATA"
    exit 1
fi

if [[ ! -d "$DEMUX" ]]; then
    echo "ERROR: Cannot find demultiplex folder:"
    echo "  $DEMUX"
    exit 1
fi

###############################################################################
# Create concatbarcode directory
###############################################################################

SAMPLE_DIR="$(dirname "$DEMUX")"
CONCATDIR="${SAMPLE_DIR}/concatbarcode"

mkdir -p "$CONCATDIR"

echo
echo "=================================================="
echo "Demultiplex folder : $DEMUX"
echo "Concatenated reads : $CONCATDIR"
echo "=================================================="

###############################################################################
# Read metadata
###############################################################################

declare -A SAMPLE

while IFS=',' read -r barcode sample
do
    barcode=$(echo "$barcode" | tr -d '\r')
    sample=$(echo "$sample" | tr -d '\r')

    [[ "$barcode" == "barcode" ]] && continue
    [[ -z "$barcode" ]] && continue

    SAMPLE["$barcode"]="$sample"

done < "$METADATA"

###############################################################################
# STEP 1 - Concatenate FASTQ files
###############################################################################

echo
echo "========== Concatenating FASTQ files =========="

for BARCODEDIR in "$DEMUX"/barcode*
do

    [[ -d "$BARCODEDIR" ]] || continue

    BARCODE=$(basename "$BARCODEDIR")
    SAMPLEID="${SAMPLE[$BARCODE]:-UnknownSample}"

    OUTFILE="${CONCATDIR}/${SAMPLEID}_${BARCODE}.fastq"

    echo
    echo "----------------------------------------------"
    echo "Barcode : $BARCODE"
    echo "Sample  : $SAMPLEID"

    rm -f "$OUTFILE"

    FOUND=0

    # Concatenate uncompressed FASTQ files
    for f in "$BARCODEDIR"/*.fastq "$BARCODEDIR"/*.fq
    do
        [[ -f "$f" ]] || continue
        cat "$f" >> "$OUTFILE"
        FOUND=1
    done

    # Concatenate gzipped FASTQ files
    for f in "$BARCODEDIR"/*.fastq.gz "$BARCODEDIR"/*.fq.gz
    do
        [[ -f "$f" ]] || continue
        zcat "$f" >> "$OUTFILE"
        FOUND=1
    done

    if [[ $FOUND -eq 0 ]]; then
        echo "No FASTQ files found."
        rm -f "$OUTFILE"
        continue
    fi

    READS=$(( $(wc -l < "$OUTFILE") / 4 ))

    echo "Reads written : $READS"
    echo "Output file   : $(basename "$OUTFILE")"

done

###############################################################################
# STEP 2 - Run Amplicon_sorter
###############################################################################

echo
echo "========== Running Amplicon_sorter =========="

tail -n +2 "$METADATA" | while IFS=',' read -r barcode sample
do

    barcode=$(echo "$barcode" | tr -d '\r')
    sample=$(echo "$sample" | tr -d '\r')

    [[ -z "$barcode" ]] && continue

    FASTQ="${CONCATDIR}/${sample}_${barcode}.fastq"

    if [[ ! -f "$FASTQ" ]]; then
        echo
        echo "WARNING: Cannot find $FASTQ"
        continue
    fi

    OUTDIR="${CONCATDIR}/${sample}_${barcode}_sorted"

    echo
    echo "=================================================="
    echo "Sample : $sample"
    echo "Barcode: $barcode"
    echo "Input  : $(basename "$FASTQ")"
    echo "Output : $(basename "$OUTDIR")"
    echo "=================================================="

    python3 amplicon_sorter.py \
        -i "$FASTQ" \
        -o "$OUTDIR" \
        -np 16 \
        -min 150 \
        -max 1250 \
        -maxr 400000

done

###############################################################################
# Finished
###############################################################################

echo
echo "=================================================="
echo "Pipeline completed successfully."
echo
echo "Concatenated FASTQ files:"
echo "  $CONCATDIR"
echo
echo "Amplicon_sorter outputs:"
echo "  ${CONCATDIR}/*_sorted"
echo "=================================================="
