import SwiftUI

public enum PicsewTypography {
    public static let hero = Font.largeTitle.weight(.bold)
    public static let title = Font.title3.weight(.semibold)
    public static let heading = Font.headline
    public static let body = Font.body
    public static let supporting = Font.subheadline
    public static let supportingStrong = Font.subheadline.weight(.semibold)
    public static let caption = Font.footnote
    public static let action = Font.body.weight(.semibold)
    public static let toolbar = Font.callout.weight(.semibold)
    public static let metric = Font.largeTitle.weight(.semibold)
    public static let badge = Font.caption.weight(.semibold)
    public static let badgeSymbol = Font.caption2.weight(.semibold)
    public static let toolbarIcon = Font.system(size: PicsewMetrics.iconSize)
    public static let navigationMaximumSize = DynamicTypeSize.xxxLarge

    public static func heroSymbol(size: CGFloat) -> Font {
        .system(size: size * 0.42, weight: .medium)
    }
}

public enum PicsewMetrics {
    public static let touchTarget: CGFloat = 44
    public static let actionHeight: CGFloat = 52
    public static let navigationHeight: CGFloat = 52
    public static let iconSize: CGFloat = 20
    public static let heroGlyphSize: CGFloat = 56
    public static let onboardingGlyphSize: CGFloat = 72
    public static let progressDiameter: CGFloat = 144
    public static let progressLineWidth: CGFloat = 6
    public static let stepBadgeSize: CGFloat = 32
}

public enum PicsewButtonRole: Sendable, Equatable {
    case primary
    case secondary
    case toolbar
    case quiet
}

public struct PicsewButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    private let role: PicsewButtonRole

    public init(_ role: PicsewButtonRole) { self.role = role }

    public init(prominent: Bool = true) { self.role = prominent ? .primary : .secondary }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fixedSize(horizontal: false, vertical: true)
            .font(role == .toolbar ? PicsewTypography.toolbar : PicsewTypography.action)
            .multilineTextAlignment(.center)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: height)
            .frame(minWidth: PicsewMetrics.touchTarget)
            .padding(.horizontal, fillsWidth ? PicsewSpacing.small.value : 0)
            .foregroundStyle(foreground)
            .background(background, in: RoundedRectangle(cornerRadius: PicsewCornerRadius.small.rawValue))
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.78 : 1)
    }

    private var fillsWidth: Bool { role == .primary || role == .secondary }
    private var height: CGFloat { fillsWidth ? PicsewMetrics.actionHeight : PicsewMetrics.touchTarget }

    private var foreground: Color {
        guard isEnabled else { return PicsewPalette.mutedInk }
        switch role {
        case .primary: return PicsewPalette.onPrimary
        case .secondary: return PicsewPalette.ink
        case .toolbar: return PicsewPalette.accent
        case .quiet: return PicsewPalette.mutedInk
        }
    }

    private var background: Color {
        switch role {
        case .primary: return isEnabled ? PicsewPalette.primaryAction : PicsewPalette.surface
        case .secondary: return PicsewPalette.background
        case .toolbar, .quiet: return .clear
        }
    }
}
