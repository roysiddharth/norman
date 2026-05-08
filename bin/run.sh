#!/usr/bin/env bash
# Norman cron launcher - invokes a named routine non-interactively via claude --dangerously-skip-permissions -p.
# Usage: bin/run.sh <routine-name>
# Crontab example: 0 8 * * * /path/to/norman/bin/run.sh morning-dogs

set -euo pipefail

ROUTINE_NAME="${1:-}"

if [[ -z "$ROUTINE_NAME" ]]; then
  echo "Error: routine name is required." >&2
  echo "Usage: $0 <routine-name>" >&2
  exit 1
fi

if [[ "$#" -ne 1 ]]; then
  echo "Error: exactly one routine name is required." >&2
  echo "Usage: $0 <routine-name>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROUTINE_PATH="$ROOT_DIR/vault/Norman/Routines/$ROUTINE_NAME.md"

if [[ ! -f "$ROUTINE_PATH" ]]; then
  echo "Error: routine file not found: $ROUTINE_PATH" >&2
  exit 1
fi

# Read full routine content for context injection
ROUTINE_CONTENT="$(cat "$ROUTINE_PATH")"

# Extract skills from frontmatter (multi-line YAML list: "  - skill-name")
SKILLS=$(awk '/^skills:/{found=1; next} found && /^[[:space:]]+-/{gsub(/^[[:space:]]+-[[:space:]]*/,"",$0); print} found && /^[^[:space:]-]/{exit}' "$ROUTINE_PATH" | tr '\n' ',' | sed 's/,$//')

# Build skill-loading instruction prefix
if [[ -n "$SKILLS" ]]; then
  SKILL_BLOCK="Load and use these skills: $SKILLS

"
else
  SKILL_BLOCK=""
fi

PROMPT="${SKILL_BLOCK}You are executing the Norman routine '${ROUTINE_NAME}'. Here is the full routine definition:

---ROUTINE START---
${ROUTINE_CONTENT}
---ROUTINE END---

Execute the routine named '${ROUTINE_NAME}' using Norman's shared execution logic. Manual tasks must check Google Calendar and create calendar blocks. HITL tasks must execute automatable steps, create handoff calendar blocks, and send handoff emails. AFK tasks must load declared skills, execute end-to-end, and handle fallback or signal email on failure. Write the execution log to vault/Norman/Log/YYYY-MM-DD.md and return a clear summary of the outcome."

claude --dangerously-skip-permissions -p "$PROMPT"

echo "Norman run.sh: triggered routine '$ROUTINE_NAME'."
