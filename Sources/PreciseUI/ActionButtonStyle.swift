import SwiftUI

/// The app's one button shape: a full-width 56pt slab. White with black type for the action that
/// moves you on (Show Answer); dark gray with white type for a choice among equals (the ratings).
struct ActionButtonStyle: ButtonStyle {
    enum Prominence {
        case primary, secondary
    }

    let prominence: Prominence

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(prominence == .primary ? Color.black : Color.white)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(background(pressed: configuration.isPressed), in: shape)
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }

    private func background(pressed: Bool) -> Color {
        switch prominence {
        case .primary: pressed ? Color(white: 0.82) : .white
        case .secondary: pressed ? Theme.fillPressed : Theme.fill
        }
    }
}

extension ButtonStyle where Self == ActionButtonStyle {
    static var primaryAction: ActionButtonStyle { ActionButtonStyle(prominence: .primary) }
    static var secondaryAction: ActionButtonStyle { ActionButtonStyle(prominence: .secondary) }
}
