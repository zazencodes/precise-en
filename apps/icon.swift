// Renders the app icon into Assets.xcassets/AppIcon.appiconset: `swift apps/icon.swift`.
// "P//" for PRECISE//EN in Inter Black: a white P and purple slashes on the ZazenCodes near-black.
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let folder = URL(filePath: #filePath).deletingLastPathComponent().appending(path: "Assets.xcassets/AppIcon.appiconset")

func color(_ hex: Int) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

/// The iPhone icon fills the square (iOS rounds it); the Mac icon sits on the macOS icon grid.
func render(pixels: Int, mac: Bool, to name: String) {
    let size = CGFloat(pixels)
    let context = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!,
        bitmapInfo: (mac ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue
    )!
    let tile = mac ? CGRect(x: size * 100 / 1024, y: size * 100 / 1024, width: size * 824 / 1024, height: size * 824 / 1024)
        : CGRect(x: 0, y: 0, width: size, height: size)
    let shape = mac ? CGPath(roundedRect: tile, cornerWidth: tile.width * 0.225, cornerHeight: tile.width * 0.225, transform: nil)
        : CGPath(rect: tile, transform: nil)
    context.addPath(shape)
    context.clip()
    let gradient = CGGradient(colorsSpace: nil, colors: [color(0x1A232E), color(0x0B0F14)] as CFArray, locations: [0, 1])!
    context.drawLinearGradient(gradient, start: CGPoint(x: tile.midX, y: tile.maxY), end: CGPoint(x: tile.midX, y: tile.minY), options: [])

    let font = CTFontCreateWithName("Inter-Regular_Black" as CFString, tile.width * 0.36, nil)
    precondition(CTFontCopyPostScriptName(font) as String == "Inter-Regular_Black", "install Inter (the brand font) to render the icon")
    let text = NSMutableAttributedString(string: "P//", attributes: [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): color(0xFFFFFF),
        NSAttributedString.Key(kCTKernAttributeName as String): -tile.width * 0.01,
    ])
    text.addAttribute(NSAttributedString.Key(kCTForegroundColorAttributeName as String), value: color(0x7C3AED), range: NSRange(location: 1, length: 2))
    let line = CTLineCreateWithAttributedString(text)
    let bounds = CTLineGetImageBounds(line, context)
    context.textPosition = CGPoint(x: tile.midX - bounds.midX, y: tile.midY - bounds.midY)
    CTLineDraw(line, context)

    let destination = CGImageDestinationCreateWithURL(folder.appending(path: name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination), "writing \(name)")
}

var images: [[String: String]] = []
render(pixels: 1024, mac: false, to: "ios-1024.png")
images.append(["filename": "ios-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"])
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "mac-\(points)@\(scale)x.png"
        render(pixels: points * scale, mac: true, to: name)
        images.append(["filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)"])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: folder.appending(path: "Contents.json"))
print("Rendered \(images.count) icons into \(folder.path)")
