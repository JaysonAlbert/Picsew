import Foundation
import PicsewAlgorithm

public struct PicsewSystemClient: Sendable {
    public var importVideoFile: @Sendable (URL) async throws -> URL
    public var saveStitchedImageToPhotos: @Sendable (PicsewStitchedImage) async throws -> Void
    public var prepareShareFile: @Sendable (PicsewStitchedImage) async throws -> URL

    public init(
        importVideoFile: @escaping @Sendable (URL) async throws -> URL,
        saveStitchedImageToPhotos: @escaping @Sendable (PicsewStitchedImage) async throws -> Void,
        prepareShareFile: @escaping @Sendable (PicsewStitchedImage) async throws -> URL
    ) {
        self.importVideoFile = importVideoFile
        self.saveStitchedImageToPhotos = saveStitchedImageToPhotos
        self.prepareShareFile = prepareShareFile
    }

    public static let unavailable = PicsewSystemClient(
        importVideoFile: { _ in
            throw PicsewSystemClientError.unavailable("Video import is unavailable in this build.")
        },
        saveStitchedImageToPhotos: { _ in
            throw PicsewSystemClientError.unavailable("Saving to Photos is unavailable in this build.")
        },
        prepareShareFile: { _ in
            throw PicsewSystemClientError.unavailable("Sharing is unavailable in this build.")
        }
    )
}

public enum PicsewSystemClientError: LocalizedError, Sendable {
    case unavailable(String)

    public var errorDescription: String? {
        switch self {
        case .unavailable(let message):
            return message
        }
    }
}
