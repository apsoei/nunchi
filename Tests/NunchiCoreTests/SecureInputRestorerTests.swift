import Testing
@testable import NunchiCore

@Suite struct SecureInputRestorerTests {
    /// (보안 입력 잠금, 지금 눈치인지) 순서대로 넣고 각 시점의 '되돌리기' 결과를 돌려준다.
    private func run(_ steps: [(secure: Bool, ours: Bool)]) -> [Bool] {
        var restorer = SecureInputRestorer()
        return steps.map { restorer.tick(secure: $0.secure, oursSelected: $0.ours) }
    }

    @Test func restoresOnlyWhenPushedOutByTheLock() {
        let results = run([
            (false, true),    // 눈치를 쓰는 중
            (true, false),    // 비밀번호 칸: macOS 가 다른 입력 소스로 바꿈
            (true, false),
            (false, false),   // 잠금이 풀림 → 되돌린다
            (false, false),   // 한 번만
        ])
        #expect(results == [false, false, false, true, false])
    }

    @Test func leavesOtherInputSourcesAlone() {
        let results = run([(false, false), (true, false), (false, false)])   // ABC 를 쓰던 중
        #expect(results == [false, false, false])
    }

    @Test func noRestoreIfAlreadyBack() {
        let results = run([(false, true), (true, false), (false, true)])     // 이미 눈치로 돌아와 있음
        #expect(results == [false, false, false])
    }
}
