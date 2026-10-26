public enum Language: Sendable, Equatable {
    case korean, english
}

/// 단어가 끝났을 때(Space·Return·문장부호 등) 최종 언어를 정한다.
public enum WordJudge {
    public static func judge(keys: [Character], previous: Language?) -> Language {
        guard !keys.isEmpty else { return previous ?? .korean }
        if EnglishSignal.looksEnglish(keys) { return .english }

        let full = HangulComposer.compose(keys)
        let body = Array(keys.dropLast(EnglishSignal.trailingExpressiveCount(keys)))
        if body.isEmpty { return .korean }   // ㅋㅋ, ㅠㅠ

        // 끝에 낱자음이 남았다(애찯ㄱ, ㄷㅎㅎ). 한국어 단어는 이렇게 끝나지 않는다.
        let bodyComposition = HangulComposer.compose(body)
        if keys.count >= 2, bodyComposition.hasOrphan || bodyComposition.hasTrailingOrphan,
           !EnglishSignal.isShorthand(full.text) {
            return .english
        }

        if Lexicon.english.contains(String(keys).lowercased()) {
            return Lexicon.korean.contains(full.text) ? (previous ?? .korean) : .english
        }

        // 키 하나짜리 낱자모(don't 의 t)는 앞 단어를 따른다.
        if keys.count == 1, full.hasOrphan || full.hasTrailingOrphan {
            return previous ?? .korean
        }
        return .korean
    }
}
