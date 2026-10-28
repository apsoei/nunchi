import Testing
@testable import NunchiCore

@Suite struct EnglishSignalTests {
    /// 처음으로 영어 신호가 켜지는 키 위치(1부터). 끝까지 안 켜지면 nil.
    private func firstSignal(_ word: String) -> Int? {
        let keys = Array(word)
        return (1...keys.count).first { EnglishSignal.looksEnglish(Array(keys.prefix($0))) }
    }

    @Test func detectsEnglishMidWord() {
        #expect(firstSignal("test") == 2)       // ㅅㄷ
        #expect(firstSignal("kubectl") == 1)    // ㅏ 로 시작(모음 시작은 바로 영어)
        #expect(firstSignal("commit") == 3)     // 채ㅡ
        #expect(firstSignal("gradle") == 2)     // ㅎㄱ
        #expect(firstSignal("spring") == 6)     // 끝의 n 은 ㅜ(울음)일 수 있어 g 까지 본다
    }

    @Test func neverSwitchesOnFirstConsonantKey() {
        #expect(!EnglishSignal.looksEnglish(Array("r")))   // ㄱ
        #expect(!EnglishSignal.looksEnglish(Array("d")))   // ㅇ
    }

    @Test func wordStartingWithVowelIsEnglishAtOnce() {
        // 한국어 글자는 모음으로 시작하지 않는다(아 = ㅇ+ㅏ).
        for key in ["o", "p", "i", "u", "y", "j", "k", "l"] {   // ㅐ ㅔ ㅑ ㅕ ㅛ ㅓ ㅏ ㅣ
            #expect(EnglishSignal.looksEnglish(Array(key)), "\(key)")
        }
        #expect(firstSignal("open") == 1)
        #expect(firstSignal("python") == 1)
    }

    @Test func chatVowelsAtStartStayKorean() {
        for word in ["b", "bb", "n", "nn", "m", "mm", "h", "hh", "P", "PP"] {   // ㅠ ㅜ ㅡ ㅗ ㅖ
            #expect(!EnglishSignal.looksEnglish(Array(word)), "\(word)")
        }
        #expect(firstSignal("hello") == 2)   // ㅗ 로 시작하는 영어는 두 번째 키에서
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

    @Test func longerShorthandStaysKorean() {
        for word in ["drfd", "wrs", "gdx", "sdt", "rde", "qqqr"] {   // ㅇㄱㄹㅇ ㅈㄱㄴ ㅎㅇㅌ ㄴㅇㅅ ㄱㅇㄷ ㅂㅂㅂㄱ
            #expect(!EnglishSignal.looksEnglish(Array(word)), "\(word)")
        }
    }

    @Test func shorthandWithLaughterStaysKorean() {
        #expect(!EnglishSignal.looksEnglish(Array("fdzz")))     // ㄹㅇㅋㅋ
        #expect(!EnglishSignal.looksEnglish(Array("drfdzz")))   // ㅇㄱㄹㅇㅋㅋ
    }

    @Test func trembleAfterWordStaysKorean() {
        #expect(!EnglishSignal.looksEnglish(Array("rufgkaee")))    // 결함ㄷㄷ
        #expect(!EnglishSignal.looksEnglish(Array("eoqkreee")))    // 대박ㄷㄷㄷ
    }

    @Test func englishWordsEndingWithThoseKeysAreStillEnglish() {
        #expect(EnglishSignal.looksEnglish(Array("testing")))
        #expect(EnglishSignal.looksEnglish(Array("bug")))
        #expect(EnglishSignal.looksEnglish(Array("long")))
    }
}
