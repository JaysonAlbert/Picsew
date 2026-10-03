import Observation
import PicsewDesignSystem
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import CoreTransferable
import PhotosUI
#endif

public struct UploadFeatureView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Bindable private var model: PicsewAppShellModel
    @State private var showsFileImporter = false

#if os(iOS)
    @State private var photosPickerItem: PhotosPickerItem?
#endif

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PicsewSpacing.medium.value) {
                PicsewStageCard(alignment: .center, spacing: PicsewSpacing.inset.value) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        PicsewHeroGlyph(
                            systemImage: model.selectedVideoURL == nil ? "video.badge.plus" : "checkmark",
                            size: PicsewMetrics.heroGlyphSize
                        )
                        .frame(maxWidth: .infinity)
                    }

                    VStack(spacing: PicsewSpacing.micro.value) {
                        Text(model.selectedVideoURL == nil ? "Choose a recording" : "Ready to stitch")
                            .font(PicsewTypography.title)
                            .foregroundStyle(PicsewPalette.ink)

                        Text(model.selectedVideoURL?.lastPathComponent ?? "Select a video from Files or Photos.")
                            .font(PicsewTypography.supporting)
                            .foregroundStyle(PicsewPalette.mutedInk)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: PicsewSpacing.small.value) { sourceChoices }
                        VStack(spacing: PicsewSpacing.small.value) { sourceChoices }
                    }
                }
                .accessibilityIdentifier("upload.stage.import")

                Label("Processed on your device. Never uploaded.", systemImage: "lock")
                    .font(PicsewTypography.caption)
                    .foregroundStyle(PicsewPalette.mutedInk)
                    .frame(maxWidth: .infinity)

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .font(PicsewTypography.supporting)
                        .foregroundStyle(PicsewPalette.ink)
                        .accessibilityIdentifier("upload.errorMessage")
                }
            }
            .padding(.bottom, PicsewSpacing.medium.value)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .safeAreaInset(edge: .bottom) {
            uploadBottomBar
        }
        .fileImporter(
            isPresented: $showsFileImporter,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await model.importPickedVideo(from: url)
                    }
                }
            case .failure(let error):
                model.errorMessage = error.localizedDescription
            }
        }
#if os(iOS)
        .task(id: photosPickerItem) {
            guard let photosPickerItem else { return }
            do {
                let importedMovie = try await photosPickerItem.loadTransferable(type: ImportedMovieFile.self)
                guard !Task.isCancelled, photosPickerItem == self.photosPickerItem else { return }
                guard let importedMovie else {
                    model.errorMessage = "This video could not be imported. Try another video or Files."
                    return
                }
                await model.importPickedVideo(from: importedMovie.url)
            } catch {
                guard !Task.isCancelled else { return }
                model.errorMessage = error.localizedDescription
            }
        }
#endif
    }

    @ViewBuilder
    private var sourceChoices: some View {
        Button {
            showsFileImporter = true
        } label: {
            SourceButtonLabel(title: "Files", systemImage: "folder")
        }
        .buttonStyle(PicsewButtonStyle(.secondary))
        .accessibilityIdentifier("upload.source.files")

#if os(iOS)
        PhotosPicker(selection: $photosPickerItem, matching: .videos) {
            SourceButtonLabel(title: "Photos", systemImage: "photo.on.rectangle")
        }
        .buttonStyle(PicsewButtonStyle(.secondary))
        .accessibilityIdentifier("upload.source.photos")
#endif
    }

    private var uploadBottomBar: some View {
        PicsewBottomActionTray {
            Button {
                Task {
                    await model.startProcessing()
                }
            } label: {
                Label(dynamicTypeSize.isAccessibilitySize ? "Create" : "Create screenshot", systemImage: "rectangle.stack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PicsewButtonStyle(.primary))
            .disabled(!model.canStartProcessing)
            .accessibilityLabel("Create screenshot")
            .accessibilityIdentifier("upload.startProcessing")

            if model.selectedVideoURL != nil {
                Button {
                    model.clearSelection()
#if os(iOS)
                    photosPickerItem = nil
#endif
                } label: {
                    Text(dynamicTypeSize.isAccessibilitySize ? "Clear" : "Choose Another Video")
                        .frame(maxWidth: .infinity, minHeight: PicsewMetrics.touchTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PicsewButtonStyle(.quiet))
                .accessibilityLabel("Choose another video")
                .accessibilityIdentifier("upload.clearSelection")
            }
        }
        .accessibilityIdentifier("upload.bottomBar")
    }
}

private struct SourceButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
    }
}

#if os(iOS)
private struct ImportedMovieFile: Transferable, Equatable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .movie) { received in
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(received.file.pathExtension)

            if FileManager.default.fileExists(atPath: destination.path()) {
                try? FileManager.default.removeItem(at: destination)
            }

            try FileManager.default.copyItem(at: received.file, to: destination)
            return ImportedMovieFile(url: destination)
        }
    }
}
#endif
