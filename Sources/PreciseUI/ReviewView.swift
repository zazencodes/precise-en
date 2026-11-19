import PreciseKit
import SwiftUI

/// One due word at a time: recall what it means, show the answer, then rate how well you knew it,
/// or archive it as one you already know.
public struct ReviewView: View {
    @Environment(WordStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize = TypeScale.displaySize
    /// The word whose answer is showing. Keyed by word so the next card never opens revealed.
    @State private var revealedID: Word.ID?
    /// Words rated here whose rating the API has not confirmed yet. The next card shows at once;
    /// if the rating fails, the word comes back to the front and the failure bar says why.
    @State private var rated: Set<Word.ID> = []

    public init() {}

    private var queue: [Word] {
        store.due.filter { !rated.contains($0.id) }
    }

    public var body: some View {
        let word = queue.first
        VStack(spacing: 0) {
            header
            ZStack {
                if let word {
                    card(word)
                        .id(word.id)
                        .transition(cardTransition)
                } else {
                    emptyState
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let word {
                actions(word)
            }
        }
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Wordmark()
            Spacer()
            if store.loaded {
                Text("\(queue.count) due")
                    .font(TypeScale.headerDetail)
                    .foregroundStyle(queue.isEmpty ? Theme.tertiary : .white)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: queue.count)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func card(_ word: Word) -> some View {
        let revealed = revealedID == word.id
        return GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(word.word)
                        .display(size: wordSize)
                        .textSelection(.enabled)
                    if revealed {
                        WordAnswer(word: word)
                            .padding(.top, 20)
                            .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 16)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                // The front sits a little above the middle, where the eye lands; the answer reads from the top.
                .padding(.bottom, revealed ? 0 : proxy.size.height * 0.12)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: revealed ? .topLeading : .leading)
            }
            // Never, even with a mouse connected, so no scroll bar flashes as the answer grows in.
            .scrollIndicators(.never)
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func actions(_ word: Word) -> some View {
        Group {
            if revealedID == word.id {
                VStack(spacing: 4) {
                    archiveButton(word)
                    ratings(word)
                }
                .transition(.opacity)
            } else {
                Button("Show Answer") {
                    withAnimation(motion) { revealedID = word.id }
                }
                .buttonStyle(.primaryAction)
                .keyboardShortcut(.space, modifiers: [])
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    /// A quiet link above the ratings, for a word you knew before it was saved.
    private func archiveButton(_ word: Word) -> some View {
        Button {
            archive(word)
        } label: {
            HStack(spacing: 6) {
                Label("Archive", systemImage: "archivebox")
                #if os(macOS)
                Text("a")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.tertiary)
                #endif
            }
            .font(TypeScale.label)
            .foregroundStyle(Theme.secondary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .keyboardShortcut("a", modifiers: [])
    }

    /// Pass or fail, on Anki's keys: 1 for Again, and Space for Good, so a word you knew is Space twice.
    private func ratings(_ word: Word) -> some View {
        HStack(spacing: 8) {
            ratingButton(word, .again, key: "1", hint: "1")
            ratingButton(word, .good, key: .space, hint: "space")
        }
    }

    private func ratingButton(_ word: Word, _ rating: Rating, key: KeyEquivalent, hint: String) -> some View {
        Button {
            rate(word, rating)
        } label: {
            VStack(spacing: 1) {
                Text(rating.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                #if os(macOS)
                Text(hint)
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.tertiary)
                #endif
            }
        }
        .buttonStyle(.secondaryAction)
        .keyboardShortcut(key, modifiers: [])
    }

    private func rate(_ word: Word, _ rating: Rating) {
        withAnimation(motion) { _ = rated.insert(word.id) }
        Task {
            await store.review(word, rating)
            rated.remove(word.id)
        }
    }

    /// Takes a word you already know out of review for good, as swiping it away in Words does.
    private func archive(_ word: Word) {
        withAnimation(motion) { _ = rated.insert(word.id) }
        Task {
            await store.archive(word)
            rated.remove(word.id)
        }
    }

    private var motion: Animation {
        reduceMotion ? .easeOut(duration: 0.2) : .snappy(duration: 0.35)
    }

    /// The rated word slides away to the left as the next one arrives from the right.
    private var cardTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(
            insertion: .opacity.combined(with: .offset(x: 40)),
            removal: .opacity.combined(with: .offset(x: -40))
        )
    }

    @ViewBuilder
    private var emptyState: some View {
        if !store.loaded {
            if store.error == nil {
                ProgressView()
            } else {
                message("Words didn't load.", detail: nil)
            }
        } else if store.words.isEmpty {
            message(
                "No words yet.",
                detail: "Write a long prompt to Claude Code or Codex. The word you could have used lands here."
            )
        } else if store.active.isEmpty {
            message("Nothing to review.", detail: "Every word is archived. Restore one from Words.")
        } else {
            message(
                "All caught up.",
                detail: store.nextDue.map { "Next review \($0.formatted(.relative(presentation: .named)))." }
            )
        }
    }

    private func message(_ title: String, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: wordSize * 0.72, weight: .heavy))
                .tracking(-wordSize * 0.72 * 0.025)
                .foregroundStyle(.white)
            if let detail {
                Text(detail)
                    .font(TypeScale.reading)
                    .foregroundStyle(Theme.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.bottom, 80)
    }
}

/// "precise//en" in bold, the slashes dimmed, at the top of Review.
struct Wordmark: View {
    var body: some View {
        Text("precise\(Text("//").foregroundStyle(Theme.tertiary))en")
            .font(TypeScale.header)
            .tracking(-0.3)
            .foregroundStyle(.white)
            .accessibilityLabel("precise//en")
    }
}
