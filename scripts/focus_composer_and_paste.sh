#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <message>" >&2
  exit 1
fi

message="$1"
printf '%s' "$message" | pbcopy

osascript <<'OSA'
tell application "WeChat" to activate
tell application "System Events"
  key code 48
  delay 0.2
  keystroke "a" using command down
  key code 51
  click menu bar item "编辑" of menu bar 1 of process "WeChat"
  delay 0.2
  click menu item "粘贴" of menu 1 of menu bar item "编辑" of menu bar 1 of process "WeChat"
end tell
OSA
