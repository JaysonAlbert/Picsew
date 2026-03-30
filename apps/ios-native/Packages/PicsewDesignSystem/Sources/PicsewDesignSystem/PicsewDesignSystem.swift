import Foundation
import SwiftUI

public enum PicsewSpacing: Double, CaseIterable, Sendable {
    case xSmall = 8
    case small = 12
    case medium = 16
    case large = 24
    case xLarge = 32
}

public enum PicsewCornerRadius: Double, Sendable {
    case small = 16
    case card = 24
    case stage = 30
    case pill = 18
    case action = 20
    case tray = 28
}

public struct PicsewSurfaceStyle: Sendable, Equatable {
    public let cornerRadius: Double
    public let backgroundOpacity: Double
    public let borderOpacity: Double
    public let tintOpacity: Double
    public let shadowOpacity: Double
    public let shadowRadius: Double
    public let shadowYOffset: Double

    public init(
        cornerRadius: Double,
        backgroundOpacity: Double,
        borderOpacity: Double,
        tintOpacity: Double,
        shadowOpacity: Double,
        shadowRadius: Double,
        shadowYOffset: Double
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
        self.tintOpacity = tintOpacity
        self.shadowOpacity = shadowOpacity
        self.shadowRadius = shadowRadius
        self.shadowYOffset = shadowYOffset
    }

    public static let primaryStage = PicsewSurfaceStyle(
        cornerRadius: PicsewCornerRadius.stage.rawValue,
        backgroundOpacity: 0.94,
        borderOpacity: 0.16,
        tintOpacity: 0.18,
        shadowOpacity: 0.10,
        shadowRadius: 30,
        shadowYOffset: 16
    )

    public static let secondaryStage = PicsewSurfaceStyle(
        cornerRadius: PicsewCornerRadius.card.rawValue,
        backgroundOpacity: 0.88,
        borderOpacity: 0.12,
        tintOpacity: 0.10,
        shadowOpacity: 0.06,
        shadowRadius: 18,
        shadowYOffset: 10
    )

    public static let floatingTray = PicsewSurfaceStyle(
        cornerRadius: PicsewCornerRadius.tray.rawValue,
        backgroundOpacity: 0.97,
        borderOpacity: 0.18,
        tintOpacity: 0.14,
        shadowOpacity: 0.12,
        shadowRadius: 26,
        shadowYOffset: 12
    )
}

public struct PicsewInsetPanelStyle: Sendable, Equatable {
    public let cornerRadius: Double
    public let backgroundOpacity: Double
    public let borderOpacity: Double
    public let tintOpacity: Double

    public init(
        cornerRadius: Double,
        backgroundOpacity: Double,
        borderOpacity: Double,
        tintOpacity: Double
    ) {
        self.cornerRadius = cornerRadius
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
        self.tintOpacity = tintOpacity
    }

    public static let soft = PicsewInsetPanelStyle(
        cornerRadius: PicsewCornerRadius.card.rawValue,
        backgroundOpacity: 0.72,
        borderOpacity: 0.84,
        tintOpacity: 0.08
    )

    public static let emphasized = PicsewInsetPanelStyle(
        cornerRadius: PicsewCornerRadius.card.rawValue,
        backgroundOpacity: 0.84,
        borderOpacity: 0.88,
        tintOpacity: 0.14
    )
}

public enum PicsewPalette {
    public static let ink = Color(red: 0.10, green: 0.16, blue: 0.26)
    public static let mutedInk = Color(red: 0.34, green: 0.41, blue: 0.52)
    public static let accent = Color(red: 0.16, green: 0.45, blue: 0.95)
    public static let accentSecondary = Color(red: 0.20, green: 0.74, blue: 0.78)
    public static let accentWarm = Color(red: 0.99, green: 0.72, blue: 0.39)
    public static let success = Color(red: 0.20, green: 0.65, blue: 0.46)
    public static let shellTop = Color(red: 0.93, green: 0.96, blue: 1.0)
    public static let shellBottom = Color(red: 0.99, green: 0.99, blue: 1.0)
    public static let shellHighlight = Color.white
    public static let shadow = Color(red: 0.10, green: 0.20, blue: 0.34)
}

public enum PicsewGradients {
    public static var shellBackground: LinearGradient {
        LinearGradient(
            colors: [
                PicsewPalette.shellTop,
                PicsewPalette.shellBottom,
                Color(red: 0.96, green: 0.98, blue: 1.0),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var brand: LinearGradient {
        LinearGradient(
            colors: [
                PicsewPalette.accent,
                PicsewPalette.accentSecondary,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var heroWash: LinearGradient {
        LinearGradient(
            colors: [
                PicsewPalette.accent.opacity(0.16),
                PicsewPalette.accentSecondary.opacity(0.10),
                PicsewPalette.accentWarm.opacity(0.10),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var previewStage: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.19, blue: 0.28),
                Color(red: 0.28, green: 0.33, blue: 0.44),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public struct PicsewProminentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.white.opacity(isEnabled ? 1 : 0.72))
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 56)
            .background(background(isPressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .shadow(
                color: PicsewPalette.accent.opacity(isEnabled ? 0.24 : 0.08),
                radius: configuration.isPressed ? 10 : 16,
                y: configuration.isPressed ? 4 : 10
            )
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
    }

    private func background(isPressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.action.rawValue), style: .continuous)
            .fill(PicsewGradients.brand)
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.action.rawValue), style: .continuous)
                    .fill(Color.white.opacity(isEnabled ? (isPressed ? 0.06 : 0.12) : 0.24))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.action.rawValue), style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.18 : 0.10), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.72)
    }
}

public struct PicsewSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(isEnabled ? PicsewPalette.accent : PicsewPalette.mutedInk.opacity(0.72))
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(minHeight: 56)
            .background(background(isPressed: configuration.isPressed))
            .scaleEffect(configuration.isPressed ? 0.988 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
    }

    private func background(isPressed: Bool) -> some View {
        RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.action.rawValue), style: .continuous)
            .fill(Color.white.opacity(isEnabled ? (isPressed ? 0.72 : 0.82) : 0.56))
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.action.rawValue), style: .continuous)
                    .fill(PicsewPalette.accent.opacity(isEnabled ? 0.06 : 0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.action.rawValue), style: .continuous)
                    .stroke(
                        Color.white.opacity(isEnabled ? (isPressed ? 0.78 : 0.88) : 0.68),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: PicsewPalette.shadow.opacity(isEnabled ? 0.06 : 0.02),
                radius: isPressed ? 8 : 12,
                y: isPressed ? 4 : 8
            )
    }
}

public struct PicsewTertiaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isEnabled ? PicsewPalette.mutedInk : PicsewPalette.mutedInk.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.62 : 0.42))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

public extension View {
    func picsewInsetPanel(style: PicsewInsetPanelStyle = .soft) -> some View {
        modifier(PicsewInsetPanelModifier(style: style))
    }
}

private struct PicsewInsetPanelModifier: ViewModifier {
    let style: PicsewInsetPanelStyle

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
                    .fill(Color.white.opacity(style.backgroundOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
                            .fill(PicsewPalette.accent.opacity(style.tintOpacity))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
                            .stroke(Color.white.opacity(style.borderOpacity), lineWidth: 1)
                    )
            )
    }
}
