/// macOS 가상 키코드(kVK_ANSI_*)를 QWERTY 글자로 바꾼다. 키보드 배열 설정과 무관하게 자판 위치로 본다.
public enum KeyCodeMap {
    static let letters: [UInt16: Character] = [
        0x00: "a", 0x01: "s", 0x02: "d", 0x03: "f", 0x04: "h", 0x05: "g", 0x06: "z", 0x07: "x",
        0x08: "c", 0x09: "v", 0x0B: "b", 0x0C: "q", 0x0D: "w", 0x0E: "e", 0x0F: "r", 0x10: "y",
        0x11: "t", 0x1F: "o", 0x20: "u", 0x22: "i", 0x23: "p", 0x25: "l", 0x26: "j", 0x28: "k",
        0x2D: "n", 0x2E: "m",
    ]
    static let backspace: UInt16 = 0x33
    static let escape: UInt16 = 0x35

    public static func event(keyCode: UInt16, shift: Bool) -> KeyEvent {
        if keyCode == backspace { return .backspace }
        if keyCode == escape { return .escape }
        guard let letter = letters[keyCode] else { return .other }
        return .letter(shift ? Character(letter.uppercased()) : letter)
    }
}

/// 오른쪽 ⌘ 를 다른 키 없이 짧게 눌렀다 뗀 것을 알아챈다. 입력기가 원래 받는 flagsChanged 이벤트만 쓴다.
public struct RightCommandTapDetector {
    static let rightCommand: UInt16 = 0x36
    public var maxDuration = 0.4

    private var downAt: Double?
    private var interrupted = false

    public init() {}

    /// 탭이 끝났으면 true.
    public mutating func flagsChanged(keyCode: UInt16, rightCommandDown: Bool, time: Double) -> Bool {
        guard keyCode == Self.rightCommand else {
            if downAt != nil { interrupted = true }
            return false
        }
        if rightCommandDown {
            downAt = time
            interrupted = false
            return false
        }
        defer { downAt = nil }
        guard let downAt, !interrupted else { return false }
        return time - downAt <= maxDuration
    }

    public mutating func keyDown() {
        if downAt != nil { interrupted = true }
    }
}
