import Foundation

public enum PicsewPipelineStage: String, CaseIterable, Sendable {
    case metadata
    case lowResolutionFrames
    case scrollingWindow
    case keyframes
    case offsets
    case stitch
}

public struct PicsewReferenceAlgorithm: Sendable, Equatable {
    public let referenceFiles: [String]
    public let stages: [PicsewPipelineStage]

    public init(
        referenceFiles: [String] = [
            "src/lib/picsew.ts",
            "src/lib/picsew-utils.ts",
            "src/lib/opencv.ts",
        ],
        stages: [PicsewPipelineStage] = PicsewPipelineStage.allCases
    ) {
        self.referenceFiles = referenceFiles
        self.stages = stages
    }
}

public enum PicsewAlgorithmMigrationRule: String, Sendable {
    case preserveReferenceBehavior
    case validateWithFixtures
}

public struct PicsewAlgorithmBaseline: Sendable, Equatable {
    public let reference: PicsewReferenceAlgorithm
    public let rules: [PicsewAlgorithmMigrationRule]

    public init(
        reference: PicsewReferenceAlgorithm = PicsewReferenceAlgorithm(),
        rules: [PicsewAlgorithmMigrationRule] = [
            .preserveReferenceBehavior,
            .validateWithFixtures,
        ]
    ) {
        self.reference = reference
        self.rules = rules
    }
}
