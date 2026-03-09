---
name: send-wechat-message
description: Send or draft WeChat desktop messages on macOS through GUI automation, including opening WeChat, verifying Accessibility and Automation permissions, navigating the visible chat list, writing exact Unicode text into the composer through AXValue, capturing verification screenshots, and sending only after explicit user confirmation. Use when a user asks to open WeChat or 微信, send a message to a contact or another account, prepare a message before sending, confirm delivery with a screenshot, or troubleshoot Codex control of the macOS WeChat app.
---

# Send WeChat Message

## Overview

Automate the macOS WeChat desktop client conservatively. Prefer deterministic GUI steps, verify state with screenshots, and never send until the user explicitly confirms.

## Workflow

1. Verify that WeChat is installed and that Codex can control it.
2. Bring WeChat to the foreground and capture the current window.
3. Identify whether the target conversation is already visible in the chat list.
4. Prefer keyboard navigation in the visible chat list over mouse clicks.
5. If the target is a group chat, confirm it has local chat history before relying on search results.
6. Open the target chat, focus the composer, and write the exact message text into the composer.
7. Stop and ask for confirmation before sending.
8. Send only after confirmation, then capture a proof screenshot.
9. Clean temporary screenshots after the user has seen the verification.
10. When the task is to read older messages, scroll the chat history upward in small increments and capture each checkpoint.

## Quick Start

Run the helpers from the skill directory:

```bash
scripts/check_wechat_access.sh
scripts/capture_wechat_window.sh
```

If both succeed, use the returned screenshot path with `view_image` to understand the current WeChat state before making further inputs.

## Navigation Strategy

Prefer these controls in this order:

1. `Command+1` to switch WeChat to the chat list.
2. `scripts/capture_wechat_window.sh` to inspect which chat is currently selected.
3. `scripts/navigate_chat_list.sh <offset>` to move from the current selection to a visible target chat.
4. Capture again and verify the title area matches the intended recipient.

Use mouse clicks only as a fallback. In this app version, synthetic mouse events may hover a row without selecting it, while arrow-key navigation is reliable.

If the desired contact is not visible in the current chat list, either:

- use WeChat search manually with screenshots and small verification steps, or
- ask the user to bring the target chat into view before continuing.

This skill is optimized for the visible-chat path because WeChat exposes a sparse accessibility tree.

## Search Strategy

When the target chat is not visible:

1. Use `Command+F` to focus WeChat search.
2. Write the search text through the focused search field's `AXValue`.
3. Wait for the dropdown results to render.
4. Use arrow keys to move onto the local result.
5. Press Return only after a local chat or group result is highlighted.

Do not press Return immediately after typing into search. In the current macOS WeChat build, that often opens the separate `搜一搜` window instead of the local chat result.

For group chats, local search works reliably only when the group already has local history on the current Mac. If the group is missing, ask the user to sync or open the group once manually before retrying.

## Drafting The Message

After the correct chat is open:

1. Focus the composer. In the current WeChat build, one `Tab` from the chat view usually lands in the message composer.
2. Use `scripts/focus_composer_and_set_value.sh "<message>"` instead of simulated typing.
3. Capture the window and verify that the exact text appears in the composer.

Prefer direct `AXValue` assignment over clipboard paste or simulated typing. This avoids IME transformations, candidate-bar interference, and cases where WeChat ignores `Command+V` even though the focus is already in the composer.

If the draft needs line breaks, pass real newline characters. Do not build the message as a plain single-quoted shell string containing literal `\n`, because WeChat will receive those characters verbatim.

## Reading History

When the task is to inspect older messages in a chat:

1. Open the correct conversation first.
2. Capture the current screen state.
3. Use `scripts/scroll_chat_history.sh` with modest increments so messages are not skipped.
4. Capture again after each scroll window.
5. Stop when you reach the desired date boundary, or when the chat no longer moves upward.

