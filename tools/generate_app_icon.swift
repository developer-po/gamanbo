import AppKit

struct IconTheme {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let trophyColor: NSColor
    let coinColor: NSColor
    let ringColor: NSColor
    let sparkleColor: NSColor
}

let outputDirectory = URL(fileURLWithPath: "/Users/aikawa.yuki/Developer/Gamanbo/Gamanbo/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

let theme = IconTheme(
    backgroundTop: NSColor(calibratedRed: 0.98, green: 0.89, blue: 0.64, alpha: 1),
    backgroundBottom: NSColor(calibratedRed: 0.95, green: 0.57, blue: 0.29, alpha: 1),
    trophyColor: NSColor.white,
    coinColor: NSColor(calibratedRed: 0.13, green: 0.43, blue: 0.29, alpha: 1),
    ringColor: NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.22),
    sparkleColor: NSColor(calibratedRed: 1, green: 0.98, blue: 0.84, alpha: 1)
)

let canvasSize = CGSize(width: 1024, height: 1024)

func drawBackground(in rect: CGRect, theme: IconTheme) {
    let roundedPath = NSBezierPath(roundedRect: rect, xRadius: 220, yRadius: 220)
    roundedPath.addClip()

    let gradient = NSGradient(starting: theme.backgroundTop, ending: theme.backgroundBottom)
    gradient?.draw(in: roundedPath, angle: -60)

    theme.ringColor.setStroke()
    let ringPath = NSBezierPath()
    ringPath.lineWidth = 30
    ringPath.appendArc(
        withCenter: CGPoint(x: 512, y: 548),
        radius: 312,
        startAngle: 205,
        endAngle: 342,
        clockwise: false
    )
    ringPath.stroke()
}

func drawTrophy(in rect: CGRect, theme: IconTheme) {
    theme.trophyColor.setFill()

    let cup = NSBezierPath(roundedRect: CGRect(x: 332, y: 396, width: 360, height: 270), xRadius: 84, yRadius: 84)
    cup.fill()

    let baseStem = NSBezierPath(roundedRect: CGRect(x: 462, y: 286, width: 100, height: 146), xRadius: 40, yRadius: 40)
    baseStem.fill()

    let base = NSBezierPath(roundedRect: CGRect(x: 356, y: 214, width: 312, height: 76), xRadius: 38, yRadius: 38)
    base.fill()

    let leftHandle = NSBezierPath()
    leftHandle.lineWidth = 40
    leftHandle.lineCapStyle = .round
    leftHandle.appendArc(
        withCenter: CGPoint(x: 310, y: 526),
        radius: 96,
        startAngle: 82,
        endAngle: 274,
        clockwise: true
    )
    leftHandle.stroke()

    let rightHandle = NSBezierPath()
    rightHandle.lineWidth = 40
    rightHandle.lineCapStyle = .round
    rightHandle.appendArc(
        withCenter: CGPoint(x: 714, y: 526),
        radius: 96,
        startAngle: 98,
        endAngle: 266,
        clockwise: false
    )
    rightHandle.stroke()
}

func drawCoin(theme: IconTheme) {
    let coinRect = CGRect(x: 622, y: 198, width: 210, height: 210)
    let coin = NSBezierPath(ovalIn: coinRect)
    theme.coinColor.setFill()
    coin.fill()

    let formatter = NSMutableParagraphStyle()
    formatter.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 124, weight: .bold),
        .foregroundColor: NSColor.white,
        .paragraphStyle: formatter
    ]

    let symbol = NSAttributedString(string: "¥", attributes: attributes)
    symbol.draw(in: CGRect(x: 622, y: 226, width: 210, height: 124))
}

func drawSparkles(theme: IconTheme) {
    theme.sparkleColor.setFill()

    let positions: [(CGFloat, CGFloat, CGFloat)] = [
        (266, 772, 42),
        (728, 760, 28),
        (232, 330, 20)
    ]

    for (x, y, radius) in positions {
        let sparkle = NSBezierPath()
        sparkle.move(to: CGPoint(x: x, y: y + radius))
        sparkle.line(to: CGPoint(x: x + radius * 0.35, y: y + radius * 0.35))
        sparkle.line(to: CGPoint(x: x + radius, y: y))
        sparkle.line(to: CGPoint(x: x + radius * 0.35, y: y - radius * 0.35))
        sparkle.line(to: CGPoint(x: x, y: y - radius))
        sparkle.line(to: CGPoint(x: x - radius * 0.35, y: y - radius * 0.35))
        sparkle.line(to: CGPoint(x: x - radius, y: y))
        sparkle.line(to: CGPoint(x: x - radius * 0.35, y: y + radius * 0.35))
        sparkle.close()
        sparkle.fill()
    }
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
        drawBackground(in: rect, theme: theme)
        drawTrophy(in: rect, theme: theme)
        drawCoin(theme: theme)
        drawSparkles(theme: theme)
        context.flushGraphics()
    }
    NSGraphicsContext.restoreGraphicsState()

    return bitmap.representation(using: .png, properties: [:])
}

let fileManager = FileManager.default

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

let extraFiles = [
    outputDirectory.appendingPathComponent("AppIcon-dark.png"),
    outputDirectory.appendingPathComponent("AppIcon-tinted.png")
]

for fileURL in extraFiles {
    try? fileManager.removeItem(at: fileURL)
}

guard let data = pngData(theme: theme) else {
    fatalError("Failed to encode AppIcon.png")
}

let fileURL = outputDirectory.appendingPathComponent("AppIcon.png")
try? fileManager.removeItem(at: fileURL)
try data.write(to: fileURL)
try normalizeTo1024(at: fileURL)
print("Wrote \(fileURL.path)")
