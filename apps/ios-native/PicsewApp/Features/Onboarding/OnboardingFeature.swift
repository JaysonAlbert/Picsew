import Observation
import PicsewDesignSystem
import SwiftUI

public struct OnboardingFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackground()

                VStack(alignment: .leading, spacing: 22) {
                    ViewThatFits {
                        HStack(spacing: 8) {
                            PicsewInfoChip(title: "Private workflow", systemImage: "lock.fill", emphasis: true)
                            PicsewInfoChip(title: "3 quick steps", systemImage: "sparkles")
                            PicsewInfoChip(title: "Native export", systemImage: "iphone")
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            PicsewInfoChip(title: "Private workflow", systemImage: "lock.fill", emphasis: true)
                            HStack(spacing: 8) {
                                PicsewInfoChip(title: "3 quick steps", systemImage: "sparkles")
                                PicsewInfoChip(title: "Native export", systemImage: "iphone")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        PicsewHeroGlyph(systemImage: "rectangle.on.rectangle.angled", size: 82)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Welcome to Picsew")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(PicsewPalette.ink)

                            Text("Import one scrolling screen recording, let the native pipeline stitch it privately on-device, then save or share the finished long screenshot.")
                                .font(.subheadline)
                                .foregroundStyle(PicsewPalette.mutedInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text("One recording in. One long screenshot out.")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(PicsewPalette.accent)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .picsewInsetPanel(style: .emphasized)
                    }

                    PicsewStageCard(spacing: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            PicsewInfoChip(title: "How it works", systemImage: "rectangle.3.group.fill", emphasis: true)

                            onboardingStep(
                                number: "1",
                                title: "Select a screen recording",
                                detail: "Choose the clip from Files or Photos."
                            )
                            onboardingStep(
                                number: "2",
                                title: "Generate the stitched image locally",
                                detail: "Picsew detects the clean scrolling region and composes the result on-device."
                            )
                            onboardingStep(
                                number: "3",
                                title: "Save it or share it instantly",
                                detail: "Export the finished long screenshot without leaving the app."
                            )
                        }
                    }

                    Text("You can always revisit feedback later once you finish your first export.")
                        .font(.footnote)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 24)
                .padding(.top, geometry.safeAreaInsets.top + 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .accessibilityIdentifier("onboarding.screen")
            }
        }
        .safeAreaInset(edge: .bottom) {
            PicsewBottomActionTray {
                Button("Continue") {
                    model.dismissOnboarding()
                }
                .buttonStyle(PicsewProminentButtonStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("onboarding.continue")
            }
        }
        .interactiveDismissDisabled()
    }

    private func onboardingStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.headline.weight(.bold))
                .foregroundStyle(PicsewPalette.accent)
                .frame(width: 38, height: 38)
                .background(PicsewPalette.accent.opacity(0.10), in: Circle())
                .overlay(Circle().stroke(PicsewPalette.accent.opacity(0.16), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(PicsewPalette.ink)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(PicsewPalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .picsewInsetPanel()
    }
}

private struct OnboardingBackground: View {
    var body: some View {
        ZStack {
            PicsewGradients.shellBackground
                .ignoresSafeArea()

            Circle()
                .fill(PicsewPalette.accent.opacity(0.18))
                .frame(width: 340, height: 340)
                .blur(radius: 46)
                .offset(x: -110, y: -270)

            Circle()
                .fill(PicsewPalette.accentWarm.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 42)
                .offset(x: 120, y: -80)

            Circle()
                .fill(PicsewPalette.accentSecondary.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 38)
                .offset(x: 140, y: 280)
        }
        .allowsHitTesting(false)
    }
}
