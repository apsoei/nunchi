/// 입력기가 받은 키를 앱 종류와 무관한 형태로 바꾼 것.
public enum KeyEvent: Equatable, Sendable {
    case letter(Character)   // a~z, A~Z (Shift 반영)
    case backspace
    case escape
    case rightCommandTap     // 오른쪽 ⌘ 를 다른 키 없이 눌렀다 뗌
    case other               // Space·Return·숫자·문장부호·방향키 등 단어를 끝내는 키
}

public struct KeyContext: Equatable, Sendable {
    public var secureInput: Bool
    public var terminalLike: Bool
    public var capsLock: Bool
    /// ⌘·⌃·⌥ 가 눌려 있다(단축키).
    public var modifierHeld: Bool

    public init(secureInput: Bool = false, terminalLike: Bool = false, capsLock: Bool = false, modifierHeld: Bool = false) {
        self.secureInput = secureInput
        self.terminalLike = terminalLike
        self.capsLock = capsLock
        self.modifierHeld = modifierHeld
    }
}

/// 앱(클라이언트)에 할 일.
public enum Effect: Equatable, Sendable {
    case insert(String)      // 확정. 미리보기가 있으면 그 자리를 대신한다
    case setMarked(String)   // 밑줄 미리보기 갱신
    case clearMarked
}

public struct RouterResult: Equatable, Sendable {
    public var effects: [Effect]
    /// true 면 원래 키를 앱이 그대로 받는다.
    public var passThrough: Bool

    public init(effects: [Effect], passThrough: Bool) {
        self.effects = effects
        self.passThrough = passThrough
    }
}

public final class KeyRouter {
    public let session: InputSession

    public init(session: InputSession = InputSession()) {
        self.session = session
    }

    public var wordbook: Wordbook {
        get { session.wordbook }
        set { session.wordbook = newValue }
    }

    /// 마지막으로 뒤집어서 확정한 단어(배우기용). 한 번 꺼내면 비워진다.
    public func takeFlip() -> Flip? { session.takeFlip() }

    /// 입력기가 새 앱(입력창)에서 켜질 때. 터미널에서는 애매한 단어를 영어로 본다.
    public func activate(terminalLike: Bool) {
        session.resetContext(to: terminalLike ? .english : nil)
    }

    public func handle(_ event: KeyEvent, context: KeyContext) -> RouterResult {
        // 비밀번호 칸: 남은 미리보기만 보이는 그대로 확정하고, 키는 손대지 않는다.
        if context.secureInput {
            return RouterResult(effects: commitAsDisplayed(), passThrough: true)
        }
        if context.modifierHeld || context.capsLock {
            return pass(after: session.endWord())
        }

        switch event {
        case .letter(let key):
            session.type(key)
            return RouterResult(effects: [.setMarked(session.display)], passThrough: false)

        case .backspace:
            guard session.backspace() else { return RouterResult(effects: [], passThrough: true) }
            return RouterResult(effects: [session.isEmpty ? .clearMarked : .setMarked(session.display)], passThrough: false)

        case .escape:
            if session.isEmpty { return RouterResult(effects: [], passThrough: true) }
            if context.terminalLike { return pass(after: session.commitAsDisplayed()) }
            _ = session.flip()
            return RouterResult(effects: [.setMarked(session.display)], passThrough: false)

        case .rightCommandTap:
            guard session.flip() else { return RouterResult(effects: [], passThrough: true) }
            return RouterResult(effects: [.setMarked(session.display)], passThrough: false)

        case .other:
            return pass(after: session.endWord())
        }
    }

    /// 포커스가 옮겨 갈 때처럼 판별 없이 지금 보이는 그대로 확정한다.
    public func commitAsDisplayed() -> [Effect] {
        session.commitAsDisplayed().map { [.insert($0)] } ?? []
    }

    private func pass(after committed: String?) -> RouterResult {
        RouterResult(effects: committed.map { [.insert($0)] } ?? [], passThrough: true)
    }
}
