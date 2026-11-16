import PreciseKit
import SwiftUI

/// Every word in review, newest first. New words carry a purple dot until you open them. Swipe a
/// word away to archive it as one you know.
public struct WordsView: View {
    @Environment(WordStore.self) private var store
    @State private var selection: Word.ID?

    public init() {}

    private var selected: Word? { store.active.first { $0.id == selection } }

    public var body: some View {
        NavigationSplitView {
            List(store.active, selection: $selection) { word in
                row(word)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("Archive", systemImage: "archivebox") {
                            if selection == word.id { selection = nil }
                            Task { await store.archive(word) }
                        }
                    }
            }
            .overlay {
                if store.loaded && store.active.isEmpty {
                    ContentUnavailableView("No words yet", systemImage: "character.book.closed")
                }
            }
            .navigationTitle("Words")
            .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 340)
            .refreshable { await store.refresh() }
        } detail: {
            if let word = selected {
                detail(word)
            } else {
                ContentUnavailableView("Select a word", systemImage: "character.book.closed")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background)
            }
        }
        .onChange(of: selection) {
            if let word = selected { Task { await store.markSeen(word) } }
        }
    }

    private func row(_ word: Word) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(word.isNew ? Theme.purple : .clear)
                .frame(width: 7, height: 7)
            VStack(alignment: .leading, spacing: 2) {
                Text(word.word)
                    .font(.body.weight(word.isNew ? .semibold : .regular))
                Text(word.definition)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .tag(word.id)
    }

    private func detail(_ word: Word) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(word.word)
                    .font(.system(size: 36, weight: .semibold))
                    .textSelection(.enabled)
                WordAnswer(word: word)
                Text(schedule(word))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(28)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background)
    }

    private func schedule(_ word: Word) -> String {
        let saved = "Saved \(word.createdAt.formatted(date: .abbreviated, time: .omitted))"
        let due = word.isDue(at: store.now)
            ? "due now"
            : "next review \(word.dueAt.formatted(.relative(presentation: .named)))"
        let reviewed = word.reviewedAt.map { "last reviewed \($0.formatted(.relative(presentation: .named)))" }
            ?? "not reviewed yet"
        return [saved, due, reviewed].joined(separator: " · ")
    }
}
