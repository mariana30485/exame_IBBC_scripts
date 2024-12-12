#!/bin/bash

# Paths and directories
MAIN="$HOME/data_IBBCscripts"
RAW_DATA="$MAIN/raw_data"
FASTQC_RESULTS="$MAIN/fastqc_results"
FASTP_RESULTS="$MAIN/fastp_results"
FASTQC_FP_RESULTS="$MAIN/fastqc_fp_results"
MULTIQC_RESULTS="$MAIN/multiqc_results"

# Function to summarize the directory structure

summarize_directories() {
    printf "Summary of directory structure in %s:\n\n" "$MAIN"
    
    for dir in "$RAW_DATA" "$FASTQC_RESULTS" "$FASTP_RESULTS" "$FASTQC_FP_RESULTS" "$MULTIQC_RESULTS"; do
        if [[ -d "$dir" ]]; then
            printf "%s:\n" "$dir"
            printf "  Number of files: %d\n" "$(find "$dir" -type f | wc -l)"
            printf "  Disk usage: %s\n" "$(du -sh "$dir" | cut -f1)"
            printf "\n"
        else
            printf "Warning: Directory %s does not exist.\n\n" "$dir"
        fi
    done
}

# Function to clean up intermediate files

cleanup_intermediate_files() {
    printf "Would you like to delete intermediate files (e.g., FastQC and raw data)? [Y/N]: "
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        printf "Cleaning up intermediate files...\n"
        rm -rf "$RAW_DATA" "$FASTQC_RESULTS" || {
            printf "Error: Failed to clean up directories.\n" >&2
            return 1
        }
        printf "Intermediate files have been removed.\n"
    else
        printf "Cleanup skipped.\n"
    fi
}

# pipeline

summarize_directories
cleanup_intermediate_files
