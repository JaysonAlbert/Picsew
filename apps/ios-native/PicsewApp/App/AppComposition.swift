import Foundation

struct AppComposition {
    let appName: String
    let featureOrder: [String]

    static let bootstrap = AppComposition(
        appName: "Picsew",
        featureOrder: [
            "Onboarding",
            "Upload",
            "Processing",
            "Preview",
            "Feedback",
        ]
    )
}
