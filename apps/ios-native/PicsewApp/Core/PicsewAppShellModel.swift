import Foundation
import Observation
import PicsewAppCore

@MainActor
@Observable
public final class PicsewAppShellModel {
    public let composition: AppComposition

    public var route: AppRoute
    public var showsOnboarding: Bool
    public var selectedVideoURL: URL?
    public var progress: PicsewAppPipelineProgress?
    public var progressHistory: [PicsewAppPipelineStage]
    public var result: PicsewAppPipelineResult?
    public var errorMessage: String?
    public var isRunning: Bool

    private let pipeline: any PicsewAppPipelineRunning

    public init(
        composition: AppComposition = .bootstrap,
        pipeline: any PicsewAppPipelineRunning = PicsewNativeAppPipeline(),
        route: AppRoute = .upload,
        showsOnboarding: Bool = true
    ) {
        self.composition = composition
        self.pipeline = pipeline
        self.route = route
        self.showsOnboarding = showsOnboarding
        self.selectedVideoURL = nil
        self.progress = nil
        self.progressHistory = []
        self.result = nil
        self.errorMessage = nil
        self.isRunning = false
    }

    public var canStartProcessing: Bool {
        selectedVideoURL != nil && !isRunning
    }

    public func dismissOnboarding() {
        showsOnboarding = false
    }

    public func selectVideo(url: URL) {
        selectedVideoURL = url
        errorMessage = nil
        result = nil
        route = .upload
    }

    public func clearSelection() {
        selectedVideoURL = nil
        progress = nil
        progressHistory = []
        result = nil
        errorMessage = nil
        isRunning = false
        route = .upload
    }

    public func showFeedback() {
        route = .feedback
    }

    public func returnToUpload() {
        route = .upload
    }

    public func startProcessing() async {
        guard let selectedVideoURL else {
            errorMessage = "Select a video before processing."
            return
        }

        route = .processing
        isRunning = true
        errorMessage = nil
        result = nil
        progress = nil
        progressHistory = []

        let progressBridge = ProgressBridge { [weak self] progress in
            guard let self else { return }
            self.progress = progress
            self.progressHistory.append(progress.stage)
        }

        do {
            let pipelineResult = try await pipeline.run(
                videoURL: selectedVideoURL,
                onProgress: progressBridge.callback
            )
            result = pipelineResult
            route = .preview
        } catch {
            errorMessage = error.localizedDescription
            route = .upload
        }

        isRunning = false
    }
}

private final class ProgressBridge: @unchecked Sendable {
    private let update: @MainActor (PicsewAppPipelineProgress) -> Void

    init(update: @escaping @MainActor (PicsewAppPipelineProgress) -> Void) {
        self.update = update
    }

    var callback: @Sendable (PicsewAppPipelineProgress) -> Void {
        { [bridge = self] progress in
            Task { @MainActor in
                bridge.update(progress)
            }
        }
    }
}
