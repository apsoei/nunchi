#!/bin/bash
# -j 1: 병렬 컴파일 중 Swift Testing 매크로 플러그인을 간헐적으로 못 찾는 툴체인 문제가 있다.
set -euo pipefail
WORK="$("$(dirname "$0")/sync-src.sh")"
cd "$WORK"
swift test -j 1 "$@"
