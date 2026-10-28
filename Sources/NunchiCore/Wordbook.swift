import Foundation

/// 사용자 단어장. 한 줄에 하나씩 "나오길 원하는 모양 그대로" 적는다. 영어로 적으면 영어, 한글로 적으면 한글로 나온다.
/// 표시 줄(`learnedMarker`) 아래는 Esc 로 배운 단어로, 입력기가 넣고 뺀다. 직접 적은 단어가 배운 단어보다 앞선다.
public struct Wordbook: Equatable, Sendable {
    public static let learnedMarker = "# --- Esc로 배운 단어 (입력기가 자동으로 넣고 뺍니다) ---"
    public static let empty = Wordbook(text: "")

    private var manual: [String: Language] = [:]
    private var learned: [String: Language] = [:]

    public init(text: String) {
        var inLearned = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.trimmingCharacters(in: .whitespaces) == Self.learnedMarker {
                inLearned = true
                continue
            }
            guard let (key, language) = Self.entry(fromLine: String(line)) else { continue }
            if inLearned { learned[key] = language } else { manual[key] = language }
        }
    }

    /// 친 키가 단어장 단어와 똑같으면 그 언어. 직접 적은 단어가 먼저다.
    public func language(for keys: [Character]) -> Language? {
        let key = Self.lookupKey(keys)
        return manual[key] ?? learned[key]
    }

    func manualLanguage(for keys: [Character]) -> Language? { manual[Self.lookupKey(keys)] }
    func learnedLanguage(for keys: [Character]) -> Language? { learned[Self.lookupKey(keys)] }

    /// 대조용 키. 대문자는 Shift 로 다른 자모가 나오는 Q W E R T O P 만 구분하고 나머지는 소문자로 본다.
    static func lookupKey(_ keys: [Character]) -> String {
        String(keys.map { Jamo.shiftedKeys.contains($0) ? $0 : Character($0.lowercased()) })
    }

    /// 한 줄을 (대조용 키, 언어)로 읽는다. 빈 줄·메모·두 단어 이상·영어와 한글이 섞인 줄은 건너뛴다.
    static func entry(fromLine line: String) -> (String, Language)? {
        let word = line.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? ""
        guard !word.isEmpty, !word.contains(where: \.isWhitespace) else { return nil }
        if word.allSatisfy({ $0.isASCII && $0.isLetter }) {
            return (lookupKey(Array(word)), .english)
        }
        if let keys = keys(forHangul: word) {
            return (lookupKey(keys), .korean)
        }
        return nil
    }

    /// 한글을 두벌식 키로 되돌린다. 새 → to, 뿔 → Qnf, ㄱㅅ → rt. 한글이 아닌 글자가 있으면 nil.
    static func keys(forHangul text: String) -> [Character]? {
        var jamo: [Character] = []
        for scalar in text.unicodeScalars {
            let value = Int(scalar.value)
            if (0xAC00...0xD7A3).contains(value) {
                let index = value - 0xAC00
                jamo.append(Jamo.choseong[index / 588])
                jamo.append(contentsOf: Jamo.splitVowel(Jamo.jungseong[index % 588 / 28]))
                if let jong = Jamo.jongseong[index % 28] {
                    if let (first, second) = Jamo.splitFinals[jong] {
                        jamo.append(contentsOf: [first, second])
                    } else {
                        jamo.append(jong)
                    }
                }
            } else {
                let character = Character(scalar)
                guard Jamo.key(for: character) != nil || Jamo.compoundVowelParts[character] != nil
                    || Jamo.splitFinals[character] != nil else { return nil }
                if let (first, second) = Jamo.splitFinals[character] {
                    jamo.append(contentsOf: [first, second])
                } else {
                    jamo.append(contentsOf: Jamo.splitVowel(character))
                }
            }
        }
        var keys: [Character] = []
        for j in jamo {
            guard let key = Jamo.key(for: j) else { return nil }
            keys.append(key)
        }
        return keys
    }

    /// 배운 단어 칸만 `lines` 로 바꾼 단어장 글. 표시 줄 위(직접 적은 부분)는 그대로 둔다.
    /// 표시 줄이 없으면 맨 끝에 빈 줄 하나를 두고 붙인다.
    static func replacingLearned(in text: String, with lines: [String]) -> String {
        var head: String
        if let range = text.range(of: learnedMarker) {
            head = String(text[..<range.lowerBound])
        } else {
            head = text
            while !head.isEmpty, !head.hasSuffix("\n\n") { head += "\n" }
        }
        return head + learnedMarker + "\n" + lines.map { $0 + "\n" }.joined()
    }

    /// 배운 단어 칸의 줄들(메모·빈 줄 제외).
    static func learnedLines(in text: String) -> [String] {
        guard let range = text.range(of: learnedMarker) else { return [] }
        return text[range.upperBound...].split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }
}
