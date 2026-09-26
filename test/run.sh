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

# Each case: fixture file | extra env (space-separated KEY=VAL) | expected ACTION
cases=(
  "stop.json|CLAUDE_NOTIFY_FRONTMOST_BUNDLE_ID_FOR_TEST=com.apple.Terminal|banner"
)

run_case() {
  local fixture="$1"
  local env_str="$2"
  local expected="$3"

  local actual
  # shellcheck disable=SC2086 # env_str is intentionally split into KEY=VAL words
  actual="$(env -i PATH="$PATH" CLAUDE_NOTIFY_DRY_RUN=1 $env_str \
    "$notify" < "$fixtures/$fixture" 2>/dev/null | grep '^ACTION=' | cut -d= -f2-)"

  if [ "$actual" = "$expected" ]; then
    echo "ok   $fixture [$env_str] -> $actual"
    pass=$((pass + 1))
  else
    echo "FAIL $fixture [$env_str] -> expected '$expected', got '$actual'"
    fail=$((fail + 1))
  fi
}

for case_def in "${cases[@]}"; do
  IFS='|' read -r fixture env_str expected <<< "$case_def"
  run_case "$fixture" "$env_str" "$expected"
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
