// 설치한 입력기를 시스템에 등록하고 입력 소스 목록에 켠다(선택은 하지 않는다).
// 실행: swift scripts/register.swift "$HOME/Library/Input Methods/HanyeongAuto.app"
import Carbon
import Foundation

let path = CommandLine.arguments[1]
let status = TISRegisterInputSource(URL(fileURLWithPath: path) as CFURL)
print("TISRegisterInputSource: \(status)")

let filter = [kTISPropertyBundleID as String: "io.github.apsoei.inputmethod.HanyeongAuto"] as CFDictionary
let sources = (TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource]) ?? []
for source in sources {
    let id = Unmanaged<CFString>.fromOpaque(TISGetInputSourceProperty(source, kTISPropertyInputSourceID)).takeUnretainedValue()
    let enableStatus = TISEnableInputSource(source)
    print("\(id): enable=\(enableStatus)")
}
if sources.isEmpty {
    print("입력 소스를 찾지 못했습니다. 로그아웃 후 다시 로그인한 뒤 시스템 설정 > 키보드 > 입력 소스에서 추가하세요.")
    exit(1)
}
