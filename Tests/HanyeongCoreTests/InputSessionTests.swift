import Testing
@testable import HanyeongCore

@Suite struct InputSessionTests {
    private func session(typing keys: String) -> InputSession {
        let s = InputSession()
        keys.forEach { s.type($0) }
        return s
    }

    @Test func showsHangulUntilSignalThenEnglish() {
        let s = session(typing: "t")
        #expect(s.display == "ㅅ")
        s.type("e")
        #expect(s.display == "te")
        s.type("s")
        s.type("t")
        #expect(s.display == "test")
    }

    @Test func englishStaysUntilWordEndEvenIfHangulWouldBeClean() {
        // 한 번 영어로 바뀐 단어는 뒤에 어떤 키가 와도 영어로 둔다(깜빡임 방지).
        let s = session(typing: "testk")
        #expect(s.display == "testk")
    }

    @Test func backspaceCanUndoTheSwitch() {
        let s = session(typing: "ts")
        #expect(s.display == "ts")
        #expect(s.backspace())
        #expect(s.display == "ㅅ")
        s.type("k")
        #expect(s.display == "사")
    }

    @Test func backspaceOnEmptyReturnsFalse() {
        let s = InputSession()
        #expect(!s.backspace())
        #expect(s.isEmpty)
    }

    @Test func flipTogglesAndLocksTheWord() {
        let s = session(typing: "rk")
        #expect(s.display == "가")
        #expect(s.flip())
        #expect(s.display == "rk")
        s.type("t")
        #expect(s.display == "rkt")
        #expect(s.flip())
        #expect(s.display == "갓")
        #expect(s.endWord() == "갓")
    }

    @Test func flipOnEmptyReturnsFalse() {
        #expect(!InputSession().flip())
    }

    @Test func endWordJudgesAndClears() {
        let s = session(typing: "git")
        #expect(s.display == "햣")
        #expect(s.endWord() == "git")
        #expect(s.isEmpty)
        #expect(s.endWord() == nil)
    }

    @Test func previousWordGivesContext() {
        let s = InputSession()
        "dkssud".forEach { s.type($0) }
        #expect(s.endWord() == "안녕")
        "to".forEach { s.type($0) }
        #expect(s.endWord() == "새")

        "want".forEach { s.type($0) }
        #expect(s.endWord() == "want")
        "to".forEach { s.type($0) }
        #expect(s.endWord() == "to")
    }

    @Test func resetContextForgetsPreviousWord() {
        let s = InputSession()
        "want".forEach { s.type($0) }
        _ = s.endWord()
        s.resetContext()
        "to".forEach { s.type($0) }
        #expect(s.endWord() == "새")
    }

    @Test func commitAsDisplayedSkipsJudging() {
        let s = session(typing: "git")
        #expect(s.commitAsDisplayed() == "햣")
        #expect(s.isEmpty)
    }
}
