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
            VStack(alignment: .leading, spacing: 18) {
                if let result = model.result {
                    PicsewStageCard {
                        VStack(alignment: .leading, spacing: 18) {
                            HStack(spacing: 10) {
                                PicsewInfoChip(title: "Capture complete", systemImage: "checkmark.circle.fill", emphasis: true)
                                Spacer()
                                PicsewInfoChip(title: "Ready to export", systemImage: "square.and.arrow.up")
                            }

                            previewSurface(for: result)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Result summary")
                                    .font(.headline)
                                    .foregroundStyle(PicsewPalette.ink)

                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 10),
                                        GridItem(.flexible(), spacing: 10),
                                    ],
                                    spacing: 10
                                ) {
                                    summaryTile(title: "Image size", value: "\(result.stitchedImage.width) × \(result.stitchedImage.height)")
                                    summaryTile(title: "Clean keyframes", value: "\(result.filtered.cleanIndices.count)")
                                    summaryTile(title: "Detected region", value: "\(result.detection.refinedWindow.width) × \(result.detection.refinedWindow.height)")
                                    summaryTile(title: "Pipeline", value: "Local native export")
                                }
                            }
                        }
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
                        .background(Color.white.opacity(0.74), in: Capsule(style: .continuous))
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.84), lineWidth: 1)
                        )
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
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.68), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.22), radius: 18, y: 10)
                        .padding(18)
                        .accessibilityElement()
                        .accessibilityLabel("Stitched preview")
                        .accessibilityAddTraits(.isImage)
                }
                .frame(minHeight: 300, idealHeight: 420, maxHeight: 460)
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
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(PicsewPalette.accent)
                .disabled(model.result == nil || model.isSavingResult)
                .accessibilityIdentifier("preview.saveToPhotos")

                if let shareURL = model.shareURL {
                    ShareLink(item: shareURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(PicsewPalette.accent)
                    .accessibilityIdentifier("preview.share")
                } else {
                    Label(
                        model.isPreparingShare ? "Preparing..." : "Share",
                        systemImage: "square.and.arrow.up"
                    )
                    .foregroundStyle(PicsewPalette.mutedInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.84), lineWidth: 1)
                    )
                    .accessibilityIdentifier("preview.sharePlaceholder")
                }
            }

            Button("New Capture") {
                model.clearSelection()
            }
            .buttonStyle(.plain)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(PicsewPalette.mutedInk)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("preview.newCapture")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("preview.bottomBar")
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.card.rawValue), style: .continuous)
                .fill(Color.white.opacity(0.64))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.card.rawValue), style: .continuous)
                .stroke(Color.white.opacity(0.84), lineWidth: 1)
        )
    }
}
