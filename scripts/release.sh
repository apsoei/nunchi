#!/bin/bash
# 배포용 압축을 만든다: 버전을 넣어 빌드 → dist/Nunchi-<버전>.zip → sha256 출력.
# brew Cask(apsoei/homebrew-tap 의 Casks/nunchi.rb)의 version·sha256 을 이 값으로 바꾼다.
# 실행: ./scripts/release.sh 0.3.0
set -euo pipefail
VERSION="${1:?버전을 주세요. 예: ./scripts/release.sh 0.3.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" -c "Set :CFBundleVersion $VERSION" Resources/Info.plist
APP="$("$ROOT/scripts/build-app.sh" | tail -1)"

mkdir -p dist
ZIP="dist/Nunchi-$VERSION.zip"
rm -f "$ZIP"
ditto -c -k --norsrc --noextattr --keepParent "$APP" "$ZIP"
echo "압축: $ROOT/$ZIP"
echo "sha256: $(shasum -a 256 "$ZIP" | cut -d' ' -f1)"
echo "GitHub Release 로 올리기(저장소 공개 후): gh release create v$VERSION $ZIP --title v$VERSION"
