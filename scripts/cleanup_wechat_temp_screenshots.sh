#!/usr/bin/env bash
set -euo pipefail

tmp_root="${TMPDIR:-/tmp}"
state_dir="$tmp_root/send-wechat-message"
state_file="$state_dir/captures.txt"

deleted=0

delete_file() {
  local path="$1"
  if [ -n "$path" ] && [ -f "$path" ]; then
    rm -f -- "$path"
    deleted=$((deleted + 1))
  fi
}

if [ -f "$state_file" ]; then
  while IFS= read -r path; do
    delete_file "$path"
  done <"$state_file"
  rm -f -- "$state_file"
fi

while IFS= read -r path; do
  delete_file "$path"
done < <(find "$tmp_root" -maxdepth 1 \( -name 'wechat-window*.png' -o -name 'wechat-shot*.png' \) -print 2>/dev/null)

echo "Deleted $deleted temporary screenshot file(s)."
