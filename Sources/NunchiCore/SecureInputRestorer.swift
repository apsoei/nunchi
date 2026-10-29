/// 비밀번호 칸 등에서 macOS 가 보안 입력을 켜면 외부 입력기(눈치)를 잠그고 다른 입력 소스로 바꾼다.
/// 잠금이 풀린 뒤에도 그 입력 소스로 남아 있어서, 잠금 때문에 밀려났던 경우에만 눈치로 되돌리게 판단한다.
/// 사용자가 원래 다른 입력 소스를 쓰고 있었으면 건드리지 않는다.
public struct SecureInputRestorer {
    private var wasSecure = false
    private var oursBeforeLock = false
    private var pending = false

    public init() {}

    /// 1초마다 부른다. 지금 눈치로 되돌려야 하면 true.
    public mutating func tick(secure: Bool, oursSelected: Bool) -> Bool {
        defer { wasSecure = secure }
        switch (wasSecure, secure) {
        case (false, false):
            oursBeforeLock = oursSelected
            return false
        case (false, true):
            pending = oursBeforeLock
            return false
        case (true, true):
            return false
        case (true, false):
            defer { pending = false }
            return pending && !oursSelected
        }
    }
}
