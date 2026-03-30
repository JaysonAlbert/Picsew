import Foundation
import ImageIO
import PicsewAlgorithm
import UniformTypeIdentifiers

public enum PicsewImageExportError: LocalizedError, Sendable {
    case imageEncodingFailed

    public var errorDescription: String? {
        switch self {
        case .imageEncodingFailed:
            return "The stitched image could not be exported."
        }
    }
}

public extension PicsewStitchedImage {
    func pngData() throws -> Data {
        guard let image = makeCGImage() else {
            throw PicsewImageExportError.imageEncodingFailed
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw PicsewImageExportError.imageEncodingFailed
        }

        CGImageDestinationAddImage(destination, image, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw PicsewImageExportError.imageEncodingFailed
        }

        return data as Data
    }
}
