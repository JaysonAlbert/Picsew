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

            PicsewStageCard(alignment: .center, spacing: 20) {
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

                progressTrack

                HStack(spacing: 10) {
                    processingMilestone(title: "Frames", index: 0)
                    processingMilestone(title: "Align", index: 1)
                    processingMilestone(title: "Export", index: 2)
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
                .fill(PicsewPalette.accent.opacity(0.10))
                .frame(width: 198, height: 198)
                .blur(radius: 10)

            Circle()
                .stroke(Color.white.opacity(0.60), lineWidth: 14)

            Circle()
                .trim(from: 0, to: max(0.08, progressValue))
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

            Circle()
                .fill(Color.white.opacity(0.66))
                .frame(width: 132, height: 132)
                .overlay(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.34),
                                    .clear,
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            VStack(spacing: 4) {
                Text("\(Int(progressValue * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PicsewPalette.ink)

                Text("Processing")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PicsewPalette.mutedInk)

                Text(currentJourneyLabel)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(PicsewPalette.accent)
            }
        }
        .frame(width: 174, height: 174)
        .padding(10)
    }

    private var progressTrack: some View {
        ZStack(alignment: .leading) {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.58))

            GeometryReader { geometry in
                Capsule(style: .continuous)
                    .fill(PicsewGradients.brand)
                    .frame(width: max(geometry.size.width * progressValue, 28))
            }
        }
        .frame(height: 10)
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.82), lineWidth: 1)
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

    private var currentJourneyLabel: String {
        switch journeySegmentIndex {
        case 0:
            "Frames"
        case 1:
            "Align"
        default:
            "Export"
        }
    }

    private var journeySegmentIndex: Int {
        guard let stage = model.progress?.stage else { return 0 }
        switch stage {
        case .metadataLoaded, .lowResolutionFramesExtracted:
            return 0
        case .scrollingWindowDetected, .candidateKeyframesSelected, .cleanKeyframesFiltered, .fullResolutionGrayKeyframesExtracted, .offsetsCalculated, .fullResolutionColorKeyframesExtracted:
            return 1
        case .stitchedImageReady:
            return 2
        }
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

    private func processingMilestone(title: String, index: Int) -> some View {
        let isActive = journeySegmentIndex == index
        let isComplete = journeySegmentIndex > index

        return VStack(spacing: 8) {
            Capsule(style: .continuous)
                .fill(
                    isActive || isComplete
                    ? AnyShapeStyle(PicsewGradients.brand)
                    : AnyShapeStyle(Color.white.opacity(0.56))
                )
                .frame(height: 8)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(isActive || isComplete ? 0.18 : 0.78), lineWidth: 1)
                )

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isActive ? PicsewPalette.accent : PicsewPalette.mutedInk)
        }
        .frame(maxWidth: .infinity)
    }
}
