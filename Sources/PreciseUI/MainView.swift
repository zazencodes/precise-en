import PreciseKit
import SwiftUI

public enum AppTab: Hashable, Sendable {
    case review, words
}

/// The whole app on both platforms: Review and Words. Each screen keeps the last request's
/// failure in a bar along its bottom until a request succeeds.
public struct MainView: View {
    @Binding private var tab: AppTab

    public init(tab: Binding<AppTab>) {
        _tab = tab
    }

    public var body: some View {
        TabView(selection: $tab) {
            ReviewView()
                .failureBar()
                .tabItem { Label("Review", systemImage: "rectangle.on.rectangle.angled") }
                .tag(AppTab.review)
            WordsView()
                .failureBar()
                .tabItem { Label("Words", systemImage: "character.book.closed") }
                .tag(AppTab.words)
        }
        .tint(.white)
        .preferredColorScheme(.dark)
    }
}
