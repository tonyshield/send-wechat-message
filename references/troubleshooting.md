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

The current skill also normalizes the viewport first, so the chat list and history pane are captured in fullscreen with the smallest available display scale.

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

If the search query keeps getting mangled, the local result never highlights correctly, or `搜一搜` keeps taking over, fall back to:

```bash
scripts/find_chat_in_sidebar_by_ocr.sh "<chat name>"
```

This scans the visible left chat list with OCR, scrolls that list if needed, and clicks the first matching visible chat row.

## Group Chat Cannot Be Found

On macOS WeChat, group chats may not be selectable from search unless the current machine already has local history for that group.

If a group does not appear in the local result section:

- ask the user to sync local history
- or ask the user to open the group once manually
- then retry the same search flow

## Temporary Screenshots Accumulate

The capture helper writes screenshots into the macOS temp directory and tracks them in a state file so they can be cleaned later.

Do not delete them automatically. Ask the user first, then run:

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

## Group `@` Mention Text Gets Corrupted

In group chats, once the `@` picker is open, continuing to type the member name and the body through the current IME may corrupt the draft.

Preferred fix:

```bash
scripts/mention_group_member_and_set_value.sh "老妈" "现在这条消息是AI发出来的"
```

This helper OCR-scans the visible `@` picker, clicks the matching member candidate, then appends the rest of the message through `AXValue`.

## Literal `\n` Appears In The Draft

The composer helper accepts real newline characters, but it will not reinterpret backslash escapes for you.

This is wrong:

```bash
msg='First paragraph\n\nSecond paragraph'
```

Preferred fixes:

```bash
msg=$'First paragraph\n\nSecond paragraph'
scripts/focus_composer_and_set_value.sh "$msg"
```

or:

```bash
msg='First paragraph

Second paragraph'
scripts/focus_composer_and_set_value.sh "$msg"
```

If WeChat shows the characters `\n` literally, the shell already built the wrong string before it reached `AXValue`.

## Screenshot Captures The Wrong Window

Use `scripts/capture_wechat_window.sh` instead of raw `screencapture`. The helper activates WeChat, reads the current window bounds through accessibility, and captures only that rectangle.

If the screenshot is still wrong, verify that WeChat actually has an open front window before capturing.

## Page Up Does Not Read Older Messages

WeChat chat history may ignore `Page Up` even when the conversation is frontmost.

Preferred fix:

1. focus the chat body with a click-like event
2. use small pixel-based scroll events
3. capture after each scroll window
4. stop once the date boundary is reached or the chat stops moving

Use:

```bash
scripts/scroll_chat_history.sh 8
scripts/capture_wechat_window.sh
```

If `pixels` is omitted, the helper computes it from the current window height. Prefer conservative values to avoid skipping messages.

If scrolling still does nothing, the focus point may have landed outside the chat-history pane. Retry with explicit coordinates inside the message area:

```bash
scripts/scroll_chat_history.sh 8 180 520 300
```

## Need A Reviewable Screenshot Set

When you need to review a whole chat history manually, use the sequence capture helper:

```bash
scripts/capture_chat_history_sequence.sh
```

It captures overlapping pages into a temporary directory and records hashes in `metadata.txt`. It now defaults to `100` pages per batch, writes OCR output from the current conversation pane into `ocr/`, creates `conversation-reference.md` for page-by-page review, and builds `conversation-merged.txt` as a simple merged transcript reference.

If `metadata.txt` says the batch reached `max_pages` without finding the stable top, ask the user whether to continue with another batch.

## Voice Message Transcripts Do Not Expand

The history-capture helper now tries to detect visible `转文字` controls with OCR, click them, wait for the transcript text to settle, and then recapture that page.

If a voice transcript is still missing:

- the button may not have been visible in the screenshot
- OCR may not have recognized the button text
- the transcript may still have been loading when the timeout expired

You can retry manually on the current page with:

```bash
scripts/expand_visible_voice_transcripts.sh /path/to/current-page.png 12
```

Then recapture the page.

## OCR Reference Text Looks Noisy

`conversation-reference.md`, `conversation-merged.txt`, and `ocr/page-*.txt` are OCR-derived reference files, not authoritative exports. Expect:

- overlap duplicates between adjacent pages
- imperfect recognition on emojis, images, and low-contrast text
- partial misses on dense or stylized content

Use these files as a reading aid, not as a canonical transcript.

## Fullscreen Or Zoom Level Is Inconsistent

If WeChat screenshots suddenly show less content than expected, run:

```bash
scripts/prepare_wechat_viewport.sh
```

The helper:

- enters fullscreen only when `AXFullScreen` is false
- then keeps sending `Command+-` until the `缩小` menu item is disabled

This is the viewport baseline expected by the rest of the skill.
