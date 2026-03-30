import Observation
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
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.14))
                            Image(systemName: model.selectedVideoURL == nil ? "video.badge.plus" : "checkmark.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(model.selectedVideoURL == nil ? Color.accentColor : .green)
                        }
                        .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(model.selectedVideoURL == nil ? "Import your screen recording" : "Video selected")
                                .font(.title3.weight(.semibold))
                            Text(model.selectedVideoURL?.lastPathComponent ?? "Choose one recording and Picsew will stitch it locally.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    HStack(spacing: 12) {
                        Button {
                            showsFileImporter = true
                        } label: {
                            SourceButtonLabel(title: "Files", systemImage: "folder")
                        }
                        .buttonStyle(.plain)

#if os(iOS)
                        PhotosPicker(selection: $photosPickerItem, matching: .videos) {
                            SourceButtonLabel(title: "Photos", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.plain)
#endif
                    }
                }
            }

            if model.selectedVideoURL != nil {
                PicsewStageCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ready to process")
                            .font(.headline)
                        Text("The native pipeline will detect scrolling content, select clean keyframes, and build one long screenshot on-device.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
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

    private var uploadBottomBar: some View {
        VStack(spacing: 10) {
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
            .disabled(!model.canStartProcessing)

            if model.selectedVideoURL != nil {
                Button("Choose Another Video") {
                    model.clearSelection()
                }
                .buttonStyle(.plain)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial)
    }

}

private struct SourceButtonLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title)
                .fontWeight(.semibold)
        }
        .font(.subheadline)
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.7), lineWidth: 1)
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
