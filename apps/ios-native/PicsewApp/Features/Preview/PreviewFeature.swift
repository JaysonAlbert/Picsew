import Observation
import SwiftUI

public struct PreviewFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Long screenshot ready")
                    .font(.largeTitle.weight(.bold))

                if let result = model.result {
                    if let image = result.stitchedImage.makeCGImage() {
                        Image(decorative: image, scale: 1)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(.quaternary, lineWidth: 1)
                            )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Result")
                            .font(.headline)
                        Text("Image size: \(result.stitchedImage.width) × \(result.stitchedImage.height)")
                        Text("Clean keyframes: \(result.filtered.cleanIndices.count)")
                        Text("Detected region: \(result.detection.refinedWindow.width) × \(result.detection.refinedWindow.height)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                    Text("No stitched result is available yet.")
                        .foregroundStyle(.secondary)
                }

                Button("Process Another Video") {
                    model.clearSelection()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
        }
    }
}
