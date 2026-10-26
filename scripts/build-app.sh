#!/bin/bash
# 릴리스 빌드 후 build/HanyeongAuto.app 번들을 조립하고 ad-hoc 서명한다. 마지막 줄에 번들 경로를 출력한다.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release --product HanyeongAuto >&2
BIN="$(swift build -c release --show-bin-path)/HanyeongAuto"

APP="$ROOT/build/HanyeongAuto.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/HanyeongAuto"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/icon.tiff "$APP/Contents/Resources/icon.tiff"
codesign --force --sign - "$APP" >&2
echo "$APP"
