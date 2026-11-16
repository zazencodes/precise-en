// Canonical icon artwork. Render every iOS and Mac size: swift apps/icon.swift
// Custom outlines keep the lettering reproducible without installed fonts.
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let folder = URL(filePath: #filePath).deletingLastPathComponent()
  .appending(path: "Assets.xcassets/AppIcon.appiconset")
func color(_ hex: Int) -> CGColor {
  CGColor(
    srgbRed: CGFloat(hex >> 16 & 255) / 255,
    green: CGFloat(hex >> 8 & 255) / 255,
    blue: CGFloat(hex & 255) / 255, alpha: 1)
}

// The e has an open aperture and optical overshoot; slash weight matches the stems.
func mark(_ c: CGContext) {
  c.setFillColor(color(0xF6F6F6))
  let p = CGMutablePath()
  for x in [CGFloat(150), 254] {
    p.move(to: CGPoint(x: x, y: 678))
    p.addLine(to: CGPoint(x: x + 57, y: 678))
    p.addLine(to: CGPoint(x: x + 148, y: 346))
    p.addLine(to: CGPoint(x: x + 91, y: 346))
    p.closeSubpath()
  }
  // Coordinates use a top-left drawing space.
  p.move(to: CGPoint(x: 611, y: 533))
  p.addCurve(
    to: CGPoint(x: 501, y: 411), control1: CGPoint(x: 611, y: 454),
    control2: CGPoint(x: 573, y: 411))
  p.addCurve(
    to: CGPoint(x: 387, y: 535), control1: CGPoint(x: 430, y: 411),
    control2: CGPoint(x: 387, y: 462))
  p.addCurve(
    to: CGPoint(x: 508, y: 660), control1: CGPoint(x: 387, y: 615),
    control2: CGPoint(x: 431, y: 660))
  p.addCurve(
    to: CGPoint(x: 605, y: 620), control1: CGPoint(x: 551, y: 660),
    control2: CGPoint(x: 586, y: 645))
  p.addLine(to: CGPoint(x: 574, y: 584))
  p.addCurve(
    to: CGPoint(x: 510, y: 610), control1: CGPoint(x: 555, y: 603),
    control2: CGPoint(x: 535, y: 610))
  p.addCurve(
    to: CGPoint(x: 446, y: 555), control1: CGPoint(x: 472, y: 610),
    control2: CGPoint(x: 450, y: 591))
  p.addLine(to: CGPoint(x: 611, y: 555))
  p.closeSubpath()
  p.move(to: CGPoint(x: 446, y: 511))
  p.addCurve(
    to: CGPoint(x: 501, y: 460), control1: CGPoint(x: 451, y: 478),
    control2: CGPoint(x: 469, y: 460))
  p.addCurve(
    to: CGPoint(x: 554, y: 511), control1: CGPoint(x: 533, y: 460),
    control2: CGPoint(x: 551, y: 478))
  p.closeSubpath()
  p.move(to: CGPoint(x: 645, y: 654))
  p.addLine(to: CGPoint(x: 645, y: 417))
  p.addLine(to: CGPoint(x: 700, y: 417))
  p.addLine(to: CGPoint(x: 700, y: 447))
  p.addCurve(
    to: CGPoint(x: 772, y: 411), control1: CGPoint(x: 716, y: 424),
    control2: CGPoint(x: 740, y: 411))
  p.addCurve(
    to: CGPoint(x: 861, y: 510), control1: CGPoint(x: 831, y: 411),
    control2: CGPoint(x: 861, y: 446))
  p.addLine(to: CGPoint(x: 861, y: 654))
  p.addLine(to: CGPoint(x: 803, y: 654))
  p.addLine(to: CGPoint(x: 803, y: 519))
  p.addCurve(
    to: CGPoint(x: 755, y: 465), control1: CGPoint(x: 803, y: 482),
    control2: CGPoint(x: 787, y: 465))
  p.addCurve(
    to: CGPoint(x: 703, y: 521), control1: CGPoint(x: 723, y: 465),
    control2: CGPoint(x: 703, y: 488))
  p.addLine(to: CGPoint(x: 703, y: 654))
  p.closeSubpath()
  c.addPath(p)
  c.drawPath(using: .eoFill)

}

func render(_ pixels: Int, mac: Bool) -> CGImage {
  let c = CGContext(
    data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: (mac ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue)!
  c.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
  c.translateBy(x: 0, y: 1024)
  c.scaleBy(x: 1, y: -1)
  if mac {
    let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
    let p = CGPath(roundedRect: tile, cornerWidth: 185, cornerHeight: 185, transform: nil)
    c.setShadow(
      offset: CGSize(width: 0, height: -8), blur: 18, color: CGColor(gray: 0, alpha: 0.25))
    c.addPath(p)
    c.setFillColor(color(0x1A1A1A))
    c.fillPath()
    c.setShadow(offset: .zero, blur: 0, color: nil)
    c.translateBy(x: 100, y: 100)
    c.scaleBy(x: 824 / 1024, y: 824 / 1024)
  } else {
    c.setFillColor(color(0x1A1A1A))
    c.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
  }
  mark(c)
  return c.makeImage()!
}
func save(_ image: CGImage, _ path: URL) {
  let d = CGImageDestinationCreateWithURL(path as CFURL, UTType.png.identifier as CFString, 1, nil)!
  CGImageDestinationAddImage(d, image, nil)
  precondition(CGImageDestinationFinalize(d))
}

var images: [[String: String]] = []
save(render(1024, mac: false), folder.appending(path: "ios-1024.png"))
images.append([
  "filename": "ios-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024",
])
for points in [16, 32, 128, 256, 512] {
  for scale in [1, 2] {
    let name = "mac-\(points)@\(scale)x.png"
    save(render(points * scale, mac: true), folder.appending(path: name))
    images.append([
      "filename": name, "idiom": "mac", "scale": "\(scale)x", "size": "\(points)x\(points)",
    ])
  }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
  .write(to: folder.appending(path: "Contents.json"))
// Check the generated assets, including the opacity required by the iOS App Store.
for entry in images {
  let source = CGImageSourceCreateWithURL(folder.appending(path: entry["filename"]!) as CFURL, nil)!
  let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
  let points = Int(entry["size"]!.split(separator: "x")[0])!
  let scale = Int(entry["scale"]?.dropLast() ?? "1")!
  precondition(image.width == points * scale && image.height == points * scale)
  precondition(
    entry["idiom"] != "universal"
      || [.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo))
}
print("Rendered \(images.count) icons into \(folder.path)")
