import CoreGraphics
import Foundation
import ImageIO
import PicsewMedia
import Testing
import UniformTypeIdentifiers

@testable import PicsewAppCore

@Test(
    "local chat recording preserves document extent",
    .enabled(if: ProcessInfo.processInfo.environment["PICSEW_LOCAL_RECORDING"] != nil))
func localChatRecordingContinuity() async throws {
    let url = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["PICSEW_LOCAL_RECORDING"]))
    let timings = PipelineTimings()
    let result = try await PicsewNativeAppPipeline().run(videoURL: url) { timings.record($0.stage.rawValue) }
    let directory = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["PICSEW_LOCAL_ARTIFACTS"]))
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let image = result.stitchedImage
    let provider = try #require(CGDataProvider(data: image.pixels as CFData))
    let cgImage = try #require(
        CGImage(
            width: image.width, height: image.height, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: image.bytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent))
    let destination = try #require(
        CGImageDestinationCreateWithURL(
            directory.appendingPathComponent("stitched.png") as CFURL, UTType.png.identifier as CFString, 1, nil))
    CGImageDestinationAddImage(destination, cgImage, nil)
    #expect(CGImageDestinationFinalize(destination))
    let sourceBatch = try await PicsewMediaAnalyzer().extractFullResolutionColorKeyframes(
        from: url, keyframeIndices: [3])
    let source = try #require(sourceBatch.frames.first)
    let sourcePixels = [UInt8](source.pixels)
    let outputPixels = [UInt8](image.pixels)
    let dark = (0..<(50 * 34)).filter { pixel in
        sourcePixels[(2100 + pixel / 50) * source.bytesPerRow + (578 + pixel % 50) * 4] < 60
    }
    let light = (0..<(50 * 34)).filter { !dark.contains($0) }
    #expect(dark.count >= 200 && dark.count <= 600)
    var hits = [Int]()
    for row in 0...(image.height - 34) {
        let darkMatches = dark.filter { pixel in
            outputPixels[(row + pixel / 50) * image.bytesPerRow + (578 + pixel % 50) * 4] < 60
        }.count
        let lightErrors = light.filter { pixel in
            outputPixels[(row + pixel / 50) * image.bytesPerRow + (578 + pixel % 50) * 4] < 60
        }.count
        if Double(darkMatches) / Double(dark.count) > 0.92 && Double(lightErrors) / Double(light.count) < 0.055 {
            hits.append(row)
        }
    }
    let arrowRows = hits.enumerated().filter { index, row in index == 0 || row > hits[index - 1] + 2 }.map {
        $0.element
    }
    #expect(arrowRows.count == 1)
    #expect(arrowRows.allSatisfy { $0 > image.height - 600 })
    let diagnostics: [String: Any] = [
        "arrowRows": arrowRows,

        "width": image.width, "height": image.height, "stageSeconds": timings.snapshot(),
        "window": [
            result.detection.refinedWindow.x, result.detection.refinedWindow.y, result.detection.refinedWindow.width,
            result.detection.refinedWindow.height,
        ],
        "candidates": result.selection.candidateIndices,
        "clean": result.filtered.cleanIndices,
        "offsets": result.offsetCalculation.offsets.map { $0.vOffset },
    ]
    try JSONSerialization.data(withJSONObject: diagnostics, options: [.prettyPrinted, .sortedKeys]).write(
        to: directory.appendingPathComponent("diagnostics.json"))
    print("Native recording diagnostics: \(diagnostics)")
    // Reviewed Web output is 8108 rows. The old native pipeline loses several
    // thousand rows; this is an extent guard, supplemented by seam inspection.
    #expect(image.width == 1206)
    #expect(image.height == 8108)
}

private final class PipelineTimings: @unchecked Sendable {
    private let lock = NSLock()
    private var previous = Date()
    private var durations = [String: Double]()
    func record(_ stage: String) {
        lock.lock()
        defer { lock.unlock() }
        let now = Date()
        durations[stage] = now.timeIntervalSince(previous)
        previous = now
        print("Native stage \(stage): \(durations[stage]!)s")
    }
    func snapshot() -> [String: Double] {
        lock.lock()
        defer { lock.unlock() }
        return durations
    }
}
