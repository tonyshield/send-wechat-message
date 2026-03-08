# Changelog

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
