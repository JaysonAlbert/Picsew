import Foundation
import Testing

@testable import PicsewAppCore

@Test("native app pipeline reports progress stages in order")
func pipelineProgressStagesAdvanceInOrder() async throws {
    let pipeline = PicsewNativeAppPipeline()
    let url = try sampleVideoURL()
    let recorder = StageRecorder()

    _ = try await pipeline.run(videoURL: url) { progress in
        recorder.append(progress.stage)
    }

    let stages = recorder.stages()
    #expect(stages == PicsewAppPipelineStage.allCases)
}

@Test("native app pipeline returns a stitched image for the sample video")
func pipelineReturnsStitchedSampleVideoResult() async throws {
    let pipeline = PicsewNativeAppPipeline()
    let url = try sampleVideoURL()

    let result = try await pipeline.run(videoURL: url, onProgress: nil)

    #expect(result.metadata.width == 756)
    #expect(result.metadata.height == 1022)
    #expect(result.selection.candidateIndices.first == 0)
    #expect(result.filtered.cleanIndices.first == result.selection.candidateIndices.first)
    #expect(Set(result.filtered.cleanIndices).isSubset(of: Set(result.selection.candidateIndices)))
    #expect(result.offsetCalculation.totalHeight == result.stitchedImage.height)
    #expect(result.stitchedImage.width == result.metadata.width)
    #expect(result.stitchedImage.bytesPerRow == result.metadata.width * 4)
    #expect(result.stitchedImage.pixels.count == result.stitchedImage.bytesPerRow * result.stitchedImage.height)
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
        domain: "PicsewAppCoreTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not locate test-video.mp4 from test bundle path."]
    )
}

private final class StageRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedStages = [PicsewAppPipelineStage]()

    func append(_ stage: PicsewAppPipelineStage) {
        lock.lock()
        recordedStages.append(stage)
        lock.unlock()
    }

    func stages() -> [PicsewAppPipelineStage] {
        lock.lock()
        defer { lock.unlock() }
        return recordedStages
    }
}
