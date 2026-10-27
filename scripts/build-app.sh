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
cp -R Resources/icon.tiff Resources/AppIcon.icns Resources/ko.lproj Resources/en.lproj "$APP/Contents/Resources/"
codesign --force --sign - "$APP" >&2
echo "$APP"
