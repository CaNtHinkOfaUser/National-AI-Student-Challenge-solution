import SwiftUI

// MARK: - Style

struct SkeuButtonStyle: ButtonStyle {
    var tint: Color = .accentColor
    var size: SkeuButtonSize = .regular

    func makeBody(configuration: Configuration) -> some View {
        _SkeuButtonBody(configuration: configuration, tint: tint, size: size)
    }
}

enum SkeuButtonSize {
    case regular
    case compact

    var fontSize: CGFloat {
        switch self {
        case .regular: 17
        case .compact: 12
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .regular: 26
        case .compact: 13
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .regular: 15
        case .compact: 7
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .regular: 16
        case .compact: 10
        }
    }
}

private struct _SkeuButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let tint: Color
    let size: SkeuButtonSize

    @Environment(\.isEnabled) private var isEnabled

    var pressed: Bool { configuration.isPressed }

    var body: some View {
        configuration.label
            .font(.system(size: size.fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous))
            .overlay(topSheen)
            .overlay(strokeBorder)
            .shadow(color: .black.opacity(pressed ? 0.04 : 0.14), radius: pressed ? 1 : 8, x: 0, y: pressed ? 0 : 4)
            .scaleEffect(pressed ? 0.94 : 1.0)
            .opacity(isEnabled ? 1.0 : 0.45)
            .animation(.spring(response: pressed ? 0.18 : 0.38, dampingFraction: pressed ? 0.82 : 0.42), value: pressed)
    }

    // Tint base + white/black overlay gradient to simulate lightened top / darkened bottom
    private var fill: some View {
        ZStack {
            tint
            LinearGradient(
                colors: pressed
                    ? [Color.black.opacity(0.06), Color.white.opacity(0.10)]
                    : [Color.white.opacity(0.24), Color.black.opacity(0.08)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    // Soft specular highlight on the upper half — the key skeuomorphic touch
    private var topSheen: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [.white.opacity(pressed ? 0.07 : 0.30), .clear],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.48)
                )
            )
    }

    // Bevel border: bright top edge fading to dark bottom edge
    private var strokeBorder: some View {
        RoundedRectangle(cornerRadius: size.cornerRadius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.52), .black.opacity(0.22)],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Shared press animation (used by SkeuTabBar and FloatingAIBar)

struct SkeuPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        SkeuPressBody(configuration: configuration)
    }
}

struct SkeuPressBody: View {
    let configuration: ButtonStyleConfiguration

    var pressed: Bool { configuration.isPressed }

    var body: some View {
        configuration.label
            .scaleEffect(pressed ? 0.94 : 1.0)
            .animation(.spring(response: pressed ? 0.18 : 0.38, dampingFraction: pressed ? 0.82 : 0.42), value: pressed)
    }
}

// MARK: - Convenience wrapper

struct SkeuButton<Label: View>: View {
    var tint: Color = .accentColor
    var size: SkeuButtonSize = .regular
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    init(
        tint: Color = .accentColor,
        size: SkeuButtonSize = .regular,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.tint = tint
        self.size = size
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action, label: label)
            .buttonStyle(SkeuButtonStyle(tint: tint, size: size))
    }
}

// MARK: - Preview

#Preview("Skeu Buttons") {
    VStack(spacing: 18) {
        SkeuButton(tint: .blue, action: {}) {
            Label("Increase", systemImage: "plus")
        }
        SkeuButton(tint: Color(red: 0.52, green: 0.28, blue: 0.92), action: {}) {
            Label("Decrease", systemImage: "minus")
        }
        SkeuButton(tint: .blue, action: {}) {
            Label("Disabled", systemImage: "lock")
        }
        .disabled(true)
    }
    .padding(48)
    .background(Color(white: 0.94))
}
