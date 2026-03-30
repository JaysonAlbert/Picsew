import Foundation
import PicsewAlgorithm
import PicsewMedia

public enum PicsewAppPipelineStage: String, CaseIterable, Sendable {
    case metadataLoaded
    case lowResolutionFramesExtracted
    case scrollingWindowDetected
    case candidateKeyframesSelected
    case cleanKeyframesFiltered
    case fullResolutionGrayKeyframesExtracted
    case offsetsCalculated
    case fullResolutionColorKeyframesExtracted
    case stitchedImageReady
}

public struct PicsewAppPipelineProgress: Sendable, Equatable {
    public let stage: PicsewAppPipelineStage
    public let completedStages: Int
    public let totalStages: Int

    public init(stage: PicsewAppPipelineStage, completedStages: Int, totalStages: Int) {
        self.stage = stage
        self.completedStages = completedStages
        self.totalStages = totalStages
    }
}

public struct PicsewAppPipelineResult: Sendable, Equatable {
    public let metadata: PicsewVideoMetadata
    public let detection: PicsewScrollingWindowDetection
    public let selection: PicsewKeyframeSelection
    public let filtered: PicsewFilteredKeyframes
    public let offsetCalculation: PicsewOffsetCalculation
    public let stitchedImage: PicsewStitchedImage

    public init(
        metadata: PicsewVideoMetadata,
        detection: PicsewScrollingWindowDetection,
        selection: PicsewKeyframeSelection,
        filtered: PicsewFilteredKeyframes,
        offsetCalculation: PicsewOffsetCalculation,
        stitchedImage: PicsewStitchedImage
    ) {
        self.metadata = metadata
        self.detection = detection
        self.selection = selection
        self.filtered = filtered
        self.offsetCalculation = offsetCalculation
        self.stitchedImage = stitchedImage
    }
}

public protocol PicsewAppPipelineRunning: Sendable {
    func run(
        videoURL: URL,
        onProgress: (@Sendable (PicsewAppPipelineProgress) -> Void)?
    ) async throws -> PicsewAppPipelineResult
}

public struct PicsewNativeAppPipeline: PicsewAppPipelineRunning, Sendable {
    public let analyzer: PicsewMediaAnalyzer
    public let scrollingWindowDetector: PicsewScrollingWindowDetector
    public let keyframeSelector: PicsewKeyframeSelector
    public let keyframeFilter: PicsewKeyframeFilter
    public let offsetCalculator: PicsewOffsetCalculator
    public let stitcher: PicsewStitcher
    public let extractionRequest: PicsewFrameExtractionRequest

    public init(
        analyzer: PicsewMediaAnalyzer = PicsewMediaAnalyzer(),
        scrollingWindowDetector: PicsewScrollingWindowDetector = PicsewScrollingWindowDetector(),
        keyframeSelector: PicsewKeyframeSelector = PicsewKeyframeSelector(),
        keyframeFilter: PicsewKeyframeFilter = PicsewKeyframeFilter(),
        offsetCalculator: PicsewOffsetCalculator = PicsewOffsetCalculator(),
        stitcher: PicsewStitcher = PicsewStitcher(),
        extractionRequest: PicsewFrameExtractionRequest = .referenceBaseline
    ) {
        self.analyzer = analyzer
        self.scrollingWindowDetector = scrollingWindowDetector
        self.keyframeSelector = keyframeSelector
        self.keyframeFilter = keyframeFilter
        self.offsetCalculator = offsetCalculator
        self.stitcher = stitcher
        self.extractionRequest = extractionRequest
    }

    public func run(
        videoURL: URL,
        onProgress: (@Sendable (PicsewAppPipelineProgress) -> Void)? = nil
    ) async throws -> PicsewAppPipelineResult {
        let totalStages = PicsewAppPipelineStage.allCases.count

        func emit(_ stage: PicsewAppPipelineStage) {
            guard let onProgress else { return }
            let completed = PicsewAppPipelineStage.allCases.firstIndex(of: stage).map { $0 + 1 } ?? 0
            onProgress(
                PicsewAppPipelineProgress(
                    stage: stage,
                    completedStages: completed,
                    totalStages: totalStages
                )
            )
        }

        let metadata = try await analyzer.loadMetadata(from: videoURL, request: extractionRequest)
        emit(.metadataLoaded)

        let lowResBatch = try await analyzer.extractLowResolutionGrayFrames(
            from: videoURL,
            request: extractionRequest
        )
        emit(.lowResolutionFramesExtracted)

        let detection = try scrollingWindowDetector.detect(in: lowResBatch)
        emit(.scrollingWindowDetected)

        let selection = try keyframeSelector.selectCandidates(
            in: lowResBatch,
            refinedWindow: detection.refinedWindow
        )
        emit(.candidateKeyframesSelected)

        let filtered = try keyframeFilter.filter(
            candidateIndices: selection.candidateIndices,
            in: lowResBatch,
            outsideMask: detection.outsideMask
        )
        emit(.cleanKeyframesFiltered)

        let grayBatch = try await analyzer.extractFullResolutionGrayKeyframes(
            from: videoURL,
            keyframeIndices: filtered.cleanIndices,
            request: extractionRequest
        )
        emit(.fullResolutionGrayKeyframesExtracted)

        let offsetCalculation = try offsetCalculator.calculate(
            in: grayBatch,
            refinedWindow: detection.refinedWindow
        )
        emit(.offsetsCalculated)

        let colorBatch = try await analyzer.extractFullResolutionColorKeyframes(
            from: videoURL,
            keyframeIndices: filtered.cleanIndices,
            request: extractionRequest
        )
        emit(.fullResolutionColorKeyframesExtracted)

        let stitchedImage = try stitcher.stitch(
            in: colorBatch,
            refinedWindow: detection.refinedWindow,
            offsets: offsetCalculation
        )
        emit(.stitchedImageReady)

        return PicsewAppPipelineResult(
            metadata: metadata,
            detection: detection,
            selection: selection,
            filtered: filtered,
            offsetCalculation: offsetCalculation,
            stitchedImage: stitchedImage
        )
    }
}
