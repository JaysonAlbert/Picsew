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
