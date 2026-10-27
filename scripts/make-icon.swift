// 아이콘 두 가지를 만든다. 로고는 ㄴ 이 한 획으로 영문 n 과 이어지는 모양(docs/logo.svg 와 같은 그림).
// - icon.tiff: 메뉴 막대용 템플릿 아이콘(검은 선, 투명 배경, 16·32px)
// - AppIcon.icns: Finder·설치 화면용 컬러 아이콘(잉크 바탕, ㄴ 흰색, n 파랑)
// 실행: swift scripts/make-icon.swift Resources
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])

/// 로고 획. 좌표는 SVG 와 같은 128 단위, y 가 아래로 커진다.
func letterPaths() -> (nieun: NSBezierPath, n: NSBezierPath) {
    let nieun = NSBezierPath()
    nieun.move(to: NSPoint(x: 28, y: 30))
    nieun.line(to: NSPoint(x: 28, y: 92))
    nieun.line(to: NSPoint(x: 66, y: 92))
    let n = NSBezierPath()
    n.move(to: NSPoint(x: 66, y: 92))
    n.line(to: NSPoint(x: 66, y: 62))
    n.curve(to: NSPoint(x: 82, y: 48), controlPoint1: NSPoint(x: 66, y: 52.67), controlPoint2: NSPoint(x: 71.33, y: 48))
    n.curve(to: NSPoint(x: 98, y: 62), controlPoint1: NSPoint(x: 92.67, y: 48), controlPoint2: NSPoint(x: 98, y: 52.67))
    n.line(to: NSPoint(x: 98, y: 92))
    for path in [nieun, n] {
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
    }
    return (nieun, n)
}

/// 128 단위 그림을 `rect` 에 맞춰 그리도록 좌표를 옮긴다(위아래 뒤집기 포함).
func withDesignSpace(in rect: NSRect, _ draw: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let t = NSAffineTransform()
    t.translateX(by: rect.minX, yBy: rect.maxY)
    t.scaleX(by: rect.width / 128, yBy: -rect.height / 128)
    t.concat()
    draw()
    NSGraphicsContext.restoreGraphicsState()
}

func bitmap(pixels: Int, points: CGFloat, _ draw: () -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: points, height: points)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

func color(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

// 메뉴 막대 아이콘: 16pt 안에 획만. 작은 크기에서 읽히도록 여백을 줄이고 선을 굵게 한다.
func templateRep(pixels: Int) -> NSBitmapImageRep {
    bitmap(pixels: pixels, points: 16) {
        withDesignSpace(in: NSRect(x: -2.5, y: -3.1, width: 21.3, height: 21.3)) {
            let (nieun, n) = letterPaths()
            NSColor.black.setStroke()
            for path in [nieun, n] {
                path.lineWidth = 10.5
                path.stroke()
            }
        }
    }
}

let template = NSImage(size: NSSize(width: 16, height: 16))
template.addRepresentation(templateRep(pixels: 16))
template.addRepresentation(templateRep(pixels: 32))
try template.tiffRepresentation!.write(to: outDir.appendingPathComponent("icon.tiff"))

// 앱 아이콘: macOS 아이콘 격자(1024 중 가운데 824)에 둥근 사각형.
func appIconRep(pixels: Int) -> NSBitmapImageRep {
    bitmap(pixels: pixels, points: CGFloat(pixels)) {
        let s = CGFloat(pixels)
        let tile = NSRect(x: s * 100 / 1024, y: s * 100 / 1024, width: s * 824 / 1024, height: s * 824 / 1024)
        color(0x111827).setFill()
        NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225).fill()
        withDesignSpace(in: tile) {
            let (nieun, n) = letterPaths()
            nieun.lineWidth = 13
            n.lineWidth = 13
            NSColor.white.setStroke()
            nieun.stroke()
            color(0x4D8DFF).setStroke()
            n.stroke()
        }
    }
}

let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let png = appIconRep(pixels: base * scale).representation(using: .png, properties: [:])!
        try png.write(to: iconset.appendingPathComponent(name))
    }
}
let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", outDir.appendingPathComponent("AppIcon.icns").path]
try iconutil.run()
iconutil.waitUntilExit()
exit(iconutil.terminationStatus)
