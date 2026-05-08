#!/usr/bin/env bash
# Norman cron launcher — invokes a named routine non-interactively via claude -p.
# Usage: bin/run.sh <routine-name>
# Crontab example: 0 8 * * * /path/to/norman/bin/run.sh morning-dogs

set -euo pipefail

ROUTINE_NAME="${1:-}"

if [[ -z "$ROUTINE_NAME" ]]; then
  echo "Error: routine name is required." >&2
  echo "Usage: $0 <routine-name>" >&2
  exit 1
fi

# Norman is not yet fully implemented. This stub exits gracefully.
echo "Norman run.sh: routine '$ROUTINE_NAME' received. (stub — full implementation pending)"
exit 0
