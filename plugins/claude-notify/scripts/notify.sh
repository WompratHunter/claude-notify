#!/usr/bin/env bash
# claude-notify: raise a macOS notification for a Claude Code Stop or
# Notification hook event. Reads the hook's JSON payload from stdin.
#
# This script must never fail the hook it's attached to: every exit path
# is 0, and every external command's own failure is swallowed.
set -u

# --- config (env overrides) -------------------------------------------------

SOUND_DONE="${CLAUDE_NOTIFY_SOUND_DONE:-Glass}"
SOUND_ATTENTION="${CLAUDE_NOTIFY_SOUND_ATTENTION:-Submarine}"
DRY_RUN="${CLAUDE_NOTIFY_DRY_RUN:-}"
# Test-only override for the frontmost app's bundle id, so tests can exercise
# both the Ghostty-frontmost and not-frontmost branches deterministically.
FRONTMOST_OVERRIDE="${CLAUDE_NOTIFY_FRONTMOST_BUNDLE_ID_FOR_TEST:-}"

GHOSTTY_BUNDLE_ID="com.mitchellh.ghostty"

if [ "${CLAUDE_NOTIFY:-}" = "off" ]; then
  echo "ACTION=skip"
  exit 0
fi

# --- read the hook payload --------------------------------------------------

payload="$(cat)"

hook_event_name="$(printf '%s' "$payload" | jq -r '.hook_event_name // empty' 2>/dev/null)"
notification_type="$(printf '%s' "$payload" | jq -r '.notification_type // empty' 2>/dev/null)"
message="$(printf '%s' "$payload" | jq -r '.message // empty' 2>/dev/null)"
last_assistant_message="$(printf '%s' "$payload" | jq -r '.last_assistant_message // empty' 2>/dev/null)"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null)"

if [ -z "$hook_event_name" ]; then
  echo "ACTION=skip"
  exit 0
fi

# --- classify ----------------------------------------------------------------

class=""
case "$hook_event_name" in
  Stop)
    class="completion"
    ;;
  Notification)
    case "$notification_type" in
      permission_prompt|idle_prompt|elicitation_dialog|agent_needs_input)
        class="attention"
        ;;
      *)
        echo "ACTION=skip"
        exit 0
        ;;
    esac
    ;;
  *)
    echo "ACTION=skip"
    exit 0
    ;;
esac

# --- build notification content ---------------------------------------------

project="$(basename "${cwd:-unknown}")"
title="Claude · ${project}"

sound="$SOUND_DONE"
if [ "$class" = "completion" ]; then
  subtitle="Done"
else
  sound="$SOUND_ATTENTION"
  if [ "$notification_type" = "permission_prompt" ]; then
    subtitle="Needs approval"
  else
    subtitle="Waiting on you"
  fi
fi

body="$message"
if [ -z "$body" ] && [ "$class" = "completion" ]; then
  body="$last_assistant_message"
fi
# Collapse newlines and truncate to ~100 chars so the banner stays readable.
body="$(printf '%s' "$body" | tr '\n' ' ')"
if [ "${#body}" -gt 100 ]; then
  body="${body:0:100}…"
fi

if [ -n "${ZELLIJ_SESSION_NAME:-}" ]; then
  body="${body} [zellij: ${ZELLIJ_SESSION_NAME}]"
fi

group="${session_id:-claude-notify}"

# --- decide banner vs. sound-only -------------------------------------------

frontmost_bundle_id="$FRONTMOST_OVERRIDE"
if [ -z "$frontmost_bundle_id" ]; then
  frontmost_app="$(lsappinfo front 2>/dev/null)"
  if [ -n "$frontmost_app" ]; then
    frontmost_bundle_id="$(lsappinfo info -only bundleid "$frontmost_app" 2>/dev/null | sed -n 's/.*"\(.*\)".*/\1/p')"
  fi
fi

action="banner"
if [ "$frontmost_bundle_id" = "$GHOSTTY_BUNDLE_ID" ]; then
  action="sound-only"
fi

# --- dry run: report the decision instead of acting -------------------------

if [ -n "$DRY_RUN" ]; then
  echo "ACTION=${action}"
  echo "TITLE=${title}"
  echo "SUBTITLE=${subtitle}"
  echo "BODY=${body}"
  echo "SOUND=${sound}"
  echo "GROUP=${group}"
  exit 0
fi

# --- deliver -----------------------------------------------------------------

if [ "$action" = "sound-only" ]; then
  afplay "/System/Library/Sounds/${sound}.aiff" >/dev/null 2>&1 &
  exit 0
fi

if command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier \
    -title "$title" \
    -subtitle "$subtitle" \
    -message "$body" \
    -sound "$sound" \
    -group "$group" \
    -activate "$GHOSTTY_BUNDLE_ID" \
    >/dev/null 2>&1
elif command -v osascript >/dev/null 2>&1; then
  esc_title="${title//\"/\\\"}"
  esc_subtitle="${subtitle//\"/\\\"}"
  esc_body="${body//\"/\\\"}"
  osascript -e "display notification \"${esc_body}\" with title \"${esc_title}\" subtitle \"${esc_subtitle}\" sound name \"${sound}\"" \
    >/dev/null 2>&1
fi

exit 0
