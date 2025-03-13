#!/bin/bash
# This script processes plant data from a CSV file

# Default values
CSV_FILE=""
PYTHON_SCRIPT="/Users/gldmmn/LINUX_Course_Project/Work/Q2/plant.py"
VENV_DIR="venv"
DIAGRAMS_DIR="Diagrams"
LOG_FILE="process_log.txt"
ERROR_LOG="error_log.txt"
VERBOSE=false
DRY_RUN=false
FORCE_REINSTALL=false
SKIP_MISSING=false
OUTPUT_FORMAT="png"

# Function to display usage information
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Process plant data from a CSV file and generate diagrams using a Python script."
    echo
    echo "Options:"
    echo "  -p, --path PATH           Path to the CSV file (default: auto-detect)"
    echo "  -s, --script PATH         Path to the Python script (default: $PYTHON_SCRIPT)"
    echo "  -v, --venv DIR            Path to virtual environment directory (default: $VENV_DIR)"
    echo "  -d, --diagrams DIR        Path to diagrams output directory (default: $DIAGRAMS_DIR)"
    echo "  -l, --log FILE            Path to log file (default: $LOG_FILE)"
    echo "  -e, --error-log FILE      Path to error log file (default: $ERROR_LOG)"
    echo "  -f, --format FORMAT       Output format for diagrams (default: $OUTPUT_FORMAT)"
    echo "  -V, --verbose             Enable verbose output"
    echo "  -n, --dry-run             Perform a dry run without executing Python script"
    echo "  -r, --reinstall           Force reinstallation of dependencies"
    echo "  -S, --skip-missing        Skip plants with missing/invalid data"
    echo "  -h, --help                Display this help message and exit"
    echo
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--path)
            CSV_FILE="$2"
            shift 2
            ;;
        -s|--script)
            PYTHON_SCRIPT="$2"
            shift 2
            ;;
        -v|--venv)
            VENV_DIR="$2"
            shift 2
            ;;
        -d|--diagrams)
            DIAGRAMS_DIR="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -e|--error-log)
            ERROR_LOG="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -V|--verbose)
            VERBOSE=true
            shift
            ;;
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -r|--reinstall)
            FORCE_REINSTALL=true
            shift
            ;;
        -S|--skip-missing)
            SKIP_MISSING=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            # If no flag is specified, assume it's the CSV file path
            if [ -z "$CSV_FILE" ] && [[ ! "$1" =~ ^- ]]; then
                CSV_FILE="$1"
                shift
            else
                echo "Error: Unknown option $1"
                usage
            fi
            ;;
    esac
done

# Clear previous log files
> "$LOG_FILE"
> "$ERROR_LOG"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    
    # Print additional details in verbose mode
    if [ "$VERBOSE" = true ] && [ -n "$2" ]; then
        echo "  $2"
        echo "  $2" >> "$LOG_FILE"
    fi
}

# Function to log errors
log_error() {
    echo "ERROR: $1" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$ERROR_LOG"
    
    # Print additional details in verbose mode
    if [ "$VERBOSE" = true ] && [ -n "$2" ]; then
        echo "  $2" >&2
        echo "  $2" >> "$ERROR_LOG"
    fi
}

# Find CSV file - use parameter or find local CSV
if [ -z "$CSV_FILE" ]; then
    log_message "No CSV file provided, searching for local CSV files..."
    # Find first CSV file in the current directory
    CSV_FILE=$(find . -maxdepth 1 -name "*.csv" | head -n 1)
    
    if [ -z "$CSV_FILE" ]; then
        log_error "No CSV file provided and no CSV files found in current directory."
        exit 1
    fi
    
    log_message "Found CSV file: $CSV_FILE"
fi

# Check if the file exists
if [ ! -f "$CSV_FILE" ]; then
    log_error "File $CSV_FILE does not exist."
    exit 1
fi

# Check if the Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    log_error "Python script $PYTHON_SCRIPT not found!"
    exit 1
fi

