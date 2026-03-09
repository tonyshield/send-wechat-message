#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
steps="${1:-8}"
pixels="${2:-180}"
focus_x="${3:-}"
focus_y="${4:-}"
dry_run="${SCROLL_CHAT_HISTORY_DRY_RUN:-0}"

case "$steps" in
  ''|*[!0-9]*)
    echo "steps must be a non-negative integer" >&2
    exit 1
    ;;
esac

case "$pixels" in
  ''|*[!0-9-]*)
    echo "pixels must be an integer" >&2
    exit 1
    ;;
esac

if [ -z "$focus_x" ] || [ -z "$focus_y" ]; then
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
  focus_x=$(( win_x + (win_w * 62 / 100) ))
  focus_y=$(( win_y + (win_h * 32 / 100) ))
fi

case "$focus_x" in
  ''|*[!0-9-]*)
    echo "focus_x must be an integer" >&2
    exit 1
    ;;
esac

case "$focus_y" in
  ''|*[!0-9-]*)
    echo "focus_y must be an integer" >&2
    exit 1
    ;;
esac

if [ "$focus_x" -le 0 ] || [ "$focus_y" -le 0 ]; then
  echo "Refusing to scroll with invalid focus coordinates: ($focus_x,$focus_y)" >&2
  exit 1
fi

if [ "$dry_run" = "1" ]; then
  echo "Dry run: steps=$steps pixels=$pixels focus=($focus_x,$focus_y)"
  exit 0
fi

"$script_dir/prepare_wechat_viewport.sh"

osascript -l JavaScript <<JXA
ObjC.import('CoreGraphics')
ObjC.import('Foundation')

const steps = Number($steps)
const pixels = Number($pixels)
const focusX = Number($focus_x)
const focusY = Number($focus_y)

if (!Number.isFinite(steps) || !Number.isFinite(pixels) || !Number.isFinite(focusX) || !Number.isFinite(focusY)) {
  throw new Error("Invalid scroll parameters")
}

function mouseEvent(type, x, y) {
  return $.CGEventCreateMouseEvent(null, type, {x:x, y:y}, $.kCGMouseButtonLeft)
}

function post(event) {
  $.CGEventPost($.kCGHIDEventTap, event)
}

function click(x, y) {
  post(mouseEvent($.kCGEventMouseMoved, x, y))
  post(mouseEvent($.kCGEventLeftMouseDown, x, y))
  post(mouseEvent($.kCGEventLeftMouseUp, x, y))
}

function scroll(delta) {
  const event = $.CGEventCreateScrollWheelEvent(null, $.kCGScrollEventUnitPixel, 1, delta)
  $.CGEventPost($.kCGHIDEventTap, event)
}

click(focusX, focusY)
$.NSThread.sleepForTimeInterval(0.2)
for (let i = 0; i < steps; i++) {
  scroll(pixels)
  $.NSThread.sleepForTimeInterval(0.03)
}
JXA

echo "Scrolled chat history: steps=$steps pixels=$pixels focus=($focus_x,$focus_y)"
