import Observation
import SwiftUI

public struct FeedbackFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Feedback")
                .font(.largeTitle.weight(.bold))

            Text("This route is ready for the future native feedback form. For now it keeps the app shell flow complete.")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("Back to Upload") {
                model.returnToUpload()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding(24)
    }
}
