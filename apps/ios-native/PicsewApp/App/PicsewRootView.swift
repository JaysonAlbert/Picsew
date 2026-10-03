import Observation
import SwiftUI

public struct PicsewRootView: View {
    @State private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel = PicsewAppShellModel()) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        @Bindable var bindableModel = model

        PicsewAppShell(
            appName: model.composition.appName,
            route: model.route,
            action: shellAction
        ) {
            currentRouteView
        }
#if os(iOS)
        .fullScreenCover(isPresented: $bindableModel.showsOnboarding) {
            OnboardingFeatureView(model: model)
        }
#else
        .sheet(isPresented: $bindableModel.showsOnboarding) {
            OnboardingFeatureView(model: model)
        }
#endif
    }

    @ViewBuilder
    private var currentRouteView: some View {
        switch model.route {
        case .upload:
            UploadFeatureView(model: model)
        case .processing:
            ProcessingFeatureView(model: model)
        case .preview:
            PreviewFeatureView(model: model)
        case .feedback:
            FeedbackFeatureView(model: model)
        }
    }

    private var shellAction: PicsewShellAction {
        if model.route == .preview {
            PicsewShellAction(systemImage: "chevron.left", accessibilityLabel: "New Capture") {
                model.clearSelection()
            }
        } else if model.route == .feedback {
            PicsewShellAction(
                systemImage: "chevron.left",
                accessibilityLabel: "Back"
            ) {
                model.returnToUpload()
            }
        } else {
            PicsewShellAction(
                systemImage: "bubble.left.and.text.bubble.right",
                accessibilityLabel: "Feedback"
            ) {
                model.showFeedback()
            }
        }
    }
}
