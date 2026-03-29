import Foundation
import Testing

@testable import PicsewAlgorithm
import PicsewMedia

@Test("reference baseline keeps the expected pipeline stages")
func referenceBaselineStages() {
    let baseline = PicsewAlgorithmBaseline()

    #expect(baseline.reference.stages == [
        .metadata,
        .lowResolutionFrames,
        .scrollingWindow,
        .keyframes,
        .offsets,
        .stitch,
    ])
    #expect(baseline.rules.contains(.preserveReferenceBehavior))
    #expect(baseline.rules.contains(.validateWithFixtures))
}

@Test("scrolling window detector finds the known synthetic motion band")
func syntheticScrollingWindowDetection() throws {
    let detector = PicsewScrollingWindowDetector()
    let width = 12
    let height = 10

    let frames = [
        makeSyntheticFrame(width: width, height: height, movingRows: []),
        makeSyntheticFrame(width: width, height: height, movingRows: Array(3...6)),
        makeSyntheticFrame(width: width, height: height, movingRows: []),
    ]

    let detection = try detector.detect(
        frames: frames,
        fullResolutionWidth: 24,
        fullResolutionHeight: 20
    )

    #expect(detection.originalFullWidthWindow == PicsewRect(x: 0, y: 6, width: 24, height: 8))
    #expect(detection.refinedWindow == PicsewRect(x: 0, y: 6, width: 24, height: 8))
    #expect(detection.outsideMask.width == 12)
    #expect(detection.outsideMask.height == 10)
}

@Test("scrolling window detector returns a stable full-width window for the sample video")
func sampleVideoScrollingWindowDetection() async throws {
    let analyzer = PicsewMediaAnalyzer()
    let detector = PicsewScrollingWindowDetector()
    let url = try sampleVideoURL()

    let batch = try await analyzer.extractLowResolutionGrayFrames(from: url)
    let detection = try detector.detect(in: batch)

    #expect(detection.originalFullWidthWindow.x == 0)
    #expect(detection.originalFullWidthWindow.width == 756)
    #expect(detection.originalFullWidthWindow.y > 600)
    #expect(detection.originalFullWidthWindow.y + detection.originalFullWidthWindow.height <= 1022)

    #expect(detection.refinedWindow.x == 0)
    #expect(detection.refinedWindow.width == 756)
    #expect(detection.refinedWindow.y >= detection.originalFullWidthWindow.y)
    #expect(detection.refinedWindow.height < detection.originalFullWidthWindow.height)
    #expect(
        detection.refinedWindow.y + detection.refinedWindow.height
            <= detection.originalFullWidthWindow.y + detection.originalFullWidthWindow.height
    )
}

private func makeSyntheticFrame(
    width: Int,
    height: Int,
    movingRows: [Int]
) -> PicsewLowResolutionGrayFrame {
    var pixels = Array(repeating: UInt8(0), count: width * height)
    for row in movingRows {
        let rowStart = row * width
        for column in 2..<10 {
            pixels[rowStart + column] = 255
        }
    }

    return PicsewLowResolutionGrayFrame(
        index: 0,
        timestampSeconds: 0,
        width: width,
        height: height,
        pixels: Data(pixels)
    )
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
        domain: "PicsewAlgorithmTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not locate test-video.mp4 from test bundle path."]
    )
}
