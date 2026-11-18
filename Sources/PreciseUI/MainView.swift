import PreciseKit
import SwiftUI

public enum AppTab: Hashable, Sendable {
    case review, words, stats, settings
}

/// Shared navigation for the Mac and iPhone apps.
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
            StatsView()
                .failureBar()
                .tabItem { Label("Stats", systemImage: "chart.bar") }
                .tag(AppTab.stats)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .tint(.white)
        .preferredColorScheme(.dark)
    }
}
