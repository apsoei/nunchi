import Carbon
import Cocoa
import NunchiCore
import InputMethodKit

/// InputMethodKit 이벤트를 `KeyRouter` 에 넘기고, 돌려받은 할 일을 입력창에 적용만 한다.
/// 판단 로직은 전부 NunchiCore 에 있다.
@objc(NunchiInputController)
final class InputController: IMKInputController {
    /// NX_DEVICERCMDKEYMASK: modifierFlags 의 장치별 비트 중 오른쪽 ⌘.
    private static let rightCommandMask: UInt = 0x10

    private let router = KeyRouter()
    private var tapDetector = RightCommandTapDetector()
    private var terminalLike = false

    override func recognizedEvents(_ sender: Any!) -> Int {
        Int(NSEvent.EventTypeMask([.keyDown, .flagsChanged]).rawValue)
    }

    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        terminalLike = AppProfile.isTerminalLike(bundleID: (sender as? IMKTextInput)?.bundleIdentifier())
        router.activate(terminalLike: terminalLike)
    }

    override func deactivateServer(_ sender: Any!) {
        apply(router.commitAsDisplayed(), to: sender)
        super.deactivateServer(sender)
    }

    /// 마우스 클릭·포커스 이동 등으로 시스템이 확정을 요청할 때.
    override func commitComposition(_ sender: Any!) {
        apply(router.commitAsDisplayed(), to: sender)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event else { return false }
        let flags = event.modifierFlags
        let keyEvent: KeyEvent

        switch event.type {
        case .flagsChanged:
            let rightDown = flags.rawValue & Self.rightCommandMask != 0
            guard tapDetector.flagsChanged(keyCode: event.keyCode, rightCommandDown: rightDown, time: event.timestamp) else {
                return false
            }
            keyEvent = .rightCommandTap
        case .keyDown:
            tapDetector.keyDown()
            keyEvent = KeyCodeMap.event(keyCode: event.keyCode, shift: flags.contains(.shift))
        default:
            return false
        }

        let context = KeyContext(
            secureInput: IsSecureEventInputEnabled(),
            terminalLike: terminalLike,
            capsLock: flags.contains(.capsLock),
            modifierHeld: event.type == .keyDown && !flags.intersection([.command, .control, .option]).isEmpty
        )
        let result = router.handle(keyEvent, context: context)
        apply(result.effects, to: sender)
        return !result.passThrough
    }

    private func apply(_ effects: [Effect], to sender: Any!) {
        guard !effects.isEmpty, let client = sender as? IMKTextInput else { return }
        let notFound = NSRange(location: NSNotFound, length: 0)
        for effect in effects {
            switch effect {
            case .insert(let text):
                client.insertText(text, replacementRange: notFound)
            case .setMarked(let text):
                client.setMarkedText(text, selectionRange: NSRange(location: text.utf16.count, length: 0), replacementRange: notFound)
            case .clearMarked:
                client.setMarkedText("", selectionRange: NSRange(location: 0, length: 0), replacementRange: notFound)
            }
        }
    }
}
