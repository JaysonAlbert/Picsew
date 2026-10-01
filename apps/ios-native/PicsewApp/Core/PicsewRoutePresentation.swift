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
                title: "Create a long screenshot",
                subtitle: "Turn a scrolling recording into one image.",
                activeStepIndex: 0
            )
        case .processing:
            PicsewRoutePresentation(
                title: "Stitching your recording",
                subtitle: "Your video stays on this device.",
                activeStepIndex: 1
            )
        case .preview:
            PicsewRoutePresentation(
                title: "Your screenshot",
                subtitle: "Ready to save or share.",
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
