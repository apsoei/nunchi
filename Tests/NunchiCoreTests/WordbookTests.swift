import Foundation
import Testing
@testable import NunchiCore

@Suite struct WordbookTests {
    @Test func hangulTurnsBackIntoKeys() {
        #expect(Wordbook.keys(forHangul: "새") == Array("to"))
        #expect(Wordbook.keys(forHangul: "뿔") == Array("Qnf"))
        #expect(Wordbook.keys(forHangul: "앉아") == Array("dkswdk"))
        #expect(Wordbook.keys(forHangul: "왜") == Array("dho"))
        #expect(Wordbook.keys(forHangul: "했어") == Array("goTdj"))
        #expect(Wordbook.keys(forHangul: "ㄱㅅㄱㅅ") == Array("rtrt"))
        #expect(Wordbook.keys(forHangul: "새1") == nil)
    }

    @Test func writtenShapeDecidesLanguage() {
        let book = Wordbook(text: "git\n새\nkubectl   # 메모\n")
        #expect(book.language(for: Array("git")) == .english)
        #expect(book.language(for: Array("to")) == .korean)
        #expect(book.language(for: Array("kubectl")) == .english)
        #expect(book.language(for: Array("rm")) == nil)
    }

    @Test func skipsCommentsBlankAndInvalidLines() {
        let book = Wordbook(text: "# git\n\ngit status\n새a\n  \n")
        #expect(book == .empty)
    }

    @Test func englishIgnoresCaseExceptShiftedJamoKeys() {
        let book = Wordbook(text: "git\nPR\n")
        #expect(book.language(for: Array("Git")) == .english)
        #expect(book.language(for: Array("GIT")) == nil)       // T 는 Shift 로 ㅆ 이 되는 키라 구분한다(대문자 시작이라 어차피 영어로 판별됨)
        #expect(book.language(for: Array("PR")) == .english)
        #expect(book.language(for: Array("pr")) == nil)
    }

    @Test func manualBeatsLearnedAndLaterLineWins() {
        let book = Wordbook(text: "to\n새\n\(Wordbook.learnedMarker)\nto\nrk\n")
        #expect(book.language(for: Array("to")) == .korean)   // 직접 적은 '새' 가 나중 줄이라 이긴다
        #expect(book.language(for: Array("rk")) == .english)  // 배운 단어
        #expect(book.manualLanguage(for: Array("rk")) == nil)
        #expect(book.learnedLanguage(for: Array("rk")) == .english)
    }

    @Test func replacingLearnedKeepsManualPartAsIs() {
        let text = "# 메모\ngit\n\n\(Wordbook.learnedMarker)\nold\n"
        #expect(Wordbook.replacingLearned(in: text, with: ["rk", "새"])
            == "# 메모\ngit\n\n\(Wordbook.learnedMarker)\nrk\n새\n")
        #expect(Wordbook.replacingLearned(in: "git", with: ["rk"]) == "git\n\n\(Wordbook.learnedMarker)\nrk\n")
        #expect(Wordbook.learnedLines(in: text) == ["old"])
    }
}

@Suite struct FlipLearnerTests {
    private let rk = Array("rk")

    @Test func learnsAfterTwoFlipsTheSameWay() {
        var learner = FlipLearner()
        #expect(learner.record(Flip(keys: rk, language: .english), wordbook: .empty) == nil)
        #expect(learner.record(Flip(keys: rk, language: .english), wordbook: .empty) == .learn(keys: rk, language: .english))
    }

    @Test func mixedDirectionsStartOver() {
        var learner = FlipLearner()
        _ = learner.record(Flip(keys: rk, language: .english), wordbook: .empty)
        #expect(learner.record(Flip(keys: rk, language: .korean), wordbook: .empty) == nil)
        #expect(learner.record(Flip(keys: rk, language: .english), wordbook: .empty) == nil)
    }

    @Test func flippingALearnedWordBackForgetsIt() {
        var learner = FlipLearner()
        let book = Wordbook(text: "\(Wordbook.learnedMarker)\nrk\n")
        #expect(learner.record(Flip(keys: rk, language: .korean), wordbook: book) == .forget(keys: rk))
    }

    @Test func neverTouchesManualWords() {
        var learner = FlipLearner()
        let book = Wordbook(text: "rk\n")
        #expect(learner.record(Flip(keys: rk, language: .korean), wordbook: book) == nil)
        #expect(learner.record(Flip(keys: rk, language: .korean), wordbook: book) == nil)
    }
}

