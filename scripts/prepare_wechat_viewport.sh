#!/usr/bin/env bash
set -euo pipefail

if [ "${WECHAT_VIEWPORT_PREPARED:-0}" = "1" ]; then
  exit 0
fi

zoom_out_max_steps="${WECHAT_VIEWPORT_MAX_ZOOM_OUT_STEPS:-8}"

case "$zoom_out_max_steps" in
  ''|*[!0-9]*)
    echo "WECHAT_VIEWPORT_MAX_ZOOM_OUT_STEPS must be a non-negative integer" >&2
    exit 1
    ;;
esac

open -a WeChat

osascript <<OSA
tell application "WeChat" to activate
delay 0.25

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

    try
      if (value of attribute "AXFullScreen" of targetWindow) is false then
        key code 3 using {control down, command down}
        repeat 40 times
          delay 0.15
          try
            if (value of attribute "AXFullScreen" of targetWindow) is true then
              exit repeat
            end if
          end try
        end repeat
      end if
    end try

    repeat $zoom_out_max_steps times
      try
        if not (enabled of menu item "缩小" of menu 1 of menu bar item "显示" of menu bar 1) then
          exit repeat
        end if
      on error
        exit repeat
      end try

      keystroke "-" using command down
      delay 0.1
    end repeat
  end tell
end tell
OSA
