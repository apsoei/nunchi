#!/bin/bash
# 릴리스 빌드 후 build/Nunchi.app 번들을 조립하고 ad-hoc 서명한다. 마지막 줄에 번들 경로를 출력한다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release --product Nunchi >&2
BIN="$(swift build -c release --show-bin-path)/Nunchi"

APP="$ROOT/build/Nunchi.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Nunchi"
cp Resources/Info.plist "$APP/Contents/Info.plist"
# 설치할 때마다 연결 이름을 새로 붙인다. 같은 이름이면 앱들이 내려간 예전 프로세스와의 연결을 붙잡고 있어
# 덮어쓴 뒤 키가 사라졌다(로그아웃해야 풀림). 새 이름이면 다시 고를 때 새 프로세스에 연결된다.
/usr/libexec/PlistBuddy -c "Set :InputMethodConnectionName io.github.apsoei.inputmethod.Nunchi_Connection_$(date +%Y%m%d%H%M%S)" \
    "$APP/Contents/Info.plist"
cp -R Resources/icon.tiff Resources/AppIcon.icns Resources/ko.lproj Resources/en.lproj "$APP/Contents/Resources/"
codesign --force --sign - "$APP" >&2
echo "$APP"
