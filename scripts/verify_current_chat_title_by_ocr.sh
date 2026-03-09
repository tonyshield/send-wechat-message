#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
chat_name="${1:-}"

if [ -z "$chat_name" ]; then
  echo "Usage: $0 <chat_name>" >&2
  exit 1
fi

shot_file="$("$script_dir/capture_wechat_window.sh")"

match="$(
  "$script_dir/ocr_wechat_screenshot.sh" --json --region 0.18 0.94 0.18 0.05 "$shot_file" | \
    CHAT_NAME="$chat_name" python3 -c '
import json
import os
import sys

target = os.environ["CHAT_NAME"].replace(" ", "")
items = json.load(sys.stdin)

for item in items:
    text = item["text"].replace(" ", "")
    if not text:
        continue
    if text == target or text.startswith(target) or target in text:
        print(item["text"])
        break
'
)"

if [ -z "$match" ]; then
  echo "Current chat title does not match target: $chat_name" >&2
  echo "Screenshot: $shot_file" >&2
  exit 1
fi

printf 'VERIFIED %s %s\n' "$chat_name" "$shot_file"
