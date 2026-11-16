import PreciseKit
import SwiftUI

public enum AppTab: Hashable, Sendable {
    case review, words
}

/// The whole app on both platforms: Review and Words, with any API failure shown above them.
public struct MainView: View {
    @Environment(WordStore.self) private var store
    @Binding private var tab: AppTab

    public init(tab: Binding<AppTab>) {
        _tab = tab
    }

    public var body: some View {
        VStack(spacing: 0) {
            if let error = store.error {
                failure(error)
            }
            TabView(selection: $tab) {
                ReviewView()
                    .tabItem { Label("Review", systemImage: "rectangle.on.rectangle.angled") }
                    .badge(store.due.count)
                    .tag(AppTab.review)
                WordsView()
                    .tabItem { Label("Words", systemImage: "character.book.closed") }
                    .badge(store.newWords.count)
                    .tag(AppTab.words)
            }
        }
        .tint(Theme.purple)
        .preferredColorScheme(.dark)
    }

    private func failure(_ message: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
                .lineLimit(3)
                .textSelection(.enabled)
            Spacer()
            Button("Retry") { Task { await store.refresh() } }
        }
        .font(.callout)
        .foregroundStyle(Theme.failure)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.failure.opacity(0.12))
    }
}
