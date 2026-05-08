#!/usr/bin/env bash
# Norman cron launcher - invokes a named routine non-interactively via claude -p.
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

PROMPT="Use the Norman skill. Read $ROUTINE_PATH and execute the routine named '$ROUTINE_NAME' using Norman's shared execution logic. Manual tasks must check Google Calendar and create calendar blocks. Write the execution log to vault/Norman/Log/YYYY-MM-DD.md and return a clear summary of the outcome."

claude -p "$PROMPT"

echo "Norman run.sh: triggered routine '$ROUTINE_NAME'."
