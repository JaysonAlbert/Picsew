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
        VStack(alignment: .leading, spacing: 20) {
            Text("Select a screen recording")
                .font(.largeTitle.weight(.bold))

            Text("Import a local recording from Files or Photos, then run the native stitching pipeline.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Selected Video")
                    .font(.headline)
                Text(model.selectedVideoURL?.lastPathComponent ?? "No video selected yet")
                    .font(.subheadline)
                    .foregroundStyle(model.selectedVideoURL == nil ? .secondary : .primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 12) {
                Button {
                    showsFileImporter = true
                } label: {
                    Label("Files", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

#if os(iOS)
                PhotosPicker(selection: $photosPickerItem, matching: .videos) {
                    Label("Photos", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
#endif
            }

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
                Button("Clear Selection") {
                    model.clearSelection()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(24)
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
