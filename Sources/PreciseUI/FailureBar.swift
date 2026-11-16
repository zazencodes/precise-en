import SwiftUI

/// The last request's failure, pinned to the bottom of every screen until a request succeeds.
/// It insets the screen's content rather than covering it, so nothing underneath jumps or hides.
struct FailureBar: View {
    @Environment(WordStore.self) private var store
    @State private var retrying = false

    var body: some View {
        if let error = store.error {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.body)
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last request failed")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
                Spacer(minLength: 8)
                Button {
                    retrying = true
                    Task {
                        await store.refresh()
                        retrying = false
                    }
                } label: {
                    Text("Retry")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.black)
                        .opacity(retrying ? 0 : 1)
                        .overlay {
                            if retrying {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.black)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 36)
                        .background(.white, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(retrying)
            }
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .padding(.vertical, 10)
            .background(Theme.fill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

/// Reserves room at the bottom of a screen for the failure bar while there is a failure, and
/// moves the screen's content up and down with it.
private struct FailureInset: ViewModifier {
    @Environment(WordStore.self) private var store

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) { FailureBar() }
            .animation(.snappy(duration: 0.3), value: store.error)
    }
}

extension View {
    func failureBar() -> some View {
        modifier(FailureInset())
    }
}
