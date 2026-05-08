#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTINE="$ROOT_DIR/vault/Norman/Routines/drain-queue.md"
SKILL="$ROOT_DIR/skills/norman/SKILL.md"
CRONTAB_DOC="$ROOT_DIR/docs/crontab-setup.md"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

test_has_dedicated_queue_drain_routine() {
  [[ -f "$ROUTINE" ]] || fail 'expected vault/Norman/Routines/drain-queue.md to exist'
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected content to contain: $needle"
}

skill_content="$(<"$SKILL")"
crontab_doc="$(<"$CRONTAB_DOC")"

test_reads_all_pending_queue_notes() {
  assert_contains "$skill_content" 'Read all notes in `vault/Norman/Queue/` whose frontmatter has `status: pending`'
}

test_executes_pending_notes_by_type() {
  assert_contains "$skill_content" 'Execute each pending queue note using the existing execution path selected by its `type` field: `AFK`, `HITL`, or `Manual`'
}

test_marks_successful_notes_done() {
  assert_contains "$skill_content" 'After successful execution, update that queue note frontmatter to `status: done`'
}

test_skips_done_and_in_progress_notes() {
  assert_contains "$skill_content" 'Skip queue notes whose frontmatter status is `done` or `in_progress`'
}

test_logs_each_drained_task() {
  assert_contains "$skill_content" 'Log each drained queue task to `vault/Norman/Log/YYYY-MM-DD.md` with note filename, type, description, and outcome'
}

test_documents_queue_drain_crontab() {
  assert_contains "$crontab_doc" '*/15 * * * * /path/to/norman/bin/run.sh drain-queue'
}

test_has_dedicated_queue_drain_routine
test_reads_all_pending_queue_notes
test_executes_pending_notes_by_type
test_marks_successful_notes_done
test_skips_done_and_in_progress_notes
test_logs_each_drained_task
test_documents_queue_drain_crontab

printf 'All Norman queue drain tests passed.\n'
