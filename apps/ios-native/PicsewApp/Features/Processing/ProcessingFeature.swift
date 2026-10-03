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
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: PicsewSpacing.inset.value)

                    VStack(spacing: PicsewSpacing.large.value) {
                        progressRing
                            .frame(maxWidth: .infinity)

                        Text(progressTitle)
                            .font(PicsewTypography.title)
                            .foregroundStyle(PicsewPalette.ink)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Keep Picsew open. We'll take care of the rest.")
                            .font(PicsewTypography.supporting)
                            .foregroundStyle(PicsewPalette.mutedInk)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("processing.stage.card")

                    Spacer(minLength: PicsewSpacing.inset.value)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(PicsewPalette.progressTrack, lineWidth: PicsewMetrics.progressLineWidth)
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(PicsewPalette.accent, style: StrokeStyle(lineWidth: PicsewMetrics.progressLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progressValue * 100))%")
                .font(PicsewTypography.metric)
                .monospacedDigit()
                .foregroundStyle(PicsewPalette.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(PicsewSpacing.small.value)
        }
        .frame(width: PicsewMetrics.progressDiameter, height: PicsewMetrics.progressDiameter)
        .padding(PicsewSpacing.xSmall.value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stitching progress")
        .accessibilityValue("\(Int(progressValue * 100)) percent")
    }

    private var progressValue: Double {
        guard let progress = model.progress else { return 0 }
        return min(1, max(0, Double(progress.completedStages) / Double(max(1, progress.totalStages))))
    }

    private var progressTitle: String {
        guard let progress = model.progress else { return "Getting ready" }
        switch progress.stage {
        case .metadataLoaded, .lowResolutionFramesExtracted:
            return "Reading your recording"
        case .scrollingWindowDetected:
            return "Finding the scrolling area"
        case .candidateKeyframesSelected, .cleanKeyframesFiltered:
            return "Choosing the clearest frames"
        case .fullResolutionGrayKeyframesExtracted, .offsetsCalculated:
            return "Aligning your screenshot"
        case .fullResolutionColorKeyframesExtracted:
            return "Adding the finishing touches"
        case .stitchedImageReady:
            return "Your screenshot is ready"
        }
    }
}
