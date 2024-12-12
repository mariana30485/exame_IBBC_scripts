#!/bin/bash


# This scripts allows the analysis of any fastq files the user wishes to input.
# It runs FastQC on the raw *fastq.gz files on a directory that the user will input.
# Then it runs FastP on those same files and re-retun FastQC on FastP results.
# And finaly runs MultiQC on the second FastQC results files.

# All the original data and correspondent results will be stored in directory tree created using 1_script.sh   


# Directories

MAIN="$HOME/data_IBBCscripts"
RAW_DATA="$MAIN/raw_data"
INDEX_FILE="$MAIN/raw_file_index.txt"
FASTQC_RESULTS="$MAIN/fastqc_results"
FASTP_RESULTS="$MAIN/fastp_results"
FASTQC_FP_RESULTS="$MAIN/fastqc_fp_results"
MULTIQC_RESULTS="$MAIN/multiqc_results"
REPORT_FILE="$MAIN/reads_statistics_report.txt"
LOG_FILE="$MAIN/script_execution.log"



# Function to initialize log file
initialize_log() {
    : > "$LOG_FILE" # Create or truncate the log file
    printf "Log initialized: %s\n" "$(date)" >> "$LOG_FILE"
}

# Wrapper function to log the output of a command
log_command() {
    local message="$1"
    shift
    printf "%s\n" "$message" >> "$LOG_FILE"
    "$@" >> "$LOG_FILE" 2>&1
}




# Function to copy sample files

copy_sample_files() {
    printf "Enter the directory containing your sample files [example: /home/user/dir1/dir2/ ]: "
    read -r input_dir                                                            # reads path inputed by user

    if [[ ! -d "$input_dir" ]]; then                                             # check if input directory (doesn't) exists
        printf "Error: Directory %s does not exist.\n" "$input_dir" >&2 | tee -a "$LOG_FILE"
        return 1
    fi

    cp "$input_dir"/*.gz "$RAW_DATA" >> "$LOG_FILE" 2>&1 || {            #copy .gz files from input dir to raw_data      
       printf "Error: Failed to copy files to %s.\n" "$RAW_DATA" >&2 | tee -a "$LOG_FILE"   # if it fails it prints error message
        return 1
    }
    printf "Sample files copied to %s.\n" "$RAW_DATA" | tee -a "$LOG_FILE"
}



# Function to activate conda

activate_conda() {
    log_command "Activating Conda..." source "$(conda info --base)/etc/profile.d/conda.sh" || {    # gets/loads conda environment
        printf "Error: Conda not found.\n" >&2 | tee -a "$LOG_FILE"
        return 1
    }
    log_command "Activating Conda environment 'tools_qc'..." conda activate tools_qc || {
        printf "Error: Conda environment 'tools_qc' not found.\n" >&2 | tee -a "$LOG_FILE"
        return 1
    }
}




# Function to run FastQC

run_fastqc() {
    printf "Running FastQC...\n" | tee -a "$LOG_FILE"
    for file in "$RAW_DATA"/*.gz; do                     # for each .gz file in raw_data runs fastqc and puts the results in fastqc_results
        log_command "Running FastQC for $file..." fastqc "$file" -o "$FASTQC_RESULTS" && \
            printf "FastQC succeeded for %s\n" "$file" | tee -a "$LOG_FILE" || \
            printf "FastQC failed for %s\n" "$file" >&2 | tee -a "$LOG_FILE"
    done
}




# Function to run Fastp for paired-end reads with flexible matching

run_fastp() {
    printf "Running Fastp for paired-end reads with flexible matching...\n" | tee -a "$LOG_FILE"

    for forward in "$RAW_DATA"/*_1*.gz "$RAW_DATA"/*_R1*.gz; do
        [[ -f "$forward" ]] || continue                     # looks for paired reads

        # Identify the matching reverse read

        reverse="${forward/_1/_2}"
        reverse="${reverse/_R1/_R2}"

        if [[ -f "$reverse" ]]; then                    
            # gets the common part of the sample files for correctly naming outputs
            common_prefix=$(basename "$forward" | sed -E 's/_1.*|_R1.*//')

            # defines output filenames
            output_forward="$FASTP_RESULTS/${common_prefix}_fastp_1.gz"
            output_reverse="$FASTP_RESULTS/${common_prefix}_fastp_2.gz"
            output_json="$FASTP_RESULTS/${common_prefix}.json"
            output_html="$FASTP_RESULTS/${common_prefix}.html"

            # Run Fastp
            log_command "Running Fastp for $forward and $reverse..." fastp -i "$forward" -I "$reverse" \
                -o "$output_forward" -O "$output_reverse" \
                --json "$output_json" --html "$output_html" && \
                printf "Fastp succeeded for pair: %s and %s\n" "$forward" "$reverse" | tee -a "$LOG_FILE" || \
                printf "Fastp failed for pair: %s and %s\n" "$forward" "$reverse" >&2 | tee -a "$LOG_FILE"
        else
            printf "Warning: No matching reverse read for %s. Skipping.\n" "$forward" >&2 | tee -a "$LOG_FILE"
        fi
    done
}



