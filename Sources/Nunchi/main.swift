import Cocoa
import InputMethodKit

// 입력기 프로세스는 IMKServer 하나를 띄워 두고 시스템이 붙여 주는 클라이언트(입력창)를 처리한다.
let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String
    ?? "io.github.apsoei.inputmethod.Nunchi_Connection"

guard let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier) else {
    fatalError("IMKServer 를 만들지 못했습니다: \(connectionName)")
}
withExtendedLifetime(server) {
    NSApplication.shared.run()
}
