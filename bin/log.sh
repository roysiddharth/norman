#!/usr/bin/env bash
# Norman Stop hook: append routine execution log to vault/Norman/Log/YYYY-MM-DD.md
# Expects env: NORMAN_ROUTINE (routine name), NORMAN_OUTPUT (path to captured stdout file)

set -euo pipefail

ROUTINE="${NORMAN_ROUTINE:-}"
OUTPUT_FILE="${NORMAN_OUTPUT:-}"

# Not a Norman run — skip silently
[[ -z "$ROUTINE" ]] && exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$ROOT_DIR/vault/Norman/Log"
LOG_FILE="$LOG_DIR/$(date +%Y-%m-%d).md"

mkdir -p "$LOG_DIR"

TIMESTAMP="$(date +%H:%M)"

{
  echo "## $ROUTINE — $TIMESTAMP"
  echo ""
  if [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]]; then
    cat "$OUTPUT_FILE"
  else
    echo "(no output captured)"
  fi
  echo ""
} >> "$LOG_FILE"
