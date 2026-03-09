#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
export WECHAT_VIEWPORT_PREPARED=0

max_pages="${1:-100}"
out_dir="${2:-}"

case "$max_pages" in
  ''|*[!0-9]*)
    echo "max_pages must be a positive integer" >&2
    exit 1
    ;;
esac

if [ "$max_pages" -le 0 ]; then
  echo "max_pages must be greater than 0" >&2
  exit 1
fi

if [ -z "$out_dir" ]; then
  out_dir="$(mktemp -d -t wechat-history)"
else
  mkdir -p "$out_dir"
fi

ocr_dir="$out_dir/ocr"
reference_file="$out_dir/conversation-reference.md"
mkdir -p "$ocr_dir"

"$script_dir/prepare_wechat_viewport.sh"
export WECHAT_VIEWPORT_PREPARED=1

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

    set {x, y} to position of targetWindow
    set {w0, h0} to size of targetWindow
    return (x as integer) & "," & (y as integer) & "," & (w0 as integer) & "," & (h0 as integer)
  end tell
end tell
OSA
)"

set -- $(printf '%s\n' "$rect" | grep -Eo '[0-9]+')
if [ "$#" -lt 4 ]; then
  echo "Could not parse WeChat window bounds: $rect" >&2
  exit 1
fi

win_x="$1"
win_y="$2"
win_w="$3"
win_h="$4"

# Focus inside the message history pane, not the left chat list or composer.
focus_x=$(( win_x + (win_w * 62 / 100) ))
focus_y=$(( win_y + (win_h * 32 / 100) ))

# Scroll by about half of the usable window height to keep strong overlap.
scroll_pixels=$(( win_h * 52 / 100 ))
if [ "$scroll_pixels" -lt 120 ]; then
  scroll_pixels=120
fi

meta_file="$out_dir/metadata.txt"
{
  echo "window=$rect"
  echo "focus=($focus_x,$focus_y)"
  echo "scroll_pixels=$scroll_pixels"
  echo "max_pages=$max_pages"
} >"$meta_file"

{
  echo "# Conversation Reference"
  echo
  echo "- source: overlapping WeChat screenshots"
  echo "- note: OCR output is best effort and may contain overlap duplicates between adjacent pages"
  echo
} >"$reference_file"

last_hash=""
reached_stable_top=0

for page in $(seq 1 "$max_pages"); do
  out_file=$(printf '%s/page-%03d.png' "$out_dir" "$page")
  "$script_dir/capture_wechat_window.sh" "$out_file" >/dev/null
  voice_clicks="$("$script_dir/expand_visible_voice_transcripts.sh" "$out_file" "${WECHAT_VOICE_TRANSCRIPT_TIMEOUT_SECONDS:-8}")"
  if [ "${voice_clicks:-0}" -gt 0 ]; then
    "$script_dir/capture_wechat_window.sh" "$out_file" >/dev/null
  fi
  current_hash=$(md5 -q "$out_file")
  echo "$(basename "$out_file") $current_hash voice_transcript_clicks=${voice_clicks:-0}" >>"$meta_file"

  if [ -n "$last_hash" ] && [ "$current_hash" = "$last_hash" ]; then
    rm -f -- "$out_file"
    rm -f -- "$(printf '%s/page-%03d.txt' "$ocr_dir" "$page")"
    echo "Reached stable top or no further movement at page $((page - 1))." >>"$meta_file"
    reached_stable_top=1
    break
  fi

  last_hash="$current_hash"

  ocr_out_file="$(printf '%s/page-%03d.txt' "$ocr_dir" "$page")"
  "$script_dir/ocr_wechat_screenshot.sh" "$out_file" >"$ocr_out_file"
  {
    echo "## page-$(printf '%03d' "$page")"
    echo
    echo "![page-$(printf '%03d' "$page")]($(basename "$out_file"))"
    echo
    echo '```text'
    cat "$ocr_out_file"
    echo '```'
    echo
  } >>"$reference_file"

  if [ "$page" -lt "$max_pages" ]; then
    "$script_dir/scroll_chat_history.sh" 1 "$scroll_pixels" "$focus_x" "$focus_y" >/dev/null
    sleep 0.6
  fi
done

if [ "$reached_stable_top" -eq 0 ]; then
  echo "Reached max_pages without finding the stable top. Ask the user whether to continue." >>"$meta_file"
fi

printf '%s\n' "$out_dir"
