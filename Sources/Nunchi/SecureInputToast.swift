import AppKit

/// 화면 위쪽 가운데에 뜨는 작은 안내. 포커스를 가져가지 않고, 누르면 닫힌다. 알림 권한이 필요 없다.
final class SecureInputToast {
    var onDismiss: (() -> Void)?
    private var panel: NSPanel?

    func show(_ text: String) {
        hide()
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .white
        let icon = NSImageView(image: NSImage(systemSymbolName: "lock.fill", accessibilityDescription: nil) ?? NSImage())
        icon.contentTintColor = .systemOrange
        let row = NSStackView(views: [icon, label])
        row.spacing = 8
        row.edgeInsets = NSEdgeInsets(top: 9, left: 16, bottom: 9, right: 18)
        let size = row.fittingSize

        let background = ClickView(frame: NSRect(origin: .zero, size: size))
        background.material = .hudWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = size.height / 2
        background.onClick = { [weak self] in
            self?.hide()
            self?.onDismiss?()
        }
        row.frame = background.bounds
        background.addSubview(row)

        let panel = NSPanel(contentRect: frame(for: size), styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.contentView = background
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.animator().alphaValue = 1
        self.panel = panel
    }

    func hide() {
        panel?.orderOut(nil)
        panel = nil
    }

    /// 마우스가 있는 화면의 메뉴 막대 바로 아래 가운데.
    private func frame(for size: NSSize) -> NSRect {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        let area = screen?.visibleFrame ?? .zero
        return NSRect(x: area.midX - size.width / 2, y: area.maxY - size.height - 12,
                      width: size.width, height: size.height)
    }

    private final class ClickView: NSVisualEffectView {
        var onClick: (() -> Void)?
        override func mouseDown(with event: NSEvent) { onClick?() }
    }
}
