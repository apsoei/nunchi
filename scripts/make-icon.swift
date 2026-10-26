// 메뉴 막대용 템플릿 아이콘(검은 글자, 투명 배경)을 만든다. 실행: swift scripts/make-icon.swift Resources/icon.tiff
import AppKit

func rep(size: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: 16, height: 16)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let text = NSAttributedString(string: "한A", attributes: [
        .font: NSFont.systemFont(ofSize: 9.5, weight: .bold),
        .foregroundColor: NSColor.black,
    ])
    let bounds = text.size()
    text.draw(at: NSPoint(x: (16 - bounds.width) / 2, y: (16 - bounds.height) / 2))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let image = NSImage(size: NSSize(width: 16, height: 16))
image.addRepresentation(rep(size: 16))
image.addRepresentation(rep(size: 32))
try! image.tiffRepresentation!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
