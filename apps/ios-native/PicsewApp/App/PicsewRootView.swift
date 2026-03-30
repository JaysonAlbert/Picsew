import Observation
import SwiftUI

public struct PicsewRootView: View {
    @State private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel = PicsewAppShellModel()) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        @Bindable var bindableModel = model

        NavigationStack {
            currentRouteView
                .navigationTitle(model.composition.appName)
                .toolbar {
                    toolbarContent
                }
        }
        .sheet(isPresented: $bindableModel.showsOnboarding) {
            OnboardingFeatureView(model: model)
        }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
#if os(iOS)
        ToolbarItem(placement: .topBarTrailing) {
            toolbarButton
        }
#else
        ToolbarItem(placement: .primaryAction) {
            toolbarButton
        }
#endif
    }

    private var toolbarButton: some View {
        Group {
            if model.route != .feedback {
                Button("Feedback") {
                    model.showFeedback()
                }
            } else {
                Button("Back") {
                    model.returnToUpload()
                }
            }
        }
    }
}
