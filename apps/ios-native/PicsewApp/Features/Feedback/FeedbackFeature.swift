import Observation
import PicsewDesignSystem
import SwiftUI

public struct FeedbackFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            PicsewStageCard {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Help improve Picsew", systemImage: "bubble.left.and.text.bubble.right")
                        .font(.headline)
                        .foregroundStyle(PicsewPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Report a problem or share an idea on GitHub.")
                        .font(.subheadline)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Link("Send feedback", destination: URL(string: "https://github.com/JaysonAlbert/Picsew/issues/new")!)
                        .buttonStyle(PicsewActionButtonStyle())
                        .accessibilityLabel("Send feedback on GitHub")
                        .accessibilityIdentifier("feedback.send")
                }
            }
            .accessibilityIdentifier("feedback.placeholder")

            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
