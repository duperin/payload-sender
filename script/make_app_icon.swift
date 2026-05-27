import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 4 else {
    fputs("usage: make_app_icon.swift <source.png> <iconset-dir> <icns-output>\n", stderr)
    exit(2)
}

let sourceURL = URL(fileURLWithPath: arguments[1])
let iconsetURL = URL(fileURLWithPath: arguments[2])
let icnsURL = URL(fileURLWithPath: arguments[3])

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("Could not read source image: \(sourceURL.path)\n", stderr)
    exit(1)
}

let fileManager = FileManager.default
if fileManager.fileExists(atPath: iconsetURL.path) {
    try fileManager.removeItem(at: iconsetURL)
}
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
if fileManager.fileExists(atPath: icnsURL.path) {
    try fileManager.removeItem(at: icnsURL)
}

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for size in sizes {
    let image = NSImage(size: NSSize(width: size.pixels, height: size.pixels))
    image.lockFocus()
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: size.pixels, height: size.pixels).fill()

    let sourceSize = sourceImage.size
    let scale = min(CGFloat(size.pixels) / sourceSize.width, CGFloat(size.pixels) / sourceSize.height)
    let drawSize = NSSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
    let drawOrigin = NSPoint(
        x: (CGFloat(size.pixels) - drawSize.width) / 2,
        y: (CGFloat(size.pixels) - drawSize.height) / 2
    )

    sourceImage.draw(
        in: NSRect(origin: drawOrigin, size: drawSize),
        from: NSRect(origin: .zero, size: sourceSize),
        operation: .copy,
        fraction: 1
    )
    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fputs("Could not render \(size.name)\n", stderr)
        exit(1)
    }

    try png.write(to: iconsetURL.appendingPathComponent(size.name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()

guard process.terminationStatus == 0 else {
    fputs("iconutil failed with status \(process.terminationStatus)\n", stderr)
    exit(Int32(process.terminationStatus))
}
