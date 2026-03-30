import PicsewDesignSystem
import SwiftUI

public struct PicsewShellAction {
    public let systemImage: String
    public let accessibilityLabel: String
    public let action: () -> Void

    public init(systemImage: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
}

public struct PicsewAppShell<Content: View>: View {
    private let appName: String
    private let route: AppRoute
    private let action: PicsewShellAction
    private let content: Content

    public init(
        appName: String,
        route: AppRoute,
        action: PicsewShellAction,
        @ViewBuilder content: () -> Content
    ) {
        self.appName = appName
        self.route = route
        self.action = action
        self.content = content()
    }

    public var body: some View {
        GeometryReader { geometry in
            let presentation = route.presentation

            ZStack {
                PicsewAtmosphericBackground()

                VStack(alignment: .leading, spacing: 16) {
                    topBar

                    if presentation.showsJourneyDots {
                        HStack(alignment: .center, spacing: 12) {
                            PicsewJourneyDots(activeStepIndex: presentation.activeStepIndex ?? 0)
                            Spacer(minLength: 12)
                            VStack(alignment: .trailing, spacing: 3) {
                                if let journeyLabel = presentation.journeyLabel {
                                    Text(journeyLabel.uppercased())
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(PicsewPalette.accent)
                                }

                                if let activeStepIndex = presentation.activeStepIndex {
                                    Text("Step \(activeStepIndex + 1) of 3")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(PicsewPalette.mutedInk)
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(presentation.title)
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                            .foregroundStyle(PicsewPalette.ink)

                        Text(presentation.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(PicsewPalette.mutedInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding(.horizontal, 20)
                .padding(.top, geometry.safeAreaInsets.top + 4)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shell.route.\(route.rawValue)")
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 12) {
                PicsewHeroGlyph(systemImage: "rectangle.on.rectangle.angled", size: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(appName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(PicsewPalette.ink)
                    Text("Private native utility")
                        .font(.caption2)
                        .foregroundStyle(PicsewPalette.mutedInk)
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.60))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.78), lineWidth: 1)
            )

            Spacer(minLength: 12)

            Button(action: action.action) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PicsewPalette.ink)
                    .frame(width: 38, height: 38)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.72))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.86), lineWidth: 1)
                    )
                    .shadow(color: PicsewPalette.shadow.opacity(0.10), radius: 14, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(action.accessibilityLabel)
            .accessibilityIdentifier("shell.utilityAction")
        }
    }
}

public struct PicsewJourneyDots: View {
    private let activeStepIndex: Int

    public init(activeStepIndex: Int) {
        self.activeStepIndex = activeStepIndex
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(index == activeStepIndex ? AnyShapeStyle(PicsewGradients.brand) : AnyShapeStyle(Color.white.opacity(0.55)))
                    .frame(width: index == activeStepIndex ? 24 : 8, height: 8)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color.white.opacity(index == activeStepIndex ? 0.18 : 0.72), lineWidth: 1)
                    )
                    .animation(.spring(response: 0.28, dampingFraction: 0.8), value: activeStepIndex)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.55))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1)
        )
        .accessibilityIdentifier("shell.journeyDots")
    }
}

public struct PicsewStageCard<Content: View>: View {
    private let style: PicsewSurfaceStyle
    private let alignment: HorizontalAlignment
    private let spacing: CGFloat
    private let content: Content

    public init(
        style: PicsewSurfaceStyle = .primaryStage,
        alignment: HorizontalAlignment = .leading,
        spacing: CGFloat = 18,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .shadow(
            color: PicsewPalette.shadow.opacity(style.shadowOpacity),
            radius: CGFloat(style.shadowRadius),
            y: CGFloat(style.shadowYOffset)
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(style.backgroundOpacity),
                                PicsewPalette.accent.opacity(style.tintOpacity),
                                PicsewPalette.accentWarm.opacity(style.tintOpacity * 0.45),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
                    .stroke(Color.white.opacity(style.borderOpacity), lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.32),
                                .clear,
                            ],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
            }
    }
}

public struct PicsewBottomActionTray<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: CGFloat(PicsewSurfaceStyle.floatingTray.cornerRadius), style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat(PicsewSurfaceStyle.floatingTray.cornerRadius), style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(PicsewSurfaceStyle.floatingTray.backgroundOpacity),
                                    PicsewPalette.accent.opacity(PicsewSurfaceStyle.floatingTray.tintOpacity),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CGFloat(PicsewSurfaceStyle.floatingTray.cornerRadius), style: .continuous)
                        .stroke(Color.white.opacity(PicsewSurfaceStyle.floatingTray.borderOpacity), lineWidth: 1)
                )
        )
        .shadow(
            color: PicsewPalette.shadow.opacity(PicsewSurfaceStyle.floatingTray.shadowOpacity),
            radius: CGFloat(PicsewSurfaceStyle.floatingTray.shadowRadius),
            y: CGFloat(PicsewSurfaceStyle.floatingTray.shadowYOffset)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

public struct PicsewInfoChip: View {
    private let title: String
    private let systemImage: String?
    private let emphasis: Bool

    public init(title: String, systemImage: String? = nil, emphasis: Bool = false) {
        self.title = title
        self.systemImage = systemImage
        self.emphasis = emphasis
    }

    public var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.semibold))
            }
            Text(title)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(emphasis ? PicsewPalette.accent : PicsewPalette.mutedInk)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule(style: .continuous)
                .fill(emphasis ? PicsewPalette.accent.opacity(0.12) : Color.white.opacity(0.72))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(emphasis ? PicsewPalette.accent.opacity(0.16) : Color.white.opacity(0.8), lineWidth: 1)
        )
    }
}

public struct PicsewHeroGlyph: View {
    private let systemImage: String
    private let size: CGFloat

    public init(systemImage: String, size: CGFloat = 58) {
        self.systemImage = systemImage
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(PicsewGradients.brand)

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: size * 0.48, height: size * 0.48)
                .offset(x: size * 0.14, y: -size * 0.14)

            Image(systemName: systemImage)
                .font(.system(size: size * 0.34, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: PicsewPalette.accent.opacity(0.18), radius: 16, y: 10)
    }
}

private struct PicsewAtmosphericBackground: View {
    var body: some View {
        ZStack {
            PicsewGradients.shellBackground
                .ignoresSafeArea()

            Circle()
                .fill(PicsewPalette.accent.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 40)
                .offset(x: -110, y: -260)

            Circle()
                .fill(PicsewPalette.accentSecondary.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 46)
                .offset(x: 160, y: -180)

            Circle()
                .fill(PicsewPalette.accentWarm.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 44)
                .offset(x: 120, y: 260)
        }
        .allowsHitTesting(false)
    }
}
