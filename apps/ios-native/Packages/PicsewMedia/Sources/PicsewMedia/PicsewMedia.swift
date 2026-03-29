import Foundation

public enum PicsewMediaImportSource: String, Sendable, CaseIterable {
    case photos
    case files
}

public struct PicsewVideoAssetDescriptor: Sendable, Equatable {
    public let identifier: String
    public let source: PicsewMediaImportSource
    public let fileExtension: String?

    public init(
        identifier: String,
        source: PicsewMediaImportSource,
        fileExtension: String? = nil
    ) {
        self.identifier = identifier
        self.source = source
        self.fileExtension = fileExtension
    }
}

public struct PicsewFrameExtractionRequest: Sendable, Equatable {
    public let preferredLongEdge: Int
    public let targetFrameCount: Int

    public init(preferredLongEdge: Int, targetFrameCount: Int) {
        self.preferredLongEdge = preferredLongEdge
        self.targetFrameCount = targetFrameCount
    }
}
