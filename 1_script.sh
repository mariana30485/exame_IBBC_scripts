#!/bin/bash

# Script to generate directory "tree"/structure.


MAIN="$HOME/data_IBBCscripts"                       # Main directory where all in and outputs will be stored 
RAW_DATA="$MAIN/raw_data"                           # Subdirectory for raw data
FASTQC_RESULTS="$MAIN/fastqc_results"               # Subdirectory for first fastqc results
FASTP_RESULTS="$MAIN/fastp_results"                 # Subdirectory fastp results
FASTQC_FP_RESULTS="$MAIN/fastqc_fp_results"         # Subdirectory for the second fastqc results on fastp results
MULTIQC_RESULTS="$MAIN/multiqc_results"             # Subdirectory for multiqc results


# Function that creates the directories; if it fails it prints an error message; if it succeeds it prints a success message

create_directory_tree() {
    local dir
    for dir in "$RAW_DATA" "$FASTQC_RESULTS" "$FASTP_RESULTS" "$FASTQC_FP_RESULTS" "$MULTIQC_RESULTS"; do
        mkdir -p "$dir" || {                         # Creates the directories and the parent directory if they don't exist
            printf "Error: Failed to create directory %s\n" "$dir" >&2       # Prints an error message if mkdir fails to inform the user   
            return 1                                 # Exits the function (stops execution) with a non-zero (= insuccess) status
        } 
    done
    printf "Directory structure successfully created in %s\n" "$MAIN"    # Prints a success message
}
# %s = placeholder for variable  # >&2 redirects the output of a command to the stderr stream


main_check() {
    if [[ ! -d "$MAIN" ]]; then        # Checks if the base directory doesn't already exists      # ! negation  
        create_directory_tree         # Calls the function to create the directory structure
    else
        printf "Directory structure already exists in %s\n" "$MAIN"  # Prints a message if the structure already exists
    fi
}

main_check                                    # Starts the script by calling the main function
