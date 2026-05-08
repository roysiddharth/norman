#!/usr/bin/env bash
set -euo pipefail

# Install gws if not on PATH
if ! command -v gws &>/dev/null; then
  echo "Installing gws via Homebrew..."
  brew install googleworkspace-cli
fi

# Check auth by exporting credentials (lightweight, no API call)
if ! gws auth export > /dev/null 2>&1; then
  echo ""
  echo "gws is not authenticated. Run the following once to set up:"
  echo ""
  echo "    gws auth setup"
  echo ""
  echo "Then retry your request."
  exit 1
fi
