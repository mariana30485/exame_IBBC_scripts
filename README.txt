# README.txt

## Overview

This repository contains a set of Bash scripts designed for automating the analysis of paired-end FASTQ sequencing files. The scripts are organized into distinct tasks, providing a modular, reproducible, and extensible workflow for pre-processing, quality control, and reporting. Below is a description of each script:




### 1. `1_script.sh`
Purpose: Creates a directory structure to store data and analysis outputs for the pipeline.

Features:
- Automatically sets up the following directories under `$HOME/data_IBBCscripts`:
  - `raw_data`: Input raw FASTQ files.
  - `fastqc_results`: Results from the initial FastQC analysis.
  - `fastp_results`: Output from FastP.
  - `fastqc_fp_results`: Results from the second FastQC analysis on FastP output.
  - `multiqc_results`: Collated report from MultiQC.

Usage:
Run this script to initialize the required directory structure or run 1_autotest_script.sh




### 2. `1_autotest_script.sh`
Purpose: Tests the setup script (1_script.sh) to ensure the directory structure is created correctly.

Features:
Simulates a clean environment by removing any existing directory structure.
Tests for successful creation of the directory structure.
Validates behavior when the directory structure already exists.

Usage:
Run the script to perform the tests:

```bash
bash 1_autotest_script.shh
```


## 3. `2_tools_script.sh`
Purpose: Executes the entire processing pipeline, including FASTQ file quality control, preprocessing, and reporting.

Workflow:
Copy Input Files: Copies user-specified FASTQ files to the raw_data directory.
Quality Control (FastQC): Runs FastQC on the raw data files.
Preprocessing (FastP): Performs read trimming and filtering.
Second Quality Control (FastQC): Runs FastQC on the FastP output.
Collated Reporting (MultiQC): Compiles results into a single report.
Read Statistics: Generates a report with statistics on reads processed, retained, and discarded.
Logging:
All actions are logged to a file named script_execution.log in the main directory.

Usage:
Execute the pipeline as follows:

```bash
bash 2_tools_script.sh
```





## 4. `3_cleanup_script.sh`
Purpose: Summarizes the directory structure and optionally cleans up intermediate files.

Features:
- Displays the number of files and disk usage for key directories.
- Optionally removes intermediate files like raw data and initial FastQC results.

Usage:
Run the script and follow prompts:

```bash
bash 3_cleanup_script.sh
```





Requirements
  Dependencies:

  - FastQC
  - FastP
  - MultiQC
  - conda with the tools_qc environment.
Environment Setup: Ensure that the tools_qc Conda environment is installed and contains the required tools.



Directory Structure
Upon successful execution of the pipeline, the directory structure will appear as follows:

$HOME/data_IBBCscripts/
├── raw_data/             # Input raw FASTQ files
├── fastqc_results/       # FastQC results (raw data)
├── fastp_results/        # FastP outputs
├── fastqc_fp_results/    # FastQC results (FastP output)
├── multiqc_results/      # MultiQC report
├── reads_statistics_report.txt  # Read statistics summary
└── script_execution.log  # Execution log



Notes
  - The scripts are modular and designed for ease of reuse and extension.
  - Logging is comprehensive and located in the script_execution.log file for troubleshooting.
  - Use 3_cleanup_script.sh to manage disk space after running the pipeline.