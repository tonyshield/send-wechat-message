#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
chat_name="${1:-}"
WECHAT_SKILL_DIR="$script_dir"
# shellcheck source=lib_wechat_ui.sh
. "$script_dir/lib_wechat_ui.sh"

if [ -z "$chat_name" ]; then
  echo "Usage: $0 <chat_name>" >&2
  exit 1
fi

"$script_dir/prepare_wechat_viewport.sh"
open -a WeChat

osascript - "$chat_name" <<'OSA'
on run argv
  set chatName to item 1 of argv
  tell application "WeChat" to activate
  delay 0.2
  tell application "System Events"
    tell process "WeChat"
      keystroke "f" using {command down}
      delay 0.3
      set focusedElement to value of attribute "AXFocusedUIElement"
      set value of attribute "AXValue" of focusedElement to chatName
      delay 0.8
    end tell
  end tell
end run
OSA

rect="$(wechat_get_window_rect)"
if ! wechat_parse_rect "$rect" >/dev/null; then
  echo "Could not parse WeChat window bounds: $rect" >&2
  exit 1
fi

shot_file="$("$script_dir/capture_wechat_window.sh")"

coords="$(
  "$script_dir/ocr_wechat_screenshot.sh" --json --region 0.00 0.45 0.30 0.53 "$shot_file" | \
    CHAT_NAME="$chat_name" python3 -c '
import json
import os
import sys

target = os.environ["CHAT_NAME"].replace(" ", "")
items = json.load(sys.stdin)

local_headers = {"群聊", "联系人", "聊天记录", "公众号", "服务号", "小程序"}
local_header_y = None

for item in items:
    compact = item["text"].replace(" ", "")
    if compact in local_headers:
        local_header_y = item["y"] if local_header_y is None else max(local_header_y, item["y"])

local_candidates = []
fallback_candidates = []

for item in items:
    text = item["text"].replace(" ", "")
    if not text:
        continue

    score = None
    if text == target:
        score = 0
    elif text.startswith(target):
        score = 1
    elif target in text:
        score = 2

    if score is None:
        continue

    candidate = (score, -item["y"], item["x"], item)
    fallback_candidates.append(candidate)

    if local_header_y is not None and item["y"] < (local_header_y - 0.003):
        local_candidates.append(candidate)

if local_candidates:
    _, _, _, item = sorted(local_candidates)[0]
    row_x = 0.03
    row_w = 0.24
    row_h = max(0.032, item["h"] * 2.6)
    row_y = max(0.0, item["y"] - (row_h - item["h"]) / 2.0)
    print("{x},{y},{w},{h}".format(x=row_x, y=row_y, w=row_w, h=row_h))
    sys.exit(0)

if fallback_candidates:
    _, _, _, item = sorted(fallback_candidates)[0]
    print("{x},{y},{w},{h}".format(x=item["x"], y=item["y"], w=item["w"], h=item["h"]))
    sys.exit(0)

sys.exit(0)
'
)"

if [ -z "$coords" ]; then
  echo "Could not find local search result for: $chat_name" >&2
  exit 1
fi

set -- $(printf '%s\n' "$coords" | tr ',' ' ')
norm_x="$1"
norm_y="$2"
norm_w="$3"
norm_h="$4"

read -r click_x click_y <<<"$(wechat_click_norm_coords "$rect" "$norm_x" "$norm_y" "$norm_w" "$norm_h")"
printf 'FOUND %s %s %s\n' "$chat_name" "$click_x" "$click_y"
