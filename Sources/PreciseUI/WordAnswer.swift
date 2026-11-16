import PreciseKit
import SwiftUI

/// The back of a card, and the body of a word's page: what the word means and the prompt it came from.
struct WordAnswer: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(word.partOfSpeech)  ·  \(word.difficulty.rawValue)")
                .font(TypeScale.label)
                .foregroundStyle(Theme.tertiary)
            Text(word.definition)
                .font(TypeScale.definition)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            part("You wrote") {
                Text("“\(word.phrase)”")
                    .foregroundStyle(Theme.secondary)
            }
            .padding(.top, 28)
            part("Precisely") {
                Text(emphasized(word.rewrite, word: word.word))
                    .foregroundStyle(.white)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    private func part(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(TypeScale.label)
                .foregroundStyle(Theme.tertiary)
            content()
                .font(TypeScale.reading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// The rewrite with the word in heavy pink, in any form: synchronize, synchronizing, synchronized.
    private func emphasized(_ text: String, word: String) -> AttributedString {
        var result = AttributedString(text)
        for range in WordForms.ranges(of: word, in: text) {
            guard let start = AttributedString.Index(range.lowerBound, within: result),
                  let end = AttributedString.Index(range.upperBound, within: result)
            else { continue }
            result[start..<end].font = TypeScale.readingEmphasis
            result[start..<end].foregroundColor = Theme.pink
        }
        return result
    }
}
