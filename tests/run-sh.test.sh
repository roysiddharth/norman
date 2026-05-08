#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_SH="$ROOT_DIR/bin/run.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]] || fail "expected output to contain: $needle"
}

test_requires_routine_name() {
  local output
  if output="$($RUN_SH 2>&1)"; then
    fail "expected missing routine name to fail"
  fi

  assert_contains "$output" "Error: routine name is required."
  assert_contains "$output" "Usage:"
}

test_launcher_is_executable() {
  [[ -x "$RUN_SH" ]] || fail "expected bin/run.sh to be executable"
}

test_invokes_claude_with_routine_prompt() {
  local tmpdir output args_file
  tmpdir="$(mktemp -d)"
  args_file="$tmpdir/claude-args"

  cat > "$tmpdir/claude" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CLAUDE_ARGS_FILE"
SH
  chmod +x "$tmpdir/claude"

  output="$(PATH="$tmpdir:$PATH" CLAUDE_ARGS_FILE="$args_file" "$RUN_SH" morning-dogs)"

  assert_contains "$output" "Norman run.sh: triggered routine 'morning-dogs'."
  [[ -f "$args_file" ]] || fail "expected claude to be invoked"

  local args
  args="$(<"$args_file")"
  assert_contains "$args" "-p"
  assert_contains "$args" "vault/Norman/Routines/morning-dogs.md"
  assert_contains "$args" "execute the routine"
  assert_contains "$args" "Manual tasks must check Google Calendar and create calendar blocks"
  assert_contains "$args" "HITL tasks must execute automatable steps, create handoff calendar blocks, and send handoff emails"
  assert_contains "$args" "AFK tasks must load declared skills, execute end-to-end, and handle fallback or signal email on failure"
}

test_rejects_extra_arguments() {
  local output
  if output="$($RUN_SH morning-dogs extra 2>&1)"; then
    fail "expected extra arguments to fail"
  fi

  assert_contains "$output" "Error: exactly one routine name is required."
  assert_contains "$output" "Usage:"
}

test_works_from_non_repo_cwd() {
  local tmpdir args_file
  tmpdir="$(mktemp -d)"
  args_file="$tmpdir/claude-args"

  cat > "$tmpdir/claude" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$CLAUDE_ARGS_FILE"
SH
  chmod +x "$tmpdir/claude"

  (cd /tmp && PATH="$tmpdir:$PATH" CLAUDE_ARGS_FILE="$args_file" "$RUN_SH" morning-dogs >/dev/null)

  local args
  args="$(<"$args_file")"
  assert_contains "$args" "$ROOT_DIR/vault/Norman/Routines/morning-dogs.md"
}

test_documents_crontab_setup() {
  local doc="$ROOT_DIR/docs/crontab-setup.md"
  [[ -f "$doc" ]] || fail "expected docs/crontab-setup.md to exist"

  local content
  content="$(<"$doc")"
  assert_contains "$content" "bin/run.sh morning-dogs"
  assert_contains "$content" "0 8 * * *"
}

test_requires_routine_name
test_launcher_is_executable
test_invokes_claude_with_routine_prompt
test_rejects_extra_arguments
test_works_from_non_repo_cwd
test_documents_crontab_setup

printf 'All run.sh tests passed.\n'
