/// 지금 치고 있는 단어 하나의 상태. 키 목록을 그대로 들고 있어서 한글·영어 어느 쪽으로든 바로 그릴 수 있다.
public final class InputSession {
    private enum Mode: Equatable {
        case auto              // 한글로 보여 주며 신호를 기다린다
        case autoEnglish       // 도중 신호로 영어가 됐다
        case forced(Language)  // 사용자가 뒤집었다. 단어 끝까지 고정
    }

    public private(set) var keys: [Character] = []
    public private(set) var previousLanguage: Language?
    private var mode: Mode = .auto
    /// 사용자 단어장. 친 키가 단어장 단어와 똑같으면 뒤집은 경우를 빼고 그 언어로 보여 주고 확정한다.
    public var wordbook: Wordbook = .empty
    private var lastFlip: Flip?

    public init() {}

    public var isEmpty: Bool { keys.isEmpty }

    public var displayLanguage: Language {
        switch mode {
        case .forced(let language): language
        case .auto: wordbook.language(for: keys) ?? .korean
        case .autoEnglish: wordbook.language(for: keys) ?? .english
        }
    }

    public var display: String { render(displayLanguage) }

    public func type(_ key: Character) {
        keys.append(key)
        if mode == .auto, EnglishSignal.looksEnglish(keys) { mode = .autoEnglish }
    }

    /// 지울 키가 없으면 false. 이때 백스페이스는 앱이 처리해야 한다.
    public func backspace() -> Bool {
        guard !keys.isEmpty else { return false }
        keys.removeLast()
        if keys.isEmpty {
            mode = .auto
        } else if mode == .autoEnglish, !EnglishSignal.looksEnglish(keys) {
            mode = .auto
        }
        return true
    }

    /// 한↔영 뒤집기. 치고 있는 단어가 없으면 false.
    public func flip() -> Bool {
        guard !keys.isEmpty else { return false }
        mode = .forced(displayLanguage == .english ? .korean : .english)
        return true
    }

    /// 단어 끝. 언어를 판별해 확정할 글자를 돌려준다. 뒤집어서 판별과 다르게 확정했으면 `takeFlip()` 으로 알 수 있다.
    public func endWord() -> String? {
        guard !keys.isEmpty else { return nil }
        let automatic = wordbook.language(for: keys)
            ?? (mode == .autoEnglish ? .english : WordJudge.judge(keys: keys, previous: previousLanguage))
        var language = automatic
        if case .forced(let forced) = mode {
            language = forced
            if forced != automatic { lastFlip = Flip(keys: keys, language: forced) }
        }
        return finish(language)
    }

    /// 마지막으로 뒤집어서 확정한 단어. 한 번 꺼내면 비워진다.
    public func takeFlip() -> Flip? {
        defer { lastFlip = nil }
        return lastFlip
    }

    /// 판별 없이 보이는 그대로 확정한다(포커스 이동, 터미널의 Esc).
    public func commitAsDisplayed() -> String? {
        guard !keys.isEmpty else { return nil }
        return finish(displayLanguage)
    }

    /// 앱이 바뀌면 앞 단어 정보는 의미가 없다. 터미널처럼 영어가 기본인 곳은 영어로 시작한다.
    public func resetContext(to language: Language? = nil) {
        previousLanguage = language
    }

    private func finish(_ language: Language) -> String {
        let text = render(language)
        previousLanguage = language
        keys.removeAll()
        mode = .auto
        return text
    }

    private func render(_ language: Language) -> String {
        language == .english ? String(keys) : HangulComposer.compose(keys).text
    }
}
