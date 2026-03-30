import Foundation
import PicsewAlgorithm
import PicsewAppCore
import PicsewMedia

public enum PicsewAutomationScenario: String, CaseIterable, Sendable {
    case onboarding
    case upload
    case processing
    case preview
    case feedback
}

public struct PicsewAutomationConfiguration: Sendable, Equatable {
    public static let scenarioKey = "picsewAutomationScenario"

    public let scenario: PicsewAutomationScenario

    public init?(arguments: [String: Any]) {
        guard let rawValue = arguments[Self.scenarioKey] as? String,
              let scenario = PicsewAutomationScenario(rawValue: rawValue) else {
            return nil
        }

        self.scenario = scenario
    }

    public static func current(userDefaults: UserDefaults = .standard) -> Self? {
        Self(arguments: userDefaults.dictionaryRepresentation())
    }
}

public extension PicsewAppShellModel {
    static func automationModel(
        for scenario: PicsewAutomationScenario,
        composition: AppComposition = .bootstrap
    ) -> PicsewAppShellModel {
        let model = PicsewAppShellModel(
            composition: composition,
            pipeline: PicsewAutomationPipeline(),
            systemClient: PicsewAutomationSystemClient.make(),
            route: scenario == .feedback ? .feedback : .upload,
            showsOnboarding: scenario == .onboarding
        )

        switch scenario {
        case .onboarding:
            model.route = .upload

        case .upload:
            model.selectVideo(url: PicsewAutomationFixtures.importedVideoURL)

        case .processing:
            model.selectVideo(url: PicsewAutomationFixtures.importedVideoURL)
            model.route = .processing
            model.progress = PicsewAppPipelineProgress(
                stage: .offsetsCalculated,
                completedStages: 7,
                totalStages: PicsewAppPipelineStage.allCases.count
            )
            model.progressHistory = Array(PicsewAppPipelineStage.allCases.prefix(7))

        case .preview:
            model.selectVideo(url: PicsewAutomationFixtures.importedVideoURL)
            model.result = PicsewAutomationFixtures.makeResult()
            model.route = .preview
            model.shareURL = PicsewAutomationFixtures.shareURL

        case .feedback:
            model.route = .feedback
        }

        return model
    }
}

private enum PicsewAutomationFixtures {
    static let importedVideoURL = URL(fileURLWithPath: "/tmp/picsew-automation-input.mov")
    static let shareURL = URL(fileURLWithPath: "/tmp/picsew-automation-share.png")

    static func makeResult() -> PicsewAppPipelineResult {
        PicsewAppPipelineResult(
            metadata: PicsewVideoMetadata(
                width: 1179,
                height: 2556,
                durationSeconds: 6,
                frameRate: 30,
                frameIntervalSeconds: 1 / 30,
                targetFrameCount: 180
            ),
            detection: PicsewScrollingWindowDetection(
                originalFullWidthWindow: PicsewRect(x: 0, y: 248, width: 1179, height: 1890),
                refinedWindow: PicsewRect(x: 0, y: 312, width: 1179, height: 1762),
                outsideMask: PicsewOutsideMask(
                    width: 64,
                    height: 64,
                    pixels: Data(repeating: 0, count: 4_096)
                )
            ),
            selection: PicsewKeyframeSelection(candidateIndices: [0, 36, 74, 110]),
            filtered: PicsewFilteredKeyframes(cleanIndices: [0, 36, 74, 110]),
            offsetCalculation: PicsewOffsetCalculation(
                offsets: [
                    PicsewStitchOffset(vOffset: 540, hOffset: 0),
                    PicsewStitchOffset(vOffset: 548, hOffset: 1),
                    PicsewStitchOffset(vOffset: 552, hOffset: 0),
                ],
                headerHeight: 312,
                footerHeight: 418,
                totalHeight: 4200
            ),
            stitchedImage: PicsewStitchedImage(
                width: 1179,
                height: 4200,
                bytesPerRow: 1179 * 4,
                pixels: makePixels(width: 1179, height: 4200)
            )
        )
    }

    private static func makePixels(width: Int, height: Int) -> Data {
        var pixels = Data(capacity: width * height * 4)

        for row in 0..<height {
            let progress = Double(row) / Double(max(1, height - 1))
            let red = UInt8((0.31 + 0.16 * progress) * 255)
            let green = UInt8((0.55 + 0.2 * progress) * 255)
            let blue = UInt8((0.97 - 0.12 * progress) * 255)

            for _ in 0..<width {
                pixels.append(red)
                pixels.append(green)
                pixels.append(blue)
                pixels.append(255)
            }
        }

        return pixels
    }
}

private struct PicsewAutomationPipeline: PicsewAppPipelineRunning {
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

        return PicsewAutomationFixtures.makeResult()
    }
}

private enum PicsewAutomationSystemClient {
    static func make() -> PicsewSystemClient {
        PicsewSystemClient(
            importVideoFile: { _ in
                PicsewAutomationFixtures.importedVideoURL
            },
            saveStitchedImageToPhotos: { _ in
            },
            prepareShareFile: { _ in
                PicsewAutomationFixtures.shareURL
            }
        )
    }
}
