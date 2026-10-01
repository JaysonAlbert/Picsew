import Observation
import PicsewAppCore
import PicsewDesignSystem
import SwiftUI

public struct PreviewFeatureView: View {
    @Bindable private var model: PicsewAppShellModel
    @State private var showsDetails = false

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let result = model.result {
                        previewSurface(for: result)
                            .frame(height: max(180, min(520, geometry.size.height - 88)))

                        DisclosureGroup(isExpanded: $showsDetails) {
                            VStack(spacing: 12) {
                                detailRow("Image size", value: "\(result.stitchedImage.width) × \(result.stitchedImage.height)")
                                detailRow("Clean keyframes", value: "\(result.filtered.cleanIndices.count)")
                            }
                            .padding(.top, 12)
                        } label: {
                            Text("Result details")
                                .frame(minHeight: 44)
                        }
                        .font(.subheadline)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .tint(PicsewPalette.mutedInk)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(PicsewPalette.surface, in: RoundedRectangle(cornerRadius: 16))
                    } else {
                        PicsewStageCard {
                            Label("Create a screenshot to see it here.", systemImage: "photo")
                                .foregroundStyle(PicsewPalette.mutedInk)
                                .accessibilityIdentifier("preview.emptyState")
                        }
                    }

                    if let exportMessage = model.exportMessage {
                        Text(exportMessage)
                            .font(.subheadline)
                            .foregroundStyle(PicsewPalette.ink)
                            .accessibilityIdentifier("preview.exportMessage")
                    }
                }
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom) { previewBottomBar }
        .task(id: model.result?.stitchedImage.pixels.count) {
            await model.prepareShareIfNeeded()
        }
    }

    private func previewSurface(for result: PicsewAppPipelineResult) -> some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                if let image = result.stitchedImage.makeCGImage() {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: geometry.size.width)
                        .accessibilityElement(children: .ignore)
                        .accessibilityHidden(false)
                        .accessibilityLabel("Stitched preview")
                        .accessibilityAddTraits(.isImage)
                }
            }
            .background(PicsewPalette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("preview.stitchedImage")
        }
    }

    private var previewBottomBar: some View {
        PicsewBottomActionTray {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { exportActions }
                VStack(spacing: 12) { exportActions }
            }

            Button { model.clearSelection() } label: {
                Text("Start over")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PicsewPalette.mutedInk)
                .accessibilityLabel("New Capture")
                .accessibilityIdentifier("preview.newCapture")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("preview.bottomBar")
    }

    @ViewBuilder
    private var exportActions: some View {
        Button {
            Task { await model.saveResultToPhotos() }
        } label: {
            Label(model.isSavingResult ? "Saving…" : "Save", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(PicsewActionButtonStyle())
        .disabled(model.result == nil || model.isSavingResult)
        .accessibilityLabel(model.isSavingResult ? "Saving to Photos" : "Save to Photos")
        .accessibilityIdentifier("preview.saveToPhotos")

        if let shareURL = model.shareURL {
            ShareLink(item: shareURL) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PicsewActionButtonStyle(prominent: false))
            .accessibilityIdentifier("preview.share")
        } else {
            Button {} label: {
                Label(model.isPreparingShare ? "Preparing…" : "Share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PicsewActionButtonStyle(prominent: false))
            .disabled(true)
            .accessibilityIdentifier("preview.sharePlaceholder")
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(PicsewPalette.ink)
        }
        .accessibilityElement(children: .combine)
    }
}
