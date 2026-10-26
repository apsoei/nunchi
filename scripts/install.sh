#!/bin/bash
# 빌드 → ~/Library/Input Methods 에 설치 → 입력 소스 등록. 이미 떠 있는 입력기 프로세스는 내려서 새 버전을 쓰게 한다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$("$ROOT/scripts/build-app.sh" | tail -1)"
DEST="$HOME/Library/Input Methods/HanyeongAuto.app"

pkill -x HanyeongAuto 2>/dev/null || true
mkdir -p "$HOME/Library/Input Methods"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
swift "$ROOT/scripts/register.swift" "$DEST"
echo "설치 완료: $DEST"
echo "시스템 설정 > 키보드 > 입력 소스에서 '한영 자동'을 고르세요(목록에 없으면 로그아웃 후 다시 로그인)."
