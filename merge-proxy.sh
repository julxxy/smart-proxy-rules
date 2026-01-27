#!/bin/bash
# This script merges multiple proxy configuration files into a single file.

OUTPUT_FILE="smart-proxy.conf"
DEFAULT_DIR="default"

# Clear the output file if it exists, or create a new one
: > "$OUTPUT_FILE"

echo "Merging files from $DEFAULT_DIR into $OUTPUT_FILE..."

# Loop through each file in the default directory
for file in "$DEFAULT_DIR"/*; do
    if [ -f "$file" ]; then
        echo "Processing $file..."

        # Append a header for clarity (optional)
        echo "# Source: $(basename "$file")" >> "$OUTPUT_FILE"

        # Append the content of the file
        cat "$file" >> "$OUTPUT_FILE"

        # Ensure there is a newline at the end of each file's content
        echo "" >> "$OUTPUT_FILE"
    fi
done

echo "Done. All rules merged into $OUTPUT_FILE"
