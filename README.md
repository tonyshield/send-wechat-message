# send-wechat-message

## English

`send-wechat-message` is a Codex skill for controlling the macOS WeChat desktop app through Accessibility automation.

It is designed for a conservative workflow:

- verify WeChat and permissions first
- navigate visible chats with the keyboard
- write the exact draft into the composer via `AXValue`
- ask for explicit confirmation before sending
- capture screenshots for verification

### Why `AXValue`

Live testing showed that WeChat may ignore clipboard paste even when the composer is focused. Direct `AXValue` assignment is more reliable because it bypasses:

- IME rewriting
- candidate bar interference
- `Command+V` being swallowed by the app

### Scripts

- `scripts/check_wechat_access.sh`
- `scripts/capture_wechat_window.sh`
- `scripts/navigate_chat_list.sh <offset>`
- `scripts/focus_composer_and_set_value.sh "<message>"`
- `scripts/focus_composer_and_paste.sh "<message>"` (compatibility wrapper)
- `scripts/send_current_draft.sh`

### Typical flow

```bash
scripts/check_wechat_access.sh
scripts/capture_wechat_window.sh
scripts/navigate_chat_list.sh 1
scripts/focus_composer_and_set_value.sh "hello from Codex"
scripts/send_current_draft.sh
scripts/capture_wechat_window.sh
```

Do not send automatically without explicit user confirmation.

## 中文

`send-wechat-message` 是一个用于控制 macOS 微信桌面端的 Codex skill，基于辅助功能自动化。

它遵循偏保守的流程：

- 先检查微信安装和系统权限
- 用键盘导航当前可见的会话列表
- 通过 `AXValue` 直接把消息写进输入框
- 发送前必须先获得用户明确确认
- 用截图验证当前状态和发送结果

### 为什么改用 `AXValue`

实测里，即使输入框已经聚焦，微信也可能不响应剪贴板粘贴。直接写 `AXValue` 更稳，因为它绕过了：

- 输入法改写
- 候选词条干扰
- `Command+V` 被应用吞掉

### 脚本列表

- `scripts/check_wechat_access.sh`
- `scripts/capture_wechat_window.sh`
- `scripts/navigate_chat_list.sh <offset>`
- `scripts/focus_composer_and_set_value.sh "<message>"`
- `scripts/focus_composer_and_paste.sh "<message>"`（兼容包装脚本）
- `scripts/send_current_draft.sh`

### 典型流程

```bash
scripts/check_wechat_access.sh
scripts/capture_wechat_window.sh
scripts/navigate_chat_list.sh 1
scripts/focus_composer_and_set_value.sh "hello from Codex"
scripts/send_current_draft.sh
scripts/capture_wechat_window.sh
```

不要在没有用户明确确认的情况下自动发送。
