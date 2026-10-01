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
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    PicsewHeroGlyph(systemImage: "rectangle.on.rectangle.angled", size: 72)
                    Text("A little recording.\nOne long screenshot.")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(PicsewPalette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text("Capture the whole story, privately on your device.")
                        .font(.body)
                        .foregroundStyle(PicsewPalette.mutedInk)
                }

                PicsewStageCard(spacing: 24) {
                    onboardingStep(number: "1", title: "Record", detail: "Record your screen as you scroll.")
                    onboardingStep(number: "2", title: "Create", detail: "Choose the video. Picsew stitches it.")
                    onboardingStep(number: "3", title: "Keep", detail: "Save or share your long screenshot.")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 16)
            .accessibilityIdentifier("onboarding.screen")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PicsewPalette.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            PicsewBottomActionTray {
                Button("Continue") { model.dismissOnboarding() }
                    .buttonStyle(PicsewActionButtonStyle())
                    .accessibilityIdentifier("onboarding.continue")
            }
            .padding(.horizontal, 24)
            .background(PicsewPalette.background)
        }
        .interactiveDismissDisabled()
    }

    private func onboardingStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PicsewPalette.accent)
                .frame(width: 32, height: 32)
                .background(PicsewPalette.accent.opacity(0.08), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(PicsewPalette.ink)
                Text(detail).font(.subheadline).foregroundStyle(PicsewPalette.mutedInk)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
