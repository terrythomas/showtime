// Draws Resources/AppIcon.icns: a gradient tile with a bold clock face.
// Usage: swift scripts/make-icon.swift <output.icns>
import AppKit

func draw(size: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size), bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = size / 1024

    // Tile with the standard macOS icon margin.
    let tile = NSRect(x: 100 * s, y: 100 * s, width: 824 * s, height: 824 * s)
    let path = NSBezierPath(roundedRect: tile, xRadius: 185 * s, yRadius: 185 * s)
    NSGradient(colors: [NSColor(srgbRed: 1.0, green: 0.36, blue: 0.27, alpha: 1),
                        NSColor(srgbRed: 0.85, green: 0.13, blue: 0.42, alpha: 1)])!.draw(in: path, angle: -60)

    // Bells, drawn first so the face can cut a gap into them.
    let center = NSPoint(x: 512 * s, y: 480 * s)
    let radius = 262 * s
    NSColor.white.setFill()
    for angle in [40.0, 140.0] {
        let a = angle * .pi / 180
        let c = NSPoint(x: center.x + cos(a) * (radius + 40 * s), y: center.y + sin(a) * (radius + 40 * s))
        NSBezierPath(ovalIn: NSRect(x: c.x - 82 * s, y: c.y - 82 * s, width: 164 * s, height: 164 * s)).fill()
    }
    let gap = 26 * s
    NSColor(srgbRed: 0.93, green: 0.25, blue: 0.34, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - radius - gap, y: center.y - radius - gap,
                                width: (radius + gap) * 2, height: (radius + gap) * 2)).fill()

    // Clock face.
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)).fill()

    // Hands and centre pin.
    let ink = NSColor(srgbRed: 0.85, green: 0.13, blue: 0.42, alpha: 1)
    ink.setStroke()
    let hands = NSBezierPath()
    hands.lineWidth = 46 * s
    hands.lineCapStyle = .round
    hands.move(to: NSPoint(x: center.x, y: center.y + 175 * s))
    hands.line(to: center)
    hands.line(to: NSPoint(x: center.x + 120 * s, y: center.y - 70 * s))
    hands.lineJoinStyle = .round
    hands.stroke()
    ink.setFill()
    NSBezierPath(ovalIn: NSRect(x: center.x - 34 * s, y: center.y - 34 * s, width: 68 * s, height: 68 * s)).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("Showtime-\(UUID().uuidString).iconset")
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(base)x\(base).png" : "icon_\(base)x\(base)@2x.png"
        let png = draw(size: CGFloat(base * scale)).representation(using: .png, properties: [:])!
        try png.write(to: iconset.appendingPathComponent(name))
    }
}
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try task.run()
task.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
exit(task.terminationStatus)
