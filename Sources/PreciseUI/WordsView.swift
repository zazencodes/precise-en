import PreciseKit
import SwiftUI

/// Every active word, newest first: filter by difficulty, sort, search, swipe a word away to archive
/// it, and open one to read it in full. Archived words are one menu choice away, to restore.
public struct WordsView: View {
    @Environment(WordStore.self) private var store
    @State private var selection: Word.ID?
    @State private var difficulty: WordsFilter = .all
    @State private var sort: WordsSort = .newest
    @State private var search = ""
    @State private var showingArchived = false
    /// Words archived or restored here that the API has not confirmed yet: they leave the list at
    /// once, and come back with the failure bar if the request fails.
    @State private var leaving: Set<Word.ID> = []

    public init() {}

    private var listed: [Word] {
        (showingArchived ? store.archived : store.active).filter { !leaving.contains($0.id) }
    }

    private var visible: [Word] {
        WordsQuery.visible(listed, difficulty: difficulty, query: search, sort: sort)
    }

    private var selected: Word? {
        store.words.first { $0.id == selection }
    }

    public var body: some View {
        split
            .onChange(of: selection) {
                if let word = selected, !word.isArchived {
                    Task { await store.markSeen(word) }
                }
            }
            .onChange(of: showingArchived) {
                selection = nil
            }
    }

    @ViewBuilder
    private var split: some View {
        #if os(macOS)
        // A NavigationSplitView would give the window a sidebar that pushes the Review, Words and
        // Stats tabs off center, so the Mac lays the list and the page side by side within the tab.
        // The hairline between them stops below the toolbar, where a split view's divider would run
        // up through the tabs.
        HStack(spacing: 0) {
            list
                .scrollIndicators(.never)
                .frame(width: 320)
            Rectangle()
                .fill(Theme.hairline)
                .frame(width: 1)
            detail
        }
        #else
        NavigationSplitView {
            list
        } detail: {
            detail
        }
        #endif
    }

    private var difficultyPicker: some View {
        Picker("Difficulty", selection: $difficulty) {
            ForEach(WordsFilter.allCases, id: \.self) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var list: some View {
        #if os(macOS)
        // Pinned above the list, so the filter stays in reach and rows never scroll up under the toolbar.
        VStack(spacing: 0) {
            difficultyPicker
                .padding(EdgeInsets(top: 4, leading: 20, bottom: 12, trailing: 20))
            words
        }
        #else
        words
        #endif
    }

    private var words: some View {
        List(selection: $selection) {
            #if os(iOS)
            difficultyPicker
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 12, trailing: 20))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            #endif

            ForEach(visible) { word in
                row(word)
                    .tag(word.id)
                    .listRowInsets(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Theme.hairline)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(showingArchived ? "Restore" : "Archive",
                               systemImage: showingArchived ? "arrow.uturn.backward" : "archivebox") {
                            move(word)
                        }
                        .tint(Theme.fillPressed)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.canvas)
        .overlay { emptyState }
        .refreshable { await store.refresh() }
        .navigationTitle(showingArchived ? "Archived" : "Words")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search words and meanings")
        #else
        .searchable(text: $search, prompt: "Search words and meanings")
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) { menu }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let word = selected {
            WordPage(word: word, now: store.now) { move(word) }
                .id(word.id)
        } else {
            Text(showingArchived ? "Choose a word to restore it." : "Choose a word to read it.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.canvas)
        }
    }

    private var menu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(WordsSort.allCases, id: \.self) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.inline)
            Divider()
            Button(
                showingArchived ? "Show Active Words" : "Show Archived Words",
                systemImage: showingArchived ? "tray.full" : "archivebox"
            ) {
                showingArchived.toggle()
            }
        } label: {
            Label("Sort and Archived", systemImage: "line.3.horizontal.decrease")
        }
    }

    private func row(_ word: Word) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            // Hangs in the margin so every word starts on the same line as the title above.
            Circle()
                .fill(Theme.pink)
                .frame(width: 7, height: 7)
                .alignmentGuide(.firstTextBaseline) { $0[VerticalAlignment.center] + 4.5 }
                .opacity(word.isNew && !word.isArchived ? 1 : 0)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(word.word)
                        .font(.body.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(word.difficulty.rawValue)
                        .font(.caption)
                        .foregroundStyle(Theme.tertiary)
                }
                Text(word.definition)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityValue(word.isNew && !word.isArchived ? "New" : "")
    }

    @ViewBuilder
    private var emptyState: some View {
        if !store.loaded {
            if store.error == nil {
                ProgressView()
            }
        } else if visible.isEmpty {
            let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
            Group {
                if listed.isEmpty {
                    Text(showingArchived ? "No archived words. Swipe a word away when you know it." : "No words yet.")
                } else if !query.isEmpty {
                    Text("Nothing matches “\(query)”.")
                } else {
                    Text("No \(difficulty.title.lowercased()) words.")
                }
            }
            .font(.headline)
            .foregroundStyle(Theme.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        }
    }

    /// Archives an active word or restores an archived one, taking it out of this list at once.
    private func move(_ word: Word) {
        if selection == word.id { selection = nil }
        withAnimation(.snappy(duration: 0.3)) { _ = leaving.insert(word.id) }
        Task {
            if word.isArchived {
                await store.restore(word)
            } else {
                await store.archive(word)
            }
            leaving.remove(word.id)
        }
    }
}

/// A word on its own page: the word, its meaning, the prompt it came from, and where it is in review.
struct WordPage: View {
    let word: Word
    let now: Date
    /// Archives the word, or restores it when archived.
    let move: () -> Void
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize = TypeScale.displaySize * 0.85

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(word.word)
                    .display(size: wordSize)
                    .textSelection(.enabled)
                WordAnswer(word: word)
                    .padding(.top, 16)
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    ForEach(WordsQuery.scheduleFacts(for: word, now: now), id: \.label) { fact in
                        GridRow {
                            Text(fact.label)
                                .foregroundStyle(Theme.tertiary)
                            Text(fact.value)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .font(TypeScale.reading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .overlay(alignment: .top) {
                    Rectangle().fill(Theme.hairline).frame(height: 1)
                }
                .padding(.top, 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 32)
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.canvas)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    word.isArchived ? "Restore" : "Archive",
                    systemImage: word.isArchived ? "arrow.uturn.backward" : "archivebox",
                    action: move
                )
            }
        }
    }
}
