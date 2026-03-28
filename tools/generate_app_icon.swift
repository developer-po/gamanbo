import AppKit

struct IconTheme {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let noseMain: NSColor
    let noseHighlight: NSColor
    let nostril: NSColor
}

let outputDirectory = URL(
    fileURLWithPath: "/Users/aikawa.yuki/Developer/Gamanbo/Gamanbo/Assets.xcassets/AppIcon.appiconset",
    isDirectory: true
)

let theme = IconTheme(
    backgroundTop: NSColor(calibratedRed: 0.99, green: 0.99, blue: 0.98, alpha: 1),
    backgroundBottom: NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.94, alpha: 1),
    noseMain: NSColor(calibratedRed: 0.98, green: 0.75, blue: 0.80, alpha: 1),
    noseHighlight: NSColor(calibratedRed: 0.995, green: 0.87, blue: 0.90, alpha: 1),
    nostril: NSColor(calibratedRed: 0.66, green: 0.35, blue: 0.45, alpha: 1)
)

let canvasSize = CGSize(width: 1024, height: 1024)

func fillBackground(rect: CGRect, theme: IconTheme) {
    let path = NSBezierPath(roundedRect: rect, xRadius: 230, yRadius: 230)
    path.addClip()

    let gradient = NSGradient(colors: [theme.backgroundTop, theme.backgroundBottom])!
    gradient.draw(in: path, angle: -90)
}

func drawNose(theme: IconTheme) {
    let noseRect = CGRect(x: 214, y: 300, width: 596, height: 420)
    let nosePath = NSBezierPath(roundedRect: noseRect, xRadius: 190, yRadius: 190)
    let noseGradient = NSGradient(colors: [theme.noseHighlight, theme.noseMain])!
    noseGradient.draw(in: nosePath, angle: -90)

    theme.noseHighlight.withAlphaComponent(0.5).setStroke()
    nosePath.lineWidth = 3
    nosePath.stroke()

    theme.noseHighlight.withAlphaComponent(0.92).setFill()
    let topOval = NSBezierPath(ovalIn: CGRect(x: 320, y: 540, width: 384, height: 74))
    topOval.fill()
}

func drawNostrils(theme: IconTheme) {
    theme.nostril.setFill()

    let left = NSBezierPath(roundedRect: CGRect(x: 352, y: 418, width: 108, height: 152), xRadius: 50, yRadius: 50)
    let right = NSBezierPath(roundedRect: CGRect(x: 564, y: 418, width: 108, height: 152), xRadius: 50, yRadius: 50)
    left.fill()
    right.fill()
}

func pngData(theme: IconTheme) -> Data? {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(canvasSize.width),
            pixelsHigh: Int(canvasSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
    else {
        return nil
    }

    bitmap.size = canvasSize

    NSGraphicsContext.saveGraphicsState()
    if let context = NSGraphicsContext(bitmapImageRep: bitmap) {
        NSGraphicsContext.current = context
        let rect = CGRect(origin: .zero, size: canvasSize)
        fillBackground(rect: rect, theme: theme)
        drawNose(theme: theme)
        drawNostrils(theme: theme)
        context.flushGraphics()
    }
    NSGraphicsContext.restoreGraphicsState()

    return bitmap.representation(using: .png, properties: [:])
}

func normalizeTo1024(at fileURL: URL) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = [
        "-z", "1024", "1024",
        fileURL.path,
        "--out", fileURL.path
    ]
    try process.run()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        throw NSError(domain: "generate_app_icon", code: Int(process.terminationStatus))
    }
}

let fileManager = FileManager.default
let fileURL = outputDirectory.appendingPathComponent("AppIcon.png")

guard let data = pngData(theme: theme) else {
    fatalError("Failed to encode AppIcon.png")
}

try? fileManager.removeItem(at: fileURL)
try data.write(to: fileURL)
try normalizeTo1024(at: fileURL)
print("Wrote \(fileURL.path)")
