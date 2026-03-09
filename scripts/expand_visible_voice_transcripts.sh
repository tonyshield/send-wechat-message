#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
image_path="${1:-}"
timeout_seconds="${2:-8}"

if [ -z "$image_path" ]; then
  echo "Usage: $0 <image.png> [timeout_seconds]" >&2
  exit 1
fi

if [ ! -f "$image_path" ]; then
  echo "Image not found: $image_path" >&2
  exit 1
fi

case "$timeout_seconds" in
  ''|*[!0-9]*)
    echo "timeout_seconds must be a non-negative integer" >&2
    exit 1
    ;;
esac

open -a WeChat
osascript -e 'tell application "WeChat" to activate' >/dev/null
sleep 0.2

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
  echo "Could not parse WeChat window bounds: $rect" >&2
  exit 1
fi

win_x="$1"
win_y="$2"
win_w="$3"
win_h="$4"

ocr_json="$("$script_dir/ocr_wechat_screenshot.sh" --json "$image_path")"

coords="$(
  printf '%s\n' "$ocr_json" | python3 -c '
import json
import sys

win_x, win_y, win_w, win_h = map(float, sys.argv[1:5])
items = json.load(sys.stdin)
matches = []

for item in items:
    compact = item["text"].replace(" ", "")
    if "转文字" not in compact:
        continue
    center_x = win_x + (item["x"] + item["w"] / 2.0) * win_w
    center_y = win_y + (1.0 - (item["y"] + item["h"] / 2.0)) * win_h
    matches.append((center_y, center_x))

matches.sort()
for center_y, center_x in matches:
    print(f"{int(round(center_x))},{int(round(center_y))}")
' "$win_x" "$win_y" "$win_w" "$win_h"
)"

if [ -z "$coords" ]; then
  echo "0"
  exit 0
fi

click_count="$(printf '%s\n' "$coords" | wc -l | tr -d ' ')"

osascript -l JavaScript - "$coords" <<'JXA'
ObjC.import('CoreGraphics')
ObjC.import('Foundation')

function scriptArgs() {
  const args = $.NSProcessInfo.processInfo.arguments
  const values = []
  for (let i = 0; i < Number(args.count); i++) {
    values.push(ObjC.unwrap(args.objectAtIndex(i)))
  }
  return values.slice(4)
}

const rawCoords = scriptArgs().join('\n')
const pairs = rawCoords.split(/\n+/).filter(Boolean)

function mouseEvent(type, x, y) {
  return $.CGEventCreateMouseEvent(null, type, {x:x, y:y}, $.kCGMouseButtonLeft)
}

function post(event) {
  $.CGEventPost($.kCGHIDEventTap, event)
}

function click(x, y) {
  post(mouseEvent($.kCGEventMouseMoved, x, y))
  $.NSThread.sleepForTimeInterval(0.05)
  post(mouseEvent($.kCGEventLeftMouseDown, x, y))
  post(mouseEvent($.kCGEventLeftMouseUp, x, y))
}

for (const pair of pairs) {
  const [x, y] = pair.split(',').map(Number)
  if (!Number.isFinite(x) || !Number.isFinite(y)) {
    continue
  }
  click(x, y)
  $.NSThread.sleepForTimeInterval(0.35)
}
JXA

baseline_hash="$(md5 -q "$image_path")"
previous_hash="$baseline_hash"
changed=0
stable_polls=0

if [ "$timeout_seconds" -gt 0 ]; then
  sleep 1
fi

for _ in $(seq 1 "$timeout_seconds"); do
  probe_image="$(mktemp -t wechat-window).png"
  "$script_dir/capture_wechat_window.sh" "$probe_image" >/dev/null
  current_hash="$(md5 -q "$probe_image")"

  if [ "$current_hash" != "$baseline_hash" ]; then
    changed=1
  fi

  if [ "$current_hash" = "$previous_hash" ]; then
    stable_polls=$((stable_polls + 1))
  else
    stable_polls=0
  fi
  previous_hash="$current_hash"

  remaining_count="$(
    "$script_dir/ocr_wechat_screenshot.sh" --json "$probe_image" | python3 -c '
import json
import sys

items = json.load(sys.stdin)
count = 0
for item in items:
    if "转文字" in item["text"].replace(" ", ""):
        count += 1
print(count)
'
  )"

  if [ "$changed" -eq 1 ] && { [ "${remaining_count:-0}" -eq 0 ] || [ "$stable_polls" -ge 1 ]; }; then
    break
  fi

  sleep 1
done

echo "$click_count"
