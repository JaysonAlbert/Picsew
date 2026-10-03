import SwiftUI

public struct PicsewStageCard<Content: View>: View {
    private let style: PicsewSurfaceStyle
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    private let content: Content

    public init(
        style: PicsewSurfaceStyle = .primaryStage,
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = PicsewSpacing.medium.value,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .padding(PicsewSpacing.inset.value)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            PicsewPalette.surface,
            in: RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
                .stroke(PicsewPalette.border, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }
}

public struct PicsewBottomActionTray<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: PicsewSpacing.xSmall.value) {
            content
        }
        .padding(.vertical, PicsewSpacing.small.value)
        .background(PicsewPalette.background)
        .accessibilityElement(children: .contain)
    }
}

public struct PicsewHeroGlyph: View {
    private let systemImage: String
    private let size: CGFloat

    public init(systemImage: String, size: CGFloat = PicsewMetrics.heroGlyphSize) {
        self.systemImage = systemImage
        self.size = size
    }

    public var body: some View {
        Image(systemName: systemImage)
            .font(PicsewTypography.heroSymbol(size: size))
            .foregroundStyle(PicsewGradients.brand)
            .frame(width: size, height: size)
            .background(
                PicsewPalette.accentSubtle,
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}
