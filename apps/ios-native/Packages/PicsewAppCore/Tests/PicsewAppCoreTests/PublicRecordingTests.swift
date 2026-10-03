import Foundation
import Testing

@testable import PicsewAppCore

@Test("public glass recording preserves the known 1400-row document")
func publicGlassRecordingPreservesDocument() async throws {
    var directory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    var fixture: URL?
    for _ in 0..<10 {
        let candidate = directory.appendingPathComponent("fixtures/floating-overlay/glass.mp4")
        if FileManager.default.fileExists(atPath: candidate.path) {
            fixture = candidate
            break
        }
        directory.deleteLastPathComponent()
    }
    let result = try await PicsewNativeAppPipeline().run(videoURL: #require(fixture))
    // Fixture geometry is documented independently: header 80 + document 1240 + footer 80.
    #expect(result.stitchedImage.width == 480)
    #expect(result.stitchedImage.height == 1400)
}
