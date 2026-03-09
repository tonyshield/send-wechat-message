#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
member_name="${1:-}"
message_text="${2:-}"

if [ -z "$member_name" ] || [ "$#" -ne 2 ]; then
  echo "Usage: $0 <member_name> <message>" >&2
  exit 1
fi

"$script_dir/prepare_wechat_viewport.sh"

tell_focus_and_clear='
tell application "WeChat" to activate
delay 0.2
tell application "System Events"
  tell process "WeChat"
    set composerElement to missing value
    repeat 5 times
      set focusedElement to value of attribute "AXFocusedUIElement"
      try
        if value of attribute "AXRole" of focusedElement is "AXTextArea" then
          set composerElement to focusedElement
          exit repeat
        end if
      end try
      key code 48
      delay 0.15
    end repeat
    if composerElement is missing value then error "Could not focus the WeChat composer."
    set value of attribute "AXValue" of composerElement to ""
  end tell
end tell'

osascript -e "$tell_focus_and_clear" >/dev/null

osascript <<'OSA'
tell application "WeChat" to activate
delay 0.2
tell application "System Events"
  tell process "WeChat"
    keystroke "@"
    delay 0.5
  end tell
end tell
OSA

shot_file="$("$script_dir/capture_wechat_window.sh")"

coords="$(
  "$script_dir/ocr_wechat_screenshot.sh" --json --region 0.30 0.00 0.69 0.30 "$shot_file" | \
    MEMBER_NAME="$member_name" python3 -c '
import json
import os
import sys

target = os.environ["MEMBER_NAME"].replace(" ", "")
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
  echo "Could not find group member in visible @ mention candidates: $member_name" >&2
  exit 1
fi

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

osascript - "$message_text" <<'OSA'
on run argv
  set suffixText to item 1 of argv
  tell application "WeChat" to activate
  delay 0.2
  tell application "System Events"
    tell process "WeChat"
      set composerElement to missing value
      repeat 5 times
        set focusedElement to value of attribute "AXFocusedUIElement"
        try
          if value of attribute "AXRole" of focusedElement is "AXTextArea" then
            set composerElement to focusedElement
            exit repeat
          end if
        end try
        key code 48
        delay 0.15
      end repeat
      if composerElement is missing value then error "Could not focus the WeChat composer."
      set currentValue to value of attribute "AXValue" of composerElement
      set value of attribute "AXValue" of composerElement to (currentValue & " " & suffixText)
    end tell
  end tell
end run
OSA
