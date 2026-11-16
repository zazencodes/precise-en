import PreciseKit
import SwiftUI

/// One due word at a time: recall what it means, show the answer, then rate how well you knew it.
public struct ReviewView: View {
    @Environment(WordStore.self) private var store
    @State private var revealed = false
    @State private var rating = false

    public init() {}

    public var body: some View {
        Group {
            if let word = store.due.first {
                card(word)
                    .id(word.id)
            } else {
                caughtUp
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .onChange(of: store.due.first?.id) { revealed = false }
    }

    private func card(_ word: Word) -> some View {
        VStack(spacing: 0) {
            Text("\(store.due.count) due")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.top, 20)
            Spacer(minLength: 24)
            Text(word.word)
                .font(.system(size: 44, weight: .semibold))
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
            if revealed {
                WordAnswer(word: word)
                    .padding(.top, 28)
                    .transition(.opacity)
            }
            Spacer(minLength: 24)
            if revealed {
                ratingButtons(word)
            } else {
                Button("Show Answer") { withAnimation(.easeOut(duration: 0.15)) { revealed = true } }
                    .keyboardShortcut(.space, modifiers: [])
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 28)
        .frame(maxWidth: 560)
    }

    private func ratingButtons(_ word: Word) -> some View {
        HStack(spacing: 10) {
            ForEach(Array(Rating.allCases.enumerated()), id: \.element) { index, choice in
                Button {
                    rating = true
                    Task {
                        await store.review(word, choice)
                        rating = false
                    }
                } label: {
                    VStack(spacing: 2) {
                        Text(choice.title)
                        Text("\(index + 1)").font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [])
                .buttonStyle(.bordered)
                .tint(choice == .again ? Theme.failure : Theme.purple)
                .controlSize(.large)
            }
        }
        .disabled(rating)
    }

    private var caughtUp: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(Theme.purple)
            if !store.loaded {
                Text("Loading…")
            } else if store.words.isEmpty {
                Text("No words yet")
                    .font(.title3.weight(.semibold))
                Text("Write a long prompt to Claude Code or Codex, and the word you could have used appears here.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            } else {
                Text("All caught up")
                    .font(.title3.weight(.semibold))
                if let next = store.nextDue {
                    Text("Next review \(next.formatted(.relative(presentation: .named)))")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(32)
        .frame(maxWidth: 420)
    }
}

/// The back of a card, and the body of a word's page: its meaning and the prompt it came from.
struct WordAnswer: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(word.partOfSpeech)
                    .font(.callout.italic())
                    .foregroundStyle(Theme.purple)
                Text(word.definition)
                    .font(.title3)
            }
            section("You wrote") {
                Text("“\(word.phrase)”")
                    .foregroundStyle(.secondary)
            }
            section("Precisely") {
                Text(emphasized(word.rewrite, word: word.word))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1)
                .foregroundStyle(.tertiary)
            content()
        }
    }

    /// The rewrite with the word in bold purple, in any form: synchronize, synchronizing, synchronized.
    private func emphasized(_ text: String, word: String) -> AttributedString {
        var result = AttributedString(text)
        for range in WordForms.ranges(of: word, in: text) {
            guard let start = AttributedString.Index(range.lowerBound, within: result),
                  let end = AttributedString.Index(range.upperBound, within: result)
            else { continue }
            result[start..<end].font = .body.weight(.semibold)
            result[start..<end].foregroundColor = Theme.purple
        }
        return result
    }
}
