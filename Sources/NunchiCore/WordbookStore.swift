import Foundation

/// 단어장 파일을 읽고(바뀌었을 때만), 배운 단어를 써 넣는다. 파일은 사용자가 편집기로 직접 고칠 수 있다.
public final class WordbookStore {
    public static let template = """
    # 눈치 단어장
    # 한 줄에 하나씩, 나오길 원하는 모양 그대로 적습니다.
    #   영어로 적으면 영어로:  git
    #   한글로 적으면 한글로:  새        (to 를 치면 앞 단어와 상관없이 '새')
    # 여기 적은 단어는 자동 판별보다 먼저 적용되고, 그래도 Esc 로 언제든 뒤집을 수 있습니다.
    # 가끔은 한글, 가끔은 영어로 쓰는 단어는 적지 마세요(자동 판별에 맡기는 게 낫습니다).
    # '#' 뒤는 메모로 무시합니다. 저장하면 다음에 칠 때부터 반영됩니다.


    """ + Wordbook.learnedMarker + "\n"

    public let url: URL
    public private(set) var wordbook: Wordbook = .empty
    private var loadedModified: Date?
    private var lastCheck: Date?
    private let checkInterval: TimeInterval

    public init(url: URL, checkInterval: TimeInterval = 1) {
        self.url = url
        self.checkInterval = checkInterval
    }

    public var backupURL: URL { url.appendingPathExtension("bak") }

    public func ensureFileExists() throws {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try write(Self.template)
    }

    /// 파일이 바뀌었으면 다시 읽는다. 키마다 불려도 되도록 `checkInterval` 안에는 다시 보지 않는다.
    @discardableResult
    public func reloadIfChanged(now: Date = Date()) -> Bool {
        if let lastCheck, now.timeIntervalSince(lastCheck) < checkInterval { return false }
        lastCheck = now
        let modified = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
        guard modified != loadedModified else { return false }
        loadedModified = modified
        wordbook = Wordbook(text: (try? String(contentsOf: url, encoding: .utf8)) ?? "")
        return true
    }

    public func apply(_ change: FlipLearner.Change) throws {
        try ensureFileExists()
        let text = try String(contentsOf: url, encoding: .utf8)
        var lines = Wordbook.learnedLines(in: text)
        switch change {
        case .learn(let keys, let language):
            let target = Wordbook.lookupKey(keys)
            lines.removeAll { Wordbook.entry(fromLine: $0)?.0 == target }
            lines.append(language == .english ? String(keys) : HangulComposer.compose(keys).text)
        case .forget(let keys):
            let target = Wordbook.lookupKey(keys)
            lines.removeAll { Wordbook.entry(fromLine: $0)?.0 == target }
        }
        try save(Wordbook.replacingLearned(in: text, with: lines))
    }

    /// 배운 단어만 지운다. 지우기 전 파일 전체를 `backupURL` 에 남긴다.
    public func clearLearned() throws {
        try ensureFileExists()
        let text = try String(contentsOf: url, encoding: .utf8)
        try? FileManager.default.removeItem(at: backupURL)
        try text.write(to: backupURL, atomically: true, encoding: .utf8)
        try save(Wordbook.replacingLearned(in: text, with: []))
    }

    private func save(_ text: String) throws {
        try write(text)
        lastCheck = nil
        reloadIfChanged()
    }

    private func write(_ text: String) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }
}
