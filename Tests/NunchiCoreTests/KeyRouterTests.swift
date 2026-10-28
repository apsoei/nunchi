import Testing
@testable import NunchiCore

@Suite struct KeyRouterTests {
    private let normal = KeyContext()
    private let terminal = KeyContext(terminalLike: true)

    private func router(typing keys: String, context: KeyContext = KeyContext()) -> KeyRouter {
        let r = KeyRouter()
        r.activate(terminalLike: context.terminalLike)
        keys.forEach { _ = r.handle(.letter($0), context: context) }
        return r
    }

    @Test func lettersUpdateMarkedText() {
        let r = KeyRouter()
        #expect(r.handle(.letter("r"), context: normal) == RouterResult(effects: [.setMarked("ㄱ")], passThrough: false))
        #expect(r.handle(.letter("k"), context: normal) == RouterResult(effects: [.setMarked("가")], passThrough: false))
    }

    @Test func boundaryCommitsJudgedWordAndPassesKey() {
        let r = router(typing: "git")
        #expect(r.handle(.other, context: normal) == RouterResult(effects: [.insert("git")], passThrough: true))
    }

    @Test func boundaryWithNothingTypedJustPasses() {
        #expect(KeyRouter().handle(.other, context: normal) == RouterResult(effects: [], passThrough: true))
    }

    @Test func backspaceEditsMarkedTextThenFallsThrough() {
        let r = router(typing: "rk")
        #expect(r.handle(.backspace, context: normal) == RouterResult(effects: [.setMarked("ㄱ")], passThrough: false))
        #expect(r.handle(.backspace, context: normal) == RouterResult(effects: [.clearMarked], passThrough: false))
        #expect(r.handle(.backspace, context: normal) == RouterResult(effects: [], passThrough: true))
    }

    @Test func escapeFlipsOnlyWhenSomethingIsTyped() {
        let r = router(typing: "rk")
        #expect(r.handle(.escape, context: normal) == RouterResult(effects: [.setMarked("rk")], passThrough: false))
        #expect(r.handle(.other, context: normal) == RouterResult(effects: [.insert("rk")], passThrough: true))
        #expect(r.handle(.escape, context: normal) == RouterResult(effects: [], passThrough: true))
    }

    @Test func escapeInTerminalCommitsAsShownAndPasses() {
        let r = router(typing: "dkssud", context: terminal)
        #expect(r.handle(.escape, context: terminal) == RouterResult(effects: [.insert("안녕")], passThrough: true))
    }

    @Test func rightCommandFlipsEverywhere() {
        let r = router(typing: "rk", context: terminal)
        #expect(r.handle(.rightCommandTap, context: terminal) == RouterResult(effects: [.setMarked("rk")], passThrough: false))
        #expect(KeyRouter().handle(.rightCommandTap, context: normal) == RouterResult(effects: [], passThrough: true))
    }

    @Test func secureInputCommitsLeftoverAndNeverComposes() {
        let r = router(typing: "rk")
        let secure = KeyContext(secureInput: true)
        #expect(r.handle(.letter("t"), context: secure) == RouterResult(effects: [.insert("가")], passThrough: true))
        #expect(r.handle(.letter("t"), context: secure) == RouterResult(effects: [], passThrough: true))
        #expect(r.handle(.backspace, context: secure) == RouterResult(effects: [], passThrough: true))
        #expect(r.handle(.escape, context: secure) == RouterResult(effects: [], passThrough: true))
    }

    @Test func modifierCombosCommitThenPass() {
        let r = router(typing: "git")
        #expect(r.handle(.letter("c"), context: KeyContext(modifierHeld: true)) == RouterResult(effects: [.insert("git")], passThrough: true))
    }

    @Test func capsLockStillComposes() {
        let r = KeyRouter()
        let caps = KeyContext(capsLock: true)
        #expect(r.handle(.letter("r"), context: caps) == RouterResult(effects: [.setMarked("ㄱ")], passThrough: false))
        #expect(r.handle(.letter("k"), context: caps) == RouterResult(effects: [.setMarked("가")], passThrough: false))
        #expect(r.handle(.other, context: caps) == RouterResult(effects: [.insert("가")], passThrough: true))
    }

    @Test func terminalAssumesEnglishForAmbiguousWords() {
        let r = router(typing: "rm", context: terminal)
        #expect(r.handle(.other, context: terminal) == RouterResult(effects: [.insert("rm")], passThrough: true))
        let n = router(typing: "rm")
        #expect(n.handle(.other, context: normal) == RouterResult(effects: [.insert("그")], passThrough: true))
    }

    @Test func spaceEndsWordLikeOtherKeys() {
        let r = router(typing: "git")
        #expect(r.handle(.space, context: normal) == RouterResult(effects: [.insert("git")], passThrough: true))
    }

