# Troubleshooting

## Accessibility And Automation

Symptoms:

- `osascript` returns `-1719`
- `osascript` returns `-25211`
- WeChat opens, but `System Events` cannot inspect or control its window

Fix:

1. Open macOS `System Settings`.
2. Go to `Privacy & Security` -> `Accessibility`.
3. Enable `Codex.app` or the actual host app that is running the commands.
4. Go to `Privacy & Security` -> `Automation`.
5. Allow the same host app to control `System Events` and `WeChat`.
6. Restart Codex if permissions were added after launch.

Use `scripts/check_wechat_access.sh` to re-verify after changing permissions.

## WeChat Not Found

If `open -a WeChat` fails, inspect installed applications:

```bash
ls -1 /Applications
find /Applications -maxdepth 2 -iname '*wechat*.app' -o -iname '*微信*.app'
```

If WeChat is installed in a nonstandard location, open it by full path.

## Mouse Clicks Hover But Do Not Select

This WeChat build may show a row hover state without actually switching the active conversation.

Prefer:

1. `Command+1`
2. visible-state screenshot
3. `scripts/navigate_chat_list.sh`
4. screenshot verification

## Typed Chinese Text Changes Unexpectedly

Direct simulated typing can be rewritten by the current IME. Typical failures include:

- full-width punctuation replacement
- romanized fragments
- substituted Chinese characters

Use `scripts/focus_composer_and_paste.sh "<message>"` so the final text is inserted from the clipboard through WeChat's Edit menu.

## Screenshot Captures The Wrong Window

Use `scripts/capture_wechat_window.sh` instead of raw `screencapture`. The helper activates WeChat, reads the current window bounds through accessibility, and captures only that rectangle.

If the screenshot is still wrong, verify that WeChat actually has an open front window before capturing.
