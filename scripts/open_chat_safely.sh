#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
chat_name="${1:-}"

if [ -z "$chat_name" ]; then
  echo "Usage: $0 <chat_name>" >&2
  exit 1
fi

"$script_dir/prepare_wechat_viewport.sh"
open -a WeChat

if "$script_dir/verify_current_chat_title_by_ocr.sh" "$chat_name" >/dev/null 2>&1; then
  printf 'OPENED %s current\n' "$chat_name"
  exit 0
fi

if "$script_dir/find_chat_in_sidebar_by_ocr.sh" "$chat_name" 0 >/dev/null 2>&1; then
  sleep 0.4
  if "$script_dir/verify_current_chat_title_by_ocr.sh" "$chat_name" >/dev/null 2>&1; then
    printf 'OPENED %s visible_sidebar\n' "$chat_name"
    exit 0
  fi
fi

if "$script_dir/search_chat_and_click_local_result.sh" "$chat_name" >/dev/null 2>&1; then
  sleep 0.4
  if "$script_dir/verify_current_chat_title_by_ocr.sh" "$chat_name" >/dev/null 2>&1; then
    printf 'OPENED %s search\n' "$chat_name"
    exit 0
  fi
fi

echo "Could not safely open verified chat: $chat_name" >&2
exit 1
