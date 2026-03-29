import Testing

@testable import PicsewDesignSystem

@Test("design system exposes stable spacing and surface tokens")
func spacingAndSurfaceTokens() {
    #expect(PicsewSpacing.medium.rawValue == 16)
    #expect(PicsewCornerRadius.card.rawValue == 24)
    #expect(PicsewSurfaceStyle.primaryStage.backgroundOpacity > 0.9)
}