# Display configuration in verbose mode
if [ "$VERBOSE" = true ]; then
    log_message "Configuration:" "CSV File: $CSV_FILE
Python Script: $PYTHON_SCRIPT
Virtual Env: $VENV_DIR
Diagrams Dir: $DIAGRAMS_DIR
Log File: $LOG_FILE
Error Log: $ERROR_LOG
Output Format: $OUTPUT_FORMAT
Dry Run: $DRY_RUN
Force Reinstall: $FORCE_REINSTALL
Skip Missing: $SKIP_MISSING"
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ] || [ "$FORCE_REINSTALL" = true ]; then
    if [ "$FORCE_REINSTALL" = true ] && [ -d "$VENV_DIR" ]; then
        log_message "Force reinstall requested, removing existing virtual environment..."
        rm -rf "$VENV_DIR"
    fi
    
    log_message "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    
    # Check if venv creation was successful
    if [ $? -ne 0 ]; then
        log_error "Failed to create virtual environment."
        exit 1
    fi
    
    log_message "Virtual environment created successfully."
    NEED_INSTALL=true
else
    NEED_INSTALL=false
    log_message "Using existing virtual environment."
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"
if [ $? -ne 0 ]; then
    log_error "Failed to activate virtual environment."
    exit 1
fi
log_message "Virtual environment activated."

# Install dependencies if needed
if [ "$NEED_INSTALL" = true ] || [ "$FORCE_REINSTALL" = true ]; then
    # Install dependencies from requirements.txt if it exists
    if [ -f "requirements.txt" ]; then
        log_message "Installing required packages from requirements.txt..."
        pip install -r requirements.txt >> "$LOG_FILE" 2>> "$ERROR_LOG"
        
        if [ $? -ne 0 ]; then
            log_error "Failed to install packages from requirements.txt."
            log_message "Will try to install essential packages directly."
        else
            log_message "Packages from requirements.txt installed successfully."
        fi
    else
        log_message "Warning: requirements.txt not found. Will install essential packages directly."
    fi

    # Install essential packages
    log_message "Installing essential packages (matplotlib, numpy, pandas)..."
    pip install matplotlib numpy pandas >> "$LOG_FILE" 2>> "$ERROR_LOG"

    if [ $? -ne 0 ]; then
        log_error "Failed to install essential packages. Cannot continue."
        deactivate
        exit 1
    fi

    log_message "Essential packages installed successfully."
fi

# Create Diagrams directory
mkdir -p "$DIAGRAMS_DIR"
log_message "Created $DIAGRAMS_DIR directory."

# If dry run, exit here
if [ "$DRY_RUN" = true ]; then
    log_message "Dry run mode enabled, skipping CSV processing."
    deactivate
    log_message "Virtual environment deactivated."
    exit 0
fi

# Counters for statistics
SUCCESSFUL_RUNS=0
TOTAL_ROWS=0
SKIPPED_ROWS=0

# Process the CSV file and run the script for each row
log_message "Processing CSV file: $CSV_FILE"

