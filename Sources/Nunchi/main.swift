import Cocoa
import InputMethodKit

// 설치 도구(brew 등)가 부르는 명령. 입력기로 뜰 때는 인자가 없다.
//   Nunchi --register    이 앱을 입력 소스로 등록하고 목록에 켠다
//   Nunchi --unregister  입력 소스 목록에서 뺀다(삭제 전에)
if let command = CommandLine.arguments.dropFirst().first {
    exit(InputSourceRegistration.run(command))
}

// 입력기 프로세스는 IMKServer 하나를 띄워 두고 시스템이 붙여 주는 클라이언트(입력창)를 처리한다.
let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String
    ?? "io.github.apsoei.inputmethod.Nunchi_Connection"

guard let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier) else {
    fatalError("IMKServer 를 만들지 못했습니다: \(connectionName)")
}
// 비밀번호 입력 등으로 macOS 가 눈치를 잠갔다 풀면 눈치로 되돌린다.
SecureInputWatcher.shared.start()
withExtendedLifetime(server) {
    NSApplication.shared.run()
}
