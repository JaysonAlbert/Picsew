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

                if let exportMessage = model.exportMessage {
                    Text(exportMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Button {
                        Task {
                            await model.saveResultToPhotos()
                        }
                    } label: {
                        Label(
                            model.isSavingResult ? "Saving..." : "Save to Photos",
                            systemImage: "square.and.arrow.down"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(model.result == nil || model.isSavingResult)

                    if let shareURL = model.shareURL {
                        ShareLink(item: shareURL) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    } else {
                        Label(
                            model.isPreparingShare ? "Preparing..." : "Share",
                            systemImage: "square.and.arrow.up"
                        )
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                Button("Process Another Video") {
                    model.clearSelection()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task(id: model.result?.stitchedImage.pixels.count) {
            await model.prepareShareIfNeeded()
        }
    }
}
