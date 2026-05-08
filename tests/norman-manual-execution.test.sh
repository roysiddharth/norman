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

test_reads_routine_and_parses_frontmatter() {
  assert_contains "$skill_content" 'Read `vault/Norman/Routines/<routine-name>.md`'
  assert_contains "$skill_content" 'Parse only the YAML frontmatter between the opening and closing `---` delimiters'
  assert_contains "$skill_content" '`name`, `schedule`, `tasks`, `skills`, and `fallback_type`'
}

test_identifies_manual_tasks() {
  assert_contains "$skill_content" 'Process only tasks whose `type` is `Manual` for the Manual execution path'
}

test_checks_calendar_before_scheduling() {
  assert_contains "$skill_content" "Use gworkspace to inspect the calendar before scheduling"
  assert_contains "$skill_content" "task's desired window derived from the routine \`schedule\` and \`duration_minutes\`"
}

test_creates_calendar_block_with_task_description() {
  assert_contains "$skill_content" 'Create a Google Calendar block for each Manual task'
  assert_contains "$skill_content" 'use the task `description` as the event title'
}

test_sends_email_when_no_free_slot() {
  assert_contains "$skill_content" 'If no conflict-free slot is available, send an email notification via gworkspace Gmail instead of failing silently'
}

test_logs_manual_execution_result() {
  assert_contains "$skill_content" 'Append the Manual execution result to `vault/Norman/Log/YYYY-MM-DD.md`'
  assert_contains "$skill_content" 'routine name, timestamp, tasks scheduled, and any conflicts'
}

test_reads_routine_and_parses_frontmatter
test_identifies_manual_tasks
test_checks_calendar_before_scheduling
test_creates_calendar_block_with_task_description
test_sends_email_when_no_free_slot
test_logs_manual_execution_result

printf 'All Norman Manual execution tests passed.\n'
