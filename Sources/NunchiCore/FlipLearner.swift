/// 사용자가 Esc·오른쪽 ⌘ 로 뒤집어서 확정한 단어. 자동 판별(단어장 포함)과 다른 언어로 확정됐을 때만 생긴다.
public struct Flip: Equatable, Sendable {
    public let keys: [Character]
    public let language: Language
}

/// 같은 단어를 같은 쪽으로 `threshold` 번 뒤집으면 단어장에 배운다. 배운 단어를 반대로 뒤집으면 반반인 단어로 보고 뺀다.
/// 직접 적은 단어는 건드리지 않는다. 횟수는 입력기가 켜져 있는 동안만 센다.
public struct FlipLearner {
    public static let threshold = 2

    public enum Change: Equatable, Sendable {
        case learn(keys: [Character], language: Language)
        case forget(keys: [Character])
    }

    private var counts: [String: (language: Language, count: Int)] = [:]

    public init() {}

    public mutating func record(_ flip: Flip, wordbook: Wordbook) -> Change? {
        let key = Wordbook.lookupKey(flip.keys)
        if wordbook.manualLanguage(for: flip.keys) != nil { return nil }
        if let learned = wordbook.learnedLanguage(for: flip.keys) {
            counts[key] = nil
            return learned == flip.language ? nil : .forget(keys: flip.keys)
        }
        let count = counts[key]?.language == flip.language ? counts[key]!.count + 1 : 1
        guard count >= Self.threshold else {
            counts[key] = (flip.language, count)
            return nil
        }
        counts[key] = nil
        return .learn(keys: flip.keys, language: flip.language)
    }

    public mutating func reset() { counts = [:] }
}
