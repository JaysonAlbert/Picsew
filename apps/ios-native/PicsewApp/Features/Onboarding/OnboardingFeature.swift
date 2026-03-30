import Observation
import SwiftUI

public struct OnboardingFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.96, blue: 1.0),
                        Color.white,
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.35, green: 0.58, blue: 1.0),
                                            Color(red: 0.56, green: 0.35, blue: 0.98),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Image(systemName: "rectangle.on.rectangle")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 72, height: 72)

                        Text("Welcome to Picsew")
                            .font(.system(size: 34, weight: .bold, design: .rounded))

                        Text("One simple flow: import a screen recording, let the native pipeline stitch it, then save or share the finished long screenshot.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    PicsewStageCard {
                        VStack(alignment: .leading, spacing: 18) {
                            onboardingStep(number: "1", title: "Select a screen recording")
                            onboardingStep(number: "2", title: "Generate the stitched image locally")
                            onboardingStep(number: "3", title: "Save it to Photos or share it")
                        }
                    }

                    Spacer()

                    Button("Continue") {
                        model.dismissOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("onboarding.continue")
                }
                .padding(.horizontal, 24)
                .padding(.top, geometry.safeAreaInsets.top + 24)
                .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 8))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .accessibilityIdentifier("onboarding.screen")
            }
        }
        .interactiveDismissDisabled()
    }

    private func onboardingStep(number: String, title: String) -> some View {
        HStack(spacing: 16) {
            Text(number)
                .font(.headline.weight(.bold))
                .frame(width: 34, height: 34)
                .background(.blue.opacity(0.12), in: Circle())
            Text(title)
                .font(.headline)
        }
    }
}
