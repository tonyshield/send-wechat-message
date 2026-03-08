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

## Paste Does Nothing

You may have a valid focused `AXTextArea`, but WeChat still ignores `Command+V` or menu-driven paste. This is the failure mode seen in live testing.

Preferred fix:

- do not rely on paste events
- write the draft directly with `AXValue`

The shipped helper already does this:

```bash
scripts/focus_composer_and_set_value.sh "<message>"
```

The old `scripts/focus_composer_and_paste.sh` entry point is kept as a compatibility wrapper.

## Search Opens `搜一搜`

If you type a query and immediately press Return, WeChat may open the separate `搜一搜` window instead of selecting the local chat result.

Preferred fix:

1. focus search with `Command+F`
2. write the query
3. wait for the dropdown results
4. use arrow keys to move to the local result
5. press Return only after the local result is highlighted

If `搜一搜` already opened, close that window and retry.

## Group Chat Cannot Be Found

On macOS WeChat, group chats may not be selectable from search unless the current machine already has local history for that group.

If a group does not appear in the local result section:

- ask the user to sync local history
- or ask the user to open the group once manually
- then retry the same search flow

## Temporary Screenshots Accumulate

The capture helper writes screenshots into the macOS temp directory and tracks them in a state file so they can be cleaned later.

After the send has been verified, run:

```bash
scripts/cleanup_wechat_temp_screenshots.sh
```

This deletes tracked WeChat screenshots and clears the tracking file.

## Typed Chinese Text Changes Unexpectedly

Direct simulated typing can be rewritten by the current IME. Typical failures include:

- full-width punctuation replacement
- romanized fragments
- substituted Chinese characters

Use `scripts/focus_composer_and_set_value.sh "<message>"` so the final text is written directly into the focused WeChat composer.

## Screenshot Captures The Wrong Window

Use `scripts/capture_wechat_window.sh` instead of raw `screencapture`. The helper activates WeChat, reads the current window bounds through accessibility, and captures only that rectangle.

If the screenshot is still wrong, verify that WeChat actually has an open front window before capturing.
