/// 앱 종류별 동작 차이. 터미널·IDE 에서는 Esc 가 중요한 키라 뒤집기에 쓰지 않는다.
public enum AppProfile {
    static let terminalLikeIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty",
        "io.alacritty",
        "com.github.wez.wezterm",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",   // Cursor
        "dev.zed.Zed",
        "com.sublimetext.4",
        "org.vim.MacVim",
        "com.apple.dt.Xcode",
    ]

    static let terminalLikePrefixes = ["com.jetbrains.", "com.google.android.studio"]

    /// 입력기가 보낸 글자를 키 입력처럼 프로그램에 넘기는 터미널. 확정한 단어를 지우기 문자(DEL)로 지우고 다시 칠 수 있다.
    /// 편집기(VSCode 등)는 넣지 않는다 — 지우기 문자가 글자로 들어가 버린다.
    static let terminalEmulatorIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.mitchellh.ghostty",
        "com.cmuxterm.app",
        "net.kovidgoyal.kitty",
        "io.alacritty",
        "com.github.wez.wezterm",
    ]

    public static func isTerminalEmulator(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return terminalEmulatorIDs.contains(bundleID)
    }

    public static func isTerminalLike(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return terminalLikeIDs.contains(bundleID) || terminalLikePrefixes.contains { bundleID.hasPrefix($0) }
    }
}
