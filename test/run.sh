#!/usr/bin/env bash
# Drives scripts/notify.sh from the outside: hook JSON + env in, dry-run
# action line out. This is the project's single test seam.
set -u

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
notify="$repo_root/plugins/claude-notify/scripts/notify.sh"
fixtures="$script_dir/fixtures"

pass=0
fail=0

# Each case: fixture file | extra env (space-separated KEY=VAL) | expected
# ACTION | expected SUBTITLE (blank = don't check) | expected SOUND (blank =
# don't check)
not_frontmost="CLAUDE_NOTIFY_FRONTMOST_BUNDLE_ID_FOR_TEST=com.apple.Terminal"
ghostty_frontmost="CLAUDE_NOTIFY_FRONTMOST_BUNDLE_ID_FOR_TEST=com.mitchellh.ghostty"
cases=(
  "stop.json|$not_frontmost|banner|Done|Glass"
  "permission_prompt.json|$not_frontmost|banner|Needs approval|Submarine"
  "idle_prompt.json|$not_frontmost|banner|Waiting on you|Submarine"
  "elicitation_dialog.json|$not_frontmost|banner|Waiting on you|Submarine"
  "agent_needs_input.json|$not_frontmost|banner|Waiting on you|Submarine"
  "unmatched_notification_type.json|$not_frontmost|skip||"
  "stop.json|$ghostty_frontmost|sound-only|Done|Glass"
  "permission_prompt.json|$ghostty_frontmost|sound-only|Needs approval|Submarine"
)

run_case() {
  local fixture="$1"
  local env_str="$2"
  local expected_action="$3"
  local expected_subtitle="$4"
  local expected_sound="$5"

  local output actual_action actual_subtitle actual_sound
  # shellcheck disable=SC2086 # env_str is intentionally split into KEY=VAL words
  output="$(env -i PATH="$PATH" CLAUDE_NOTIFY_DRY_RUN=1 $env_str \
    "$notify" < "$fixtures/$fixture" 2>/dev/null)"
  actual_action="$(printf '%s\n' "$output" | grep '^ACTION=' | cut -d= -f2-)"
  actual_subtitle="$(printf '%s\n' "$output" | grep '^SUBTITLE=' | cut -d= -f2-)"
  actual_sound="$(printf '%s\n' "$output" | grep '^SOUND=' | cut -d= -f2-)"

  local ok=1
  [ "$actual_action" = "$expected_action" ] || ok=0
  [ -z "$expected_subtitle" ] || [ "$actual_subtitle" = "$expected_subtitle" ] || ok=0
  [ -z "$expected_sound" ] || [ "$actual_sound" = "$expected_sound" ] || ok=0

  if [ "$ok" -eq 1 ]; then
    echo "ok   $fixture -> action=$actual_action subtitle=$actual_subtitle sound=$actual_sound"
    pass=$((pass + 1))
  else
    echo "FAIL $fixture -> expected action=$expected_action subtitle=$expected_subtitle sound=$expected_sound, got action=$actual_action subtitle=$actual_subtitle sound=$actual_sound"
    fail=$((fail + 1))
  fi
}

for case_def in "${cases[@]}"; do
  IFS='|' read -r fixture env_str expected_action expected_subtitle expected_sound <<< "$case_def"
  run_case "$fixture" "$env_str" "$expected_action" "$expected_subtitle" "$expected_sound"
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
