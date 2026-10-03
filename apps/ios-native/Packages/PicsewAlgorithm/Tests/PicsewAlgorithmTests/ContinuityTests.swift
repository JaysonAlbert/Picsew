import Foundation
import PicsewMedia
import Testing

@testable import PicsewAlgorithm

@Test("filtered frames are restored only when their overlap chain proves continuity")
func filteredFramesBridgeDocumentGap() throws {
    let width = 24
    let height = 60
    let frames = [0, 40, 80].enumerated().map { index, shift in
        PicsewLowResolutionGrayFrame(
            index: index, timestampSeconds: Double(index), width: width, height: height,
            pixels: Data(
                (0..<(width * height)).map { pixel in
                    UInt8(
                        ((pixel / width + shift) * 71 + (pixel % width) * 31 + (pixel / width + shift) * (pixel % width)
                            * 13)
                            % 251)
                }))
    }
    let indices = try PicsewKeyframeContinuity().restore(
        retainedIndices: [0, 2], candidateIndices: [0, 1, 2], frames: frames,
        refinedWindow: PicsewRect(x: 0, y: 0, width: width, height: height))
    #expect(indices == [0, 1, 2])
    let fullFrames = indices.map { i in
        PicsewFullResolutionGrayFrame(
            index: i, timestampSeconds: Double(i), width: width, height: height, pixels: frames[i].pixels)
    }
    let offsets = try PicsewOffsetCalculator().calculate(
        frames: fullFrames, refinedWindow: PicsewRect(x: 0, y: 0, width: width, height: height))
    #expect(offsets.offsets.map(\.vOffset) == [40, 40])
    #expect(offsets.totalHeight == 140)
}

@Test("a consistent retained match does not restore outside-UI noise")
func consistentRetainedMatchKeepsFiltering() throws {
    let width = 24
    let height = 60
    let frames = [0, 20, 40].enumerated().map { index, shift in
        PicsewLowResolutionGrayFrame(
            index: index, timestampSeconds: Double(index), width: width, height: height,
            pixels: Data(
                (0..<(width * height)).map { pixel in
                    UInt8(
                        ((pixel / width + shift) * 71 + (pixel % width) * 31 + (pixel / width + shift) * (pixel % width)
                            * 13)
                            % 251)
                }))
    }
    #expect(
        try PicsewKeyframeContinuity().restore(
            retainedIndices: [0, 2], candidateIndices: [0, 1, 2], frames: frames,
            refinedWindow: PicsewRect(x: 0, y: 0, width: width, height: height)) == [0, 2])
}

@Test("unrelated frames cannot be reported as reliable scrolling overlap")
func unrelatedFramesRejectOverlap() throws {
    let width = 24
    let height = 60
    func pixels(seed: UInt64) -> Data {
        var state = seed
        return Data(
            (0..<(width * height)).map { _ in
                state = state &* 6_364_136_223_846_793_005 &+ 1
                return UInt8(truncatingIfNeeded: state >> 32)
            })
    }
    let frames = [1, 17, 99].enumerated().map { index, seed in
        PicsewLowResolutionGrayFrame(
            index: index, timestampSeconds: Double(index), width: width, height: height,
            pixels: pixels(seed: UInt64(seed)))
    }
    let window = PicsewRect(x: 0, y: 0, width: width, height: height)
    #expect(
        try PicsewKeyframeContinuity().restore(
            retainedIndices: [0, 2], candidateIndices: [0, 1, 2], frames: frames, refinedWindow: window) == [0, 2])
    #expect(throws: PicsewOffsetCalculationError.unreliableOverlap) {
        try PicsewOffsetCalculator().calculate(
            frames: [0, 2].map { i in
                PicsewFullResolutionGrayFrame(
                    index: i, timestampSeconds: Double(i), width: width, height: height, pixels: frames[i].pixels)
            }, refinedWindow: window, minimumConfidence: 0.7)
    }
}

@Test("fixed control masking reaches beyond the inset scrolling window")
func controlAcrossWindowBoundaryIsMasked() {
    let width = 200
    let height = 180
    let frames = (0..<8).map { index in
        var state = UInt64(index + 1)
        let pixels = (0..<(width * height)).map { at -> UInt8 in
            let x = at % width
            let y = at / width
            if x >= 96 && x < 104 && y >= 152 && y < 163 { return 0 }
            if x >= 92 && x < 108 && y >= 148 && y < 167 { return 255 }
            state = state &* 6_364_136_223_846_793_005 &+ 1
            return UInt8(truncatingIfNeeded: state >> 32)
        }
        return PicsewLowResolutionGrayFrame(
            index: index, timestampSeconds: Double(index), width: width, height: height, pixels: Data(pixels))
    }
    let controls = PicsewFloatingControls().detect(
        frames: frames, window: PicsewRect(x: 0, y: 10, width: width, height: 150))
    #expect(controls.contains { $0.x <= 96 && $0.x + $0.width >= 104 && $0.y <= 152 && $0.y + $0.height >= 163 })
}

@Test("stitched document pixels hidden by fixed controls come from aligned clean frames")
func fixedControlRecoveryPreservesDocument() throws {
    let width = 80
    let height = 60
    let control = PicsewRect(x: 30, y: 45, width: 10, height: 10)
    func document(_ x: Int, _ y: Int) -> [UInt8] { [UInt8(y + 1), UInt8(x + 1), 180, 255] }
    let frames = [0, 20, 40].enumerated().map { index, shift in
        let pixels = (0..<(width * height)).flatMap { at -> [UInt8] in
            let x = at % width
            let y = at / width
            if x >= 30 && x < 40 && y >= 45 && y < 55 { return [0, 0, 0, 255] }
            return document(x, y + shift)
        }
        return PicsewFullResolutionColorFrame(
            index: index, timestampSeconds: Double(index), width: width, height: height, bytesPerRow: width * 4,
            pixels: Data(pixels))
    }
    let stitched = try PicsewStitcher().stitch(
        frames: frames, refinedWindow: PicsewRect(x: 0, y: 0, width: width, height: height),
        offsets: PicsewOffsetCalculation(
            offsets: [PicsewStitchOffset(vOffset: 20, hOffset: 0), PicsewStitchOffset(vOffset: 20, hOffset: 0)],
            headerHeight: 0, footerHeight: 0, totalHeight: 100), floatingControls: [control])
    let pixels = [UInt8](stitched.pixels)
    #expect(stitched.height == 100)
    var mismatches = 0
    for y in 0..<85 {
        for x in 0..<width {
            let at = (y * width + x) * 4
            if Array(pixels[at..<(at + 4)]) != document(x, y) { mismatches += 1 }
        }
    }
    #expect(mismatches == 0)
    // No frame exposes the last control's background: retain original pixels.
    let at = (90 * width + 35) * 4
    #expect(Array(pixels[at..<(at + 4)]) == [0, 0, 0, 255])
}
