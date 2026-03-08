#!/usr/bin/env bash
set -euo pipefail

out="${1:-$(mktemp -t wechat-window).png}"
state_dir="${TMPDIR:-/tmp}/send-wechat-message"
state_file="$state_dir/captures.txt"

mkdir -p "$state_dir"

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
    set w to targetWindow
    set {x, y} to position of w
    set {w0, h0} to size of w
    return (x as text) & "," & (y as text) & "," & (w0 as text) & "," & (h0 as text)
  end tell
end tell
OSA
)"

screencapture -x -R"$rect" "$out"
printf '%s\n' "$out" >>"$state_file"
printf '%s\n' "$out"
