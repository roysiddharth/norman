#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARD_DIR="$ROOT_DIR/dashboard"

export NORMAN_ROOT="${NORMAN_ROOT:-$ROOT_DIR}"

cd "$DASHBOARD_DIR"
npm run dev
