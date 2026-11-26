import Observation
import PicsewDesignSystem
import SwiftUI

public struct FeedbackFeatureView: View {
    @Bindable private var model: PicsewAppShellModel
    @AppStorage("picsew.feedback.lastDraft") private var lastFeedbackDraft = ""
    @FocusState private var editorIsFocused: Bool
    @State private var message = ""
    @State private var showsConfirmation = false

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        ScrollView {
            PicsewStageCard {
                VStack(alignment: .leading, spacing: PicsewSpacing.medium.value) {
                    Label("Help improve Picsew", systemImage: "bubble.left.and.text.bubble.right")
                        .font(PicsewTypography.heading)
                        .foregroundStyle(PicsewPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Save a note on this device, or send feedback on GitHub.")
                        .font(PicsewTypography.supporting)
                        .foregroundStyle(PicsewPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                    TextEditor(text: $message)
                        .focused($editorIsFocused)
                        .font(PicsewTypography.body)
                        .foregroundStyle(PicsewPalette.ink)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120, maxHeight: 180)
                        .padding(PicsewSpacing.xSmall.value)
                        .background(PicsewPalette.background,
                                    in: RoundedRectangle(cornerRadius: PicsewCornerRadius.small.rawValue))
                        .overlay {
                            RoundedRectangle(cornerRadius: PicsewCornerRadius.small.rawValue)
                                .stroke(PicsewPalette.border, lineWidth: 1)
                        }
                        .accessibilityLabel("Feedback draft")
                        .accessibilityHint("Enter at least ten characters to save a draft.")
                        .accessibilityIdentifier("feedback.message")
                    Button("Save draft") {
                        lastFeedbackDraft = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        showsConfirmation = true
                    }
                    .buttonStyle(PicsewButtonStyle(.secondary))
                    .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).count < 10)
                    .accessibilityIdentifier("feedback.saveDraft")
                    if showsConfirmation {
                        Text("Draft saved on this device.")
                            .font(PicsewTypography.supporting)
                            .foregroundStyle(PicsewPalette.success)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityIdentifier("feedback.confirmation")
                    }
                    Link("Send feedback", destination: URL(string: "https://github.com/JaysonAlbert/Picsew/issues/new")!)
                        .buttonStyle(PicsewButtonStyle(.primary))
                        .accessibilityLabel("Send feedback on GitHub")
                        .accessibilityIdentifier("feedback.send")
                }
            }
            .accessibilityIdentifier("feedback.placeholder")
            .padding(.bottom, PicsewSpacing.medium.value)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { editorIsFocused = false }
                    .accessibilityIdentifier("feedback.dismissKeyboard")
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear { message = lastFeedbackDraft }
        .onChange(of: message) { showsConfirmation = false }
    }
}
