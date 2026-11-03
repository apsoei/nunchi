import Testing
@testable import NunchiCore

@Suite struct SecureInputNoticeTests {
    /// 1초마다 '눈치가 잠금에 밀려나 있는지'를 넣고 각 시점의 동작을 돌려준다.
    private func run(_ steps: [Bool], dismissAt: Int? = nil) -> [SecureInputNotice.Action] {
        var notice = SecureInputNotice()
        return steps.enumerated().map { index, pushedOut in
            if index == dismissAt { notice.dismiss() }
            return notice.tick(pushedOut: pushedOut)
        }
    }

    @Test func showsAfterDelayAndHidesWhenReleased() {
        let results = run([true, true, true, true, false, false])
        #expect(results == [.none, .none, .show, .none, .hide, .none])
    }

    @Test func shortLockShowsNothing() {   // 비밀번호를 금방 치고 나가면 안내 없음
        #expect(run([true, true, false, false]) == [.none, .none, .none, .none])
    }

    @Test func dismissedStaysHiddenUntilNextLock() {
        let results = run([true, true, true, true, true, false, true, true, true], dismissAt: 3)
        #expect(results == [.none, .none, .show, .none, .none, .none, .none, .none, .show])
    }

    @Test func messageNamesTheHolder() {
        #expect(SecureInputNotice.message(appName: "Google Chrome", frontmost: true)
            == "Google Chrome 비밀번호 잠금 중 · 입력이 끝났다면 다른 입력칸을 한 번 클릭하세요")
        #expect(SecureInputNotice.message(appName: "Arc", frontmost: false)
            == "뒤에 있는 Arc 의 비밀번호 잠금 · Arc 에서 아무 입력칸이나 한 번 클릭하세요")
        #expect(SecureInputNotice.message(appName: nil, frontmost: false)
            == "다른 앱의 비밀번호 잠금 · 잠금을 건 앱에서 입력칸을 한 번 클릭하세요")
    }
}

@Suite struct SecureInputRestorerPushedOutTests {
    @Test func pushedOutOnlyWhileLockedAfterUsingNunchi() {
        var restorer = SecureInputRestorer()
        var states: [Bool] = []
        for (secure, ours) in [(false, true), (true, false), (true, false), (false, false)] {
            _ = restorer.tick(secure: secure, oursSelected: ours)
            states.append(restorer.pushedOut)
        }
        #expect(states == [false, true, true, false])
    }

    @Test func notPushedOutWhenUsingAnotherSource() {
        var restorer = SecureInputRestorer()
        _ = restorer.tick(secure: false, oursSelected: false)
        _ = restorer.tick(secure: true, oursSelected: false)
        #expect(restorer.pushedOut == false)
    }
}
