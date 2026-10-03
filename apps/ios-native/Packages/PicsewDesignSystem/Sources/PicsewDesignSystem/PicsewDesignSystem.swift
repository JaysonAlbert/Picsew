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

// Shared role values: docs/features/shared-technology-theme.md.
// Keep feature views independent of appearance-specific color literals.
public enum PicsewPalette {
    public static let ink = adaptive(light: 0x14213D, dark: 0xEDF3FF)
    public static let mutedInk = adaptive(light: 0x52617A, dark: 0xAABAD4)
    public static let primaryAction = adaptive(light: 0x2457E6, dark: 0x2457E6)
    public static let accent = adaptive(light: 0x2457E6, dark: 0x8AB4FF)
    public static let accentSecondary = adaptive(light: 0x6941C6, dark: 0xBAA7FF)
    public static let onPrimary = Color.white
    public static let accentSubtle = adaptive(light: 0xE8EEFF, dark: 0x1B2D50)
    public static let progressTrack = accentSubtle
    public static let accentWarm = accentSecondary
    public static let success = adaptive(light: 0x167252, dark: 0x70D9B0)
    public static let border = adaptive(light: 0xD6DFEF, dark: 0x34445F)
#if os(iOS)
    public static let canvasUIColor = adaptiveUIColor(light: 0xF3F6FC, dark: 0x080F20)
    public static let surfaceUIColor = adaptiveUIColor(light: 0xFFFFFF, dark: 0x121D33)
    public static let background = Color(uiColor: canvasUIColor)
    public static let surface = Color(uiColor: surfaceUIColor)

    private static func adaptiveUIColor(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        }
    }
#else
    public static let background = Color(nsColor: .windowBackgroundColor)
    public static let surface = Color(nsColor: .controlBackgroundColor)
#endif
    public static let shellTop = background
    public static let shellBottom = background
    public static let shellHighlight = surface
    public static let shadow = Color.black

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
#if os(iOS)
        Color(uiColor: adaptiveUIColor(light: light, dark: dark))
#else
        Color(
            red: Double((light >> 16) & 0xFF) / 255,
            green: Double((light >> 8) & 0xFF) / 255,
            blue: Double(light & 0xFF) / 255
        )
#endif
    }
}

// Compatibility name; both entry points use the same role-based style.
public typealias PicsewActionButtonStyle = PicsewButtonStyle

public enum PicsewGradients {
    public static var shellBackground: LinearGradient {
        LinearGradient(
            colors: [
                PicsewPalette.shellTop,
                PicsewPalette.shellBottom,
                PicsewPalette.shellHighlight,
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
