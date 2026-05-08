#!/usr/bin/env bash
# Norman status — reads vault files and crontab directly, no LLM round-trips.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
QUEUE_DIR="$ROOT_DIR/vault/Norman/Queue"
LOG_DIR="$ROOT_DIR/vault/Norman/Log"
TODAY="$(date +%Y-%m-%d)"

# --- helpers ---

# Extract a single frontmatter field value from a file.
# Usage: get_field <file> <field>
get_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    /^---/ { if (++n == 2) exit }
    n == 1 && $0 ~ "^" f ":" {
      sub("^" f ":[ \t]*", "")
      gsub(/^["\x27]|["\x27]$/, "")
      print
      exit
    }
  ' "$file"
}

# --- sync status ---

print_sync() {
  local crontab_out
  crontab_out="$(crontab -l 2>/dev/null || true)"

  local bootstrap="✗ not installed — run bootstrap from docs/crontab-setup.md"
  if echo "$crontab_out" | grep -q "sync.sh"; then
    bootstrap="✓ sync.sh installed (runs every 5 min)"
  fi

  local in_block=0
  local managed_entries=()
  while IFS= read -r line; do
    if [[ "$line" == "# BEGIN NORMAN" ]]; then
      in_block=1; continue
    fi
    if [[ "$line" == "# END NORMAN" ]]; then
      in_block=0; continue
    fi
    if [[ "$in_block" == 1 && -n "$line" && "$line" != \#* ]]; then
      managed_entries+=("$line")
    fi
  done <<< "$crontab_out"

  echo "### Sync"
  echo "- Bootstrap: $bootstrap"

  if [[ ${#managed_entries[@]} -eq 0 ]]; then
    echo "- Managed entries: 0"
    echo "  _No managed entries — sync.sh has not run yet or no routines are scheduled._"
  else
    echo "- Managed entries: ${#managed_entries[@]}"
    for entry in "${managed_entries[@]}"; do
      # entry format: "<cron expr> /path/to/run.sh <routine-name>"
      local routine cron_expr
      routine="$(echo "$entry" | awk '{print $NF}')"
      cron_expr="$(echo "$entry" | awk '{$NF=""; print}' | sed 's/[[:space:]]*$//')"
      echo "  - $routine: $cron_expr"
    done
  fi
}

# --- queue ---

print_queue() {
  echo "### Queue (pending)"

  local found=0
  for f in "$QUEUE_DIR"/*.md; do
    [[ -f "$f" ]] || continue
    local base
    base="$(basename "$f" .md)"
    [[ "$base" == "_template" ]] && continue

    local status
    status="$(get_field "$f" "status")"
    [[ "$status" == "pending" ]] || continue

    local type description
    type="$(get_field "$f" "type")"
    description="$(get_field "$f" "description")"
    echo "- [$type] $description"
    found=1
  done

  if [[ "$found" == 0 ]]; then
    echo "_No pending tasks._"
  fi
}

# --- log ---

print_log() {
  echo "### Today's Log"
  local log_file="$LOG_DIR/$TODAY.md"
  if [[ ! -f "$log_file" ]]; then
    echo "_No runs logged today._"
    return
  fi
  # Print log content, skipping the leading blank line if present
  sed '/^$/d' "$log_file"
}

# --- main ---

echo "## Norman Status — $TODAY"
echo ""
print_sync
echo ""
print_queue
echo ""
print_log
