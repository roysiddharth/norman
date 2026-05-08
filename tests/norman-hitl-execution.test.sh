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

test_identifies_hitl_tasks() {
  assert_contains "$skill_content" 'Process only tasks whose `type` is `HITL` for the HITL execution path'
}

test_executes_automatable_steps_before_handoff() {
  assert_contains "$skill_content" 'Load skills listed in the routine frontmatter `skills` field before automating HITL steps'
  assert_contains "$skill_content" 'Execute any automatable HITL steps using those declared skills before handing off to the human'
}

test_checks_calendar_and_creates_free_slot_block() {
  assert_contains "$skill_content" 'Check Google Calendar for conflicts via gworkspace before creating the HITL handoff block'
  assert_contains "$skill_content" 'Create the HITL handoff calendar block only in a conflict-free slot'
}

test_calendar_event_contains_handoff_context() {
  assert_contains "$skill_content" 'HITL calendar event description must contain what Norman completed, what the human must do, and any relevant context'
}

test_sends_handoff_email_with_same_context() {
  assert_contains "$skill_content" 'Send a HITL handoff email via gworkspace with the same context as the calendar event'
}

test_logs_hitl_execution_result() {
  assert_contains "$skill_content" 'Append the HITL execution result to `vault/Norman/Log/YYYY-MM-DD.md`'
  assert_contains "$skill_content" 'steps completed, handoff time, and calendar block created'
}

test_identifies_hitl_tasks
test_executes_automatable_steps_before_handoff
test_checks_calendar_and_creates_free_slot_block
test_calendar_event_contains_handoff_context
test_sends_handoff_email_with_same_context
test_logs_hitl_execution_result

printf 'All Norman HITL execution tests passed.\n'
