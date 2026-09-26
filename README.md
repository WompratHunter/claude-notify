# claude-notify

macOS notifications for Claude Code, tuned for Ghostty + Zellij: get a banner or sound when an agent finishes a turn or needs your input.

Status: work in progress, tracked via GitHub issues in this repo.

## Install

```sh
brew install terminal-notifier
claude plugin marketplace add WompratHunter/claude-notify
claude plugin install claude-notify@claude-notify
```

## Configuration

Environment variables:

- `CLAUDE_NOTIFY=off` — disable all notifications
- `CLAUDE_NOTIFY_SOUND_DONE` — sound name for Completion (default `Glass`)
- `CLAUDE_NOTIFY_SOUND_ATTENTION` — sound name for Attention request (default `Submarine`)
- `CLAUDE_NOTIFY_DRY_RUN=1` — print the action that would be taken instead of taking it

## Future

Two possible enhancements were spiked but not built, since they can't fully drive the plugin's design without more evidence:

- **Zellij → Ghostty native OSC notification passthrough.** Zellij does forward OSC 9, OSC 99, and OSC 777 desktop-notification escape sequences from a pane to the attached host terminal, controlled by its `host_notification_protocol` config option (default `auto`: OSC 99 when the terminal advertises kitty-protocol support via a query handshake, else OSC 9). Whether Ghostty responds to that handshake and shows a native banner isn't confirmed here — this needs a live check from an actual attached Ghostty+Zellij terminal (not this repo's automated tooling, which isn't running in a real TTY): run `printf '\033]9;test\007'` inside a Zellij pane in Ghostty and see if a banner appears. If it works, it could replace `terminal-notifier` entirely with zero extra dependencies — worth a follow-up ticket if confirmed.
- **Renaming a non-focused Zellij tab.** `zellij action rename-tab <name>` (checked against Zellij 0.43.1) only renames the *focused* tab/pane — there's no tab-index or tab-name target argument. The only way to rename another tab is to `go-to-tab <index>`, rename, then `go-to-previous-tab`, which briefly moves focus and could be visually disruptive. Not implemented; a tab indicator (e.g. `● project`) is possible but would need to accept that flicker, or wait for Zellij to add a targeted rename.

## Uninstall

```sh
claude plugin marketplace remove claude-notify
```
