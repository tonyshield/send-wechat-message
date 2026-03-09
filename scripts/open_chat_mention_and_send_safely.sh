#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
chat_name="${1:-}"
member_name="${2:-}"
message_text="${3:-}"

if [ "$#" -ne 3 ] || [ -z "$chat_name" ] || [ -z "$member_name" ]; then
  echo "Usage: $0 <chat_name> <member_name> <message>" >&2
  exit 1
fi

export WECHAT_VIEWPORT_PREPARED=0

"$script_dir/prepare_wechat_viewport.sh"
export WECHAT_VIEWPORT_PREPARED=1

"$script_dir/open_chat_safely.sh" "$chat_name" >/dev/null
"$script_dir/verify_current_chat_title_by_ocr.sh" "$chat_name" >/dev/null
"$script_dir/mention_group_member_and_set_value.sh" "$member_name" "$message_text"
"$script_dir/send_current_draft.sh" >/dev/null

printf 'SENT %s @%s\n' "$chat_name" "$member_name"
