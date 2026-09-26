# claude-notify

macOS notifications for Claude Code, tuned for Ghostty + Zellij: get a banner or sound when an agent finishes a turn or needs your input.

Status: work in progress, tracked via GitHub issues in this repo.

## Install

```sh
brew install terminal-notifier
claude plugin marketplace add evanmarkscott/claude-notify
claude plugin install claude-notify@claude-notify
```

## Configuration

Environment variables:

- `CLAUDE_NOTIFY=off` — disable all notifications
- `CLAUDE_NOTIFY_SOUND_DONE` — sound name for Completion (default `Glass`)
- `CLAUDE_NOTIFY_SOUND_ATTENTION` — sound name for Attention request (default `Submarine`)
- `CLAUDE_NOTIFY_DRY_RUN=1` — print the action that would be taken instead of taking it

## Uninstall

```sh
claude plugin marketplace remove claude-notify
```
