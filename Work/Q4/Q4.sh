#!/bin/bash
# This script processes plant data from a CSV file

# Setup log files
LOG_FILE="process_log.txt"
ERROR_LOG="error_log.txt"

# Clear previous log files
> "$LOG_FILE"
> "$ERROR_LOG"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to log errors
log_error() {
    echo "ERROR: $1" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$ERROR_LOG"
}

# Find CSV file - use parameter or find local CSV
CSV_FILE="$1"
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

# Full path to the Python script - adjust to the correct path on your system
PYTHON_SCRIPT="/Users/gldmmn/LINUX_Course_Project/Work/Q2/plant.py"

# Check if the Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    log_error "Python script $PYTHON_SCRIPT not found!"
    exit 1
fi

# Create virtual environment if it doesn't exist
VENV_DIR="venv"
if [ ! -d "$VENV_DIR" ]; then
    log_message "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
    
    # Check if venv creation was successful
    if [ $? -ne 0 ]; then
        log_error "Failed to create virtual environment."
        exit 1
    fi
    
    log_message "Virtual environment created successfully."
fi

# Activate the virtual environment
source "$VENV_DIR/bin/activate"
if [ $? -ne 0 ]; then
    log_error "Failed to activate virtual environment."
    exit 1
fi
log_message "Virtual environment activated."

# Install dependencies if requirements.txt exists
if [ -f "requirements.txt" ]; then
    log_message "Installing required packages..."
    pip install -r requirements.txt >> "$LOG_FILE" 2>> "$ERROR_LOG"
    
    if [ $? -ne 0 ]; then
        log_error "Failed to install packages from requirements.txt."
        deactivate
        exit 1
    fi
    
    log_message "Packages installed successfully."
else
    log_message "Warning: requirements.txt not found. Continuing without installing dependencies."
fi

# Create Diagrams directory
DIAGRAMS_DIR="Diagrams"
mkdir -p "$DIAGRAMS_DIR"
log_message "Created $DIAGRAMS_DIR directory."

# Counters for statistics
SUCCESSFUL_RUNS=0
TOTAL_ROWS=0

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
    log_message "Processing data for plant: $plant"
    
    # Create plant-specific directory inside Diagrams
    PLANT_DIR="$DIAGRAMS_DIR/$plant"
    mkdir -p "$PLANT_DIR"
    log_message "Created directory: $PLANT_DIR"
    
    # Get current files in the plant directory before running the script
    files_before=$(ls -1 "$PLANT_DIR" 2>/dev/null | wc -l)
    
    # Run the Python script with proper argument handling
    log_message "Running Python script for plant: $plant"
    
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
    
    log_message "Parameters: --plant '$plant' --height$height_args --leaf_count$leaf_count_args --dry_weight$dry_weight_args"
    
    # Change directory to the plant directory so diagrams are saved there
    (cd "$PLANT_DIR" && python3 "$PYTHON_SCRIPT" \
        --plant "$plant" \
        --height $height_args \
        --leaf_count $leaf_count_args \
        --dry_weight $dry_weight_args \
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
log_message "Successful runs: $SUCCESSFUL_RUNS"
if [ $SUCCESSFUL_RUNS -eq $TOTAL_ROWS ]; then
    log_message "All plants were processed successfully!"
    exit 0
else
    log_error "Warning: Some plants were not processed successfully. See $ERROR_LOG for details."
    exit 1
fi