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

public struct PicsewFullResolutionGrayFrame: Sendable, Equatable {
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

public struct PicsewFullResolutionKeyframeBatch: Sendable, Equatable {
    public let metadata: PicsewVideoMetadata
    public let keyframeIndices: [Int]
    public let frames: [PicsewFullResolutionGrayFrame]

    public init(
        metadata: PicsewVideoMetadata,
        keyframeIndices: [Int],
        frames: [PicsewFullResolutionGrayFrame]
    ) {
        self.metadata = metadata
        self.keyframeIndices = keyframeIndices
        self.frames = frames
    }
}

public struct PicsewFullResolutionColorFrame: Sendable, Equatable {
    public let index: Int
    public let timestampSeconds: Double
    public let width: Int
    public let height: Int
    public let bytesPerRow: Int
    public let pixels: Data

    public init(
        index: Int,
        timestampSeconds: Double,
        width: Int,
        height: Int,
        bytesPerRow: Int,
        pixels: Data
    ) {
        self.index = index
        self.timestampSeconds = timestampSeconds
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
        self.pixels = pixels
    }
}

public struct PicsewFullResolutionColorKeyframeBatch: Sendable, Equatable {
    public let metadata: PicsewVideoMetadata
    public let keyframeIndices: [Int]
    public let frames: [PicsewFullResolutionColorFrame]

    public init(
        metadata: PicsewVideoMetadata,
        keyframeIndices: [Int],
        frames: [PicsewFullResolutionColorFrame]
    ) {
        self.metadata = metadata
        self.keyframeIndices = keyframeIndices
        self.frames = frames
    }
}

public enum PicsewMediaError: Error, LocalizedError {
    case missingVideoTrack
    case invalidImageContext
    case failedToReadFrame(Double)
    case invalidFrameIndex(Int)

    public var errorDescription: String? {
        switch self {
        case .missingVideoTrack:
            return "No video track was found in the asset."
        case .invalidImageContext:
            return "Unable to create a grayscale rendering context."
        case let .failedToReadFrame(timestamp):
            return "Unable to read a frame at \(timestamp) seconds."
        case let .invalidFrameIndex(index):
            return "The requested frame index \(index) is invalid."
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

    public func extractFullResolutionGrayKeyframes(
        from url: URL,
        keyframeIndices: [Int],
        request: PicsewFrameExtractionRequest = .referenceBaseline
    ) async throws -> PicsewFullResolutionKeyframeBatch {
        let metadata = try await loadMetadata(from: url, request: request)
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        let frames = try keyframeIndices.map { frameIndex in
            guard frameIndex >= 0 else {
                throw PicsewMediaError.invalidFrameIndex(frameIndex)
            }

            let timestampSeconds = Double(frameIndex) * metadata.frameIntervalSeconds
            let time = CMTime(seconds: timestampSeconds, preferredTimescale: 600)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return try makeFullResolutionGrayFrame(
                from: cgImage,
                index: frameIndex,
                timestampSeconds: timestampSeconds
            )
        }

        return PicsewFullResolutionKeyframeBatch(
            metadata: metadata,
            keyframeIndices: keyframeIndices,
            frames: frames
        )
    }

    public func extractFullResolutionColorKeyframes(
        from url: URL,
        keyframeIndices: [Int],
        request: PicsewFrameExtractionRequest = .referenceBaseline
    ) async throws -> PicsewFullResolutionColorKeyframeBatch {
        let metadata = try await loadMetadata(from: url, request: request)
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero

        let frames = try keyframeIndices.map { frameIndex in
            guard frameIndex >= 0 else {
                throw PicsewMediaError.invalidFrameIndex(frameIndex)
            }

            let timestampSeconds = Double(frameIndex) * metadata.frameIntervalSeconds
            let time = CMTime(seconds: timestampSeconds, preferredTimescale: 600)
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return try makeFullResolutionColorFrame(
                from: cgImage,
                index: frameIndex,
                timestampSeconds: timestampSeconds
            )
        }

        return PicsewFullResolutionColorKeyframeBatch(
            metadata: metadata,
            keyframeIndices: keyframeIndices,
            frames: frames
        )
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
        let raster = try makeGrayRaster(
            from: image,
            timestampSeconds: timestampSeconds,
            resizeScale: resizeScale
        )
        return PicsewLowResolutionGrayFrame(
            index: index,
            timestampSeconds: timestampSeconds,
            width: raster.width,
            height: raster.height,
            pixels: raster.pixels
        )
    }

    private func makeFullResolutionGrayFrame(
        from image: CGImage,
        index: Int,
        timestampSeconds: Double
    ) throws -> PicsewFullResolutionGrayFrame {
        let raster = try makeGrayRaster(
            from: image,
            timestampSeconds: timestampSeconds,
            resizeScale: 1
        )
        return PicsewFullResolutionGrayFrame(
            index: index,
            timestampSeconds: timestampSeconds,
            width: raster.width,
            height: raster.height,
            pixels: raster.pixels
        )
    }

    private func makeFullResolutionColorFrame(
        from image: CGImage,
        index: Int,
        timestampSeconds: Double
    ) throws -> PicsewFullResolutionColorFrame {
        let raster = try makeColorRaster(
            from: image,
            timestampSeconds: timestampSeconds
        )
        return PicsewFullResolutionColorFrame(
            index: index,
            timestampSeconds: timestampSeconds,
            width: raster.width,
            height: raster.height,
            bytesPerRow: raster.bytesPerRow,
            pixels: raster.pixels
        )
    }

    private func makeGrayRaster(
        from image: CGImage,
        timestampSeconds: Double,
        resizeScale: Double
    ) throws -> (width: Int, height: Int, pixels: Data) {
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
        // Match image-space orientation so downstream analysis lines up with
        // the browser pipeline instead of a vertically flipped buffer.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let rawData = context.data else {
            throw PicsewMediaError.failedToReadFrame(timestampSeconds)
        }

        let pixels = Data(bytes: rawData, count: bytesPerRow * height)
        return (width, height, pixels)
    }

    private func makeColorRaster(
        from image: CGImage,
        timestampSeconds: Double
    ) throws -> (width: Int, height: Int, bytesPerRow: Int, pixels: Data) {
        let width = image.width
        let height = image.height
        let bytesPerRow = width * 4
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw PicsewMediaError.invalidImageContext
        }

        context.interpolationQuality = .medium
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let rawData = context.data else {
            throw PicsewMediaError.failedToReadFrame(timestampSeconds)
        }

        let pixels = Data(bytes: rawData, count: bytesPerRow * height)
        return (width, height, bytesPerRow, pixels)
    }
}
