import Testing
@testable import HanyeongCore

@Suite struct EnglishSignalTests {
    /// 처음으로 영어 신호가 켜지는 키 위치(1부터). 끝까지 안 켜지면 nil.
    private func firstSignal(_ word: String) -> Int? {
        let keys = Array(word)
        return (1...keys.count).first { EnglishSignal.looksEnglish(Array(keys.prefix($0))) }
    }

    @Test func detectsEnglishMidWord() {
        #expect(firstSignal("test") == 2)       // ㅅㄷ
        #expect(firstSignal("kubectl") == 2)    // ㅏㅕ
        #expect(firstSignal("commit") == 3)     // 채ㅡ
        #expect(firstSignal("gradle") == 2)     // ㅎㄱ
        #expect(firstSignal("spring") == 6)     // 끝의 n 은 ㅜ(울음)일 수 있어 g 까지 본다
    }

    @Test func neverSwitchesOnFirstLowercaseKey() {
        #expect(!EnglishSignal.looksEnglish(Array("o")))
        #expect(!EnglishSignal.looksEnglish(Array("k")))
    }

    @Test func capitalizedFirstLetterIsEnglish() {
        #expect(EnglishSignal.looksEnglish(Array("H")))
        #expect(EnglishSignal.looksEnglish(Array("I")))
        // Shift 로 쌍자음·ㅒㅖ 가 나오는 키는 한글일 수 있다.
        #expect(!EnglishSignal.looksEnglish(Array("T")))
        #expect(!EnglishSignal.looksEnglish(Array("Tk")))
    }

    @Test func shiftHeldOverInsideKoreanWordStaysKorean() {
        // 했 을 치다 Shift 가 다음 키까지 눌린 경우(goTDj → 했어)
        #expect(!EnglishSignal.looksEnglish(Array("goTDj")))
    }

    @Test func koreanSlangStaysKorean() {
        #expect(!EnglishSignal.looksEnglish(Array("zzz")))    // ㅋㅋㅋ
        #expect(!EnglishSignal.looksEnglish(Array("bb")))     // ㅠㅠ
        #expect(!EnglishSignal.looksEnglish(Array("nn")))     // ㅜㅜ
        #expect(!EnglishSignal.looksEnglish(Array("gg")))     // ㅎㅎ
        #expect(!EnglishSignal.looksEnglish(Array("dz")))     // ㅇㅋ
        #expect(!EnglishSignal.looksEnglish(Array("fd")))     // ㄹㅇ
        #expect(!EnglishSignal.looksEnglish(Array("rt")))     // ㄱㅅ
    }

    @Test func koreanWordsNeverSignal() {
        for word in ["dkssudgktpdy", "rkatkgkqslek", "goTdj", "dkswdk", "ekfrdmf", "rhkdlf", "dnjsgksek", "Tkdnjs"] {
            #expect(firstSignal(word) == nil, "\(word)")
        }
    }

    @Test func wordsThatLookKoreanUntilTheEnd() {
        #expect(firstSignal("git") == nil)      // 햣
        #expect(firstSignal("the") == nil)      // 솓
        #expect(firstSignal("docker") == nil)   // 애찯ㄱ
    }
}

@Suite struct EnglishSignalChatTests {
    @Test func laughterAttachedToKoreanWordStaysKorean() {
        #expect(!EnglishSignal.looksEnglish(Array("whgdkzz")))   // 좋아ㅋㅋ
        #expect(!EnglishSignal.looksEnglish(Array("whgdkgg")))   // 좋아ㅎㅎ
        #expect(!EnglishSignal.looksEnglish(Array("rkatkbb")))   // 감사ㅠㅠ
        #expect(!EnglishSignal.looksEnglish(Array("dzzz")))      // ㅇㅋㅋㅋ
        #expect(!EnglishSignal.looksEnglish(Array("zzzgg")))     // ㅋㅋㅋㅎㅎ
    }

    @Test func englishWordsEndingWithThoseKeysAreStillEnglish() {
        #expect(EnglishSignal.looksEnglish(Array("testing")))
        #expect(EnglishSignal.looksEnglish(Array("bug")))
        #expect(EnglishSignal.looksEnglish(Array("long")))
    }
}
