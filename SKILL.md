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
5. Open the target chat, focus the composer, and write the exact message text into the composer.
6. Stop and ask for confirmation before sending.
7. Send only after confirmation, then capture a proof screenshot.

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

## Drafting The Message

After the correct chat is open:

1. Focus the composer. In the current WeChat build, one `Tab` from the chat view usually lands in the message composer.
2. Use `scripts/focus_composer_and_paste.sh "<message>"` instead of simulated typing.
3. Capture the window and verify that the exact text appears in the composer.

Prefer direct `AXValue` assignment over clipboard paste or simulated typing. This avoids IME transformations, candidate-bar interference, and cases where WeChat ignores `Command+V` even though the focus is already in the composer.

## Sending Policy

Always stop after the draft is visible and ask for explicit user confirmation.

Only after the user replies with clear approval such as "发送" or "send":

```bash
scripts/send_current_draft.sh
scripts/capture_wechat_window.sh
```

Return the screenshot path so the user can inspect or archive it.

## Scripts

- `scripts/check_wechat_access.sh`: Verify that WeChat exists and that `System Events` can control it.
- `scripts/capture_wechat_window.sh [output.png]`: Activate WeChat, detect the front window bounds, and capture a window screenshot.
- `scripts/navigate_chat_list.sh <offset>`: Move the visible chat selection up or down with arrow keys.
- `scripts/focus_composer_and_paste.sh "<message>"`: Focus the composer, clear the current draft, and write the exact text through the focused text area's `AXValue`.
- `scripts/send_current_draft.sh`: Press Return in WeChat to send the currently visible draft.

## Troubleshooting

Read [references/troubleshooting.md](references/troubleshooting.md) when:

- `osascript` reports Accessibility or Automation permission failures
- WeChat opens but cannot be controlled
- typed Chinese text is altered by the IME
- `Command+V` or the Edit menu paste does not land in the composer
- window screenshots are blank or capture the desktop instead of WeChat
