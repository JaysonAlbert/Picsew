import Observation
import PicsewDesignSystem
import SwiftUI
import UniformTypeIdentifiers

#if os(iOS)
import CoreTransferable
import PhotosUI
#endif

public struct UploadFeatureView: View {
    @Bindable private var model: PicsewAppShellModel
    @State private var showsFileImporter = false

#if os(iOS)
    @State private var photosPickerItem: PhotosPickerItem?
#endif

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    PicsewStageCard(spacing: model.selectedVideoURL == nil ? 20 : 18) {
                        stageHeader

                        if let selectedVideoURL = model.selectedVideoURL {
                            selectedState(for: selectedVideoURL)
                        } else {
                            emptyState
                        }
                    }
                    .accessibilityIdentifier("upload.stage.import")

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 4)
                            .accessibilityIdentifier("upload.errorMessage")
                    }
                }
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            uploadBottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        .task(id: photosPickerItem?.itemIdentifier) {
            guard let photosPickerItem else { return }
            do {
                if let importedMovie = try await photosPickerItem.loadTransferable(type: ImportedMovieFile.self) {
                    await model.importPickedVideo(from: importedMovie.url)
                }
            } catch {
                model.errorMessage = error.localizedDescription
            }
        }
#endif
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                PicsewHeroGlyph(
                    systemImage: "video.badge.plus",
                    size: 64
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Bring in one clean screen recording")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PicsewPalette.ink)

                    Text("Choose a scrolling capture from Files or Photos. Picsew keeps the stitching pipeline private and on-device.")
                        .font(.subheadline)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            sourcePickerStack
        }
    }

    private func selectedState(for selectedVideoURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                PicsewHeroGlyph(
                    systemImage: "checkmark.circle.fill",
                    size: 56
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Ready to stitch")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PicsewPalette.ink)

                    Text("Your recording is attached and ready for the native pipeline.")
                        .font(.subheadline)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            selectedVideoPanel(for: selectedVideoURL)
        }
    }

    private var stageHeader: some View {
        ViewThatFits {
            HStack(spacing: 8) {
                PicsewInfoChip(
                    title: model.selectedVideoURL == nil ? "One clip in" : "Clip selected",
                    systemImage: model.selectedVideoURL == nil ? "video" : "checkmark.circle.fill",
                    emphasis: true
                )
                PicsewInfoChip(title: "No upload", systemImage: "icloud.slash")
                PicsewInfoChip(title: "PNG result", systemImage: "photo")
            }

            VStack(alignment: .leading, spacing: 8) {
                PicsewInfoChip(
                    title: model.selectedVideoURL == nil ? "One clip in" : "Clip selected",
                    systemImage: model.selectedVideoURL == nil ? "video" : "checkmark.circle.fill",
                    emphasis: true
                )
                HStack(spacing: 8) {
                    PicsewInfoChip(title: "No upload", systemImage: "icloud.slash")
                    PicsewInfoChip(title: "PNG result", systemImage: "photo")
                }
            }
        }
    }

    private var sourcePickerStack: some View {
        VStack(spacing: 12) {
            Button {
                showsFileImporter = true
            } label: {
                SourceButtonLabel(
                    title: "Browse Files",
                    subtitle: "Choose a local movie clip",
                    systemImage: "folder.fill"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("upload.source.files")

#if os(iOS)
            PhotosPicker(selection: $photosPickerItem, matching: .videos) {
                SourceButtonLabel(
                    title: "Open Photos",
                    subtitle: "Pick from the photo library",
                    systemImage: "photo.on.rectangle.angled"
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("upload.source.photos")
#endif
        }
    }

    private func selectedVideoPanel(for selectedVideoURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected clip")
                        .font(.headline)
                        .foregroundStyle(PicsewPalette.ink)

                    Text("Start processing to detect the scrolling window and build the final long screenshot locally.")
                        .font(.footnote)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                PicsewInfoChip(title: "Ready", systemImage: "sparkles", emphasis: true)
            }

            Text(selectedVideoURL.lastPathComponent)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(PicsewPalette.ink)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .picsewInsetPanel(style: .emphasized)
    }

    private var uploadBottomBar: some View {
        PicsewBottomActionTray {
            if model.selectedVideoURL == nil {
                Text("Pick one recording to unlock the native stitching pipeline.")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(PicsewPalette.mutedInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task {
                    await model.startProcessing()
                }
            } label: {
                Label("Start Processing", systemImage: "sparkles.rectangle.stack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PicsewProminentButtonStyle())
            .disabled(!model.canStartProcessing)
            .accessibilityIdentifier("upload.startProcessing")

            if model.selectedVideoURL != nil {
                Button("Choose Another Video") {
                    model.clearSelection()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PicsewPalette.mutedInk)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("upload.clearSelection")
            }
        }
        .accessibilityIdentifier("upload.bottomBar")
    }
}

private struct SourceButtonLabel: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(PicsewGradients.brand)

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PicsewPalette.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PicsewPalette.mutedInk)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(PicsewPalette.accent)
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.74), in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.84), lineWidth: 1)
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .picsewInsetPanel()
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
