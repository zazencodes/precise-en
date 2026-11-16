import PreciseKit
import PreciseUI
import SwiftUI

/// The iPhone app: the same Review and Words as the Mac, checking the API every minute while open.
@main
struct PreciseENApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store = WordStore(api: PreciseAPI(config: .fromInfoPlist()))
    @State private var tab: AppTab = .review

    var body: some Scene {
        WindowGroup {
            MainView(tab: $tab)
                .environment(store)
                .task(id: scenePhase) {
                    guard scenePhase == .active else { return }
                    while true {
                        await store.refresh()
                        do {
                            try await Task.sleep(for: .seconds(60))
                        } catch {
                            return  // the app left the foreground
                        }
                    }
                }
        }
    }
}
