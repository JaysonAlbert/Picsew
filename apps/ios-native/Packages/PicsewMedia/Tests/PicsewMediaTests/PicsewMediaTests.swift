import Foundation
import Testing

@testable import PicsewMedia

@Test("frame extraction request keeps the TypeScript baseline defaults")
func frameExtractionRequestDefaults() {
    let asset = PicsewVideoAssetDescriptor(
        identifier: "demo4",
        source: .photos,
        fileExtension: "mp4"
    )
    let request = PicsewFrameExtractionRequest.referenceBaseline

    #expect(asset.source == .photos)
    #expect(asset.fileExtension == "mp4")
    #expect(request.frameRate == 6)
    #expect(request.maxExtractFrames == 480)
    #expect(request.resizeScale == 0.5)
    #expect(request.frameLimit == nil)
}

@Test("metadata loader matches the sample video display size and cadence")
func metadataLoaderMatchesSampleVideo() async throws {
    let analyzer = PicsewMediaAnalyzer()
    let url = try sampleVideoURL()

    let metadata = try await analyzer.loadMetadata(from: url)

    #expect(metadata.width == 756)
    #expect(metadata.height == 1022)
    #expect(abs(metadata.durationSeconds - 8.923333) < 0.02)
    #expect(metadata.frameRate == 6)
    #expect(abs(metadata.frameIntervalSeconds - (1 / 6.0)) < 0.0001)
    #expect(metadata.targetFrameCount == 53)
}

@Test("low-resolution extraction produces grayscale half-scale frames")
func lowResolutionExtractionProducesGrayFrames() async throws {
    let analyzer = PicsewMediaAnalyzer()
    let url = try sampleVideoURL()
    let request = PicsewFrameExtractionRequest(
        frameRate: 6,
        maxExtractFrames: 480,
        resizeScale: 0.5,
        frameLimit: 3
    )

    let batch = try await analyzer.extractLowResolutionGrayFrames(from: url, request: request)

    #expect(batch.metadata.width == 756)
    #expect(batch.metadata.height == 1022)
    #expect(batch.frames.count == 3)
    #expect(batch.frames.allSatisfy { $0.width == 378 })
    #expect(batch.frames.allSatisfy { $0.height == 511 })
    #expect(batch.frames.allSatisfy { $0.pixels.count == 378 * 511 })
    #expect(batch.frames[0].timestampSeconds == 0)
    #expect(abs(batch.frames[1].timestampSeconds - (1 / 6.0)) < 0.0001)
}

private func sampleVideoURL(filePath: String = #filePath) throws -> URL {
    var candidate = URL(fileURLWithPath: filePath)

    for _ in 0..<10 {
        let videoURL = candidate.appendingPathComponent("test-video.mp4")
        if FileManager.default.fileExists(atPath: videoURL.path) {
            return videoURL
        }
        candidate.deleteLastPathComponent()
    }

    throw NSError(
        domain: "PicsewMediaTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not locate test-video.mp4 from test bundle path."]
    )
}
