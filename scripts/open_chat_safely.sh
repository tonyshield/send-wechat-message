#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
chat_name="${1:-}"

if [ -z "$chat_name" ]; then
  echo "Usage: $0 <chat_name>" >&2
  exit 1
fi

"$script_dir/prepare_wechat_viewport.sh"
open -a WeChat

title_matches() {
  local shot_file="$1"
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
        sys.exit(0)
sys.exit(1)
'
}

click_result_from_region() {
  local shot_file="$1"
  local region_left="$2"
  local region_bottom="$3"
  local region_width="$4"
  local region_height="$5"
  local rect nums win_x win_y win_w win_h coords norm_x norm_y norm_w norm_h click_x click_y

  rect="$(
    osascript <<'OSA'
tell application "System Events"
  tell process "WeChat"
    set targetWindow to missing value
    repeat with w in windows
      try
        if name of w is "微信" then
          set targetWindow to w
          exit repeat
        end if
      end try
    end repeat
    if targetWindow is missing value then
      set targetWindow to window 1
    end if

    set {x, y} to position of targetWindow
    set {w0, h0} to size of targetWindow
    return (x as integer) & "," & (y as integer) & "," & (w0 as integer) & "," & (h0 as integer)
  end tell
end tell
OSA
  )"

  set -- $(printf '%s\n' "$rect" | grep -Eo '[0-9]+')
  if [ "$#" -lt 4 ]; then
    return 1
  fi
  win_x="$1"
  win_y="$2"
  win_w="$3"
  win_h="$4"

  coords="$(
    "$script_dir/ocr_wechat_screenshot.sh" --json --region "$region_left" "$region_bottom" "$region_width" "$region_height" "$shot_file" | \
      CHAT_NAME="$chat_name" python3 -c '
import json
import os
import sys

target = os.environ["CHAT_NAME"].replace(" ", "")
items = json.load(sys.stdin)
candidates = []

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
    candidates.append((score, -item["y"], item["x"], item))

if not candidates:
    sys.exit(0)

_, _, _, item = sorted(candidates)[0]
print("{x},{y},{w},{h}".format(x=item["x"], y=item["y"], w=item["w"], h=item["h"]))
'
  )"

  if [ -z "$coords" ]; then
    return 1
  fi

  set -- $(printf '%s\n' "$coords" | tr ',' ' ')
  norm_x="$1"
  norm_y="$2"
  norm_w="$3"
  norm_h="$4"

  click_x="$(python3 -c 'import sys; win_x, win_w, x, w = map(float, sys.argv[1:5]); print(int(round(win_x + (x + w / 2.0) * win_w)))' "$win_x" "$win_w" "$norm_x" "$norm_w")"
  click_y="$(python3 -c 'import sys; win_y, win_h, y, h = map(float, sys.argv[1:5]); print(int(round(win_y + (1.0 - (y + h / 2.0)) * win_h)))' "$win_y" "$win_h" "$norm_y" "$norm_h")"

  osascript -l JavaScript <<JXA >/dev/null
ObjC.import('CoreGraphics')
ObjC.import('Foundation')

function mouseEvent(type, x, y) {
  return $.CGEventCreateMouseEvent(null, type, {x:x, y:y}, $.kCGMouseButtonLeft)
}

function post(event) {
  $.CGEventPost($.kCGHIDEventTap, event)
}

const clickX = Number($click_x)
const clickY = Number($click_y)

post(mouseEvent($.kCGEventMouseMoved, clickX, clickY))
$.NSThread.sleepForTimeInterval(0.05)
post(mouseEvent($.kCGEventLeftMouseDown, clickX, clickY))
post(mouseEvent($.kCGEventLeftMouseUp, clickX, clickY))
JXA
  return 0
}

current_shot="$("$script_dir/capture_wechat_window.sh")"

if title_matches "$current_shot"; then
  printf 'OPENED %s current\n' "$chat_name"
  exit 0
fi

if click_result_from_region "$current_shot" 0.00 0.02 0.30 0.92; then
  sleep 0.35
  visible_shot="$("$script_dir/capture_wechat_window.sh")"
  if title_matches "$visible_shot"; then
    printf 'OPENED %s visible_sidebar\n' "$chat_name"
    exit 0
  fi
fi

if "$script_dir/search_chat_and_click_local_result.sh" "$chat_name" >/dev/null 2>&1; then
  sleep 0.35
  search_shot="$("$script_dir/capture_wechat_window.sh")"
  if title_matches "$search_shot"; then
    printf 'OPENED %s search\n' "$chat_name"
    exit 0
  fi
fi

echo "Could not safely open verified chat: $chat_name" >&2
exit 1