# Function to re-run fastqc on fastp results

run_second_fastqc() {
    printf "Running FastQC on Fastp result files...\n" | tee -a "$LOG_FILE"

    # Validate if the FASTP_RESULTS directory exists and contains files
    if [[ ! -d "$FASTP_RESULTS" ]] || [[ -z "$(find "$FASTP_RESULTS" -type f -name '*_fastp_*.gz')" ]]; then
        printf "Error: No Fastp result files found in %s. Skipping FastQC.\n" "$FASTP_RESULTS" >&2 | tee -a "$LOG_FILE"
        return 1
    fi

    # Loop through Fastp output files
    for file in "$FASTP_RESULTS"/*_fastp_*.gz; do
        [[ -f "$file" ]] || continue  # Skip if the file doesn't exist

        # Run FastQC
        log_command "Running FastQC for Fastp result file $file..." fastqc -o "$FASTQC_FP_RESULTS" "$file" && \
            printf "FastQC succeeded for %s\n" "$file" | tee -a "$LOG_FILE" || \
            printf "FastQC failed for %s\n" "$file" >&2 | tee -a "$LOG_FILE"
    done
}



# Function to run multiqc on the second fastqc results

run_multiqc() {
    pprintf "Running MultiQC on Second FastQC results...\n" | tee -a "$LOG_FILE"

    # Run MultiQC
    log_command "Running MultiQC..." multiqc -o "$MULTIQC_RESULTS" "$FASTQC_FP_RESULTS" && \
        printf "MultiQC succeeded. Results saved in %s\n" "$MULTIQC_RESULTS" | tee -a "$LOG_FILE" || \
        printf "MultiQC failed. Check the logs for details.\n" >&2 | tee -a "$LOG_FILE"
}



# Function to extract read statistics from fastp JSON 

generate_read_statistics() {
    printf "Generating read statistics report...\n" | tee -a "$LOG_FILE"
    
    # Header for the report file
    printf "Sample\tInitial_Reads\tFinal_Reads\tDiscarded_Reads\n" > "$REPORT_FILE"
    for json_file in "$FASTP_RESULTS"/*.json; do
        [[ -f "$json_file" ]] || continue

        # Extract relevant fields using grep and sed/awk
       local sample_name; sample_name=$(basename "$json_file" | sed -E 's/\.json$//')
        local initial_reads; initial_reads=$(grep -Po '"total_reads":\s*\K[0-9]+' "$json_file" | head -1)
        local final_reads; final_reads=$(grep -Po '"total_reads":\s*\K[0-9]+' "$json_file" | tail -1)
        local discarded_reads=$((initial_reads - final_reads))

        # Append the statistics to the report file
        printf "%s\t%s\t%s\t%s\n" "$sample_name" "$initial_reads" "$final_reads" "$discarded_reads" >> "$REPORT_FILE"
    done

    printf "Read statistics report generated: %s\n" "$REPORT_FILE" | tee -a "$LOG_FILE"
}




# Main workflow 

initialize_log
copy_sample_files || exit 1

printf "Generating file index...\n" | tee -a "$LOG_FILE"
if ! find "$RAW_DATA" -type f -name '*.gz' > "$INDEX_FILE"; then
    printf "Error: Failed to generate file index from %s.\n" "$RAW_DATA" >&2 | tee -a "$LOG_FILE"
    exit 1
fi

if [[ ! -s "$INDEX_FILE" ]]; then
    printf "No .gz files found in %s. Aborting.\n" "$RAW_DATA" >&2 | tee -a "$LOG_FILE"
    exit 1
fi

printf "File index created: %s\n" "$INDEX_FILE" | tee -a "$LOG_FILE"

activate_conda || exit 1
run_fastqc
run_fastp
run_second_fastqc
run_multiqc
generate_read_statistics
