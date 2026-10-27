import Testing
@testable import NunchiCore

@Suite struct WordJudgeTests {
    private func judge(_ word: String, after previous: Language? = nil) -> Language {
        WordJudge.judge(keys: Array(word), previous: previous)
    }

    @Test func midWordSignalWins() {
        #expect(judge("test") == .english)
        #expect(judge("spring") == .english)
    }

    @Test func leftoverLoneJamoAtWordEndMeansEnglish() {
        #expect(judge("docker") == .english)   // 애찯ㄱ
        #expect(judge("egg") == .english)      // ㄷㅎㅎ
    }

    @Test func lexiconWordsAreEnglish() {
        #expect(judge("git") == .english)      // 햣
        #expect(judge("the") == .english)      // 솓
        #expect(judge("sudo") == .english)     // 녀애
    }

    @Test func wordsThatAreAlsoKoreanFollowThePreviousWord() {
        #expect(judge("to") == .korean)                    // 새
        #expect(judge("to", after: .korean) == .korean)
        #expect(judge("to", after: .english) == .english)
        #expect(judge("go", after: .english) == .english)  // 해
    }

    @Test func koreanStaysKorean() {
        #expect(judge("rk") == .korean)
        #expect(judge("dkssud") == .korean)
        #expect(judge("dkssud", after: .english) == .korean)
        #expect(judge("whgdkz") == .korean)    // 좋아ㅋ
        #expect(judge("zz") == .korean)        // ㅋㅋ
        #expect(judge("rt") == .korean)        // ㄱㅅ
    }

    @Test func singleLoneKeyFollowsThePreviousWord() {
        #expect(judge("t") == .korean)
        #expect(judge("t", after: .english) == .english)   // don't 의 t
    }
}
