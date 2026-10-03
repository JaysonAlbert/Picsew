import Observation
import PicsewAlgorithm
import PicsewAppCore
import PicsewDesignSystem
import SwiftUI

public struct PreviewFeatureView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        Group {
            if let result = model.result {
                StitchedImageViewport(image: result.stitchedImage)
            } else {
                ContentUnavailableView(
                    "No screenshot yet", systemImage: "photo",
                    description: Text("Choose New to select a recording."))
                    .accessibilityIdentifier("preview.emptyState")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) { previewBottomBar }
        .task(id: model.result?.stitchedImage.pixels.count) {
            await model.prepareShareIfNeeded()
        }
    }

    private var previewBottomBar: some View {
        VStack(spacing: 0) {
            if let message = model.exportMessage {
                Text(message)
                    .font(PicsewTypography.caption)
                    .foregroundStyle(PicsewPalette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, PicsewSpacing.medium.value)
                    .padding(.vertical, PicsewSpacing.xSmall.value)
                    .accessibilityIdentifier("preview.exportMessage")
            }
            HStack {
                Button {
                    Task { await model.saveResultToPhotos() }
                } label: {
                    exportLabel(model.isSavingResult ? "Saving…" : "Save", systemImage: "square.and.arrow.down")
                }
                .disabled(model.result == nil || model.isSavingResult)
                .accessibilityLabel(model.isSavingResult ? "Saving to Photos" : "Save to Photos")
                .accessibilityIdentifier("preview.saveToPhotos")

                Spacer()

                if let shareURL = model.shareURL {
                    ShareLink(item: shareURL) {
                        exportLabel("Share", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share screenshot")
                    .accessibilityIdentifier("preview.share")
                } else {
                    Button {} label: {
                        exportLabel(model.isPreparingShare ? "Preparing…" : "Share", systemImage: "square.and.arrow.up")
                    }
                    .disabled(true)
                    .accessibilityLabel(model.isPreparingShare ? "Preparing share" : "Share screenshot")
                    .accessibilityIdentifier("preview.sharePlaceholder")
                }
            }
            .buttonStyle(PicsewButtonStyle(.toolbar))
            .padding(.horizontal, PicsewSpacing.large.value)
            .padding(.vertical, PicsewSpacing.micro.value)
        }
        .background(PicsewPalette.surface)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("preview.bottomBar")
    }

    private func exportLabel(_ title: String, systemImage: String) -> some View {
        HStack(spacing: PicsewSpacing.xSmall.value) {
            Image(systemName: systemImage)
                .font(PicsewTypography.toolbarIcon)
            if !dynamicTypeSize.isAccessibilitySize { Text(title) }
        }
        .frame(minWidth: PicsewMetrics.touchTarget, minHeight: PicsewMetrics.touchTarget)
        .contentShape(Rectangle())
    }
}

private struct StitchedImageViewport: View {
    // Cache decoding in this view's state: save/share status must not reset zoom.
    @State private var cgImage: CGImage?

    init(image: PicsewStitchedImage) {
        _cgImage = State(initialValue: image.makeCGImage())
    }

    var body: some View {
        if let cgImage {
            PicsewZoomableImage(image: cgImage)
                .accessibilityIdentifier("preview.stitchedImage")
        }
    }
}
