import CoreGraphics
import CoreText
import Foundation
import PicsewAlgorithm
import PicsewAppCore
import PicsewMedia

public enum PicsewAutomationScenario: String, CaseIterable, Sendable {
    case onboarding
    case upload
    case uploadError = "upload-error"
    case processing
    case preview
    case previewEmpty = "preview-empty"
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

        case .uploadError:
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
            model.shareURL = PicsewAutomationFixtures.shareURL

        case .feedback:
            model.route = .feedback

        case .previewEmpty:
            model.route = .preview
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
