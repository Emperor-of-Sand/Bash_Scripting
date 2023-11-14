#!/bin/bash

# Check if the user provided a file as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
    echo "File not found: $input_file"
    exit 1
fi

# Detect the separator in the input file
separator=$(awk 'NR==1{ if (gsub(",", ",") > 0) separator = ","; else if (gsub("\t", "\t") > 0) separator = "\t"; else separator = " "; } END { print separator; }' "$input_file")

# Create a new output file with ".csv" extension
output_file="${input_file%.txt}.csv"

# Process the input file and create the output CSV file
awk -F"$separator" -v OFS="," '{print $0}' "$input_file" > "$output_file"

echo "Conversion complete. Output saved to $output_file"
