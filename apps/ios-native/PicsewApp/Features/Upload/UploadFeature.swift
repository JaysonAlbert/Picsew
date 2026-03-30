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
        VStack(alignment: .leading, spacing: 18) {
            PicsewStageCard {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 16) {
                        PicsewHeroGlyph(
                            systemImage: model.selectedVideoURL == nil ? "video.badge.plus" : "checkmark.circle.fill",
                            size: 64
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text(model.selectedVideoURL == nil ? "Import your screen recording" : "Ready to stitch")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(PicsewPalette.ink)

                            Text(
                                model.selectedVideoURL?.lastPathComponent
                                ?? "Choose one scrolling screen recording. Picsew keeps the full pipeline on-device and turns it into one long screenshot."
                            )
                            .font(.subheadline)
                            .foregroundStyle(PicsewPalette.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    ViewThatFits {
                        HStack(spacing: 8) {
                            PicsewInfoChip(title: "Private by default", systemImage: "lock.fill", emphasis: true)
                            PicsewInfoChip(title: "No upload", systemImage: "icloud.slash")
                            PicsewInfoChip(title: "PNG result", systemImage: "photo")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            PicsewInfoChip(title: "Private by default", systemImage: "lock.fill", emphasis: true)
                            HStack(spacing: 8) {
                                PicsewInfoChip(title: "No upload", systemImage: "icloud.slash")
                                PicsewInfoChip(title: "PNG result", systemImage: "photo")
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            showsFileImporter = true
                        } label: {
                            SourceButtonLabel(
                                title: "Files",
                                subtitle: "Browse local clips",
                                systemImage: "folder.fill"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upload.source.files")

#if os(iOS)
                        PhotosPicker(selection: $photosPickerItem, matching: .videos) {
                            SourceButtonLabel(
                                title: "Photos",
                                subtitle: "Pick from library",
                                systemImage: "photo.on.rectangle.angled"
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("upload.source.photos")
#endif
                    }

                    if let selectedVideoURL = model.selectedVideoURL {
                        selectedVideoPanel(for: selectedVideoURL)
                    }
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

            Spacer(minLength: 0)
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

    private func selectedVideoPanel(for selectedVideoURL: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(PicsewPalette.success)
                Text("Selected clip")
                    .font(.headline)
                    .foregroundStyle(PicsewPalette.ink)
                Spacer()
                PicsewInfoChip(title: "Ready", systemImage: "sparkles", emphasis: true)
            }

            Text(selectedVideoURL.lastPathComponent)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PicsewPalette.ink)
                .lineLimit(2)

            Text("Next step: start processing to detect the scrolling window, filter keyframes, and stitch the final image locally.")
                .font(.footnote)
                .foregroundStyle(PicsewPalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.card.rawValue), style: .continuous)
                .fill(Color.white.opacity(0.64))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CGFloat(PicsewCornerRadius.card.rawValue), style: .continuous)
                .stroke(Color.white.opacity(0.86), lineWidth: 1)
        )
    }

    private var uploadBottomBar: some View {
        PicsewBottomActionTray {
            Button {
                Task {
                    await model.startProcessing()
                }
            } label: {
                Label("Start Processing", systemImage: "sparkles.rectangle.stack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(PicsewPalette.accent)
            .disabled(!model.canStartProcessing)
            .accessibilityIdentifier("upload.startProcessing")

            if model.selectedVideoURL != nil {
                Button("Choose Another Video") {
                    model.clearSelection()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.medium))
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(PicsewGradients.brand)

                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PicsewPalette.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(PicsewPalette.mutedInk)
            }

            Spacer(minLength: 8)

            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(PicsewPalette.mutedInk)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.84), lineWidth: 1)
        )
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
