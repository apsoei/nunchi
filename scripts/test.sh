#!/bin/bash
# swift test 를 실행한다. Command Line Tools 6.4 에서 Swift Testing 매크로 플러그인을
# 간헐적으로 못 찾는 문제("plugin for module 'TestingMacros' not found")가 있어,
# 그 오류일 때만 최대 5번까지 다시 시도한다. 다른 실패는 그대로 실패로 끝난다.
set -uo pipefail
cd "$(dirname "$0")/.."
for attempt in 1 2 3 4 5; do
    output="$(swift test "$@" 2>&1)"
    status=$?
    if [ $status -ne 0 ] && grep -q "plugin for module 'TestingMacros' not found" <<<"$output"; then
        echo "(매크로 플러그인 오류 — 다시 시도 $attempt/5)" >&2
        continue
    fi
    echo "$output"
    exit $status
done
echo "$output"
exit 1
