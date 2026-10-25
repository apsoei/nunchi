#!/bin/bash
set -euo pipefail
WORK="$("$(dirname "$0")/sync-src.sh")"
cd "$WORK"
swift test "$@"
