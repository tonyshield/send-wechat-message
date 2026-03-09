#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
chat_name="${1:-}"
message_text="${2:-}"

if [ "$#" -ne 2 ] || [ -z "$chat_name" ]; then
  echo "Usage: $0 <chat_name> <message>" >&2
  exit 1
fi

export WECHAT_VIEWPORT_PREPARED=0

"$script_dir/prepare_wechat_viewport.sh"
export WECHAT_VIEWPORT_PREPARED=1

"$script_dir/open_chat_safely.sh" "$chat_name"
"$script_dir/verify_current_chat_title_by_ocr.sh" "$chat_name" >/dev/null
"$script_dir/focus_composer_and_set_value.sh" "$message_text"

printf 'DRAFTED %s\n' "$chat_name"
