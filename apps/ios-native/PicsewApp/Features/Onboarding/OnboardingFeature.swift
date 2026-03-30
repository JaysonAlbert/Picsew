import Observation
import SwiftUI

public struct OnboardingFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                Text("Welcome to Picsew")
                    .font(.largeTitle.weight(.bold))

                VStack(alignment: .leading, spacing: 16) {
                    onboardingStep(number: "1", title: "Select a screen recording")
                    onboardingStep(number: "2", title: "Run the native stitching pipeline")
                    onboardingStep(number: "3", title: "Preview the generated long screenshot")
                }

                Spacer()

                Button("Continue") {
                    model.dismissOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
        .presentationDetents([.medium])
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
