import Observation
import PicsewAppCore
import PicsewDesignSystem
import SwiftUI

public struct PreviewFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let result = model.result {
                    PicsewStageCard(spacing: 18) {
                        ViewThatFits {
                            HStack(spacing: 10) {
                                PicsewInfoChip(title: "Capture complete", systemImage: "checkmark.circle.fill", emphasis: true)
                                Spacer()
                                PicsewInfoChip(title: "Ready to export", systemImage: "square.and.arrow.up")
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                PicsewInfoChip(title: "Capture complete", systemImage: "checkmark.circle.fill", emphasis: true)
                                PicsewInfoChip(title: "Ready to export", systemImage: "square.and.arrow.up")
                            }
                        }

                        previewSurface(for: result)

                        summaryCluster(for: result)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("preview.stage.result")
                } else {
                    PicsewStageCard(style: .secondaryStage) {
                        Text("No stitched result is available yet.")
                            .foregroundStyle(PicsewPalette.mutedInk)
                            .accessibilityIdentifier("preview.emptyState")
                    }
                }

                if let exportMessage = model.exportMessage {
                    Text(exportMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .picsewInsetPanel()
                        .accessibilityIdentifier("preview.exportMessage")
                }
            }
            .padding(.bottom, 148)
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

    private func previewSurface(for result: PicsewAppPipelineResult) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(PicsewGradients.previewStage)

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            .clear,
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let image = result.stitchedImage.makeCGImage() {
                ScrollView([.vertical, .horizontal], showsIndicators: false) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color.white.opacity(0.14))

                        Image(decorative: image, scale: 1)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(Color.white.opacity(0.70), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.22), radius: 18, y: 10)
                            .padding(14)
                    }
                    .padding(16)
                        .accessibilityElement()
                        .accessibilityLabel("Stitched preview")
                        .accessibilityAddTraits(.isImage)
                }
                .frame(minHeight: 220, idealHeight: 270, maxHeight: 300)
            }
        }
        .overlay(alignment: .topLeading) {
            PicsewInfoChip(title: "Long screenshot", systemImage: "rectangle.portrait.on.rectangle.portrait")
                .padding(16)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("preview.stitchedImage")
    }

    private var previewBottomBar: some View {
        PicsewBottomActionTray {
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
                .buttonStyle(PicsewProminentButtonStyle())
                .disabled(model.result == nil || model.isSavingResult)
                .accessibilityIdentifier("preview.saveToPhotos")

                if let shareURL = model.shareURL {
                    ShareLink(item: shareURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PicsewSecondaryButtonStyle())
                    .accessibilityIdentifier("preview.share")
                } else {
                    Label(
                        model.isPreparingShare ? "Preparing..." : "Share",
                        systemImage: "square.and.arrow.up"
                    )
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PicsewPalette.mutedInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .picsewInsetPanel()
                    .accessibilityIdentifier("preview.sharePlaceholder")
                }
            }

            Button("New Capture") {
                model.clearSelection()
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(PicsewPalette.mutedInk)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("preview.newCapture")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("preview.bottomBar")
    }

    private func summaryCluster(for result: PicsewAppPipelineResult) -> some View {
        ViewThatFits {
            HStack(spacing: 10) {
                summaryTile(title: "Image", value: "\(result.stitchedImage.width) × \(result.stitchedImage.height)")
                summaryTile(title: "Keyframes", value: "\(result.filtered.cleanIndices.count)")
                summaryTile(title: "Region", value: "\(result.detection.refinedWindow.width) × \(result.detection.refinedWindow.height)")
                summaryTile(title: "Pipeline", value: "Local native")
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    summaryTile(title: "Image", value: "\(result.stitchedImage.width) × \(result.stitchedImage.height)")
                    summaryTile(title: "Keyframes", value: "\(result.filtered.cleanIndices.count)")
                }

                HStack(spacing: 10) {
                    summaryTile(title: "Region", value: "\(result.detection.refinedWindow.width) × \(result.detection.refinedWindow.height)")
                    summaryTile(title: "Pipeline", value: "Local native")
                }
            }
        }
    }

    private func summaryTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PicsewPalette.mutedInk)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PicsewPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .picsewInsetPanel()
    }
}
