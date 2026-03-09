# send-wechat-message

## English

`send-wechat-message` is a Codex skill for controlling the macOS WeChat desktop app through Accessibility automation.

It is designed for a conservative workflow:

- verify WeChat and permissions first
- normalize the viewport before actions by entering fullscreen and zooming out
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
- `scripts/prepare_wechat_viewport.sh`
- `scripts/ocr_wechat_screenshot.sh [--json] [--region left bottom width height] <image.png>`
- `scripts/expand_visible_voice_transcripts.sh <image.png> [timeout_seconds]`
- `scripts/find_chat_in_sidebar_by_ocr.sh "<chat name>" [max_scrolls]`
- `scripts/focus_composer_and_set_value.sh "<message>"`
- `scripts/mention_group_member_and_set_value.sh "<member_name>" "<message>"`
- `scripts/focus_composer_and_paste.sh "<message>"` (compatibility wrapper)
- `scripts/scroll_chat_history.sh [steps] [pixels] [x] [y]`
- `scripts/capture_chat_history_sequence.sh [max_pages] [out_dir]`
- `scripts/merge_ocr_pages.py <output.txt> <page-001.txt> [...]`
- `scripts/send_current_draft.sh`
- `scripts/cleanup_wechat_temp_screenshots.sh`

### Typical flow

```bash
scripts/check_wechat_access.sh
scripts/capture_wechat_window.sh
scripts/navigate_chat_list.sh 1
scripts/focus_composer_and_set_value.sh "hello from Codex"
scripts/send_current_draft.sh
scripts/capture_wechat_window.sh
```

Do not send automatically without explicit user confirmation. After verification, ask the user whether those temporary screenshots should be cleaned.

### Viewport normalization

Before capture, navigation, drafting, sending, or history scrolling, the skill now normalizes the WeChat viewport:

- if WeChat is not fullscreen, it enters fullscreen with `Control+Command+F`
- then it sends `Command+-` until the `缩小` menu item is no longer available

This makes screenshots denser and keeps more conversation content visible per frame.

### Multiline messages

`focus_composer_and_set_value.sh` accepts real newline characters. Do not pass literal `\n` sequences inside a plain single-quoted shell string, or WeChat will receive backslash-and-n as text.

Prefer one of these forms:

```bash
msg=$'First paragraph\n\nSecond paragraph'
scripts/focus_composer_and_set_value.sh "$msg"
```

```bash
msg='First paragraph

Second paragraph'
scripts/focus_composer_and_set_value.sh "$msg"
```

For group-chat `@mentions`, avoid typing the mention target and body through the IME after opening the picker. A more stable path is:

```bash
scripts/mention_group_member_and_set_value.sh "老妈" "现在这条消息是AI发出来的"
```

The helper OCR-scans the visible `@` candidate list, clicks the matching member, then appends the body through `AXValue`.

### Group chat and search notes

- Group chats are searchable only after local history exists on the current Mac WeChat client.
- In search, do not press Return immediately after entering text.
- Wait for the dropdown, move to the local result with arrow keys, then press Return.
- Avoid mouse-based selection for fragile states; keyboard navigation is more reliable.
- If search becomes unstable, use `scripts/find_chat_in_sidebar_by_ocr.sh "<chat name>"` to scan the visible left chat list with OCR and click the first matching row.

### Reading chat history

- `Page Up` is not reliable for WeChat history reading.
- A better approach is to focus the chat body and send small pixel-based scroll events.
- Use small increments first, capture each checkpoint, and stop when the date boundary is reached.

Example:

```bash
scripts/scroll_chat_history.sh 8
scripts/capture_wechat_window.sh
```

The helper computes a default focus point inside the chat-history pane, and if `pixels` is omitted it derives the scroll length from the current window height.

For a whole review set, capture a sequence into a temporary directory:

```bash
scripts/capture_chat_history_sequence.sh
```

This now defaults to `100` pages per batch. If the batch ends before the stable top is reached, ask the user whether to continue.

The output folder also includes:

- `ocr/` with per-page OCR text from the current conversation pane only
- `conversation-reference.md` with page-by-page extracted text for reference
- `conversation-merged.txt` with overlap-deduplicated merged text across the captured pages

When a visible voice message exposes a `转文字` control, the sequence helper will best-effort click it, wait for the transcript text to settle, and then recapture that page.

### Privacy

This repository is public. Published examples and docs should stay generic:

- do not include real chat screenshots
- do not expose local usernames or absolute machine paths
- do not publish real contact names or message contents unless intentionally anonymized
- prefer reusable placeholders in examples
- clean temporary screenshots only after the user explicitly asks for cleanup

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
- `scripts/prepare_wechat_viewport.sh`
- `scripts/ocr_wechat_screenshot.sh [--json] [--region left bottom width height] <image.png>`
- `scripts/expand_visible_voice_transcripts.sh <image.png> [timeout_seconds]`
- `scripts/find_chat_in_sidebar_by_ocr.sh "<chat name>" [max_scrolls]`
- `scripts/focus_composer_and_set_value.sh "<message>"`
- `scripts/mention_group_member_and_set_value.sh "<member_name>" "<message>"`
- `scripts/focus_composer_and_paste.sh "<message>"`（兼容包装脚本）
- `scripts/scroll_chat_history.sh [steps] [pixels] [x] [y]`
- `scripts/capture_chat_history_sequence.sh [max_pages] [out_dir]`
- `scripts/merge_ocr_pages.py <output.txt> <page-001.txt> [...]`
- `scripts/send_current_draft.sh`
- `scripts/cleanup_wechat_temp_screenshots.sh`

### 典型流程

```bash
scripts/check_wechat_access.sh
scripts/capture_wechat_window.sh
scripts/navigate_chat_list.sh 1
scripts/focus_composer_and_set_value.sh "hello from Codex"
scripts/send_current_draft.sh
scripts/capture_wechat_window.sh
```

不要在没有用户明确确认的情况下自动发送。验证完成后，应该先问用户要不要清理这些临时截图。

### 视口归一化

现在在截图、导航、写消息、发送、滚动历史之前，skill 会先归一化微信视口：

- 如果当前不是全屏，就先用 `Control+Command+F` 进入全屏
- 然后连续执行 `Command+-`，直到“显示”菜单里的 `缩小` 不再可用

这样每张截图里能容纳更多聊天内容，历史审阅也更稳定。

### 多段消息与换行

`focus_composer_and_set_value.sh` 支持真实换行。不要把字面量 `\n` 放进普通单引号 shell 字符串里，否则微信里看到的就会是反斜杠和 `n`。

推荐这样传：

```bash
msg=$'第一段\n\n第二段'
scripts/focus_composer_and_set_value.sh "$msg"
```

或者直接传真实多行文本：

```bash
msg='第一段

第二段'
scripts/focus_composer_and_set_value.sh "$msg"
```

如果是在群聊里 `@` 某个成员，不要在打开 `@` 候选后继续靠输入法把成员名和正文都打进去。更稳的方式是：

```bash
scripts/mention_group_member_and_set_value.sh "老妈" "现在这条消息是AI发出来的"
```

这个脚本会先 OCR 扫描当前可见的 `@` 候选列表并点中目标成员，然后再通过 `AXValue` 追加正文。

### 群聊与搜索经验

- 群聊只有在当前 Mac 微信已经同步到本地历史后，才比较容易被本地搜索命中。
- 在搜索框输入后不要立刻回车。
- 先等下拉结果出现，再用方向键选中本地结果后回车。
- 在容易失焦的场景里，优先使用键盘导航，不要依赖鼠标点选。
- 如果搜索本身不稳，就改用 `scripts/find_chat_in_sidebar_by_ocr.sh "<chat name>"`，它会 OCR 扫描左侧会话列表并点击第一个匹配项。

### 读取历史消息

- `Page Up` 对微信历史读取并不稳定。
- 更稳的做法是先把焦点落在聊天正文区域，再发送小幅度的像素滚轮事件。
- 先小步滚动、逐屏截图，确认方向和密度后再继续往上读。

示例：

```bash
scripts/scroll_chat_history.sh 8
scripts/capture_wechat_window.sh
```

脚本会自动计算聊天正文区域的焦点位置；如果不传 `pixels`，还会根据当前窗口高度自适应计算滚动长度。

如果要把整段历史截图下来给人审核，更适合直接跑：

```bash
scripts/capture_chat_history_sequence.sh
```

它现在默认一批抓 `100` 张；如果到达上限还没读到稳定顶部，应该先问用户是否继续。

输出目录里还会包含：

- `ocr/`：每页截图中仅当前对话正文区域的 OCR 文本
- `conversation-reference.md`：按页汇总的提取文本，便于后续参考
- `conversation-merged.txt`：把这一批页面做简单重叠去重后的合并文本

如果截图里能识别到语音消息的 `转文字` 按钮，脚本会尽力先点开它、等待文字返回，再重拍这一页。

### 隐私约束

这个仓库是公开的，文档和示例需要保持通用化：

- 不要提交真实聊天截图
- 不要暴露本机用户名或绝对路径
- 不要公开真实联系人名称或真实消息内容，除非已经明确做过匿名化
- 示例里优先使用可复用的占位写法
- 发送验证完成后，只有在用户明确要求清理时才删除临时截图