# Read the CSV file line by line, properly handling quoted fields
while IFS= read -r line || [ -n "$line" ]; do
    # Skip header row or empty lines
    if [[ "$line" =~ ^Plant|^plant|^"Plant"|^"plant" || -z "$line" ]]; then
        continue
    fi
    
    # Parse CSV line correctly (handles quoted fields)
    # This is a simple parser, for complex CSV with quoted commas and escaped quotes, 
    # consider using Python or another tool
    IFS=',' read -ra fields <<< "$line"
    
    plant="${fields[0]}"
    plant="${plant//\"/}"  # Remove quotes if present
    height="${fields[1]}"
    leaf_count="${fields[2]}"
    dry_weight="${fields[3]}"
    
    TOTAL_ROWS=$((TOTAL_ROWS + 1))
    
    # Check for missing data
    if [ -z "$height" ] || [ -z "$leaf_count" ] || [ -z "$dry_weight" ]; then
        log_message "Plant $plant has missing data."
        if [ "$SKIP_MISSING" = true ]; then
            log_message "Skipping plant $plant due to missing data."
            SKIPPED_ROWS=$((SKIPPED_ROWS + 1))
            continue
        fi
    fi
    
    log_message "Processing data for plant: $plant"
    
    # Create plant-specific directory inside Diagrams
    PLANT_DIR="$DIAGRAMS_DIR/$plant"
    mkdir -p "$PLANT_DIR"
    log_message "Created directory: $PLANT_DIR"
    
    # Get current files in the plant directory before running the script
    files_before=$(ls -1 "$PLANT_DIR" 2>/dev/null | wc -l)
    
    # Split the space-separated values into individual arguments
    height_values=(${height// / })
    leaf_count_values=(${leaf_count// / })
    dry_weight_values=(${dry_weight// / })
    
    # Construct the command with separate arguments
    height_args=""
    for val in "${height_values[@]}"; do
        height_args+=" $val"
    done
    
    leaf_count_args=""
    for val in "${leaf_count_values[@]}"; do
        leaf_count_args+=" $val"
    done
    
    dry_weight_args=""
    for val in "${dry_weight_values[@]}"; do
        dry_weight_args+=" $val"
    done
    
    # Check if the Python script supports the format parameter
    python3 "$PYTHON_SCRIPT" -h 2>&1 | grep -q -- "--format" > /dev/null
    format_supported=$?
    
    format_arg=""
    if [ -n "$OUTPUT_FORMAT" ] && [ $format_supported -eq 0 ]; then
        format_arg="--format $OUTPUT_FORMAT"
        log_message "Format parameter supported, using format: $OUTPUT_FORMAT"
    elif [ -n "$OUTPUT_FORMAT" ] && [ $format_supported -ne 0 ]; then
        log_message "Warning: Format parameter specified but not supported by the Python script. Ignoring."
    fi
    
    log_message "Running Python script for plant: $plant"
    log_message "Parameters: --plant '$plant' --height$height_args --leaf_count$leaf_count_args --dry_weight$dry_weight_args $format_arg"
    
    # Change directory to the plant directory so diagrams are saved there
    (cd "$PLANT_DIR" && python3 "$PYTHON_SCRIPT" \
        --plant "$plant" \
        --height $height_args \
        --leaf_count $leaf_count_args \
        --dry_weight $dry_weight_args \
        $format_arg \
        > >(tee -a "$PLANT_DIR/output.log" | tee -a "../../$LOG_FILE") \
        2> >(tee -a "$PLANT_DIR/error.log" | tee -a "../../$ERROR_LOG"))
    
    script_exit=$?
    
    # Get files in the plant directory after running the script
    files_after=$(ls -1 "$PLANT_DIR" 2>/dev/null | wc -l)
    new_files=$((files_after - files_before))
    
    if [ $script_exit -eq 0 ]; then
        SUCCESSFUL_RUNS=$((SUCCESSFUL_RUNS + 1))
        log_message "Processing of plant $plant completed successfully"
        log_message "Generated $new_files new files in $PLANT_DIR"
    else
        log_error "Error processing plant $plant (Exit code: $script_exit)"
    fi
    
    log_message "----------------------------------------"
done < "$CSV_FILE"

# Deactivate the virtual environment
deactivate
log_message "Virtual environment deactivated."

# Summary
log_message ""
log_message "Summary:"
log_message "Total rows processed: $TOTAL_ROWS"
log_message "Successfully processed: $SUCCESSFUL_RUNS"
log_message "Skipped rows: $SKIPPED_ROWS"
log_message "Failed rows: $((TOTAL_ROWS - SUCCESSFUL_RUNS - SKIPPED_ROWS))"

if [ $SUCCESSFUL_RUNS -eq $((TOTAL_ROWS - SKIPPED_ROWS)) ]; then
    log_message "All plants were processed successfully!"
    exit 0
else
    log_error "Warning: Some plants were not processed successfully. See $ERROR_LOG for details."
    exit 1
fi