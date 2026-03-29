import Foundation

public enum PicsewSpacing: Double, CaseIterable, Sendable {
    case xSmall = 8
    case small = 12
    case medium = 16
    case large = 24
    case xLarge = 32
}

public enum PicsewCornerRadius: Double, Sendable {
    case card = 24
    case pill = 18
    case action = 20
}

public struct PicsewSurfaceStyle: Sendable, Equatable {
    public let backgroundOpacity: Double
    public let borderOpacity: Double

    public init(backgroundOpacity: Double, borderOpacity: Double) {
        self.backgroundOpacity = backgroundOpacity
        self.borderOpacity = borderOpacity
    }

    public static let primaryStage = PicsewSurfaceStyle(
        backgroundOpacity: 0.96,
        borderOpacity: 0.08
    )
}
