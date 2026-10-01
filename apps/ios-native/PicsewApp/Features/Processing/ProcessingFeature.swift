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
                    Spacer(minLength: 20)

                    PicsewStageCard(alignment: .center, spacing: 24) {
                        progressRing
                            .frame(maxWidth: .infinity)

                        Text(progressTitle)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(PicsewPalette.ink)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)

                        Text("Keep Picsew open. We'll take care of the rest.")
                            .font(.subheadline)
                            .foregroundStyle(PicsewPalette.mutedInk)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .accessibilityIdentifier("processing.stage.card")

                    Spacer(minLength: 20)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(PicsewPalette.accent.opacity(0.12), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(PicsewPalette.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progressValue * 100))%")
                .font(.largeTitle.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(PicsewPalette.ink)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .padding(12)
        }
        .frame(width: 144, height: 144)
        .padding(8)
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
