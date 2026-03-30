import Foundation

public struct PicsewRoutePresentation: Equatable, Sendable {
    public let title: String
    public let subtitle: String
    public let activeStepIndex: Int?

    public init(title: String, subtitle: String, activeStepIndex: Int?) {
        self.title = title
        self.subtitle = subtitle
        self.activeStepIndex = activeStepIndex
    }

    public var showsJourneyDots: Bool {
        activeStepIndex != nil
    }
}

public extension AppRoute {
    var presentation: PicsewRoutePresentation {
        switch self {
        case .upload:
            PicsewRoutePresentation(
                title: "Select a screen recording",
                subtitle: "Import a video from Files or Photos to start a native capture.",
                activeStepIndex: 0
            )
        case .processing:
            PicsewRoutePresentation(
                title: "Building your long screenshot",
                subtitle: "Picsew is matching motion and stitching frames locally on your device.",
                activeStepIndex: 1
            )
        case .preview:
            PicsewRoutePresentation(
                title: "Long screenshot ready",
                subtitle: "Review the result, then save it to Photos or share it instantly.",
                activeStepIndex: 2
            )
        case .feedback:
            PicsewRoutePresentation(
                title: "Feedback",
                subtitle: "Share a bug, an idea, or anything that would make Picsew better.",
                activeStepIndex: nil
            )
        }
    }
}
