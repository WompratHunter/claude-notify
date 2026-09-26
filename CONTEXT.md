# claude-notify — Domain Glossary

## Terms

**Agent**
A running Claude Code session. Identified by its `session_id`.

**Completion**
The notification class raised when an agent finishes its turn and control returns to the user. Backed by the `Stop` hook event.

**Attention request**
The notification class raised when an agent needs the user before it can continue: a permission prompt, an idle timeout, an elicitation dialog, or a request for input. Backed by the `Notification` hook event, filtered to `notification_type` values `permission_prompt`, `idle_prompt`, `elicitation_dialog`, and `agent_needs_input`. Distinct from **Completion**: an Attention request means the agent is blocked, not finished.

**Banner**
A visible macOS notification (via `terminal-notifier`, falling back to `osascript`) shown for a Completion or Attention request.

**Sound-only**
The reduced form of a notification — a sound with no banner — raised when Ghostty is already the frontmost application. The user can see the terminal, so a banner would be redundant; the sound is enough to distinguish which tab/pane wants attention.

**Frontmost app**
The macOS application currently in focus, as reported by `lsappinfo front`. Determines whether a notification is a Banner or Sound-only.

## Non-goals

- No Zellij tab-renaming or jump-to-tab. Whether it's feasible is tracked as a spike; not part of the initial scope.
- No re-notification/reminder timer for ignored Attention requests — the built-in `idle_prompt` event already covers that case.
