#!/bin/bash
CSV_FILE="plants.csv"

menu() {
    echo "Choose an option:"
    echo "1 - Create CSV file and set as current"
    echo "2 - Select a file as current"
    echo "3 - Display current file"
    echo "4 - Add new data for a specific plant"
    echo "5 - Run Python script plant.py with CSV parameters"
    echo "6 - Update values in a specific row by plant name"
    echo "7 - Delete row by plant name"
    echo "8 - Print the plant with highest average leaf count"
    echo "9 - Exit"
}

create_csv() {
    echo "Enter file name to create:"
    read file_name
    echo "Plant,Height,Leaf Count,Dry Weight" > "$file_name"
    CSV_FILE="$file_name"
    echo "File $file_name created and set as current file!"
}

select_csv() {
    echo "Enter file name to use:"
    read file_name
    if [[ -f "$file_name" ]]; then
        CSV_FILE="$file_name"
        echo "File $file_name selected!"
    else
        echo "File not found!"
    fi
}

display_csv() {
    column -s, -t < "$CSV_FILE" | less
}

add_entry() {
    echo "Enter plant name:"
    read plant
    echo "Enter heights (space separated):"
    read -a height
    echo "Enter leaf counts (space separated):"
    read -a leaf_count
    echo "Enter dry weights (space separated):"
    read -a dry_weight
    echo "$plant,${height[*]},${leaf_count[*]},${dry_weight[*]}" >> "$CSV_FILE"
    echo "Row added successfully!"
}

run_python_script() {
    echo "Enter plant name:"
    read plant
    echo "Enter heights (space separated):"
    read height
    echo "Enter leaf counts (space separated):"
    read leaf_count
    echo "Enter dry weights (space separated):"
    read dry_weight
    python3 Work/Q2/plant.py --plant "$plant" --height $height --leaf_count $leaf_count --dry_weight $dry_weight
}

update_entry() {
    echo "Enter plant name to update:"
    read plant
    
    # Check if the plant exists in the file
    if grep -q "^$plant," "$CSV_FILE"; then
        # Create a temporary backup
        cp "$CSV_FILE" "${CSV_FILE}.bak"
        
        # Remove existing row and save to temp file
        grep -v "^$plant," "$CSV_FILE" > temp.csv
        
        # Request new data
        echo "Enter heights (space separated):"
        read -a height
        echo "Enter leaf counts (space separated):"
        read -a leaf_count
        echo "Enter dry weights (space separated):"
        read -a dry_weight
        
        # Add new row to temp file
        echo "$plant,${height[*]},${leaf_count[*]},${dry_weight[*]}" >> temp.csv
        
        # Check if everything was written successfully
        if [ $? -eq 0 ]; then
            mv temp.csv "$CSV_FILE"
            echo "Value updated successfully!"
            rm -f "${CSV_FILE}.bak"  # Remove backup if all is well
        else
            # Restore from backup in case of error
            mv "${CSV_FILE}.bak" "$CSV_FILE"
            echo "An error occurred during update. File restored to previous state."
        fi
    else
        echo "Plant '$plant' not found in the file!"
    fi
}

delete_entry() {
    echo "Enter plant name to delete:"
    read plant
    
    # Check if the plant exists
    if grep -q "^$plant," "$CSV_FILE"; then
        # Create backup
        cp "$CSV_FILE" "${CSV_FILE}.bak"
        
        # Remove the plant entry
        grep -v "^$plant," "$CSV_FILE" > temp.csv
        
        # Check if operation was successful
        if [ $? -eq 0 ]; then
            mv temp.csv "$CSV_FILE"
            echo "Row deleted successfully!"
            rm -f "${CSV_FILE}.bak"
        else
            mv "${CSV_FILE}.bak" "$CSV_FILE"
            echo "An error occurred during deletion. File restored to previous state."
        fi
    else
        echo "Plant '$plant' not found in the file!"
    fi
}

max_leaf_count() {
    awk -F, 'NR>1 {
        split($3, arr, " ");
        sum = 0;
        count = 0;
        for (i in arr) {
            sum += arr[i];
            count++;
        }
        if (count > 0) {
            avg = sum / count;
            if (avg > max_avg || max_avg == 0) {
                max_avg = avg;
                max_plant = $1;
            }
        }
    } 
    END {
        printf "Plant with highest average leaf count: %s (Average: %.2f)\n", max_plant, max_avg
    }' "$CSV_FILE"
}

while true; do
    menu
    read choice
    case $choice in
        1) create_csv ;;
        2) select_csv ;;
        3) display_csv ;;
        4) add_entry ;;
        5) run_python_script ;;
        6) update_entry ;;
        7) delete_entry ;;
        8) max_leaf_count ;;
        9) exit 0 ;;
        *) echo "Invalid choice!" ;;
    esac
done
