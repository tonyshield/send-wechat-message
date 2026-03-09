#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <message>" >&2
  exit 1
fi

message="$1"

"$script_dir/prepare_wechat_viewport.sh"

osascript - "$message" <<'OSA'
on run argv
  if (count of argv) is not 1 then error "Expected exactly one message argument."

  set messageText to item 1 of argv

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
      delay 0.05
      set value of attribute "AXValue" of composerElement to messageText
    end tell
  end tell
end run
OSA
