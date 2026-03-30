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
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color.white,
                        Color(red: 0.97, green: 0.98, blue: 1.0),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    topBar

                    if presentation.showsJourneyDots {
                        PicsewJourneyDots(activeStepIndex: presentation.activeStepIndex ?? 0)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(presentation.title)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.primary)

                        Text(presentation.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .padding(.horizontal, 20)
                .padding(.top, geometry.safeAreaInsets.top + 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("shell.route.\(route.rawValue)")
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.35, green: 0.58, blue: 1.0),
                                    Color(red: 0.56, green: 0.35, blue: 0.98),
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)

                VStack(alignment: .leading, spacing: 1) {
                    Text(appName)
                        .font(.headline.weight(.semibold))
                    Text("Native")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            Button(action: action.action) {
                Image(systemName: action.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primary)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(.white.opacity(0.6), lineWidth: 1))
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
                Circle()
                    .fill(index == activeStepIndex ? Color.accentColor : Color.primary.opacity(0.14))
                    .frame(width: index == activeStepIndex ? 9 : 7, height: index == activeStepIndex ? 9 : 7)
                    .animation(.easeInOut(duration: 0.2), value: activeStepIndex)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(Capsule(style: .continuous).stroke(.white.opacity(0.7), lineWidth: 1))
        .accessibilityIdentifier("shell.journeyDots")
    }
}

public struct PicsewStageCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 18, y: 10)
    }
}
