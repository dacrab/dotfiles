#!/usr/bin/env bash
set -euo pipefail

TERM_BIN=${TERMINAL:-foot}
CMD='sudo dnf upgrade -y; echo "Done — press enter to close"; read'

if command -v "$TERM_BIN" >/dev/null 2>&1; then
  "$TERM_BIN" -e bash -lc "$CMD"
else
  bash -lc "$CMD"
fi
