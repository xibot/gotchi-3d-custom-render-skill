import AppKit
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

guard CommandLine.arguments.count == 4 else {
    fail("Usage: swift add-bg-color.swift <input.png> <output.png> <hex_color>")
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]
let hexColor = CommandLine.arguments[3]

func parseHexColor(_ value: String) -> NSColor? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
    guard trimmed.count == 6, let rgb = Int(trimmed, radix: 16) else { return nil }
    let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
    let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(rgb & 0xFF) / 255.0
    return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
}

guard let image = NSImage(contentsOfFile: inputPath) else {
    fail("Could not open input PNG: \(inputPath)")
}

guard let color = parseHexColor(hexColor) else {
    fail("Invalid hex color: \(hexColor)")
}

var proposedRect = NSRect(origin: .zero, size: image.size)
guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
    fail("Could not decode image: \(inputPath)")
}

let width = cgImage.width
let height = cgImage.height
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fail("Could not create CGContext")
}

context.setFillColor(color.cgColor)
context.fill(CGRect(x: 0, y: 0, width: width, height: height))
context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

guard let composited = context.makeImage() else {
    fail("Could not create composited image")
}

let bitmap = NSBitmapImageRep(cgImage: composited)
guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fail("Could not encode PNG")
}

do {
    try pngData.write(to: URL(fileURLWithPath: outputPath))
} catch {
    fail("Could not write output PNG: \(error.localizedDescription)")
}
