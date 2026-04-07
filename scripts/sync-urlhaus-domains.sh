#!/usr/bin/env bash
set -euo pipefail

REJECT_URLHAUS="reject/reject-urlhaus.txt"

echo "Downloading URLhaus hostfile..."
curl -s https://urlhaus.abuse.ch/downloads/hostfile/ -o /tmp/urlhaus-raw.txt

if [ -f /tmp/urlhaus-raw.txt ]; then
  echo "Processing..."

  # 保留原始注释行（来源、更新时间、条目数等）
  grep '^#' /tmp/urlhaus-raw.txt > "$REJECT_URLHAUS"

  # 提取纯域名（去掉 127.0.0.1 前缀），去重排序后追加
  grep -v '^#' /tmp/urlhaus-raw.txt \
    | grep -v '^$' \
    | awk '{print $2}' \
    | grep -v '^$' \
    | sort -u \
    >> "$REJECT_URLHAUS"

  COUNT=$(grep -v '^#' "$REJECT_URLHAUS" | grep -v '^$' | wc -l | tr -d ' ')
  echo "Done! $COUNT domains saved to $REJECT_URLHAUS"

  # 清理临时文件
  rm -f /tmp/urlhaus-raw.txt
  echo "Cleaned up /tmp/urlhaus-raw.txt"
else
  echo "Download failed."
  exit 1
fi
