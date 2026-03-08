# Contributing

## Development setup

This repository is public, but the notes below are for people iterating on the skill itself rather than just using it.

### Local symlink workflow

For fast local iteration, symlink the repo into your Codex skills directory instead of copying files:

```bash
export CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
ln -sfn /path/to/send-wechat-message "$CODEX_HOME/skills/send-wechat-message"
```

This keeps the installed skill pointing at your working tree, so edits in the repo are immediately reflected in the installed skill.

### Validate before pushing

Run:

```bash
python3 "$CODEX_HOME/skills/.system/skill-creator/scripts/quick_validate.py" /path/to/send-wechat-message
```

### Release notes

- Update `CHANGELOG.md` when behavior changes.
- Prefer a tagged GitHub release for user-visible updates.

### Publishing checklist

Before pushing to the public GitHub repository:

- remove or generalize machine-specific absolute paths
- do not commit screenshots from real chats
- replace real names, group titles, and message text with generic placeholders
- make sure new operating knowledge is reflected in `SKILL.md`, troubleshooting docs, and `CHANGELOG.md`
