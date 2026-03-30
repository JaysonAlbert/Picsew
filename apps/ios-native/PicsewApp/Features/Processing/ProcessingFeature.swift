import Observation
import PicsewAppCore
import SwiftUI

public struct ProcessingFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            PicsewStageCard {
                VStack(alignment: .center, spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 8) {
                        Text(progressTitle)
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text(progressSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    ProgressView(value: progressValue)
                        .progressViewStyle(.linear)
                        .tint(Color.accentColor)

                    Text("Everything runs locally on your device.")
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
            .accessibilityIdentifier("processing.stage.card")

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            return "The native pipeline is warming up."
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
