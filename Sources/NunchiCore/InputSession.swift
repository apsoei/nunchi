/// 지금 치고 있는 단어 하나의 상태. 키 목록을 그대로 들고 있어서 한글·영어 어느 쪽으로든 바로 그릴 수 있다.
public final class InputSession {
    private enum Mode: Equatable {
        case auto              // 한글로 보여 주며 신호를 기다린다
        case autoEnglish       // 도중 신호로 영어가 됐다
        case forced(Language)  // 사용자가 뒤집었다. 단어 끝까지 고정
    }

    public private(set) var keys: [Character] = []
    /// 키마다 Caps Lock 이 켜져 있었는지. 판별은 소문자 키로 하고, 영어로 보여 줄 때만 대문자로 바꾼다.
    private var capsLocked: [Bool] = []
    public private(set) var previousLanguage: Language?
    private var mode: Mode = .auto
    /// 사용자 단어장. 친 키가 단어장 단어와 똑같으면 뒤집은 경우를 빼고 그 언어로 보여 주고 확정한다.
    public var wordbook: Wordbook = .empty
    private var lastFlip: Flip?

    /// 확정한 단어. `automatic` 은 뒤집기 없이 판별했을 때의 언어.
    private struct Committed {
        let keys: [Character]
        let capsLocked: [Bool]
        var language: Language
        let automatic: Language
    }
    private var lastEnded: Committed?
    /// 되돌릴 수 있는 단어(Space 로 끝낸 직후에만 있다).
    private var retro: Committed?

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

    public func type(_ key: Character, capsLock: Bool = false) {
        keys.append(key)
        capsLocked.append(capsLock)
        if mode == .auto, EnglishSignal.looksEnglish(keys) {
            mode = .autoEnglish
        } else if mode == .autoEnglish, EnglishSignal.isChatExpression(keys) {
            // ㅇㄱㄹ 에서 영어가 됐어도 ㅇㄱㄹㅇ 처럼 줄임말이 되면 한글로 돌아온다.
            mode = .auto
        }
    }

    /// 지울 키가 없으면 false. 이때 백스페이스는 앱이 처리해야 한다.
    public func backspace() -> Bool {
        guard !keys.isEmpty else { return false }
        keys.removeLast()
        capsLocked.removeLast()
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
        lastEnded = Committed(keys: keys, capsLocked: capsLocked, language: language, automatic: automatic)
        return finish(language)
    }

    /// 방금 끝낸 단어를 되돌릴 수 있게 한다(Space 로 끝냈을 때 라우터가 부른다).
    public func armRetro() { retro = lastEnded }

    public func clearRetro() { retro = nil }

    /// 되돌리기 후보: (지금 입력창에 있는 모양, 바꿀 모양).
    public func retroCandidate() -> (old: String, new: String)? {
        guard let retro else { return nil }
        let other: Language = retro.language == .english ? .korean : .english
        return (render(retro.language, keys: retro.keys, capsLocked: retro.capsLocked),
                render(other, keys: retro.keys, capsLocked: retro.capsLocked))
    }

    /// 되돌리기를 적용했다. 한 번 더 누르면 다시 뒤집을 수 있게 남겨 둔다.
    public func applyRetroFlip() {
        guard var flipped = retro else { return }
        flipped.language = flipped.language == .english ? .korean : .english
        retro = flipped
        previousLanguage = flipped.language
        lastFlip = flipped.language == flipped.automatic ? nil : Flip(keys: flipped.keys, language: flipped.language)
    }

    /// 마지막으로 뒤집어서 확정한 단어. 한 번 꺼내면 비워진다.
    public func takeFlip() -> Flip? {
        defer { lastFlip = nil }
        return lastFlip
    }

    /// 판별 없이 보이는 그대로 확정한다(포커스 이동, 터미널의 Esc).
    public func commitAsDisplayed() -> String? {
        lastEnded = nil
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
        capsLocked.removeAll()
        mode = .auto
        return text
    }

    private func render(_ language: Language) -> String {
        render(language, keys: keys, capsLocked: capsLocked)
    }

    private func render(_ language: Language, keys: [Character], capsLocked: [Bool]) -> String {
        guard language == .english else { return HangulComposer.compose(keys).text }
        return String(zip(keys, capsLocked).map { key, caps in caps ? Character(key.uppercased()) : key })
    }
}
