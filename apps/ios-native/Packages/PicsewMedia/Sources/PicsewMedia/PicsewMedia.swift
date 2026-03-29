import AVFoundation
import CoreGraphics
import Foundation

public enum PicsewMediaImportSource: String, Sendable, CaseIterable {
    case photos
    case files
}

public struct PicsewVideoAssetDescriptor: Sendable, Equatable {
    public let identifier: String
    public let source: PicsewMediaImportSource
    public let fileExtension: String?

    public init(
        identifier: String,
        source: PicsewMediaImportSource,
        fileExtension: String? = nil
    ) {
        self.identifier = identifier
        self.source = source
        self.fileExtension = fileExtension
    }
}

public struct PicsewVideoMetadata: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public let durationSeconds: Double
    public let frameRate: Double
    public let frameIntervalSeconds: Double
    public let targetFrameCount: Int

    public init(
        width: Int,
        height: Int,
        durationSeconds: Double,
        frameRate: Double,
        frameIntervalSeconds: Double,
        targetFrameCount: Int
    ) {
        self.width = width
        self.height = height
        self.durationSeconds = durationSeconds
        self.frameRate = frameRate
        self.frameIntervalSeconds = frameIntervalSeconds
        self.targetFrameCount = targetFrameCount
    }
}

public struct PicsewFrameExtractionRequest: Sendable, Equatable {
    public let frameRate: Double
    public let maxExtractFrames: Int
    public let resizeScale: Double
    public let frameLimit: Int?

    public init(
        frameRate: Double = 6,
        maxExtractFrames: Int = 480,
        resizeScale: Double = 0.5,
        frameLimit: Int? = nil
    ) {
        self.frameRate = frameRate
        self.maxExtractFrames = maxExtractFrames
        self.resizeScale = resizeScale
        self.frameLimit = frameLimit
    }

    public static let referenceBaseline = PicsewFrameExtractionRequest()
}

public struct PicsewLowResolutionGrayFrame: Sendable, Equatable {
    public let index: Int
    public let timestampSeconds: Double
    public let width: Int
    public let height: Int
    public let pixels: Data

    public init(
        index: Int,
        timestampSeconds: Double,
        width: Int,
        height: Int,
        pixels: Data
    ) {
        self.index = index
        self.timestampSeconds = timestampSeconds
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}

public struct PicsewLowResolutionFrameBatch: Sendable, Equatable {
    public let metadata: PicsewVideoMetadata
    public let frames: [PicsewLowResolutionGrayFrame]

    public init(metadata: PicsewVideoMetadata, frames: [PicsewLowResolutionGrayFrame]) {
        self.metadata = metadata
        self.frames = frames
    }
}

public enum PicsewMediaError: Error, LocalizedError {
    case missingVideoTrack
    case invalidImageContext
    case failedToReadFrame(Double)

    public var errorDescription: String? {
        switch self {
        case .missingVideoTrack:
            return "No video track was found in the asset."
        case .invalidImageContext:
            return "Unable to create a grayscale rendering context."
        case let .failedToReadFrame(timestamp):
            return "Unable to read a frame at \(timestamp) seconds."
        }
    }
}

public struct PicsewMediaAnalyzer: Sendable {
    public init() {}

    public func loadMetadata(
        from url: URL,
        request: PicsewFrameExtractionRequest = .referenceBaseline
    ) async throws -> PicsewVideoMetadata {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let videoTrack = try await loadVideoTrack(from: asset)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let orientedSize = naturalSize.applying(preferredTransform)
        let width = max(1, Int(abs(orientedSize.width).rounded()))
        let height = max(1, Int(abs(orientedSize.height).rounded()))
        let durationSeconds = CMTimeGetSeconds(duration)
        let frameIntervalSeconds = 1 / request.frameRate
        let targetFrameCount = min(
            Int(floor(durationSeconds * request.frameRate)),
            request.maxExtractFrames
        )

        return PicsewVideoMetadata(
            width: width,
            height: height,
            durationSeconds: durationSeconds,
            frameRate: request.frameRate,
            frameIntervalSeconds: frameIntervalSeconds,
            targetFrameCount: targetFrameCount
        )
    }

    public func extractLowResolutionGrayFrames(
        from url: URL,
        request: PicsewFrameExtractionRequest = .referenceBaseline
    ) async throws -> PicsewLowResolutionFrameBatch {
        let metadata = try await loadMetadata(from: url, request: request)
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        let extractionCount = request.frameLimit.map {
            min($0, metadata.targetFrameCount)
        } ?? metadata.targetFrameCount

        let frames = try (0..<extractionCount).map { index in
            let timestampSeconds = Double(index) * metadata.frameIntervalSeconds
            let time = CMTime(seconds: timestampSeconds, preferredTimescale: 600)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return try makeGrayFrame(
                from: cgImage,
                index: index,
                timestampSeconds: timestampSeconds,
                resizeScale: request.resizeScale
            )
        }

        return PicsewLowResolutionFrameBatch(metadata: metadata, frames: frames)
    }

    private func loadVideoTrack(from asset: AVAsset) async throws -> AVAssetTrack {
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = tracks.first else {
            throw PicsewMediaError.missingVideoTrack
        }
        return videoTrack
    }

    private func makeGrayFrame(
        from image: CGImage,
        index: Int,
        timestampSeconds: Double,
        resizeScale: Double
    ) throws -> PicsewLowResolutionGrayFrame {
        let width = max(1, Int((Double(image.width) * resizeScale).rounded()))
        let height = max(1, Int((Double(image.height) * resizeScale).rounded()))
        let bytesPerRow = width
        let colorSpace = CGColorSpaceCreateDeviceGray()

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            throw PicsewMediaError.invalidImageContext
        }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let rawData = context.data else {
            throw PicsewMediaError.failedToReadFrame(timestampSeconds)
        }

        let pixels = Data(bytes: rawData, count: bytesPerRow * height)
        return PicsewLowResolutionGrayFrame(
            index: index,
            timestampSeconds: timestampSeconds,
            width: width,
            height: height,
            pixels: pixels
        )
    }
}
