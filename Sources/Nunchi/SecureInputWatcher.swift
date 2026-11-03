import AppKit
import Carbon
import IOKit
import NunchiCore

/// 보안 입력 잠금이 풀리면 눈치로 되돌린다(판단은 `SecureInputRestorer`). 잠금이 계속되면 잠금을 건 앱과
/// 푸는 방법을 화면에 띄운다(`SecureInputNotice`). 입력기 프로세스는 다른 입력 소스를 쓰는 동안에도 떠 있으므로
/// 여기서 1초마다 확인한다. 권한은 필요 없다.
final class SecureInputWatcher {
    static let shared = SecureInputWatcher()

    private static let modeID = "io.github.apsoei.inputmethod.Nunchi.Korean"
    /// 화면 잠금·시스템 암호 창. 사용자가 할 일이 없으므로 안내하지 않는다.
    private static let systemHolders: Set<String> = ["com.apple.loginwindow", "com.apple.SecurityAgent"]
    private var timer: Timer?
    private var restorer = SecureInputRestorer()
    private var notice = SecureInputNotice()
    private let toast = SecureInputToast()

    func start() {
        guard timer == nil else { return }
        toast.onDismiss = { [weak self] in self?.notice.dismiss() }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func tick() {
        let holder = Self.secureInputHolder()
        if restorer.tick(secure: holder != nil, oursSelected: Self.oursSelected()) { selectOurs() }

        let app = holder.flatMap { NSRunningApplication(processIdentifier: $0) }
        let byUser = !Self.systemHolders.contains(app?.bundleIdentifier ?? "")
        switch notice.tick(pushedOut: restorer.pushedOut && byUser) {
        case .show:
            let frontmost = app != nil && NSWorkspace.shared.frontmostApplication?.processIdentifier == holder
            toast.show(SecureInputNotice.message(appName: app?.localizedName, frontmost: frontmost))
        case .hide:
            toast.hide()
        case .none:
            break
        }
    }

    private func selectOurs() {
        let filter = [kTISPropertyInputSourceID as String: Self.modeID] as CFDictionary
        if let ours = (TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource])?.first {
            TISSelectInputSource(ours)
        }
    }

    private static func oursSelected() -> Bool {
        let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        guard let raw = TISGetInputSourceProperty(current, kTISPropertyInputSourceID) else { return false }
        return (Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String) == modeID
    }

    /// 보안 입력을 켜 둔 프로세스 번호. 없으면 nil. (`ioreg -l | grep kCGSSessionSecureInputPID` 와 같은 값)
    static func secureInputHolder() -> pid_t? {
        // 레지스트리 맨 위(Root). IORegistryEntryFromPath("IOService:/") 는 맥 기종 항목을 돌려줘서 여기 값이 없다.
        let root = IORegistryGetRootEntry(kIOMainPortDefault)
        defer { IOObjectRelease(root) }
        guard let users = IORegistryEntryCreateCFProperty(root, "IOConsoleUsers" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? [[String: Any]] else { return nil }
        return users.lazy.compactMap { $0["kCGSSessionSecureInputPID"] as? Int }.first.map { pid_t($0) }
    }
}
