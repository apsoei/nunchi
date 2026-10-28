import Carbon
import Cocoa
import NunchiCore
import InputMethodKit

/// 입력창(앱)마다 컨트롤러가 따로 생기므로, 단어장과 배우기 횟수는 프로세스에 하나만 둔다.
enum Shared {
    static let store = WordbookStore(url: FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Nunchi/words.txt"))
    static var learner = FlipLearner()

    private static let learnKey = "learnFromEsc"
    /// 뒤집어서(Esc·오른쪽 ⌘) 배우기. 기본은 켬.
    static var learnFromEsc: Bool {
        get { UserDefaults.standard.object(forKey: learnKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: learnKey) }
    }
}

/// InputMethodKit 이벤트를 `KeyRouter` 에 넘기고, 돌려받은 할 일을 입력창에 적용만 한다.
/// 판단 로직은 전부 NunchiCore 에 있다.
@objc(NunchiInputController)
final class InputController: IMKInputController {
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
            // 입력기에 오는 이벤트에는 오른쪽 ⌘ 전용 비트(NX_DEVICERCMDKEYMASK)가 지워져 있다.
            // 키코드로 오른쪽 ⌘ 인지 보고, ⌘ 표시로 누름·뗌을 가른다.
            let rightDown = flags.contains(.command)
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
        Shared.store.reloadIfChanged()
        router.wordbook = Shared.store.wordbook
        let result = router.handle(keyEvent, context: context)
        apply(result.effects, to: sender)
        learn()
        return !result.passThrough
    }

    private func learn() {
        guard let flip = router.takeFlip(), Shared.learnFromEsc,
              let change = Shared.learner.record(flip, wordbook: Shared.store.wordbook) else { return }
        do {
            try Shared.store.apply(change)
        } catch {
            NSLog("Nunchi: 단어장에 쓰지 못했습니다: \(error)")
        }
    }

    // MARK: - 입력 메뉴

    override func menu() -> NSMenu! {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "단어장 열기", action: #selector(openWordbook(_:)), keyEquivalent: ""))
        let learnItem = NSMenuItem(title: "뒤집어서 배우기", action: #selector(toggleLearning(_:)), keyEquivalent: "")
        learnItem.state = Shared.learnFromEsc ? .on : .off
        menu.addItem(learnItem)
        menu.addItem(NSMenuItem(title: "배운 단어 지우기", action: #selector(clearLearned(_:)), keyEquivalent: ""))
        return menu
    }

    @objc func openWordbook(_ sender: Any!) {
        do {
            try Shared.store.ensureFileExists()
            NSWorkspace.shared.open(Shared.store.url)
        } catch {
            NSLog("Nunchi: 단어장을 만들지 못했습니다: \(error)")
        }
    }

    @objc func toggleLearning(_ sender: Any!) {
        Shared.learnFromEsc.toggle()
        if !Shared.learnFromEsc { Shared.learner.reset() }
    }

    /// 배운 단어만 지운다. 지우기 전 내용은 words.txt.bak 에 남는다.
    @objc func clearLearned(_ sender: Any!) {
        do {
            try Shared.store.clearLearned()
            Shared.learner.reset()
        } catch {
            NSLog("Nunchi: 배운 단어를 지우지 못했습니다: \(error)")
        }
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
