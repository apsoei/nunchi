/// 두벌식 자판 배열과 한글 자모 표.
enum Jamo {
    static let keyMap: [Character: Character] = [
        "q": "ㅂ", "w": "ㅈ", "e": "ㄷ", "r": "ㄱ", "t": "ㅅ", "y": "ㅛ", "u": "ㅕ", "i": "ㅑ", "o": "ㅐ", "p": "ㅔ",
        "a": "ㅁ", "s": "ㄴ", "d": "ㅇ", "f": "ㄹ", "g": "ㅎ", "h": "ㅗ", "j": "ㅓ", "k": "ㅏ", "l": "ㅣ",
        "z": "ㅋ", "x": "ㅌ", "c": "ㅊ", "v": "ㅍ", "b": "ㅠ", "n": "ㅜ", "m": "ㅡ",
        "Q": "ㅃ", "W": "ㅉ", "E": "ㄸ", "R": "ㄲ", "T": "ㅆ", "O": "ㅒ", "P": "ㅖ",
    ]

    /// Shift 를 눌러 다른 자모가 나오는 키. 나머지 대문자는 소문자와 같은 자모가 된다.
    static let shiftedKeys: Set<Character> = ["Q", "W", "E", "R", "T", "O", "P"]

    static func jamo(for key: Character) -> Character? {
        if let j = keyMap[key] { return j }
        guard let lower = key.lowercased().first else { return nil }
        return keyMap[lower]
    }

    static let choseong: [Character] = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ")
    static let jungseong: [Character] = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ")
    /// 받침 표. 0번은 받침 없음.
    static let jongseong: [Character?] = [nil] + Array("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ").map { $0 }

    static func isVowel(_ j: Character) -> Bool { jungseong.contains(j) }

    static let compoundVowels: [String: Character] = [
        "ㅗㅏ": "ㅘ", "ㅗㅐ": "ㅙ", "ㅗㅣ": "ㅚ", "ㅜㅓ": "ㅝ", "ㅜㅔ": "ㅞ", "ㅜㅣ": "ㅟ", "ㅡㅣ": "ㅢ",
    ]

    static let compoundFinals: [String: Character] = [
        "ㄱㅅ": "ㄳ", "ㄴㅈ": "ㄵ", "ㄴㅎ": "ㄶ", "ㄹㄱ": "ㄺ", "ㄹㅁ": "ㄻ", "ㄹㅂ": "ㄼ",
        "ㄹㅅ": "ㄽ", "ㄹㅌ": "ㄾ", "ㄹㅍ": "ㄿ", "ㄹㅎ": "ㅀ", "ㅂㅅ": "ㅄ",
    ]

    static let splitFinals: [Character: (Character, Character)] = Dictionary(
        uniqueKeysWithValues: compoundFinals.map { key, value in
            (value, (key.first!, key.last!))
        }
    )

    static func canBeFinal(_ j: Character) -> Bool { jongseong.contains(j) }

    /// 자모 → 키. 단어장의 한글을 키로 되돌릴 때 쓴다.
    private static let keyForJamo: [Character: Character] = Dictionary(uniqueKeysWithValues: keyMap.map { ($1, $0) })

    static func key(for jamo: Character) -> Character? { keyForJamo[jamo] }

    static let compoundVowelParts: [Character: [Character]] = Dictionary(
        uniqueKeysWithValues: compoundVowels.map { ($1, Array($0)) }
    )

    /// 겹모음은 두 키로 나눈다(ㅘ → ㅗㅏ).
    static func splitVowel(_ vowel: Character) -> [Character] { compoundVowelParts[vowel] ?? [vowel] }

    static func syllable(cho: Character, jung: Character, jong: Character?) -> Character {
        let c = choseong.firstIndex(of: cho)!
        let v = jungseong.firstIndex(of: jung)!
        let f = jongseong.firstIndex(of: jong)!
        return Character(Unicode.Scalar(0xAC00 + (c * 21 + v) * 28 + f)!)
    }
}
