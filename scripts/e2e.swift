// 실제 입력기로 타이핑해 보는 확인 도구(개발용). 설치된 입력기를 잠시 선택하고, 이 프로세스의 창에만 키 이벤트를 보낸 뒤
// 원래 입력 소스로 되돌린다. 이벤트를 보내려면 실행하는 터미널에 손쉬운 사용 권한이 필요하다(입력기 자체는 필요 없음).
// 주의: 테스트 창이 앞으로 나와 포커스를 가져간다. 자리를 비웠을 때만 돌린다.
// 실행: swift scripts/e2e.swift
import AppKit
import Carbon

let modeID = "io.github.apsoei.inputmethod.HanyeongAuto.Korean"

func inputSource(_ id: String) -> TISInputSource? {
    let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
    return (TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource])?.first
}

guard CGPreflightPostEventAccess() else {
    print("키 이벤트를 보낼 권한이 없습니다. 시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서 터미널을 허용하세요.")
    exit(2)
}
guard let target = inputSource(modeID) else {
    print("입력기가 등록돼 있지 않습니다. scripts/install.sh 를 먼저 실행하세요.")
    exit(2)
}
let original = TISCopyCurrentKeyboardInputSource().takeRetainedValue()

let letterCodes: [Character: CGKeyCode] = [
    "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05, "z": 0x06, "x": 0x07, "c": 0x08, "v": 0x09,
    "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10, "t": 0x11, "o": 0x1F, "u": 0x20, "i": 0x22,
    "p": 0x23, "l": 0x25, "j": 0x26, "k": 0x28, "n": 0x2D, "m": 0x2E,
]
let pid = getpid()

func post(_ code: CGKeyCode, flags: CGEventFlags = []) {
    for down in [true, false] {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)!
        event.flags = flags
        event.postToPid(pid)
        usleep(20_000)
    }
}

func rightCommandTap() {
    let down = CGEvent(keyboardEventSource: nil, virtualKey: 0x36, keyDown: true)!
    down.type = .flagsChanged
    down.flags = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | 0x10)
    down.postToPid(pid)
    usleep(60_000)
    let up = CGEvent(keyboardEventSource: nil, virtualKey: 0x36, keyDown: false)!
    up.type = .flagsChanged
    up.flags = []
    up.postToPid(pid)
    usleep(20_000)
}

/// 특수 키 표기: ␣ Space, ⏎ Return, ⎋ Esc, ⌫ Backspace, ⌘ 오른쪽 ⌘ 탭
func type(_ keys: String) {
    for ch in keys {
        switch ch {
        case "␣": post(0x31)
        case "⏎": post(0x24)
        case "⎋": post(0x35)
        case "⌫": post(0x33)
        case "⌘": rightCommandTap()
        default:
            let lower = Character(ch.lowercased())
            post(letterCodes[lower]!, flags: ch.isUppercase ? .maskShift : [])
        }
    }
}

struct Case {
    let name: String
    let keys: String
    let expected: String
    var secure = false
}

let cases: [Case] = [
    Case(name: "한글 문장", keys: "dkssudgktpdy␣", expected: "안녕하세요 "),
    Case(name: "치는 도중(1타) 한글", keys: "t", expected: "ㅅ"),
    Case(name: "치는 도중(2타) 영어로 전환", keys: "te", expected: "te"),
    Case(name: "영어 단어", keys: "test␣", expected: "test "),
    Case(name: "개발 명령", keys: "git␣status␣", expected: "git status "),
    Case(name: "끝에 낱자음 → 영어", keys: "docker␣", expected: "docker "),
    Case(name: "대문자로 시작", keys: "Hello␣", expected: "Hello "),
    Case(name: "채팅 웃음(ㅋ 은 받침이 된다)", keys: "whgdkzz␣", expected: "좋앜ㅋ "),
    Case(name: "앞 단어 문맥(to)", keys: "want␣to␣go␣", expected: "want to go "),
    Case(name: "한글 문맥(새)", keys: "tptkd␣to␣", expected: "세상 새 "),
    Case(name: "Esc 뒤집기", keys: "rk⎋␣", expected: "rk "),
    Case(name: "오른쪽 ⌘ 뒤집기", keys: "test⌘␣", expected: "ㅅㄷㄴㅅ "),
    Case(name: "백스페이스", keys: "dkssud⌫␣", expected: "안녀 "),
    Case(name: "미리보기 없을 때 백스페이스는 앱으로", keys: "rk␣⌫", expected: "가"),
    Case(name: "Return", keys: "test⏎", expected: "test\n"),
    Case(name: "비밀번호 칸", keys: "rkt", expected: "rkt", secure: true),
]

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let window = NSWindow(contentRect: NSRect(x: 240, y: 240, width: 520, height: 260), styleMask: [.titled], backing: .buffered, defer: false)
window.title = "hanyeong-auto e2e"
window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

func onMain<T>(_ body: () -> T) -> T { DispatchQueue.main.sync(execute: body) }

/// 케이스마다 새 입력창을 만든다. 미리보기가 남은 입력창을 비우면 입력기의 늦은 요청이 사라진 위치를 가리켜 앱이 죽는다.
func freshInput(secure: Bool) -> NSView {
    window.contentView!.subviews.forEach { $0.removeFromSuperview() }
    let view: NSView = secure
        ? NSSecureTextField(frame: NSRect(x: 10, y: 110, width: 300, height: 24))
        : NSTextView(frame: NSRect(x: 0, y: 0, width: 520, height: 260))
    window.contentView!.addSubview(view)
    _ = window.makeFirstResponder(view)
    return view
}

func text(of view: NSView) -> String {
    if let field = view as? NSSecureTextField { return field.currentEditor()?.string ?? field.stringValue }
    return (view as! NSTextView).string
}

Thread.detachNewThread {
    var failures = 0
    defer {
        onMain {
            TISSelectInputSource(original)
            print(failures == 0 ? "\n전부 통과 (\(cases.count)건)" : "\n실패 \(failures)건 / \(cases.count)건")
            exit(failures == 0 ? 0 : 1)
        }
    }
    sleep(1)
    onMain {
        _ = freshInput(secure: false)
        TISSelectInputSource(target)
    }
    sleep(2)
    for c in cases {
        let view = onMain { freshInput(secure: c.secure) }
        usleep(400_000)
        type(c.keys)
        usleep(400_000)
        let got = onMain { text(of: view) }
        let ok = got == c.expected
        if !ok { failures += 1 }
        print("\(ok ? "✔" : "✘") \(c.name): \(c.keys.debugDescription) → \(got.debugDescription)\(ok ? "" : " (기대: \(c.expected.debugDescription))")")
        // 다음 케이스로 넘어가기 전에 남은 미리보기를 확정시킨다.
        onMain { NSTextInputContext.current?.discardMarkedText() }
        usleep(300_000)
    }
}
app.run()
