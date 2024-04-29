#!/bin/bash

# Parameters
submitted_code="$1"      # Path to the submitted code file
course_id="$2"           # Course ID
exercise_number="$3"     # Exercise number
languageFormat="$4"      # Programming languageFormat (e.g., python, c)

# Directory containing reference inputs and implementations
reference_dir="/var/www/my_node_app/reference"

# Construct the paths to the input file and the reference implementation
input_file="${reference_dir}/${course_id}/${exercise_number}/input.txt"
reference_file="${reference_dir}/${course_id}/${exercise_number}/reference.${languageFormat}"

# Check if the necessary files exist
if [[ ! -f "$input_file" || ! -f "$reference_file" ]]; then
  exit 1
fi

# Function to execute code and capture output for a given input
# Parameters: file_path, input (single argument)
execute_code_for_input() {
    local file_path=$1
    local input=$2
    local output

    case $languageFormat in
        "py")
            output=$(echo "$input" | python3 "$file_path")
            ;;
        "c")
            # Compile C file
            gcc "$file_path" -o "${file_path}.out"
            output=$(echo "$input" | "${file_path}.out")
            # Clean up compiled output
            rm "${file_path}.out"
            ;;
        *)
            exit 1
            ;;
    esac
}

# Initialize a success count
success_count=0
total_tests=0

# Read each line from input.txt and execute both codes
while IFS= read -r line; do
    submitted_output=$(execute_code_for_input "$submitted_code" "$line")
    reference_output=$(execute_code_for_input "$reference_file" "$line")

    # Increment the total test counter
    ((total_tests++))

    # Compare the actual output with the expected output
    if [ "$submitted_output" == "$reference_output" ]; then
        ((success_count++))
    fi
done < "$input_file"

# Calculate success percentage
percentage=$((success_count * 100 / total_tests))

echo "$percentage"  # Output the success percentage

# Remove the submitted code file
rm "$submitted_code"