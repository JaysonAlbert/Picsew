import Observation
import PicsewDesignSystem
import SwiftUI

public struct FeedbackFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PicsewStageCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        PicsewHeroGlyph(systemImage: "bubble.left.and.text.bubble.right.fill", size: 56)

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Native feedback page is next")
                                .font(.headline)
                                .foregroundStyle(PicsewPalette.ink)

                            Text("The route is in the right place, and the shared shell is already ready for a real feedback form.")
                                .font(.subheadline)
                                .foregroundStyle(PicsewPalette.mutedInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(spacing: 8) {
                        PicsewInfoChip(title: "Shell-ready", systemImage: "checkmark.circle.fill", emphasis: true)
                        PicsewInfoChip(title: "Future form", systemImage: "square.and.pencil")
                    }
                }
            }
            .accessibilityIdentifier("feedback.placeholder")

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
