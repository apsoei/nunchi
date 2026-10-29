import Carbon
import Foundation
import IOKit
import NunchiCore

/// 보안 입력 잠금이 풀리면 눈치로 되돌린다(판단은 `SecureInputRestorer`). 입력기 프로세스는 다른 입력 소스를
/// 쓰는 동안에도 떠 있으므로 여기서 1초마다 확인한다. 권한은 필요 없다.
final class SecureInputWatcher {
    static let shared = SecureInputWatcher()

    private static let modeID = "io.github.apsoei.inputmethod.Nunchi.Korean"
    private var timer: Timer?
    private var restorer = SecureInputRestorer()

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard restorer.tick(secure: Self.secureInputHolder() != nil, oursSelected: Self.oursSelected()) else { return }
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
        let root = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/")
        defer { IOObjectRelease(root) }
        guard let users = IORegistryEntryCreateCFProperty(root, "IOConsoleUsers" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? [[String: Any]] else { return nil }
        return users.lazy.compactMap { $0["kCGSSessionSecureInputPID"] as? Int }.first.map { pid_t($0) }
    }
}
