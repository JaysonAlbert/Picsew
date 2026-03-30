import Observation
import PicsewAppCore
import SwiftUI

public struct ProcessingFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView(value: progressValue)
                .progressViewStyle(.linear)
                .frame(maxWidth: 260)

            Text(progressTitle)
                .font(.title2.weight(.semibold))

            Text(progressSubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            Spacer()
        }
        .padding(24)
    }

    private var progressValue: Double {
        guard let progress = model.progress else { return 0.05 }
        return Double(progress.completedStages) / Double(max(1, progress.totalStages))
    }

    private var progressTitle: String {
        guard let progress = model.progress else { return "Preparing native pipeline" }
        return title(for: progress.stage)
    }

    private var progressSubtitle: String {
        guard let progress = model.progress else {
            return "The native app is warming up the processing pipeline."
        }
        return "Step \(progress.completedStages) of \(progress.totalStages)"
    }

    private func title(for stage: PicsewAppPipelineStage) -> String {
        switch stage {
        case .metadataLoaded:
            return "Loaded video metadata"
        case .lowResolutionFramesExtracted:
            return "Extracted low-res frames"
        case .scrollingWindowDetected:
            return "Detected scrolling region"
        case .candidateKeyframesSelected:
            return "Selected candidate keyframes"
        case .cleanKeyframesFiltered:
            return "Filtered clean keyframes"
        case .fullResolutionGrayKeyframesExtracted:
            return "Loaded gray keyframes"
        case .offsetsCalculated:
            return "Calculated offsets"
        case .fullResolutionColorKeyframesExtracted:
            return "Loaded color keyframes"
        case .stitchedImageReady:
            return "Built stitched image"
        }
    }
}
