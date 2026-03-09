#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
member_name="${1:-}"
message_text="${2:-}"
WECHAT_SKILL_DIR="$script_dir"
# shellcheck source=lib_wechat_ui.sh
. "$script_dir/lib_wechat_ui.sh"

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

find_candidate_coords() {
  local region_left="$1"
  local region_bottom="$2"
  local region_width="$3"
  local region_height="$4"

  wechat_ocr_find_coords "$shot_file" "$region_left" "$region_bottom" "$region_width" "$region_height" "$member_name"
}

coords="$(
  find_candidate_coords 0.22 0.05 0.18 0.24
)"

if [ -z "$coords" ]; then
  coords="$(
    find_candidate_coords 0.18 0.03 0.26 0.30
  )"
fi

if [ -z "$coords" ]; then
  echo "Could not find group member in visible @ mention candidates: $member_name" >&2
  exit 1
fi

rect="$(wechat_get_window_rect)"
if ! wechat_parse_rect "$rect" >/dev/null; then
  echo "Could not parse WeChat window bounds: $rect" >&2
  exit 1
fi

set -- $(printf '%s\n' "$coords" | tr ',' ' ')
norm_x="$1"
norm_y="$2"
norm_w="$3"
norm_h="$4"

wechat_click_norm_coords "$rect" "$norm_x" "$norm_y" "$norm_w" "$norm_h" >/dev/null

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
