import Carbon
import Foundation

/// 이 앱 번들을 입력 소스로 등록·해제한다. 설치하는 맥에 Swift 가 없어도 되도록 앱 안에 둔다.
enum InputSourceRegistration {
    static func run(_ command: String) -> Int32 {
        switch command {
        case "--register": return register()
        case "--unregister": return unregister()
        default:
            print("사용법: Nunchi --register | --unregister")
            return 2
        }
    }

    private static var bundleID: String { Bundle.main.bundleIdentifier ?? "io.github.apsoei.inputmethod.Nunchi" }

    private static func sources() -> [TISInputSource] {
        let filter = [kTISPropertyBundleID as String: bundleID] as CFDictionary
        return (TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource]) ?? []
    }

    private static func id(_ source: TISInputSource) -> String {
        Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(source, kTISPropertyInputSourceID)).takeUnretainedValue() as String
    }

    private static func register() -> Int32 {
        let status = TISRegisterInputSource(Bundle.main.bundleURL as CFURL)
        print("등록: \(status)")
        let found = sources()
        for source in found {
            print("\(id(source)): 켜기 \(TISEnableInputSource(source))")
        }
        if found.isEmpty {
            print("입력 소스를 찾지 못했습니다. 로그아웃 후 다시 로그인한 뒤 시스템 설정 > 키보드 > 입력 소스에서 '눈치'를 추가하세요.")
        }
        return status == noErr ? 0 : 1
    }

    private static func unregister() -> Int32 {
        for source in sources() {
            print("\(id(source)): 끄기 \(TISDisableInputSource(source))")
        }
        return 0
    }
}
