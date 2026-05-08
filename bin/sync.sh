#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROUTINES_DIR="$REPO_ROOT/vault/Norman/Routines"
RUN_SH="$SCRIPT_DIR/run.sh"
BEGIN_MARKER="# BEGIN NORMAN"
END_MARKER="# END NORMAN"

schedule_to_cron() {
    local schedule="$1"

    if [[ "$schedule" =~ ^daily\ at\ ([0-9]{2}):([0-9]{2})$ ]]; then
        echo "${BASH_REMATCH[2]} ${BASH_REMATCH[1]} * * *"
        return 0
    fi

    if [[ "$schedule" =~ ^weekdays\ at\ ([0-9]{2}):([0-9]{2})$ ]]; then
        echo "${BASH_REMATCH[2]} ${BASH_REMATCH[1]} * * 1-5"
        return 0
    fi

    if [[ "$schedule" =~ ^every\ ([0-9]+)\ minutes$ ]]; then
        echo "*/${BASH_REMATCH[1]} * * * *"
        return 0
    fi

    return 1
}

extract_schedule() {
    local file="$1"
    awk '/^---/{if(++n==2)exit} n==1 && /^schedule:/' "$file" \
        | sed 's/^schedule:[[:space:]]*//' \
        | tr -d '"'
}

generate_entries() {
    local entries=()

    for routine_file in "$ROUTINES_DIR"/*.md; do
        [[ -f "$routine_file" ]] || continue
        local name
        name="$(basename "$routine_file" .md)"
        [[ "$name" == "_template" ]] && continue

        local schedule
        schedule="$(extract_schedule "$routine_file")"

        if [[ -z "$schedule" ]]; then
            echo "WARNING: No schedule found in $name, skipping" >&2
            continue
        fi

        local cron_expr
        if ! cron_expr="$(schedule_to_cron "$schedule")"; then
            echo "WARNING: Unknown schedule pattern '$schedule' in $name, skipping" >&2
            continue
        fi

        entries+=("$cron_expr $RUN_SH $name")
    done

    if [[ ${#entries[@]} -gt 0 ]]; then
        printf '%s\n' "${entries[@]}"
    fi
}

main() {
    local new_entries
    new_entries="$(generate_entries)"

    local current
    current="$(crontab -l 2>/dev/null || true)"

    # Remove existing managed block
    local cleaned
    cleaned="$(awk '/^# BEGIN NORMAN$/{skip=1; next} /^# END NORMAN$/{skip=0; next} !skip{print}' <<< "$current")"

    # Build managed block
    local managed_block="$BEGIN_MARKER"
    if [[ -n "$new_entries" ]]; then
        managed_block="$managed_block"$'\n'"$new_entries"
    fi
    managed_block="$managed_block"$'\n'"$END_MARKER"

    # Combine: existing entries (if any) + managed block
    local new_crontab
    if [[ -n "$cleaned" ]]; then
        new_crontab="$cleaned"$'\n'"$managed_block"
    else
        new_crontab="$managed_block"
    fi

    echo "$new_crontab" | crontab -
    echo "Norman crontab synced." >&2
}

main
