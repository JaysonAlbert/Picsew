import Observation
import SwiftUI

public struct UploadFeatureView: View {
    @Bindable private var model: PicsewAppShellModel

    public init(model: PicsewAppShellModel) {
        self.model = model
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select a screen recording")
                .font(.largeTitle.weight(.bold))

            Text("The native pipeline is ready. Pick a local video in the future app target, then process it here.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                Text("Selected Video")
                    .font(.headline)
                Text(model.selectedVideoURL?.lastPathComponent ?? "No video selected yet")
                    .font(.subheadline)
                    .foregroundStyle(model.selectedVideoURL == nil ? .secondary : .primary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }

            Button {
                Task {
                    await model.startProcessing()
                }
            } label: {
                Label("Start Processing", systemImage: "sparkles.rectangle.stack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!model.canStartProcessing)

            if model.selectedVideoURL != nil {
                Button("Clear Selection") {
                    model.clearSelection()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding(24)
    }
}
