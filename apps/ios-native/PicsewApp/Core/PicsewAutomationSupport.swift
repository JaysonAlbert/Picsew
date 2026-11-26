import CoreGraphics
import CoreText
import Foundation
import PicsewAlgorithm
import PicsewAppCore
import PicsewMedia

public enum PicsewAutomationScenario: String, CaseIterable, Sendable {
    case onboarding
    case upload
    case uploadEmpty = "upload-empty"
    case uploadError = "upload-error"
    case processing
    case preview
    case previewEmpty = "preview-empty"
    case feedback
    case liveDemoUpload = "live-demo-upload"
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
              let scenario = PicsewAutomationScenario(rawValue: rawValue)
                ?? ["uploadEmpty": .uploadEmpty, "uploadError": .uploadError,
                    "previewEmpty": .previewEmpty, "liveDemoUpload": .liveDemoUpload][rawValue] else {
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
            model.errorMessage = "This video couldn't be opened. Choose another recording."

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
            // Sharing is prepared through the configured client, including failure injection.

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
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return Data(repeating: 255, count: width * height * 4)
        }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        func text(_ value: String, x: CGFloat = 80, y: CGFloat, size: CGFloat, bold: Bool = false) {
            let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, size, nil)
            let attributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key(kCTFontAttributeName as String): font,
                NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.15, alpha: 1),
            ]
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: value, attributes: attributes))
            context.saveGState()
            context.translateBy(x: x, y: y + size)
            context.scaleBy(x: 1, y: -1)
            context.textMatrix = .identity
            context.textPosition = .zero
            CTLineDraw(line, context)
            context.restoreGState()
        }

        text("FIELD NOTES", y: 80, size: 36, bold: true)
        text("A day worth keeping", y: 180, size: 76, bold: true)
        text("Little moments, all in one place.", y: 290, size: 40)
        for section in 0..<4 {
            let top = CGFloat(430 + section * 880)
            context.setFillColor(CGColor(red: 0.88, green: 0.94, blue: 0.91, alpha: 1))
            context.fill(CGRect(x: 80, y: top, width: CGFloat(width - 160), height: 330))
            context.setFillColor(CGColor(red: 0.17, green: 0.42, blue: 0.36, alpha: 1))
            context.fill(CGRect(x: 130, y: top + 200, width: CGFloat(width - 260), height: 130))
            context.setFillColor(CGColor(red: 0.50, green: 0.67, blue: 0.55, alpha: 1))
            context.fill(CGRect(x: 250, y: top + 110, width: CGFloat(width - 500), height: 220))
            text(["Take the scenic route", "Make room for small things", "Pause along the way", "Keep the whole story"][section],
                 y: top + 380, size: 48, bold: true)
            for (index, line) in [
                "Some things deserve more than a single frame.",
                "A quiet morning. A favorite place. A useful idea.",
                "Keep the details together, from start to finish.",
                "Come back whenever you need a little inspiration.",
            ].enumerated() {
                text(line, y: top + 475 + CGFloat(index * 58), size: 36)
            }
        }
        guard let data = context.data else { return Data() }
        return Data(bytes: data, count: width * height * 4)
    }

}

private enum PicsewAutomationLocalStore {
    static func seededImportedVideoURL(filename: String?) -> URL? {
        guard let filename, !filename.isEmpty,
              filename != ".", filename != "..",
              !filename.contains("/"), !filename.contains("\\") else {
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
