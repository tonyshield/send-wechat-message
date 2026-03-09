#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
chat_name="${1:-}"
WECHAT_SKILL_DIR="$script_dir"
# shellcheck source=lib_wechat_ui.sh
. "$script_dir/lib_wechat_ui.sh"

if [ -z "$chat_name" ]; then
  echo "Usage: $0 <chat_name>" >&2
  exit 1
fi

"$script_dir/prepare_wechat_viewport.sh"
open -a WeChat

title_matches() {
  local shot_file="$1"
  wechat_ocr_contains_text "$shot_file" 0.18 0.94 0.18 0.05 "$chat_name"
}

click_result_from_region() {
  local shot_file="$1"
  local region_left="$2"
  local region_bottom="$3"
  local region_width="$4"
  local region_height="$5"
  local rect coords norm_x norm_y norm_w norm_h
  rect="$(wechat_get_window_rect)"

  coords="$(
    wechat_ocr_find_coords "$shot_file" "$region_left" "$region_bottom" "$region_width" "$region_height" "$chat_name"
  )"

  if [ -z "$coords" ]; then
    return 1
  fi

  set -- $(printf '%s\n' "$coords" | tr ',' ' ')
  norm_x="$1"
  norm_y="$2"
  norm_w="$3"
  norm_h="$4"

  wechat_click_norm_coords "$rect" "$norm_x" "$norm_y" "$norm_w" "$norm_h" >/dev/null
  return 0
}

current_shot="$("$script_dir/capture_wechat_window.sh")"

if title_matches "$current_shot"; then
  printf 'OPENED %s current\n' "$chat_name"
  exit 0
fi

if click_result_from_region "$current_shot" 0.00 0.02 0.30 0.92; then
  sleep 0.35
  visible_shot="$("$script_dir/capture_wechat_window.sh")"
  if title_matches "$visible_shot"; then
    printf 'OPENED %s visible_sidebar\n' "$chat_name"
    exit 0
  fi
fi

if "$script_dir/search_chat_and_click_local_result.sh" "$chat_name" >/dev/null 2>&1; then
  sleep 0.35
  search_shot="$("$script_dir/capture_wechat_window.sh")"
  if title_matches "$search_shot"; then
    printf 'OPENED %s search\n' "$chat_name"
    exit 0
  fi
fi

echo "Could not safely open verified chat: $chat_name" >&2
exit 1
