#!/bin/bash
# 저장소 경로에 한글이 있으면 Swift 매크로 플러그인(Swift Testing)을 간헐적으로 못 찾는
# 툴체인 문제가 있다. 소스를 ASCII 경로로 복사해 그곳에서 빌드한다. 복사본 경로를 출력한다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${HANYEONG_WORK_DIR:-$HOME/Library/Caches/hanyeong-auto/src}"
mkdir -p "$WORK"
rsync -a --delete --exclude .git --exclude .build --exclude build "$ROOT/" "$WORK/"
echo "$WORK"
