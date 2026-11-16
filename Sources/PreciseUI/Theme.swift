import SwiftUI

/// Dark grays, white and heavy type, like Alex's other apps. The brand pink is the one accent:
/// the dot on a new word and the word inside its rewrite, nowhere else.
public enum Theme {
    /// The canvas behind every screen and the Mac window.
    public static let canvas = gray(0x0F)
    /// Buttons, the failure bar and other filled controls.
    static let fill = gray(0x1F)
    static let fillPressed = gray(0x2C)
    /// Separators between rows.
    static let hairline = gray(0x26)
    /// Supporting text: definitions in lists, your own phrase, labels beside numbers.
    static let secondary = gray(0xA3)
    /// Labels that name a part of the screen ("You wrote", week dates). 4.6:1 on the canvas.
    static let tertiary = gray(0x7C)
    /// The ZazenCodes pink.
    static let pink = Color(red: 0xF3 / 255, green: 0x8A / 255, blue: 0xC8 / 255)

    private static func gray(_ level: Int) -> Color {
        Color(red: Double(level) / 255, green: Double(level) / 255, blue: Double(level) / 255)
    }
}

/// Text sizes that differ between the platforms. The iPhone follows Dynamic Type; the Mac's
/// system sizes (13pt body) are too small for reading a card, so it gets fixed larger ones.
enum TypeScale {
    /// A word's definition on its card and its page.
    static var definition: Font {
        #if os(macOS)
        .system(size: 21, weight: .medium)
        #else
        .title3.weight(.medium)
        #endif
    }

    /// Your phrase and the rewrite on a card and a page.
    static var reading: Font {
        #if os(macOS)
        .system(size: 15)
        #else
        .body
        #endif
    }

    static var readingEmphasis: Font {
        #if os(macOS)
        .system(size: 15, weight: .heavy)
        #else
        .body.weight(.heavy)
        #endif
    }

    /// Small labels above a part of a card and beside the facts on a page.
    static var label: Font {
        #if os(macOS)
        .system(size: 12, weight: .semibold)
        #else
        .subheadline.weight(.semibold)
        #endif
    }

    /// The point size of a word set as the subject of the screen: the card and the word's page.
    static var displaySize: CGFloat {
        #if os(macOS)
        72
        #else
        60
        #endif
    }

    /// The wordmark and the due count at the top of Review.
    static var header: Font {
        #if os(macOS)
        .system(size: 15, weight: .heavy)
        #else
        .headline.weight(.heavy)
        #endif
    }

    static var headerDetail: Font {
        #if os(macOS)
        .system(size: 14, weight: .semibold).monospacedDigit()
        #else
        .subheadline.weight(.semibold).monospacedDigit()
        #endif
    }
}

extension Text {
    /// A word set as the subject of a screen: heavy, tight, never wrapped.
    func display(size: CGFloat) -> some View {
        font(.system(size: size, weight: .heavy))
            .tracking(-size * 0.025)
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
