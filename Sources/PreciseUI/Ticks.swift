import SwiftUI

/// Stats draws every word as one tick, so a count reads as that many words side by side.
enum TickLayout {
    /// The distance from one tick to the next: `preferred` while `count` ticks fit in `length`,
    /// closer together once they don't, so the row never overflows.
    static func pitch(count: Int, length: CGFloat, preferred: CGFloat) -> CGFloat {
        guard count > 0 else { return preferred }
        return min(preferred, length / CGFloat(count))
    }

    /// How much of the pitch a tick fills; the rest is the gap before the next one.
    static let fill: CGFloat = 0.5
    /// Tick spacing along a row, and up a column, while they fit.
    static let rowPitch: CGFloat = 14
    static let columnPitch: CGFloat = 6
}

/// `lit` bright ticks followed by dim ones up to `total`: a share of the words drawn as words.
struct TickRow: View {
    let lit: Int
    let total: Int

    var body: some View {
        Canvas { context, size in
            let pitch = TickLayout.pitch(count: total, length: size.width, preferred: TickLayout.rowPitch)
            let width = max(1, pitch * TickLayout.fill)
            for index in 0..<total {
                let rect = CGRect(x: CGFloat(index) * pitch, y: 0, width: width, height: size.height)
                context.fill(Path(roundedRect: rect, cornerRadius: min(1.5, width / 2)),
                             with: .color(index < lit ? Theme.tickOn : Theme.tickOff))
            }
        }
        .accessibilityHidden(true)
    }
}

/// A column of `count` ticks stacked from the bottom, one per word, `pitch` apart.
struct TickColumn: View {
    let count: Int
    let pitch: CGFloat

    var body: some View {
        Canvas { context, size in
            let height = max(1, pitch * TickLayout.fill)
            for index in 0..<max(count, 1) {
                let rect = CGRect(x: 0, y: size.height - height - CGFloat(index) * pitch, width: size.width, height: height)
                context.fill(Path(roundedRect: rect, cornerRadius: min(1.5, height / 2)),
                             with: .color(count == 0 ? Theme.tickOff : Theme.tickOn))
            }
        }
        .accessibilityHidden(true)
    }
}