@Suite struct WordbookSessionTests {
    private func session(_ text: String, typing keys: String) -> InputSession {
        let s = InputSession()
        s.wordbook = Wordbook(text: text)
        keys.forEach { s.type($0) }
        return s
    }

    @Test func previewSwitchesTheMomentKeysMatch() {
        let s = session("git\n", typing: "gi")
        #expect(s.display == "햐")
        s.type("t")
        #expect(s.display == "git")
        s.type("s")
        #expect(s.display == "햣ㄴ")   // 더 치면 단어장 단어가 아니다
    }

    @Test func wordbookDecidesAtWordEnd() {
        #expect(session("git\n", typing: "git").endWord() == "git")
        #expect(session("새\n", typing: "to").endWord() == "새")
        #expect(session("ㄱㅅㄱㅅ\n", typing: "rtrt").endWord() == "ㄱㅅㄱㅅ")   // 도중엔 영어였어도 단어장이 이긴다
    }

    @Test func wordbookBeatsPreviousWordContext() {
        let s = session("새\n", typing: "want")
        _ = s.endWord()
        "to".forEach { s.type($0) }
        #expect(s.endWord() == "새")
    }

    @Test func escStillFlipsAndIsReportedAsFlip() {
        let s = session("git\n", typing: "git")
        #expect(s.flip())
        #expect(s.display == "햣")
        #expect(s.endWord() == "햣")
        #expect(s.takeFlip() == Flip(keys: Array("git"), language: .korean))
        #expect(s.takeFlip() == nil)
    }

    @Test func flippingTwiceBackToTheJudgementIsNotAFlip() {
        let s = session("", typing: "rk")
        _ = s.flip()
        _ = s.flip()
        #expect(s.endWord() == "가")
        #expect(s.takeFlip() == nil)
    }
}

@Suite struct WordbookStoreTests {
    private func store() -> WordbookStore {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("nunchi-test-\(UUID().uuidString)")
        return WordbookStore(url: dir.appendingPathComponent("words.txt"), checkInterval: 0)
    }

    private func contents(_ store: WordbookStore) -> String {
        (try? String(contentsOf: store.url, encoding: .utf8)) ?? ""
    }

    @Test func createsTemplateWithLearnedMarker() throws {
        let s = store()
        try s.ensureFileExists()
        #expect(contents(s) == WordbookStore.template)
        #expect(s.reloadIfChanged())
        #expect(s.wordbook == .empty)
    }

    @Test func picksUpEditsToTheFile() throws {
        let s = store()
        try s.ensureFileExists()
        s.reloadIfChanged()
        try (contents(s) + "\n").replacingOccurrences(of: "\n\n\(Wordbook.learnedMarker)", with: "\nkubectl\n\n\(Wordbook.learnedMarker)")
            .write(to: s.url, atomically: true, encoding: .utf8)
        // 같은 초에 다시 쓰면 수정 시각이 안 바뀔 수 있어 시각을 직접 옮긴다.
        try FileManager.default.setAttributes([.modificationDate: Date().addingTimeInterval(5)], ofItemAtPath: s.url.path)
        #expect(s.reloadIfChanged())
        #expect(s.wordbook.language(for: Array("kubectl")) == .english)
    }

    @Test func learnsAndForgetsUnderTheMarker() throws {
        let s = store()
        try s.apply(.learn(keys: Array("rk"), language: .english))
        try s.apply(.learn(keys: Array("to"), language: .korean))
        #expect(Wordbook.learnedLines(in: contents(s)) == ["rk", "새"])
        #expect(s.wordbook.language(for: Array("to")) == .korean)
        try s.apply(.forget(keys: Array("rk")))
        #expect(Wordbook.learnedLines(in: contents(s)) == ["새"])
        #expect(s.wordbook.language(for: Array("rk")) == nil)
        #expect(contents(s).hasPrefix(WordbookStore.template))
    }

    @Test func clearLearnedKeepsManualAndBacksUp() throws {
        let s = store()
        try s.ensureFileExists()
        let manual = WordbookStore.template.replacingOccurrences(of: "\n\n\(Wordbook.learnedMarker)", with: "\ngit\n\n\(Wordbook.learnedMarker)")
        try manual.write(to: s.url, atomically: true, encoding: .utf8)
        try s.apply(.learn(keys: Array("rk"), language: .english))
        try s.clearLearned()
        #expect(contents(s) == manual)
        #expect(Wordbook.learnedLines(in: (try? String(contentsOf: s.backupURL, encoding: .utf8)) ?? "") == ["rk"])
        #expect(s.wordbook.language(for: Array("git")) == .english)
    }
}
