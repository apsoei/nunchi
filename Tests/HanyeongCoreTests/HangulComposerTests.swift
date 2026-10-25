import Testing
@testable import HanyeongCore

@Suite struct HangulComposerTests {
    private func text(_ keys: String) -> String {
        HangulComposer.compose(Array(keys)).text
    }

    @Test func basicSyllables() {
        #expect(text("rk") == "가")
        #expect(text("gksrmf") == "한글")
        #expect(text("dkssudgktpdy") == "안녕하세요")
    }

    @Test func finalConsonantMovesToNextSyllable() {
        #expect(text("dkssud") == "안녕")
        #expect(text("rkqt") == "값")
        #expect(text("rkqtdl") == "값이")
        #expect(text("dkswdk") == "앉아")
        #expect(text("ekfrdmf") == "닭을")
    }

    @Test func compoundVowels() {
        #expect(text("rhk") == "과")
        #expect(text("dnjs") == "원")
        #expect(text("dml") == "의")
        #expect(text("dho") == "왜")
    }

    @Test func shiftedDoubleConsonantsAndVowels() {
        #expect(text("Tk") == "싸")
        #expect(text("Rk") == "까")
        #expect(text("dO") == "얘")
        #expect(text("goTdj") == "했어")
    }

    @Test func uppercaseNonDoubleLettersFallBackToPlainJamo() {
        #expect(text("Gk") == "하")
    }

    @Test func doubleConsonantCannotBeFinal() {
        // ㄸ 은 받침이 될 수 없어 다음 음절 초성으로 간다.
        #expect(text("rkE") == "가ㄸ")
    }

    @Test func orphanFlags() {
        let lone = HangulComposer.compose(Array("o"))
        #expect(lone.text == "ㅐ")
        #expect(lone.hasOrphan)

        let committed = HangulComposer.compose(Array("ts"))
        #expect(committed.text == "ㅅㄴ")
        #expect(committed.hasOrphan)

        let trailing = HangulComposer.compose(Array("rkr"))
        #expect(trailing.text == "각")
        #expect(!trailing.hasOrphan)

        let trailingLone = HangulComposer.compose(Array("rkE"))
        #expect(!trailingLone.hasOrphan)
        #expect(trailingLone.hasTrailingOrphan)

        let clean = HangulComposer.compose(Array("dkssud"))
        #expect(!clean.hasOrphan)
        #expect(!clean.hasTrailingOrphan)
    }

    @Test func emptyInput() {
        #expect(text("") == "")
    }
}
