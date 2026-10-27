#!/bin/bash
# 빌드 → ~/Library/Input Methods 에 설치 → 입력 소스 등록. 이미 떠 있는 입력기 프로세스는 내려서 새 버전을 쓰게 한다.
# 예전 이름(한영 자동, HanyeongAuto)으로 설치된 것이 있으면 입력 소스에서 빼고 지운다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$("$ROOT/scripts/build-app.sh" | tail -1)"
METHODS="$HOME/Library/Input Methods"
DEST="$METHODS/Nunchi.app"
OLD="$METHODS/HanyeongAuto.app"

if [ -d "$OLD" ]; then
    swift "$ROOT/scripts/register.swift" --disable "io.github.apsoei.inputmethod.HanyeongAuto" || true
    pkill -x HanyeongAuto 2>/dev/null || true
    rm -rf "$OLD"
    echo "예전 '한영 자동'을 지웠습니다."
fi

pkill -x Nunchi 2>/dev/null || true
mkdir -p "$METHODS"
rm -rf "$DEST"
cp -R "$APP" "$DEST"
swift "$ROOT/scripts/register.swift" "$DEST"
echo "설치 완료: $DEST"
echo "메뉴 막대의 입력 메뉴에서 '눈치'를 고르세요(목록에 없거나 키가 안 먹으면 로그아웃 후 다시 로그인)."
