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

    @Test func wordsEndingInㅜOrㅠSyllableStayKorean() {
        // 끝의 ㅜ·ㅠ 가 앞 자음과 글자를 이루면 울음 표시가 아니다. 떼고 보면 ㅇ 이 홀로 남아 영어로 잘못 바뀌었다.
        #expect(judge("wjqtngksmsruddn") == .korean)   // 접수하는경우
        #expect(judge("ruddn") == .korean)             // 경우
        #expect(judge("snrn") == .korean)              // 누구
        #expect(judge("dndb") == .korean)              // 우유
        #expect(judge("dlgn") == .korean)              // 이후
        #expect(judge("ruddnbb") == .korean)          // 경우ㅠㅠ
        #expect(judge("gjfbb") == .korean)             // 헐ㅠㅠ → 허류ㅠ
    }

    @Test func chatExpressionsStayKorean() {
        #expect(judge("rufgkaee") == .korean)   // 결함ㄷㄷ
        #expect(judge("eoqkree") == .korean)    // 대박ㄷㄷ
        #expect(judge("drfd") == .korean)       // ㅇㄱㄹㅇ
        #expect(judge("fdzz") == .korean)       // ㄹㅇㅋㅋ
        #expect(judge("drfdzz") == .korean)     // ㅇㄱㄹㅇㅋㅋ
    }

    @Test func englishEndingInDoubleLettersStaysEnglish() {
        for word in ["free", "see", "tree", "coffee", "class", "glass", "add", "dress"] {
            #expect(judge(word) == .english, "\(word)")
        }
    }

    @Test func singleLoneKeyFollowsThePreviousWord() {
        #expect(judge("t") == .korean)
        #expect(judge("t", after: .english) == .english)   // don't 의 t
    }
}
