/// 앱 종류별 동작 차이. 터미널·IDE 에서는 Esc 가 중요한 키라 뒤집기에 쓰지 않는다.
public enum AppProfile {
    static let terminalLikeIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.mitchellh.ghostty",
        "com.cmuxterm.app",                // cmux (Ghostty 기반)
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

    public static func isTerminalLike(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        return terminalLikeIDs.contains(bundleID) || terminalLikePrefixes.contains { bundleID.hasPrefix($0) }
    }
}
