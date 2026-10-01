import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

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

public enum PicsewPalette {
    public static let ink = Color.primary
#if os(iOS)
    public static let mutedInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.72, alpha: 1)
            : UIColor(red: 0.36, green: 0.39, blue: 0.42, alpha: 1)
    })
#else
    public static let mutedInk = Color.secondary
#endif
    public static let accent = Color(red: 0.03, green: 0.48, blue: 0.44)
    public static let accentSecondary = accent
    public static let accentWarm = accent
    public static let success = accent
#if os(iOS)
    public static let background = Color(uiColor: .systemGroupedBackground)
    public static let surface = Color(uiColor: .secondarySystemGroupedBackground)
#else
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let surface = Color(nsColor: .controlBackgroundColor)
#endif
    public static let shellTop = background
    public static let shellBottom = background
    public static let shellHighlight = surface
    public static let shadow = Color.black
}

public struct PicsewActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private let prominent: Bool

    public init(prominent: Bool = true) {
        self.prominent = prominent
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fixedSize(horizontal: false, vertical: true)
            .font(.body.weight(.semibold))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.horizontal, 12)
            .foregroundStyle(isEnabled ? (prominent ? Color.white : PicsewPalette.ink) : PicsewPalette.mutedInk)
            .background(
                isEnabled && prominent ? PicsewPalette.accent : PicsewPalette.surface,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
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
