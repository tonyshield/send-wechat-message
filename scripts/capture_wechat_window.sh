#!/usr/bin/env bash
set -euo pipefail

out="${1:-$(mktemp -t wechat-window).png}"

open -a WeChat
osascript -e 'tell application "WeChat" to activate' >/dev/null
sleep 0.2

rect="$(
  osascript <<'OSA'
tell application "System Events"
  tell process "WeChat"
    set w to window 1
    set {x, y} to position of w
    set {w0, h0} to size of w
    return (x as text) & "," & (y as text) & "," & (w0 as text) & "," & (h0 as text)
  end tell
end tell
OSA
)"

screencapture -x -R"$rect" "$out"
printf '%s\n' "$out"
