import Foundation

public struct AppComposition: Sendable, Equatable {
    public let appName: String
    public let featureOrder: [AppRoute]

    public init(appName: String, featureOrder: [AppRoute]) {
        self.appName = appName
        self.featureOrder = featureOrder
    }

    public static let bootstrap = AppComposition(
        appName: "Picsew",
        featureOrder: [
            .upload,
            .processing,
            .preview,
            .feedback,
        ]
    )
}
