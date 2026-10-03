import Observation
import PicsewDesignSystem
import SwiftUI

public struct OnboardingFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PicsewSpacing.xLarge.value) {
                VStack(alignment: .leading, spacing: PicsewSpacing.medium.value) {
                    PicsewHeroGlyph(systemImage: "rectangle.on.rectangle.angled", size: PicsewMetrics.onboardingGlyphSize)
                    Text("A little recording.\nOne long screenshot.")
                        .font(PicsewTypography.hero)
                        .foregroundStyle(PicsewPalette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Capture the whole story, privately on your device.")
                        .font(PicsewTypography.body)
                        .foregroundStyle(PicsewPalette.mutedInk)
                }

                PicsewStageCard(spacing: PicsewSpacing.large.value) {
                    onboardingStep(number: "1", title: "Record", detail: "Record your screen as you scroll.")
                    onboardingStep(number: "2", title: "Create", detail: "Choose the video. Picsew stitches it.")
                    onboardingStep(number: "3", title: "Keep", detail: "Save or share your long screenshot.")
                }
            }
            .padding(.horizontal, PicsewSpacing.large.value)
            .padding(.top, PicsewSpacing.xLarge.value)
            .padding(.bottom, PicsewSpacing.medium.value)
            .accessibilityIdentifier("onboarding.screen")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PicsewPalette.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PicsewBottomActionTray {
                Button("Continue") { model.dismissOnboarding() }
                    .buttonStyle(PicsewButtonStyle(.primary))
                    .accessibilityIdentifier("onboarding.continue")
            }
            .padding(.horizontal, PicsewSpacing.large.value)
            .background(PicsewPalette.background)
        }
        .interactiveDismissDisabled()
    }

    private func onboardingStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: PicsewSpacing.medium.value) {
            Text(number)
                .font(PicsewTypography.supportingStrong)
                .foregroundStyle(PicsewPalette.accent)
                .frame(width: PicsewMetrics.stepBadgeSize, height: PicsewMetrics.stepBadgeSize)
                .background(PicsewPalette.accentSubtle, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PicsewSpacing.micro.value) {
                Text(title).font(PicsewTypography.heading).foregroundStyle(PicsewPalette.ink)
                Text(detail).font(PicsewTypography.supporting).foregroundStyle(PicsewPalette.mutedInk)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
