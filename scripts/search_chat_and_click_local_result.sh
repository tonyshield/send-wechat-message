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
  wechat_ocr_find_coords "$shot_file" 0.00 0.45 0.30 0.53 "$chat_name"
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
