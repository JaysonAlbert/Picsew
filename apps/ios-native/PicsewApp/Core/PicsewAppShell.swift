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
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, route == .preview ? 0 : PicsewSpacing.inset.value)
                .padding(.top, route == .preview ? 0 : PicsewSpacing.medium.value)
                .background(PicsewPalette.background.ignoresSafeArea())
                .navigationTitle(navigationTitle)
#if os(iOS)
                .toolbar(.hidden, for: .navigationBar)
#endif
                .safeAreaInset(edge: .top, spacing: 0) { navigationBar }
                .tint(PicsewPalette.accent)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shell.route.\(route.rawValue)")
        }
    }

    private var navigationBar: some View {
        HStack(spacing: 0) {
            if route == .preview || route == .feedback { navigationAction }
            Spacer(minLength: 0)
            if route != .preview && route != .feedback { navigationAction }
        }
        .overlay {
            Text(navigationTitle)
                .font(PicsewTypography.heading)
                .foregroundStyle(PicsewPalette.ink)
                .accessibilityAddTraits(.isHeader)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, PicsewSpacing.inset.value)
        .frame(height: PicsewMetrics.navigationHeight)
        .dynamicTypeSize(...PicsewTypography.navigationMaximumSize)
        .background(PicsewPalette.background)
    }

    private var navigationAction: some View {
        Button(action: action.action) {
            if route == .preview {
                Text("New")
            } else {
                Image(systemName: action.systemImage)
                    .font(PicsewTypography.toolbarIcon)
            }
        }
        .buttonStyle(PicsewButtonStyle(.toolbar))
        .accessibilityLabel(action.accessibilityLabel)
        .accessibilityIdentifier(route == .preview ? "preview.newCapture" : "shell.utilityAction")
    }

    private var navigationTitle: String {
        switch route {
        case .upload: appName
        case .processing: "Stitching"
        case .preview: "Screenshot"
        case .feedback: "Feedback"
        }
    }
}

public struct PicsewJourneyDots: View {
    private let activeStepIndex: Int

    public init(activeStepIndex: Int) {
        self.activeStepIndex = activeStepIndex
    }

    public var body: some View {
        HStack(spacing: PicsewSpacing.xSmall.value) {
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
        .padding(.horizontal, PicsewSpacing.small.value)
        .padding(.vertical, PicsewSpacing.xSmall.value)
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
        HStack(spacing: PicsewSpacing.micro.value) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(PicsewTypography.badgeSymbol)
            }
            Text(title)
                .lineLimit(1)
        }
        .font(PicsewTypography.badge)
        .foregroundStyle(emphasis ? PicsewPalette.accent : PicsewPalette.mutedInk)
        .padding(.horizontal, PicsewSpacing.small.value)
        .padding(.vertical, PicsewSpacing.xSmall.value)
        .background(
            Capsule(style: .continuous)
                .fill(emphasis ? PicsewPalette.progressTrack : Color.white.opacity(0.72))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(emphasis ? PicsewPalette.accent.opacity(0.16) : Color.white.opacity(0.8), lineWidth: 1)
        )
    }
}
