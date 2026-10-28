/// 치는 도중 "한국어 단어라면 나올 수 없는 모양"이 생겼는지 본다. 켜지면 그 단어는 바로 영어로 바꾼다.
public enum EnglishSignal {
    /// 채팅에서 흔한 초성 줄임말. 낱자모지만 한글로 둔다.
    static let shorthand: Set<String> = [
        "ㅇㅋ", "ㄱㅅ", "ㅈㅅ", "ㄴㄴ", "ㄱㄱ", "ㅎㅇ", "ㅂㅇ", "ㄹㅇ", "ㅊㅋ", "ㅅㄱ", "ㄷㄷ", "ㅂㅂ",
        "ㅁㄹ", "ㅇㄴ", "ㅈㅂ", "ㄱㅊ", "ㄴㅇ", "ㅇㅈ", "ㅅㅂ", "ㅁㅊ", "ㅇㄷ", "ㄱㄷ", "ㅎㄹ",
    ]

    /// 단어 끝에 붙는 ㅋ·ㅎ·ㅠ·ㅜ 키. 끝에 몰려 있으면 떼고 판단한다(좋아ㅋㅋ).
    static let expressiveKeys: Set<Character> = ["z", "g", "b", "n"]
    static let cryingKeys: Set<Character> = ["b", "n"]
    /// 낱자모만으로 이뤄져도 한글로 두는 자모(ㅋㅋㅋㅎㅎ, ㅇㅋㅋ, ㅠㅜ).
    static let expressiveJamo: Set<Character> = ["ㅋ", "ㅎ", "ㅠ", "ㅜ", "ㅇ"]

    public static func looksEnglish(_ keys: [Character]) -> Bool {
        guard let first = keys.first else { return false }
        if first.isUppercase && !Jamo.shiftedKeys.contains(first) { return true }

        let body = keys.dropLast(trailingExpressiveCount(keys))
        guard body.count >= 2 else { return false }

        let composition = HangulComposer.compose(Array(body))
        guard composition.hasOrphan else { return false }
        return !isShorthand(HangulComposer.compose(keys).text)
    }

    /// 끝에 붙은 같은 키 반복(ㅋㅋ, ㅎㅎ)이나 ㅠ·ㅜ 묶음의 길이. 섞인 끝(spring 의 ng)은 한 글자만 뗀다.
    /// 낱자모로 남은 것만 뗀다. 경우 의 ㅜ 처럼 앞 자음과 글자를 이룬 키까지 떼면 ㅇ 이 홀로 남아 영어로 잘못 본다.
    static func trailingExpressiveCount(_ keys: [Character]) -> Int {
        guard let last = keys.last, expressiveKeys.contains(last) else { return 0 }
        let sameRun = keys.reversed().prefix { $0 == last }.count
        let cryRun = cryingKeys.contains(last) ? keys.reversed().prefix { cryingKeys.contains($0) }.count : 0
        return min(max(sameRun, cryRun), HangulComposer.compose(keys).trailingLoneCount)
    }

    static func isShorthand(_ text: String) -> Bool {
        Set(text).count == 1 || shorthand.contains(text) || text.allSatisfy(expressiveJamo.contains)
    }
}
