#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_JSON="$REPO_ROOT/.claude-plugin/plugin.json"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

read -rp "Bump type? [patch/minor/major]: " bump_type
case "$bump_type" in
  patch|minor|major) ;;
  *) echo "Error: bump type must be patch, minor, or major" >&2; exit 1 ;;
esac

read -rp "What changed? " description

old_version="$(jq -r '.version' "$PLUGIN_JSON")"

new_version="$(awk -v ver="$old_version" -v type="$bump_type" '
BEGIN {
  split(ver, parts, ".")
  major = parts[1] + 0
  minor = parts[2] + 0
  patch = parts[3] + 0
  if (type == "patch") patch++
  else if (type == "minor") { minor++; patch = 0 }
  else if (type == "major") { major++; minor = 0; patch = 0 }
  print major "." minor "." patch
}')"

jq --arg v "$new_version" '.version = $v' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp" && mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"

today="$(date +%Y-%m-%d)"
entry="## v${new_version} — ${today}
${description}"

if [ -f "$CHANGELOG" ]; then
  tmp="$(mktemp)"
  { echo "$entry"; echo ""; cat "$CHANGELOG"; } > "$tmp"
  mv "$tmp" "$CHANGELOG"
else
  echo "$entry" > "$CHANGELOG"
fi

echo "Bumped $old_version → $new_version"
