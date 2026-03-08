#!/usr/bin/env bash
set -euo pipefail

osascript <<'OSA'
tell application "WeChat" to activate
tell application "System Events"
  key code 36
end tell
OSA
