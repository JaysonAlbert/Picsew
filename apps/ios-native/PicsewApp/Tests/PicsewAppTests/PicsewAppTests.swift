import Foundation
import Testing

@testable import PicsewApp
import PicsewAlgorithm
import PicsewAppCore
import PicsewMedia

@Test("route presentation keeps the expected titles and active step mapping")
func routePresentationKeepsExpectedMetadata() {
    #expect(AppRoute.upload.presentation.title == "Select a screen recording")
    #expect(AppRoute.upload.presentation.activeStepIndex == 0)

    #expect(AppRoute.processing.presentation.title == "Building your long screenshot")
    #expect(AppRoute.processing.presentation.activeStepIndex == 1)

    #expect(AppRoute.preview.presentation.title == "Long screenshot ready")
    #expect(AppRoute.preview.presentation.activeStepIndex == 2)

    #expect(AppRoute.feedback.presentation.title == "Feedback")
    #expect(AppRoute.feedback.presentation.activeStepIndex == nil)
    #expect(AppRoute.feedback.presentation.showsJourneyDots == false)
}

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

@Test("imported file selection updates the active video through the system client")
@MainActor
func importedFileSelectionUpdatesActiveVideo() async throws {
    let importedURL = URL(fileURLWithPath: "/tmp/imported-demo.mov")
    let model = PicsewAppShellModel(
        systemClient: MockSystemClient(importedVideoURL: importedURL).makeClient()
    )

    await model.importPickedVideo(from: URL(fileURLWithPath: "/tmp/source.mov"))

    #expect(model.selectedVideoURL == importedURL)
    #expect(model.errorMessage == nil)
    #expect(model.canStartProcessing)
}

@Test("share preparation stores a share URL for the current stitched result")
@MainActor
func sharePreparationStoresShareURL() async throws {
    let expectedURL = URL(fileURLWithPath: "/tmp/picsew-share.png")
    let systemClient = MockSystemClient(shareURL: expectedURL)
    let model = PicsewAppShellModel(systemClient: systemClient.makeClient())
    model.result = MockFixtures.makeResult()

    await model.prepareShareIfNeeded()

    #expect(model.shareURL == expectedURL)
    #expect(model.exportMessage == nil)
}

@Test("save delegates to the system client and reports success")
@MainActor
func saveDelegatesToSystemClient() async throws {
    let tracker = SaveTracker()
    let model = PicsewAppShellModel(
        systemClient: MockSystemClient(saveTracker: tracker).makeClient()
    )
    model.result = MockFixtures.makeResult()

    await model.saveResultToPhotos()

    #expect(await tracker.savedValue())
    #expect(model.exportMessage == "Saved to Photos.")
}

@Test("import errors surface on the shell model")
@MainActor
func importErrorsSurfaceOnShellModel() async throws {
    let model = PicsewAppShellModel(
        systemClient: MockSystemClient(importError: NSError(
            domain: "PicsewAppTests",
            code: 99,
            userInfo: [NSLocalizedDescriptionKey: "Mock import failure."]
        )).makeClient()
    )

    await model.importPickedVideo(from: URL(fileURLWithPath: "/tmp/source.mov"))

    #expect(model.selectedVideoURL == nil)
    #expect(model.errorMessage == "Mock import failure.")
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

        return MockFixtures.makeResult()
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

private enum MockFixtures {
    static func makeResult() -> PicsewAppPipelineResult {
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

private struct MockSystemClient {
    var importedVideoURL: URL = URL(fileURLWithPath: "/tmp/mock-import.mov")
    var importError: Error?
    var shareURL: URL = URL(fileURLWithPath: "/tmp/mock-share.png")
    var shareError: Error?
    var saveTracker: SaveTracker?
    var saveError: Error?

    func makeClient() -> PicsewSystemClient {
        PicsewSystemClient(
            importVideoFile: { _ in
                if let importError {
                    throw importError
                }
                return importedVideoURL
            },
            saveStitchedImageToPhotos: { _ in
                if let saveError {
                    throw saveError
                }
                await saveTracker?.markSaved()
            },
            prepareShareFile: { _ in
                if let shareError {
                    throw shareError
                }
                return shareURL
            }
        )
    }
}

actor SaveTracker {
    private(set) var didSave = false

    func markSaved() {
        didSave = true
    }

    func savedValue() -> Bool {
        didSave
    }
}
