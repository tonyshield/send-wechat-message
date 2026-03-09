#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
target_name="${1:-}"
max_scrolls="${2:-18}"

if [ -z "$target_name" ]; then
  echo "Usage: $0 <chat_name> [max_scrolls]" >&2
  exit 1
fi

case "$max_scrolls" in
  ''|*[!0-9]*)
    echo "max_scrolls must be a non-negative integer" >&2
    exit 1
    ;;
esac

"$script_dir/prepare_wechat_viewport.sh"
open -a WeChat
osascript -e 'tell application "WeChat" to activate' >/dev/null
sleep 0.3

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

sidebar_focus_x=$(( win_x + (win_w * 14 / 100) ))
sidebar_focus_y=$(( win_y + (win_h * 30 / 100) ))
scroll_pixels=$(( win_h * 22 / 100 ))
if [ "$scroll_pixels" -lt 120 ]; then
  scroll_pixels=120
fi

tmp_dir="$(mktemp -d -t wechat-sidebar-scan)"
trap 'rm -rf -- "$tmp_dir"' EXIT

for attempt in $(seq 0 "$max_scrolls"); do
  shot_file=$(printf '%s/scan-%03d.png' "$tmp_dir" "$attempt")
  "$script_dir/capture_wechat_window.sh" "$shot_file" >/dev/null
  coords="$(
    "$script_dir/ocr_wechat_screenshot.sh" --json --region 0.00 0.02 0.30 0.92 "$shot_file" | \
      CHAT_NAME="$target_name" python3 -c '
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

  if [ -n "$coords" ]; then
    set -- $(printf '%s\n' "$coords" | tr ',' ' ')
    norm_x="$1"
    norm_y="$2"
    norm_w="$3"
    norm_h="$4"
    click_x="$(python3 -c 'import sys; win_x, win_w, x, w = map(float, sys.argv[1:5]); print(int(round(win_x + (x + w / 2.0) * win_w)))' "$win_x" "$win_w" "$norm_x" "$norm_w")"
    click_y="$(python3 -c 'import sys; win_y, win_h, y, h = map(float, sys.argv[1:5]); print(int(round(win_y + (1.0 - (y + h / 2.0)) * win_h)))' "$win_y" "$win_h" "$norm_y" "$norm_h")"

    osascript -l JavaScript <<JXA
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
    printf 'FOUND %s %s %s\n' "$target_name" "$click_x" "$click_y"
    exit 0
  fi

  if [ "$attempt" -lt "$max_scrolls" ]; then
    osascript -l JavaScript <<JXA >/dev/null
ObjC.import('CoreGraphics')
ObjC.import('Foundation')

function mouseEvent(type, x, y) {
  return $.CGEventCreateMouseEvent(null, type, {x:x, y:y}, $.kCGMouseButtonLeft)
}

function post(event) {
  $.CGEventPost($.kCGHIDEventTap, event)
}

const focusX = Number($sidebar_focus_x)
const focusY = Number($sidebar_focus_y)
const pixels = Number($scroll_pixels)

post(mouseEvent($.kCGEventMouseMoved, focusX, focusY))
$.NSThread.sleepForTimeInterval(0.05)
post(mouseEvent($.kCGEventLeftMouseDown, focusX, focusY))
post(mouseEvent($.kCGEventLeftMouseUp, focusX, focusY))
$.NSThread.sleepForTimeInterval(0.1)

for (let i = 0; i < 3; i++) {
  const event = $.CGEventCreateScrollWheelEvent(null, $.kCGScrollEventUnitPixel, 1, -pixels)
  $.CGEventPost($.kCGHIDEventTap, event)
  $.NSThread.sleepForTimeInterval(0.05)
}
JXA
    sleep 0.6
  fi
done

echo "Chat not found in visible sidebar after $((max_scrolls + 1)) scans: $target_name" >&2
exit 1
