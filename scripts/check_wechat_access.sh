#!/usr/bin/env bash
set -euo pipefail

if ! osascript -e 'tell application "System Events" to get name of every process' >/dev/null 2>&1; then
  echo "System Events is not accessible from the current host process." >&2
  exit 1
fi

if ! open -Ra WeChat >/dev/null 2>&1; then
  echo "WeChat.app is not installed or not discoverable by Launch Services." >&2
  exit 1
fi

open -a WeChat

if ! osascript -e 'tell application "WeChat" to activate' \
  -e 'tell application "System Events" to tell process "WeChat" to get role of window 1' >/dev/null 2>&1; then
  echo "WeChat opened, but GUI automation is blocked. Check Accessibility and Automation permissions." >&2
  exit 1
fi

echo "WeChat is installed and GUI automation is available."
