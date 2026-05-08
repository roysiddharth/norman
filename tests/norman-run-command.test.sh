#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="$ROOT_DIR/skills/norman/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected skill to contain: $needle"
}

skill_content="$(<"$SKILL")"

test_accepts_routine_name_argument() {
  assert_contains "$skill_content" 'Accept exactly one routine name argument, as in `/norman run morning-dogs`'
}

test_reads_named_routine_from_vault() {
  assert_contains "$skill_content" 'Read the named routine from `vault/Norman/Routines/<routine-name>.md`'
}

test_reuses_cron_execution_logic_for_all_task_types() {
  assert_contains "$skill_content" 'Execute the routine using the same execution logic as the cron path (`bin/run.sh`)'
  assert_contains "$skill_content" 'Manual, HITL, and AFK paths must all work from `/norman run`'
}

test_writes_same_log_as_cron_runs() {
  assert_contains "$skill_content" 'Write execution log to `vault/Norman/Log/YYYY-MM-DD.md` using the same log format as cron-triggered runs'
}

test_returns_clear_summary() {
  assert_contains "$skill_content" 'Return a clear summary naming the routine, tasks executed, and final outcome'
}

test_handles_missing_routine_gracefully() {
  assert_contains "$skill_content" 'No routine found: `<routine-name>`. Check `vault/Norman/Routines/` for available routines.'
  assert_contains "$skill_content" 'Do not attempt execution or write a success log when the named routine does not exist'
}

test_accepts_routine_name_argument
test_reads_named_routine_from_vault
test_reuses_cron_execution_logic_for_all_task_types
test_writes_same_log_as_cron_runs
test_returns_clear_summary
test_handles_missing_routine_gracefully

printf 'All Norman run command tests passed.\n'
