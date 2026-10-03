import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

public enum PicsewSpacing: Double, CaseIterable, Sendable {
    case micro = 4
    case xSmall = 8
    case small = 12
    case medium = 16
    case inset = 20
    case large = 24
    case xLarge = 32

    public var value: CGFloat { CGFloat(rawValue) }
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
    public static let primaryAction = Color(red: 0.03, green: 0.48, blue: 0.44)
#if os(iOS)
    public static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.76, blue: 0.69, alpha: 1)
            : UIColor(primaryAction)
    })
#else
    public static let accent = primaryAction
#endif
    public static let onPrimary = Color.white
    public static let accentSubtle = accent.opacity(0.08)
    public static let progressTrack = accent.opacity(0.12)
    public static let accentSecondary = accent
    public static let accentWarm = accent
    public static let success = accent
#if os(iOS)
    public static let canvasUIColor = UIColor.systemGroupedBackground
    public static let surfaceUIColor = UIColor.secondarySystemGroupedBackground
    public static let background = Color(uiColor: canvasUIColor)
    public static let surface = Color(uiColor: surfaceUIColor)
#else
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let surface = Color(nsColor: .controlBackgroundColor)
#endif
    public static let shellTop = background
    public static let shellBottom = background
    public static let shellHighlight = surface
    public static let shadow = Color.black
}

// Compatibility name; both entry points use the same role-based style.
public typealias PicsewActionButtonStyle = PicsewButtonStyle

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
