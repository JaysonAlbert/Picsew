import Observation
import PicsewAppCore
import PicsewDesignSystem
import SwiftUI

public struct ProcessingFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            PicsewStageCard(alignment: .center, spacing: 22) {
                progressOrb

                VStack(spacing: 8) {
                    Text(progressTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PicsewPalette.ink)
                        .multilineTextAlignment(.center)

                    Text(progressSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)

                ProgressView(value: progressValue)
                    .progressViewStyle(.linear)
                    .tint(PicsewPalette.accent)

                ViewThatFits {
                    HStack(spacing: 8) {
                        PicsewInfoChip(title: stageCounterText, systemImage: "circle.grid.2x2.fill", emphasis: true)
                        PicsewInfoChip(title: "On-device", systemImage: "iphone")
                        PicsewInfoChip(title: "No upload", systemImage: "icloud.slash")
                    }

                    VStack(spacing: 8) {
                        PicsewInfoChip(title: stageCounterText, systemImage: "circle.grid.2x2.fill", emphasis: true)
                        HStack(spacing: 8) {
                            PicsewInfoChip(title: "On-device", systemImage: "iphone")
                            PicsewInfoChip(title: "No upload", systemImage: "icloud.slash")
                        }
                    }
                }

                Text("Keep this screen open while Picsew aligns motion, filters clean frames, and builds the final long screenshot.")
                    .font(.footnote)
                    .foregroundStyle(PicsewPalette.mutedInk)
                    .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("processing.stage.card")

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var progressOrb: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.62), lineWidth: 14)

            Circle()
                .trim(from: 0, to: max(0.06, progressValue))
                .stroke(
                    AngularGradient(
                        colors: [
                            PicsewPalette.accentSecondary,
                            PicsewPalette.accent,
                            PicsewPalette.accentWarm,
                            PicsewPalette.accentSecondary,
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(progressValue * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PicsewPalette.ink)

                Text("Processing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PicsewPalette.mutedInk)
            }
        }
        .frame(width: 174, height: 174)
        .padding(8)
        .background(
            Circle()
                .fill(Color.white.opacity(0.40))
        )
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
        guard model.progress != nil else {
            return "The native pipeline is warming up."
        }
        return "Picsew is stitching locally and updating this stage as each pass completes."
    }

    private var stageCounterText: String {
        guard let progress = model.progress else { return "Starting" }
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
