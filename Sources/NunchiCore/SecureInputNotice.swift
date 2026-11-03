/// 눈치가 보안 입력 잠금에 밀려난 채 몇 초가 지나면 안내를 띄우고, 잠금이 풀리면 내린다.
/// 비밀번호를 금방 치고 나가는 보통의 경우에는 띄우지 않는다. 사용자가 닫으면 다음 잠금 때까지 다시 띄우지 않는다.
public struct SecureInputNotice {
    public enum Action: Equatable { case none, show, hide }

    /// 잠긴 채 이만큼(초) 지나면 띄운다.
    public static let delay = 3

    private var lockedTicks = 0
    private var shown = false
    private var dismissed = false

    public init() {}

    /// 1초마다 부른다. `pushedOut`: 눈치를 쓰다가 잠금에 밀려나 아직 잠겨 있는지.
    public mutating func tick(pushedOut: Bool) -> Action {
        guard pushedOut else {
            lockedTicks = 0
            dismissed = false
            defer { shown = false }
            return shown ? .hide : .none
        }
        lockedTicks += 1
        guard !shown, !dismissed, lockedTicks >= Self.delay else { return .none }
        shown = true
        return .show
    }

    /// 사용자가 안내를 닫았다.
    public mutating func dismiss() {
        shown = false
        dismissed = true
    }

    /// 안내 문구. 잠금을 건 앱이 앞에 있으면(로그인 직후 비밀번호 칸이 사라진 경우 등) 그 앱 안에서 다른 칸을 누르게 하고,
    /// 뒤에 있으면 그 앱으로 가게 한다. 앱 이름 뒤 조사는 받침에 따라 달라져서 띄어 쓴다.
    public static func message(appName: String?, frontmost: Bool) -> String {
        guard let appName else { return "다른 앱의 비밀번호 잠금 · 잠금을 건 앱에서 입력칸을 한 번 클릭하세요" }
        return frontmost
            ? "\(appName) 비밀번호 잠금 중 · 입력이 끝났다면 다른 입력칸을 한 번 클릭하세요"
            : "뒤에 있는 \(appName) 의 비밀번호 잠금 · \(appName) 에서 아무 입력칸이나 한 번 클릭하세요"
    }
}
