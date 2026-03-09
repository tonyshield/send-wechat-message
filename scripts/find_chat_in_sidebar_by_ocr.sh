#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
target_name="${1:-}"
max_scrolls="${2:-18}"
WECHAT_SKILL_DIR="$script_dir"
# shellcheck source=lib_wechat_ui.sh
. "$script_dir/lib_wechat_ui.sh"

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

rect="$(wechat_get_window_rect)"
parsed="$(wechat_parse_rect "$rect" || true)"
if [ -z "$parsed" ]; then
  echo "Could not parse WeChat window bounds: $rect" >&2
  exit 1
fi

read -r win_x win_y win_w win_h <<<"$parsed"

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
    wechat_ocr_find_coords "$shot_file" 0.00 0.02 0.30 0.92 "$target_name"
  )"

  if [ -n "$coords" ]; then
    set -- $(printf '%s\n' "$coords" | tr ',' ' ')
    norm_x="$1"
    norm_y="$2"
    norm_w="$3"
    norm_h="$4"
    read -r click_x click_y <<<"$(wechat_click_norm_coords "$rect" "$norm_x" "$norm_y" "$norm_w" "$norm_h")"
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
