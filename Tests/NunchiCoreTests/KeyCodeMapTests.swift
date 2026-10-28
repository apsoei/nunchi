import Testing
@testable import NunchiCore

@Suite struct KeyCodeMapTests {
    @Test func lettersFollowQwertyRegardlessOfLayout() {
        #expect(KeyCodeMap.event(keyCode: 0x00, shift: false) == .letter("a"))
        #expect(KeyCodeMap.event(keyCode: 0x11, shift: false) == .letter("t"))
        #expect(KeyCodeMap.event(keyCode: 0x11, shift: true) == .letter("T"))
        #expect(KeyCodeMap.event(keyCode: 0x2E, shift: false) == .letter("m"))
    }

    @Test func specialKeys() {
        #expect(KeyCodeMap.event(keyCode: 0x33, shift: false) == .backspace)
        #expect(KeyCodeMap.event(keyCode: 0x35, shift: false) == .escape)
        #expect(KeyCodeMap.event(keyCode: 0x31, shift: false) == .space)
        #expect(KeyCodeMap.event(keyCode: 0x24, shift: false) == .other)   // Return
        #expect(KeyCodeMap.event(keyCode: 0x12, shift: true) == .other)    // !
    }
}

@Suite struct RightCommandTapDetectorTests {
    @Test func quickTapAloneCounts() {
        var d = RightCommandTapDetector()
        let pressed = d.flagsChanged(keyCode: 54, rightCommandDown: true, time: 1.0)
        #expect(!pressed)
        let released = d.flagsChanged(keyCode: 54, rightCommandDown: false, time: 1.2)
        #expect(released)
    }

    @Test func longHoldDoesNotCount() {
        var d = RightCommandTapDetector()
        _ = d.flagsChanged(keyCode: 54, rightCommandDown: true, time: 1.0)
        let tapped = d.flagsChanged(keyCode: 54, rightCommandDown: false, time: 1.6)
        #expect(!tapped)
    }

    @Test func shortcutDoesNotCount() {
        var d = RightCommandTapDetector()
        _ = d.flagsChanged(keyCode: 54, rightCommandDown: true, time: 1.0)
        d.keyDown()   // ⌘C
        let tapped = d.flagsChanged(keyCode: 54, rightCommandDown: false, time: 1.1)
        #expect(!tapped)
    }

    @Test func otherModifierDuringHoldDoesNotCount() {
        var d = RightCommandTapDetector()
        _ = d.flagsChanged(keyCode: 54, rightCommandDown: true, time: 1.0)
        _ = d.flagsChanged(keyCode: 56, rightCommandDown: true, time: 1.05)   // Shift
        let tapped = d.flagsChanged(keyCode: 54, rightCommandDown: false, time: 1.1)
        #expect(!tapped)
    }

    @Test func leftCommandIsIgnored() {
        var d = RightCommandTapDetector()
        let first = d.flagsChanged(keyCode: 55, rightCommandDown: false, time: 1.0)
        #expect(!first)
        let second = d.flagsChanged(keyCode: 55, rightCommandDown: false, time: 1.1)
        #expect(!second)
    }
}
