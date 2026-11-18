import PreciseKit
import SwiftUI

struct SettingsView: View {
    @Environment(WordStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var limits: [CaptureLimit] = []
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily word limits")
                        .font(.title.weight(.heavy))
                    Text("Choose how many new words to save in each category. Set a limit to zero to pause it.")
                        .font(TypeScale.reading)
                        .foregroundStyle(Theme.secondary)
                    VStack(spacing: 0) {
                        ForEach(Difficulty.allCases, id: \.self) { difficulty in
                            if let limit = limits.first(where: { $0.difficulty == difficulty }) {
                                Stepper(value: Binding(get: { limit.dailyLimit }, set: { value in
                                    Task { await update(difficulty, to: value) }
                                }), in: 0...99) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(difficulty.title).font(.headline)
                                            Text("\(limit.capturedToday) saved today")
                                                .font(TypeScale.note)
                                                .foregroundStyle(Theme.secondary)
                                        }
                                        Spacer()
                                        Text("\(limit.dailyLimit)")
                                            .font(.title3.bold().monospacedDigit())
                                    }
                                }
                                .accessibilityLabel("\(difficulty.title) daily limit")
                                .accessibilityValue("\(limit.dailyLimit)")
                                .padding(.vertical, 12)
                                Divider().overlay(Theme.hairline)
                            }
                        }
                    }
                    .disabled(busy)
                    if limits.isEmpty && busy { ProgressView() }
                    Text("Limits reset at midnight UTC. Scheduled reviews continue as usual.")
                        .font(TypeScale.note)
                        .foregroundStyle(Theme.tertiary)
                    if let error {
                        Text(error).foregroundStyle(Theme.secondary)
                        Button("Reload limits") { Task { await load() } }
                            .disabled(busy)
                    }
                }
                .padding(20)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.canvas)
            .navigationTitle("Settings")
            #if os(iOS)
            .toolbarBackground(Theme.canvas, for: .navigationBar)
            #endif
            .refreshable { await load() }
            .task(id: scenePhase) {
                if scenePhase == .active { await load() }
            }
        }
    }

    private func load() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            limits = try await store.api.captureLimits()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func update(_ difficulty: Difficulty, to value: Int) async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            try await store.api.setLimit(value, for: difficulty)
            limits = try await store.api.captureLimits()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}
