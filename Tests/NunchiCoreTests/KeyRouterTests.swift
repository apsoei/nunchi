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

    @Test func modifierCombosAndCapsLockCommitThenPass() {
        let r = router(typing: "git")
        #expect(r.handle(.letter("c"), context: KeyContext(modifierHeld: true)) == RouterResult(effects: [.insert("git")], passThrough: true))
        let r2 = router(typing: "rk")
        #expect(r2.handle(.letter("a"), context: KeyContext(capsLock: true)) == RouterResult(effects: [.insert("가")], passThrough: true))
    }

    @Test func terminalAssumesEnglishForAmbiguousWords() {
        let r = router(typing: "rm", context: terminal)
        #expect(r.handle(.other, context: terminal) == RouterResult(effects: [.insert("rm")], passThrough: true))
        let n = router(typing: "rm")
        #expect(n.handle(.other, context: normal) == RouterResult(effects: [.insert("그")], passThrough: true))
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
        #expect(!AppProfile.isTerminalLike(bundleID: "com.tinyspeck.slackmacgap"))
        #expect(!AppProfile.isTerminalLike(bundleID: nil))
    }
}
