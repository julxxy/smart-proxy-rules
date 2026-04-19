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

# 处理 URLhaus 恶意域名列表（https://urlhaus.abuse.ch/downloads/hostfile/）
REJECT_URLHAUS="reject/reject-urlhaus.txt"

echo "Downloading URLhaus hostfile..."
curl -s https://urlhaus.abuse.ch/downloads/hostfile/ -o /tmp/urlhaus-raw.txt

if [ -f /tmp/urlhaus-raw.txt ]; then
	echo "Processing..."

	# 保留原始注释行（来源、更新时间、条目数等）
	grep '^#' /tmp/urlhaus-raw.txt >"$REJECT_URLHAUS"

	# 提取纯域名（去掉 127.0.0.1 前缀），去重排序后追加
	grep -v '^#' /tmp/urlhaus-raw.txt |
		grep -v '^$' |
		awk '{print $2}' |
		grep -v '^$' |
		sort -u \
			>>"$REJECT_URLHAUS"

	COUNT=$(grep -v '^#' "$REJECT_URLHAUS" | grep -v '^$' | wc -l | tr -d ' ')
	echo "Done! $COUNT domains saved to $REJECT_URLHAUS"
else
	echo "Download failed."
	exit 1
fi

echo "$OUTPUT_FILE $OUTPUT_YAML Done."
echo "  conf -> $OUTPUT_FILE"
echo "  yaml -> $OUTPUT_YAML"
