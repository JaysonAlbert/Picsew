import Observation
import SwiftUI

public struct FeedbackFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PicsewStageCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Native feedback page is next", systemImage: "bubble.left.and.text.bubble.right.fill")
                        .font(.headline)
                        .foregroundStyle(Color.accentColor)

                    Text("The menu entry is now in the right place for the native app shell. The next product pass can plug the full feedback form into this route without reshaping the app chrome again.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityIdentifier("feedback.placeholder")

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
