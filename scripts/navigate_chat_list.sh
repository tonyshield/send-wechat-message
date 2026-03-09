#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <offset>" >&2
  exit 1
fi

offset="$1"

case "$offset" in
  ''|*[!0-9-]*)
    echo "Offset must be an integer." >&2
    exit 1
    ;;
esac

if [ "$offset" -eq 0 ]; then
  exit 0
fi

"$script_dir/prepare_wechat_viewport.sh"

if [ "$offset" -gt 0 ]; then
  keycode=125
  steps="$offset"
else
  keycode=126
  steps=$(( -offset ))
fi

osascript <<OSA
tell application "WeChat" to activate
tell application "System Events"
  keystroke "1" using command down
  delay 0.25
  repeat $steps times
    key code $keycode
    delay 0.15
  end repeat
end tell
OSA
