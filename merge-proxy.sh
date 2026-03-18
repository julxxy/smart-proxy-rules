#!/bin/bash

OUTPUT_FILE="smart-proxy.conf"
OUTPUT_YAML="smart-proxy.yaml"
DEFAULT_DIR="default"

# Clear the output files if they exist, or create new ones
: >"$OUTPUT_FILE"
: >"$OUTPUT_YAML"

echo "Merging files from $DEFAULT_DIR into $OUTPUT_FILE and $OUTPUT_YAML..."

# Write YAML header
echo "payload:" >>"$OUTPUT_YAML"

# Loop through each file in the default directory
for file in "$DEFAULT_DIR"/*; do
  if [ -f "$file" ]; then
    echo "Processing $file..."

    # ---- conf file ----
    echo "# Source: $(basename "$file")" >>"$OUTPUT_FILE"
    cat "$file" >>"$OUTPUT_FILE"
    echo "" >>"$OUTPUT_FILE"

    # ---- yaml file ----
    echo "  # Source: $(basename "$file")" >>"$OUTPUT_YAML"
    # Convert each non-empty, non-comment line into a YAML payload item
    while IFS= read -r line; do
      # Skip empty lines and comment lines
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      echo "  - '$line'" >>"$OUTPUT_YAML"
    done <"$file"
    echo "" >>"$OUTPUT_YAML"
  fi
done

echo "Done."
echo "  conf -> $OUTPUT_FILE"
echo "  yaml -> $OUTPUT_YAML"
