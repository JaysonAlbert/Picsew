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
                if let result = model.result {
                    PicsewStageCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Capture complete")
                                    .font(.headline.weight(.semibold))
                                Spacer()
                            }

                            if let image = result.stitchedImage.makeCGImage() {
                                Image(decorative: image, scale: 1)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                                            .stroke(.quaternary, lineWidth: 1)
                                    )
                                    .accessibilityElement()
                                    .accessibilityLabel("Stitched preview")
                                    .accessibilityAddTraits(.isImage)
                                    .accessibilityIdentifier("preview.stitchedImage")
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("preview.stage.result")

                    PicsewStageCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary")
                                .font(.headline)

                            summaryRow(title: "Image size", value: "\(result.stitchedImage.width) × \(result.stitchedImage.height)")
                            summaryRow(title: "Clean keyframes", value: "\(result.filtered.cleanIndices.count)")
                            summaryRow(title: "Detected region", value: "\(result.detection.refinedWindow.width) × \(result.detection.refinedWindow.height)")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("preview.stage.summary")
                } else {
                    Text("No stitched result is available yet.")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("preview.emptyState")
                }

                if let exportMessage = model.exportMessage {
                    Text(exportMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule(style: .continuous))
                        .accessibilityIdentifier("preview.exportMessage")
                }
            }
            .padding(.bottom, 120)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom) {
            previewBottomBar
        }
        .task(id: model.result?.stitchedImage.pixels.count) {
            await model.prepareShareIfNeeded()
        }
    }

    private var previewBottomBar: some View {
        VStack(spacing: 10) {
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
                .accessibilityIdentifier("preview.saveToPhotos")

                if let shareURL = model.shareURL {
                    ShareLink(item: shareURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .accessibilityIdentifier("preview.share")
                } else {
                    Label(
                        model.isPreparingShare ? "Preparing..." : "Share",
                        systemImage: "square.and.arrow.up"
                    )
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityIdentifier("preview.sharePlaceholder")
                }
            }

            Button("New Capture") {
                model.clearSelection()
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("preview.newCapture")
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("preview.bottomBar")
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 12)
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}
