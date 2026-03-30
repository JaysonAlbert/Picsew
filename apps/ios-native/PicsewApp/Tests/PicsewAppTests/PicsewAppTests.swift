import Foundation
import Testing

@testable import PicsewApp
import PicsewAlgorithm
import PicsewAppCore
import PicsewMedia

@Test("shell model transitions from upload to preview on pipeline success")
@MainActor
func shellTransitionsToPreviewOnSuccess() async throws {
    let model = PicsewAppShellModel(
        pipeline: MockSuccessPipeline()
    )

    model.selectVideo(url: URL(fileURLWithPath: "/tmp/demo.mp4"))
    await model.startProcessing()

    #expect(model.route == .preview)
    #expect(model.result != nil)
    #expect(model.errorMessage == nil)
    #expect(model.progressHistory == PicsewAppPipelineStage.allCases)
    #expect(model.progress?.stage == .stitchedImageReady)
}

@Test("shell model returns to upload with an error on pipeline failure")
@MainActor
func shellReturnsToUploadOnFailure() async throws {
    let model = PicsewAppShellModel(
        pipeline: MockFailurePipeline()
    )

    model.selectVideo(url: URL(fileURLWithPath: "/tmp/demo.mp4"))
    await model.startProcessing()

    #expect(model.route == .upload)
    #expect(model.result == nil)
    #expect(model.errorMessage == "Mock pipeline failure.")
}

@Test("stitched image preview adapter builds a cg image")
func stitchedImagePreviewAdapterBuildsCGImage() {
    let image = PicsewStitchedImage(
        width: 2,
        height: 2,
        bytesPerRow: 8,
        pixels: Data([
            255, 0, 0, 255, 0, 255, 0, 255,
            0, 0, 255, 255, 255, 255, 255, 255,
        ])
    )

    let cgImage = image.makeCGImage()

    #expect(cgImage != nil)
    #expect(cgImage?.width == 2)
    #expect(cgImage?.height == 2)
}

private struct MockSuccessPipeline: PicsewAppPipelineRunning {
    func run(
        videoURL: URL,
        onProgress: (@Sendable (PicsewAppPipelineProgress) -> Void)?
    ) async throws -> PicsewAppPipelineResult {
        for (index, stage) in PicsewAppPipelineStage.allCases.enumerated() {
            onProgress?(
                PicsewAppPipelineProgress(
                    stage: stage,
                    completedStages: index + 1,
                    totalStages: PicsewAppPipelineStage.allCases.count
                )
            )
            await Task.yield()
        }

        return makeResult()
    }

    private func makeResult() -> PicsewAppPipelineResult {
        PicsewAppPipelineResult(
            metadata: PicsewVideoMetadata(
                width: 100,
                height: 200,
                durationSeconds: 3,
                frameRate: 6,
                frameIntervalSeconds: 1 / 6,
                targetFrameCount: 18
            ),
            detection: PicsewScrollingWindowDetection(
                originalFullWidthWindow: PicsewRect(x: 0, y: 20, width: 100, height: 120),
                refinedWindow: PicsewRect(x: 0, y: 30, width: 100, height: 100),
                outsideMask: PicsewOutsideMask(
                    width: 50,
                    height: 100,
                    pixels: Data(repeating: 0, count: 5_000)
                )
            ),
            selection: PicsewKeyframeSelection(candidateIndices: [0, 5, 9]),
            filtered: PicsewFilteredKeyframes(cleanIndices: [0, 5, 9]),
            offsetCalculation: PicsewOffsetCalculation(
                offsets: [
                    PicsewStitchOffset(vOffset: 20, hOffset: 0),
                    PicsewStitchOffset(vOffset: 20, hOffset: 0),
                ],
                headerHeight: 30,
                footerHeight: 70,
                totalHeight: 220
            ),
            stitchedImage: PicsewStitchedImage(
                width: 100,
                height: 220,
                bytesPerRow: 400,
                pixels: Data(repeating: 255, count: 88_000)
            )
        )
    }
}

private struct MockFailurePipeline: PicsewAppPipelineRunning {
    func run(
        videoURL: URL,
        onProgress: (@Sendable (PicsewAppPipelineProgress) -> Void)?
    ) async throws -> PicsewAppPipelineResult {
        throw NSError(
            domain: "PicsewAppTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Mock pipeline failure."]
        )
    }
}