    @Test func rightCommandRightAfterSpaceRewritesTheLastWord() {
        let r = router(typing: "rk")
        _ = r.handle(.space, context: normal)
        #expect(r.handle(.rightCommandTap, context: normal)
            == RouterResult(effects: [.replaceLast(old: "가 ", new: "rk ")], passThrough: false))
        r.retroFlipApplied()
        // 한 번 더 누르면 원래대로
        #expect(r.handle(.rightCommandTap, context: normal)
            == RouterResult(effects: [.replaceLast(old: "rk ", new: "가 ")], passThrough: false))
    }

    @Test func anyOtherKeyCancelsTheRewrite() {
        let r = router(typing: "rk")
        _ = r.handle(.space, context: normal)
        _ = r.handle(.backspace, context: normal)   // 공백을 지웠다
        #expect(r.handle(.rightCommandTap, context: normal) == RouterResult(effects: [], passThrough: true))
    }

    @Test func rewriteOnlyAfterSpaceAndNotInTerminal() {
        let r = router(typing: "rk")
        _ = r.handle(.other, context: normal)        // Return·문장부호로 끝냄
        #expect(r.handle(.rightCommandTap, context: normal) == RouterResult(effects: [], passThrough: true))
        let t = router(typing: "rk", context: terminal)
        _ = t.handle(.space, context: terminal)
        #expect(t.handle(.rightCommandTap, context: terminal) == RouterResult(effects: [], passThrough: true))
    }

    @Test func terminalEmulatorRetypesWithDeletes() {
        // 터미널은 앞 글자를 바꿔 쓸 수 없어서, 지우기 문자를 보낸 뒤 다시 친다.
        let console = KeyContext(terminalEmulator: true)
        let r = router(typing: "rk", context: console)
        _ = r.handle(.space, context: console)
        #expect(r.handle(.rightCommandTap, context: console)
            == RouterResult(effects: [.retypeLast(deleteCount: 2, text: "rk ")], passThrough: false))
        r.retroFlipApplied()
        #expect(r.handle(.rightCommandTap, context: console)
            == RouterResult(effects: [.retypeLast(deleteCount: 3, text: "가 ")], passThrough: false))
    }

    @Test func failedRewriteIsForgotten() {
        let r = router(typing: "rk")
        _ = r.handle(.space, context: normal)
        _ = r.handle(.rightCommandTap, context: normal)
        r.retroFlipFailed()
        #expect(r.handle(.rightCommandTap, context: normal) == RouterResult(effects: [], passThrough: true))
        #expect(r.takeFlip() == nil)
    }

    @Test func rewriteIsReportedForLearning() {
        let r = router(typing: "rk")
        _ = r.handle(.space, context: normal)
        _ = r.handle(.rightCommandTap, context: normal)
        r.retroFlipApplied()
        #expect(r.takeFlip() == Flip(keys: Array("rk"), language: .english))
        _ = r.handle(.rightCommandTap, context: normal)
        r.retroFlipApplied()
        #expect(r.takeFlip() == nil)   // 자동 판별대로 되돌린 것은 배울 거리가 아니다
    }

    @Test func rewriteKeepsCapsLockCase() {
        let r = KeyRouter()
        let caps = KeyContext(capsLock: true)
        "api".forEach { _ = r.handle(.letter($0), context: caps) }
        #expect(r.handle(.space, context: caps) == RouterResult(effects: [.insert("API")], passThrough: true))
        #expect(r.handle(.rightCommandTap, context: caps)
            == RouterResult(effects: [.replaceLast(old: "API ", new: "메ㅑ ")], passThrough: false))
    }

    @Test func focusLossCommitsAsShown() {
        let r = router(typing: "git")
        #expect(r.commitAsDisplayed() == [.insert("햣")])
        #expect(r.commitAsDisplayed() == [])
    }
}

@Suite struct AppProfileTests {
    @Test func terminalsAndEditors() {
        #expect(AppProfile.isTerminalLike(bundleID: "com.apple.Terminal"))
        #expect(AppProfile.isTerminalLike(bundleID: "com.googlecode.iterm2"))
        #expect(AppProfile.isTerminalLike(bundleID: "com.jetbrains.intellij"))
        #expect(AppProfile.isTerminalLike(bundleID: "com.microsoft.VSCode"))
        #expect(AppProfile.isTerminalEmulator(bundleID: "com.cmuxterm.app"))
        #expect(AppProfile.isTerminalEmulator(bundleID: "com.apple.Terminal"))
        #expect(!AppProfile.isTerminalEmulator(bundleID: "com.microsoft.VSCode"))   // 편집기에 지우기 문자를 넣으면 안 된다
        #expect(!AppProfile.isTerminalLike(bundleID: "com.cmuxterm.app"))          // cmux 는 Esc 뒤집기를 쓴다
        #expect(!AppProfile.isTerminalLike(bundleID: "com.tinyspeck.slackmacgap"))
        #expect(!AppProfile.isTerminalLike(bundleID: nil))
    }
}
