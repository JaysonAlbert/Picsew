import Foundation
import PicsewAlgorithm
import PicsewAppCore
import PicsewMedia

public enum PicsewAutomationScenario: String, CaseIterable, Sendable {
    case onboarding
    case upload
    case uploadEmpty
    case uploadError
    case processing
    case preview
    case previewEmpty
    case feedback
    case liveDemoUpload
}

public enum PicsewAutomationExportBehavior: String, Sendable {
    case success
    case failure
}

public struct PicsewAutomationConfiguration: Sendable, Equatable {
    public static let scenarioKey = "picsewAutomationScenario"
    public static let seededVideoFilenameKey = "picsewAutomationSeededVideoFilename"
    public static let exportBehaviorKey = "picsewAutomationExportBehavior"

    public let scenario: PicsewAutomationScenario
    public let seededVideoFilename: String?
    public let exportBehavior: PicsewAutomationExportBehavior

    public init(
        scenario: PicsewAutomationScenario,
        seededVideoFilename: String? = nil,
        exportBehavior: PicsewAutomationExportBehavior = .success
    ) {
        self.scenario = scenario
        self.seededVideoFilename = seededVideoFilename
        self.exportBehavior = exportBehavior
    }

    public init?(arguments: [String: Any]) {
        guard let rawValue = arguments[Self.scenarioKey] as? String,
              let scenario = PicsewAutomationScenario(rawValue: rawValue) else {
            return nil
        }

        let seededVideoFilename = arguments[Self.seededVideoFilenameKey] as? String
        let exportBehavior = (arguments[Self.exportBehaviorKey] as? String)
            .flatMap(PicsewAutomationExportBehavior.init(rawValue:))
            ?? .success

        self.scenario = scenario
        self.seededVideoFilename = seededVideoFilename
        self.exportBehavior = exportBehavior
    }

    public static func current(userDefaults: UserDefaults = .standard) -> Self? {
        Self(arguments: userDefaults.dictionaryRepresentation())
    }
}

public extension PicsewAppShellModel {
    static func automationModel(
        for configuration: PicsewAutomationConfiguration,
        composition: AppComposition = .bootstrap
    ) -> PicsewAppShellModel {
        switch configuration.scenario {
        case .liveDemoUpload:
            let model = PicsewAppShellModel(
                composition: composition,
                pipeline: PicsewNativeAppPipeline(),
                systemClient: PicsewAutomationSystemClient.make(
                    exportBehavior: configuration.exportBehavior,
                    seededVideoFilename: configuration.seededVideoFilename
                ),
                route: .upload,
                showsOnboarding: false
            )

            if let seededVideoURL = PicsewAutomationLocalStore.seededImportedVideoURL(
                filename: configuration.seededVideoFilename
            ) {
                model.selectVideo(url: seededVideoURL)
            } else {
                model.errorMessage = "Seeded demo video is unavailable for automation."
            }

            return model

        default:
            return automationFixtureModel(
                for: configuration,
                composition: composition
            )
        }
    }

    static func automationModel(
        for scenario: PicsewAutomationScenario,
        composition: AppComposition = .bootstrap
    ) -> PicsewAppShellModel {
        automationModel(
            for: PicsewAutomationConfiguration(scenario: scenario),
            composition: composition
        )
    }

    private static func automationFixtureModel(
        for configuration: PicsewAutomationConfiguration,
        composition: AppComposition
    ) -> PicsewAppShellModel {
        let model = PicsewAppShellModel(
            composition: composition,
            pipeline: PicsewAutomationPipeline(),
            systemClient: PicsewAutomationSystemClient.make(
                exportBehavior: configuration.exportBehavior,
                seededVideoFilename: configuration.seededVideoFilename
            ),
            route: configuration.scenario == .feedback ? .feedback : .upload,
            showsOnboarding: configuration.scenario == .onboarding
        )

        switch configuration.scenario {
        case .onboarding:
            model.route = .upload

        case .upload:
            model.selectVideo(url: PicsewAutomationFixtures.importedVideoURL)

        case .uploadEmpty:
            model.route = .upload

        case .uploadError:
            model.route = .upload
            model.errorMessage = "Demo video import failed. Choose another recording."

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

        case .previewEmpty:
            model.route = .preview

        case .feedback:
            model.route = .feedback

        case .liveDemoUpload:
            break
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

private enum PicsewAutomationLocalStore {
    static func seededImportedVideoURL(filename: String?) -> URL? {
        guard let filename, !filename.isEmpty else {
            return nil
        }

        do {
            let directory = try ensureDirectory(named: "ImportedVideos")
            let videoURL = directory.appendingPathComponent(filename)
            return FileManager.default.fileExists(atPath: videoURL.path()) ? videoURL : nil
        } catch {
            return nil
        }
    }

    static func prepareShareFile(for stitchedImage: PicsewStitchedImage) throws -> URL {
        let exportDirectory = try ensureDirectory(named: "AutomationSharedExports")
        let exportURL = exportDirectory.appendingPathComponent("picsew-automation-share.png")
        let pngData = try stitchedImage.pngData()

        if FileManager.default.fileExists(atPath: exportURL.path()) {
            try? FileManager.default.removeItem(at: exportURL)
        }

        try pngData.write(to: exportURL, options: .atomic)
        return exportURL
    }

    private static func ensureDirectory(named component: String) throws -> URL {
        let baseDirectory = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = baseDirectory.appendingPathComponent(component, isDirectory: true)

        if !FileManager.default.fileExists(atPath: directory.path()) {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        return directory
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
    static func make(
        exportBehavior: PicsewAutomationExportBehavior = .success,
        seededVideoFilename: String? = nil
    ) -> PicsewSystemClient {
        PicsewSystemClient(
            importVideoFile: { _ in
                if let seededVideoURL = PicsewAutomationLocalStore.seededImportedVideoURL(
                    filename: seededVideoFilename
                ) {
                    return seededVideoURL
                }

                return PicsewAutomationFixtures.importedVideoURL
            },
            saveStitchedImageToPhotos: { _ in
                guard exportBehavior == .success else {
                    throw PicsewAutomationSystemClientError.exportFailed(
                        "Automation save failed."
                    )
                }
            },
            prepareShareFile: { stitchedImage in
                guard exportBehavior == .success else {
                    throw PicsewAutomationSystemClientError.exportFailed(
                        "Automation share export failed."
                    )
                }

                return try PicsewAutomationLocalStore.prepareShareFile(for: stitchedImage)
            }
        )
    }
}

private enum PicsewAutomationSystemClientError: LocalizedError {
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .exportFailed(let message):
            return message
        }
    }
}
