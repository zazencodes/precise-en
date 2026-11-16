import AppKit
import PreciseKit
import PreciseUI
import ServiceManagement
import SwiftUI

/// The Mac app: a menu bar item that counts new words, and a window to review and browse them.
/// It opens at login and checks the API every minute.
@main
struct PreciseENApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    @State private var store: WordStore
    @State private var capture: CaptureWatch
    @State private var tab: AppTab = .review

    init() {
        let store = WordStore(api: PreciseAPI(config: .fromInfoPlist()))
        let capture = CaptureWatch()
        _store = State(initialValue: store)
        _capture = State(initialValue: capture)
        Task { @MainActor in
            while true {
                await store.refresh()
                capture.read()
                try await Task.sleep(for: .seconds(60))
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(tab: $tab)
                .environment(store)
                .environment(capture)
        } label: {
            MenuBarLabel(openMain: { delegate.openMain = $0 })
                .environment(store)
                .environment(capture)
        }
        Window("precise//en", id: MainWindow.id) {
            MainView(tab: $tab)
                .environment(store)
                .frame(minWidth: 680, minHeight: 520)
                .containerBackground(Theme.canvas, for: .window)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
                .task { await store.refresh() }
        }
        .defaultSize(width: 900, height: 640)
        .defaultLaunchBehavior(.suppressed)
    }
}

enum MainWindow {
    static let id = "main"
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Set by the menu bar label, which has SwiftUI's `openWindow`.
    var openMain: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        openAtLogin()
    }

    /// Opening the app again from Spotlight or Finder shows the window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        openMain?()
        return false
    }

    /// Registers the /Applications copy as a login item the first time it runs (status `.notFound`
    /// until then). Turning it off in System Settings → Login Items (`.requiresApproval`) leaves it off.
    private func openAtLogin() {
        guard Bundle.main.bundlePath.hasPrefix("/Applications/"),
              [.notFound, .notRegistered].contains(SMAppService.mainApp.status)
        else { return }
        do {
            try SMAppService.mainApp.register()
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "precise//en couldn't add itself to Login Items"
            alert.runModal()
        }
    }
}

/// The latest capture attempt, from the file the `precise-en` hook writes.
@MainActor
@Observable
final class CaptureWatch {
    /// Why the latest capture failed, or nil when it worked.
    private(set) var failure: String?

    func read() {
        do {
            let status = try CaptureStatus.read()
            failure = status?.outcome == .failed ? status?.detail ?? "unknown error" : nil
        } catch {
            failure = "reading \(CaptureStatus.url.path): \(error.localizedDescription)"
        }
    }
}

struct MenuBarLabel: View {
    @Environment(WordStore.self) private var store
    @Environment(CaptureWatch.self) private var capture
    @Environment(\.openWindow) private var openWindow
    let openMain: (@escaping () -> Void) -> Void

    var body: some View {
        let count = store.newWords.count
        Group {
            if capture.failure != nil || store.error != nil {
                Image(systemName: "exclamationmark.triangle")
            } else if count > 0 {
                Text("\(Image(systemName: "character.book.closed.fill")) \(count)")
            } else {
                Image(systemName: "character.book.closed")
            }
        }
        .onAppear {
            openMain {
                NSApp.activate()
                openWindow(id: MainWindow.id)
            }
        }
    }
}

struct MenuContent: View {
    @Environment(WordStore.self) private var store
    @Environment(CaptureWatch.self) private var capture
    @Environment(\.openWindow) private var openWindow
    @Binding var tab: AppTab

    var body: some View {
        Button(store.due.isEmpty ? "Review" : "Review · \(store.due.count) due") { show(.review) }
        Button(store.newWords.isEmpty ? "Words" : "Words · \(store.newWords.count) new") { show(.words) }
        Button("Stats") { show(.stats) }
        if let error = store.error {
            Divider()
            Text("Last request failed: \(error.prefix(90))")
        }
        if let failure = capture.failure {
            Divider()
            Text("Capture failed: \(failure.prefix(90))")
            Button("Open Capture Log") { NSWorkspace.shared.open(CaptureStatus.logURL) }
        }
        Divider()
        Button("Quit precise//en") { NSApp.terminate(nil) }
            .keyboardShortcut("q")
    }

    private func show(_ destination: AppTab) {
        tab = destination
        NSApp.activate()
        openWindow(id: MainWindow.id)
    }
}
