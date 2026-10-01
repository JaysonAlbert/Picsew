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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let appName: String
    private let route: AppRoute
    private let subtitle: String?
    private let action: PicsewShellAction
    private let content: Content

    public init(
        appName: String,
        route: AppRoute,
        subtitle: String? = nil,
        action: PicsewShellAction,
        @ViewBuilder content: () -> Content
    ) {
        self.appName = appName
        self.route = route
        self.subtitle = subtitle
        self.action = action
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            topBar

            VStack(alignment: .leading, spacing: 6) {
                Text(routeHeading)
                    .font(dynamicTypeSize.isAccessibilitySize ? .headline : .title.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(route.presentation.title)
                    .foregroundStyle(PicsewPalette.ink)
                    .accessibilityAddTraits(.isHeader)

                if !dynamicTypeSize.isAccessibilitySize {
                    Text(subtitle ?? route.presentation.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(PicsewPalette.background.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("shell.route.\(route.rawValue)")
    }

    private var routeHeading: String {
        guard dynamicTypeSize.isAccessibilitySize else { return route.presentation.title }
        switch route {
        case .upload: return "Import"
        case .processing: return "Stitching"
        case .preview: return "Preview"
        case .feedback: return "Feedback"
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(PicsewPalette.accent)
                .accessibilityHidden(true)
            Text(appName)
                .font(.headline)
                .foregroundStyle(PicsewPalette.ink)

            Spacer(minLength: 12)

            Button(action: action.action) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(PicsewPalette.mutedInk)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
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
        .background(
            PicsewPalette.surface,
            in: RoundedRectangle(cornerRadius: CGFloat(style.cornerRadius), style: .continuous)
        )
        .accessibilityElement(children: .contain)
    }
}

public struct PicsewBottomActionTray<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .padding(.vertical, 12)
        .background(PicsewPalette.background)
        .accessibilityElement(children: .contain)
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
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(PicsewPalette.accent)
            .frame(width: size, height: size)
            .background(
                PicsewPalette.accent.opacity(0.08),
                in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}