Prefer many small scrolls over a few large jumps. In live testing, moderate pixel-based scrolling was more reliable than `Page Up`, and less likely to skip context than aggressive jumps.

Recommended starting command:

```bash
scripts/scroll_chat_history.sh 8 180
scripts/capture_wechat_window.sh
```

Use a larger `steps` count only after confirming the direction and density of messages in the current chat.

The scroll helper computes a default focus point inside the chat-history pane. Override the coordinates only when the window layout is unusual.

For continuous review of a whole chat history, prefer:

```bash
scripts/capture_chat_history_sequence.sh 20
```

This captures a sequence of overlapping screenshots into a temporary directory, scrolling by a conservative amount each round so the previous top content moves downward instead of jumping out of view.

## Sending Policy

Always stop after the draft is visible and ask for explicit user confirmation.

Only after the user replies with clear approval such as "发送" or "send":

```bash
scripts/send_current_draft.sh
scripts/capture_wechat_window.sh
scripts/cleanup_wechat_temp_screenshots.sh
```

Return the screenshot path so the user can inspect it, then remove temporary screenshots once the verification is no longer needed.

## Iteration Policy

Whenever a new macOS WeChat behavior is discovered in real use, fold that behavior back into this skill.

Typical examples:

- search and chat-selection edge cases
- focus and composer-detection failures
- IME or paste failures
- send-key behavior differences
- group-chat discovery constraints

Update the relevant script, `SKILL.md`, troubleshooting notes, and release notes together so the skill remains the canonical record of operating knowledge.

## Privacy And Publishing

Treat this repository as public by default.

Before pushing any update to GitHub:

1. Remove local absolute paths that reveal usernames or machine-specific directories.
2. Do not commit screenshots captured from real conversations.
3. Do not include personal contact names, chat titles, message contents, or IDs unless they are clearly synthetic.
4. Keep user-facing examples generic and reusable.
5. Prefer placeholders such as `/path/to/...`, `$HOME`, or `$CODEX_HOME`.
6. Clean temporary screenshots after successful sends and verification.

If a real interaction taught the workflow, capture the behavior generically and strip the personal context before publishing.

## Scripts

- `scripts/check_wechat_access.sh`: Verify that WeChat exists and that `System Events` can control it.
- `scripts/capture_wechat_window.sh [output.png]`: Activate WeChat, detect the front window bounds, and capture a window screenshot.
- `scripts/navigate_chat_list.sh <offset>`: Move the visible chat selection up or down with arrow keys.
- `scripts/focus_composer_and_set_value.sh "<message>"`: Focus the composer, clear the current draft, and write the exact text through the focused text area's `AXValue`.
- `scripts/focus_composer_and_paste.sh "<message>"`: Backward-compatible wrapper that forwards to `focus_composer_and_set_value.sh`.
- `scripts/scroll_chat_history.sh [steps] [pixels] [x] [y]`: Focus the chat body and scroll older history upward in measured pixel increments.
- `scripts/capture_chat_history_sequence.sh [max_pages] [out_dir]`: Capture overlapping screenshots of older chat history into a temporary directory for manual review.
- `scripts/send_current_draft.sh`: Press Return in WeChat to send the currently visible draft.
- `scripts/cleanup_wechat_temp_screenshots.sh`: Delete tracked WeChat screenshots from the temp directory after verification.

## Troubleshooting

Read [references/troubleshooting.md](references/troubleshooting.md) when:

- `osascript` reports Accessibility or Automation permission failures
- WeChat opens but cannot be controlled
- typed Chinese text is altered by the IME
- `Command+V` or the Edit menu paste does not land in the composer
- WeChat search opens `搜一搜` instead of the local chat
- a group chat cannot be found until local history is synced
- older history must be read by controlled scroll instead of `Page Up`
- temporary screenshots need to be cleaned after sending
- window screenshots are blank or capture the desktop instead of WeChat
