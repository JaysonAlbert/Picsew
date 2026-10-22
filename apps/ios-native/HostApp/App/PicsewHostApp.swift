import Foundation
import Photos
import PicsewApp
import PicsewAlgorithm
import SwiftUI

@main
struct PicsewHostApp: App {
    var body: some Scene {
        WindowGroup {
            PicsewRootView(model: PicsewHostEnvironment.makeModel())
        }
    }
}

private enum PicsewHostEnvironment {
    @MainActor
    static func makeModel() -> PicsewAppShellModel {
        if let automation = PicsewAutomationConfiguration.current() {
            return PicsewAppShellModel.automationModel(for: automation)
        }

        return PicsewAppShellModel(systemClient: makeSystemClient())
    }

    static func makeSystemClient() -> PicsewSystemClient {
        PicsewSystemClient(
            importVideoFile: { sourceURL in
                try HostFileStore.importVideoFile(from: sourceURL)
            },
            saveStitchedImageToPhotos: { stitchedImage in
                try await HostExporter.saveToPhotoLibrary(stitchedImage)
            },
            prepareShareFile: { stitchedImage in
                try HostExporter.prepareShareFile(for: stitchedImage)
            }
        )
    }
}

private enum HostFileStore {
    static func importVideoFile(from sourceURL: URL) throws -> URL {
        let destinationDirectory = try ensureDirectory(named: "ImportedVideos")
        let destinationURL = destinationDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(sourceURL.pathExtension)

        let didAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        if FileManager.default.fileExists(atPath: destinationURL.path()) {
            try? FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    static func ensureDirectory(named component: String) throws -> URL {
        let baseDirectory = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = baseDirectory.appendingPathComponent(component, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path()) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
    }
}

private enum HostExporter {
    static func prepareShareFile(for stitchedImage: PicsewStitchedImage) throws -> URL {
        let exportDirectory = try HostFileStore.ensureDirectory(named: "SharedExports")
        let exportURL = exportDirectory.appendingPathComponent("picsew-\(UUID().uuidString).png")
        let pngData = try stitchedImage.pngData()

        if FileManager.default.fileExists(atPath: exportURL.path()) {
            try? FileManager.default.removeItem(at: exportURL)
        }

        try pngData.write(to: exportURL, options: .atomic)
        return exportURL
    }

    static func saveToPhotoLibrary(_ stitchedImage: PicsewStitchedImage) async throws {
        let pngData = try stitchedImage.pngData()
        let authorizationStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)

        guard authorizationStatus == .authorized || authorizationStatus == .limited else {
            throw HostExporterError.photoLibraryAccessDenied
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: pngData, options: nil)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HostExporterError.photoLibrarySaveFailed)
                }
            })
        }
    }
}

private enum HostExporterError: LocalizedError {
    case photoLibraryAccessDenied
    case photoLibrarySaveFailed

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo Library access is required to save the long screenshot."
        case .photoLibrarySaveFailed:
            return "The long screenshot could not be saved to Photos."
        }
    }
}
