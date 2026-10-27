// 설치한 입력기를 시스템에 등록하고 입력 소스 목록에 켠다(선택은 하지 않는다).
// 실행: swift scripts/register.swift "$HOME/Library/Input Methods/Nunchi.app"
//       swift scripts/register.swift --disable <번들 ID>   (그 번들의 입력 소스를 목록에서 뺀다)
import Carbon
import Foundation

func sources(bundleID: String) -> [TISInputSource] {
    let filter = [kTISPropertyBundleID as String: bundleID] as CFDictionary
    return (TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource]) ?? []
}

func sourceID(_ source: TISInputSource) -> String {
    Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(source, kTISPropertyInputSourceID)).takeUnretainedValue() as String
}

let args = CommandLine.arguments
if args.count == 3, args[1] == "--disable" {
    for source in sources(bundleID: args[2]) {
        print("\(sourceID(source)): disable=\(TISDisableInputSource(source))")
    }
    exit(0)
}

let path = args[1]
let status = TISRegisterInputSource(URL(fileURLWithPath: path) as CFURL)
print("TISRegisterInputSource: \(status)")

let bundleID = Bundle(path: path)?.bundleIdentifier ?? "io.github.apsoei.inputmethod.Nunchi"
let found = sources(bundleID: bundleID)
for source in found {
    print("\(sourceID(source)): enable=\(TISEnableInputSource(source))")
}
if found.isEmpty {
    print("입력 소스를 찾지 못했습니다. 로그아웃 후 다시 로그인한 뒤 시스템 설정 > 키보드 > 입력 소스에서 추가하세요.")
    exit(1)
}
