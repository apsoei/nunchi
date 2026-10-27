<img src="docs/logo.svg" width="96" alt="눈치 로고">

# 눈치 (Nunchi)

눈치껏 한글과 영어를 골라 주는 입력기. 치는 도중 영어를 알아채 바로 바꿔 주는 macOS 두벌식 한영 자동전환 입력기.

- 한글로는 나올 수 없는 모양(홀로 남은 자모 등)이 보이면 단어 중간에 영어로 바꾼다. 예: `te` → `ㅅㄷ` 대신 `te`.
- 애매한 짧은 단어(`git`, `the`)는 단어 끝(Space·Return·문장부호)에서 작은 사전과 앞 단어로 정한다.
- 판별이 틀리면 확정 전에 `Esc`(터미널·IDE 제외) 또는 오른쪽 `⌘` 단독 탭으로 한↔영을 뒤집는다.
- 비밀번호 칸(보안 입력)에서는 조합하지 않고 키를 그대로 넘긴다.
- 네트워크 통신·자동 업데이트·손쉬운 사용 권한·전역 키 감시를 쓰지 않는다.

## 빌드·설치

Command Line Tools(또는 Xcode)만 있으면 된다.

```bash
./scripts/test.sh        # 단위 테스트
./scripts/install.sh     # 빌드 → ~/Library/Input Methods 설치 → 입력 소스 등록
```

설치 후 **로그아웃했다가 다시 로그인**한 뒤 시스템 설정 > 키보드 > 입력 소스에서 "눈치"를 고른다.
예전 이름("한영 자동")으로 설치돼 있었다면 `install.sh` 가 입력 소스에서 빼고 지운다.
이미 설치된 버전을 덮어쓴 경우에도 로그아웃이 필요하다(아래 알려진 문제).

## 구조

| 위치 | 하는 일 |
|---|---|
| `Sources/NunchiCore/HangulComposer.swift` | 두벌식 조합기 |
| `Sources/NunchiCore/EnglishSignal.swift` | 치는 도중 영어 신호 |
| `Sources/NunchiCore/WordJudge.swift`, `Lexicon.swift` | 단어 끝 판별 |
| `Sources/NunchiCore/InputSession.swift` | 치고 있는 단어 상태 |
| `Sources/NunchiCore/KeyRouter.swift` | 키 → 미리보기/확정/통과 결정 |
| `Sources/Nunchi/InputController.swift` | InputMethodKit 연결(판단 로직 없음) |
| `scripts/make-icon.swift` | 메뉴 막대 아이콘·앱 아이콘 생성(그림은 `docs/logo.svg` 와 같음) |
| `scripts/e2e.swift` | 실제 입력기로 타이핑해 보는 개발용 도구(포커스를 가져간다) |

## 알려진 문제

- 설치된 입력기를 덮어쓰고 프로세스를 다시 띄우면, 앱들이 옛 연결을 붙잡아 키가 사라진다. 로그아웃·로그인으로 풀린다.
- 입력기를 새로 추가하거나 빼면 입력 메뉴 목록이 로그아웃·로그인 전까지 바뀌지 않을 수 있다(TextInputMenuAgent 재시작으로는 안 풀렸다).
- E2E(가짜 키 입력)에서 비밀번호 칸 입력 일부가 사라졌지만 실제 키보드로는 문제가 없었다. Return 이 줄바꿈 없이 확정만 되는 현상, 오른쪽 ⌘ 탭(가짜 이벤트)이 안 먹는 현상을 조사 중.
- Command Line Tools 6.4 에서 Swift Testing 매크로 플러그인을 간헐적으로 못 찾는 문제가 있어 `scripts/test.sh` 가 그 오류일 때만 다시 시도한다.

## 참고

hannyeong 등 다른 입력기의 코드는 보지 않고 새로 작성했다(동작 관찰만 참고). 라이선스는 공개 전환 시 정한다.
