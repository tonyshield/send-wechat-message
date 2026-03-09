# Changelog

## 0.9.0 - 2026-03-09

- Stopped treating screenshot cleanup as automatic workflow; the user should now explicitly decide whether to keep or delete temporary screenshots.
- Increased history capture batches to `100` pages by default and record when another batch is needed.
- Added OCR extraction for WeChat screenshots, including `ocr/` page files and `conversation-reference.md`.
- Added best-effort voice transcript expansion by detecting and clicking visible `转文字` controls before the final page capture.
- Updated history scrolling defaults to derive pixel distance from the current window size when omitted.

## 0.8.0 - 2026-03-09

- Added `prepare_wechat_viewport.sh` to normalize WeChat into fullscreen and the smallest available display scale before operations.
- Updated capture, navigation, drafting, sending, and history-scrolling scripts to use the normalized viewport.
- Documented the fullscreen-and-zoom baseline in the skill, README, and troubleshooting guide.

## 0.7.1 - 2026-03-09

- Documented the multiline message rule: pass real newline characters instead of literal `\n` sequences.
- Added examples in the README and troubleshooting guide for shell-safe multiline drafting.

## 0.7.0 - 2026-03-09

- Added `scroll_chat_history.sh` for controlled WeChat history reading.
- Documented the proven history-reading pattern: focus the chat body, use small pixel-based scroll increments, and capture each checkpoint.
- Documented that `Page Up` is unreliable for reading older messages in macOS WeChat.
- Updated history scrolling to compute the chat-body focus point from the active WeChat window instead of relying on a fixed coordinate.
- Added `capture_chat_history_sequence.sh` to collect a reviewable, overlapping screenshot set in a temporary directory.

## 0.6.0 - 2026-03-09

- Added screenshot tracking in `capture_wechat_window.sh`.
- Added `cleanup_wechat_temp_screenshots.sh` to delete temporary WeChat screenshots after verification.
- Updated the skill docs and privacy guidance to require screenshot cleanup after successful sends.

## 0.5.0 - 2026-03-09

- Added a formal iteration policy so new macOS WeChat behaviors are folded back into the skill.
- Added privacy and publication rules for the public GitHub repository.
- Added a contributor publishing checklist to keep personal data out of the repo.

## 0.4.1 - 2026-03-09

- Moved the local symlink development workflow out of the public README.
- Added `CONTRIBUTING.md` for repository-specific development notes.

## 0.4.0 - 2026-03-09

- Added guidance for group-chat handling on macOS WeChat, including the requirement for local history before local search can select a group.
- Added search-result guidance to avoid accidentally opening the separate `搜一搜` window.
- Added bilingual installation instructions for using a symlink in the local Codex skills directory.
- Captured the keyboard-first workflow and the real-world group-chat discovery behavior in the skill docs.

## 0.3.1 - 2026-03-09

- Renamed the primary draft writer to `focus_composer_and_set_value.sh`.
- Kept `focus_composer_and_paste.sh` as a compatibility wrapper.
- Updated skill and README references to use the new script name.

## 0.3.0 - 2026-03-09

- Switched message drafting from clipboard paste to direct `AXValue` assignment.
- Updated the skill instructions to prefer `AXValue` over paste and simulated typing.
- Documented the paste failure mode in troubleshooting notes.
- Added a bilingual `README.md`.

## 0.2.0 - 2026-03-09

- Improved window capture to prefer the main WeChat window when floating helper windows are present.
- Published the repository to GitHub under the MIT license.

## 0.1.0 - 2026-03-09

- Added the initial `send-wechat-message` Codex skill.
- Added helpers for permission checks, screenshots, chat-list navigation, drafting, and sending.
