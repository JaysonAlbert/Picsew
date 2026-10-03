import Foundation
import PicsewMedia
import Testing

@testable import PicsewAlgorithm

// Characterize the existing public outcomes against its original centered NCC.
// Cases intentionally include ambiguous matches: optimization must keep the winner.
@Test("vertical alignment preserves scalar NCC scores and winners", arguments: 0..<8)
func alignmentScalarParity(pattern: Int) throws {
    for width in [1, 3, 17, 64] {
        let height = 39
        let templateHeight = height / 3
        let document = matchingDocument(width: width, height: height * 2, pattern: pattern)
        for shift in [0, 1, 13, 26] {
            let previous = Array(document[0..<(width * height)])
            let current = Array(document[(shift * width)..<((shift + height) * width)])
            let template = Array(previous[(width * (height - templateHeight))...])
            let expected = scalarMatch(template: template, search: current, width: width)
            let actual = try PicsewOffsetCalculator().alignment(
                previous: grayFrame(previous, width: width, height: height),
                current: grayFrame(current, width: width, height: height),
                refinedWindow: PicsewRect(x: 0, y: 0, width: width, height: height))
            #expect(actual.offset == height - templateHeight - (expected?.y ?? 0))
            #expect(abs(actual.score - (expected?.score ?? 0)) < 1e-9)
        }
    }
}

@Test("low resolution candidates preserve exhaustive scalar matching", arguments: 0..<8)
func selectionScalarParity(pattern: Int) throws {
    let width = 17
    let height = 40
    let shifts = [0, 3, 7, 12, 18, 25, 31, 34]
    let document = matchingDocument(width: width, height: height + shifts.last!, pattern: pattern)
    let pixels = shifts.map { shift in Array(document[(shift * width)..<((shift + height) * width)]) }
    let frames = pixels.enumerated().map { index, values in
        PicsewLowResolutionGrayFrame(
            index: index, timestampSeconds: Double(index), width: width, height: height, pixels: Data(values))
    }
    var expected = [0]
    var accumulated = 0
    let templateHeight = height / 4
    let templateY = height / 2 - templateHeight / 2
    for index in 1..<pixels.count {
        let template = Array(pixels[index - 1][(templateY * width)..<((templateY + templateHeight) * width)])
        if let match = scalarMatch(template: template, search: pixels[index], width: width), match.score > 0.7 {
            accumulated += max(0, templateY - match.y)
        }
        if Double(accumulated) > Double(height) * 0.5 {
            expected.append(index)
            accumulated = 0
        }
    }
    if expected.last != pixels.count - 1 { expected.append(pixels.count - 1) }
    let actual = try PicsewKeyframeSelector().selectCandidates(
        frames: frames, fullResolutionWidth: width, fullResolutionHeight: height,
        refinedWindow: PicsewRect(x: 0, y: 0, width: width, height: height))
    #expect(actual.candidateIndices == expected)
}

private func matchingDocument(width: Int, height: Int, pattern: Int) -> [UInt8] {
    var state: UInt64 = 17
    return (0..<(width * height)).map { at in
        state = state &* 6_364_136_223_846_793_005 &+ 1
        let random = Int((state >> 32) & 255)
        switch pattern {
        case 0: return UInt8(random)
        case 1: return 255  // Constant template and search: no confidence.
        case 2: return UInt8(254 + random % 2)  // Low contrast near white.
        case 3: return UInt8((at / width % 3) * 70 + at % width % 17)  // Repeated ties.
        case 4: return at / width < height / 2 ? 0 : UInt8(random)  // Blank candidate windows.
        case 5: return UInt8((at / width + at % width) % 80 + 100)  // Affine/near-tied matches.
        case 6: return UInt8(at / width % 2 == 0 ? random : 255 - random)
        default: return at % (width * 9) == 0 ? 254 : 255  // Almost-constant repeated matches.
        }
    }
}

private func grayFrame(_ pixels: [UInt8], width: Int, height: Int) -> PicsewFullResolutionGrayFrame {
    PicsewFullResolutionGrayFrame(
        index: 0, timestampSeconds: 0, width: width, height: height, pixels: Data(pixels))
}

private func scalarMatch(template: [UInt8], search: [UInt8], width: Int) -> (y: Int, score: Double)? {
    let count = template.count
    let templateMean = template.reduce(0.0) { $0 + Double($1) } / Double(count)
    let templateVariance = template.reduce(0.0) { $0 + pow(Double($1) - templateMean, 2) }
    guard templateVariance > 0 else { return nil }
    var best: (y: Int, score: Double)?
    for y in 0...((search.count - count) / width) {
        let window = search[(y * width)..<(y * width + count)]
        let mean = window.reduce(0.0) { $0 + Double($1) } / Double(count)
        let variance = window.reduce(0.0) { $0 + pow(Double($1) - mean, 2) }
        guard variance > 0 else { continue }
        var numerator = 0.0
        for index in 0..<count {
            numerator += (Double(template[index]) - templateMean) * (Double(search[y * width + index]) - mean)
        }
        let score = numerator / sqrt(templateVariance * variance)
        if score > (best?.score ?? -.infinity) { best = (y, score) }
    }
    return best
}
