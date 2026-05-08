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

test_identifies_afk_tasks() {
  assert_contains "$skill_content" 'Process only tasks whose `type` is `AFK` for the AFK execution path'
}

test_loads_declared_skills() {
  assert_contains "$skill_content" 'Load skills declared in routine `skills` frontmatter field'
}

test_executes_task_end_to_end() {
  assert_contains "$skill_content" 'Execute the task end-to-end using loaded skills'
}

test_falls_back_or_signals_on_failure() {
  assert_contains "$skill_content" 'If `fallback_type` is set in frontmatter: re-run the task as that type'
  assert_contains "$skill_content" 'Otherwise: send a signal email with failure details via gworkspace Gmail'
}

test_signal_email_only_on_failure_or_escalation() {
  assert_contains "$skill_content" 'Send signal email only on failure or escalation'
  assert_contains "$skill_content" 'never on successful runs'
}

test_logs_afk_execution_result() {
  assert_contains "$skill_content" 'Append the AFK execution result to `vault/Norman/Log/YYYY-MM-DD.md`'
  assert_contains "$skill_content" 'success or failure, and any escalation'
}

test_identifies_afk_tasks
test_loads_declared_skills
test_executes_task_end_to_end
test_falls_back_or_signals_on_failure
test_signal_email_only_on_failure_or_escalation
test_logs_afk_execution_result

printf 'All Norman AFK execution tests passed.\n'
