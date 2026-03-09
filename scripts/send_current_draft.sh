#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

"$script_dir/prepare_wechat_viewport.sh"

osascript <<'OSA'
tell application "WeChat" to activate
tell application "System Events"
  key code 36
end tell
OSA
