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

### Group chat and search notes

- Group chats are searchable only after local history exists on the current Mac WeChat client.
- In search, do not press Return immediately after entering text.
- Wait for the dropdown, move to the local result with arrow keys, then press Return.
- Avoid mouse-based selection for fragile states; keyboard navigation is more reliable.

### Privacy

This repository is public. Published examples and docs should stay generic:

- do not include real chat screenshots
- do not expose local usernames or absolute machine paths
- do not publish real contact names or message contents unless intentionally anonymized
- prefer reusable placeholders in examples

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

### 群聊与搜索经验

- 群聊只有在当前 Mac 微信已经同步到本地历史后，才比较容易被本地搜索命中。
- 在搜索框输入后不要立刻回车。
- 先等下拉结果出现，再用方向键选中本地结果后回车。
- 在容易失焦的场景里，优先使用键盘导航，不要依赖鼠标点选。

### 隐私约束

这个仓库是公开的，文档和示例需要保持通用化：

- 不要提交真实聊天截图
- 不要暴露本机用户名或绝对路径
- 不要公开真实联系人名称或真实消息内容，除非已经明确做过匿名化
- 示例里优先使用可复用的占位写法
