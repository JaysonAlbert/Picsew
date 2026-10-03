import Foundation
import PicsewMedia

/// Restore filtered candidates only when every link has confident forward overlap.
/// A direct high score alone can be misleading after a gap in repeating content.
public struct PicsewKeyframeContinuity: Sendable {
    public init() {}

    public func restore(
        retainedIndices: [Int], candidateIndices: [Int],
        frames: [PicsewLowResolutionGrayFrame], refinedWindow: PicsewRect,
        excludedRegions: [PicsewRect] = []
    ) throws -> [Int] {
        guard let first = retainedIndices.first else { return [] }
        let ordered = Array(Set(retainedIndices)).sorted()
        guard (ordered + candidateIndices).allSatisfy({ frames.indices.contains($0) }) else {
            throw PicsewOffsetCalculationError.invalidRefinedWindow
        }
        let calculator = PicsewOffsetCalculator()
        func frame(_ index: Int) -> PicsewFullResolutionGrayFrame {
            let source = frames[index]
            return PicsewFullResolutionGrayFrame(
                index: source.index, timestampSeconds: source.timestampSeconds,
                width: source.width, height: source.height, pixels: source.pixels)
        }
        func match(_ previous: Int, _ current: Int) throws -> (offset: Int, score: Double) {
            try calculator.alignment(
                previous: frame(previous), current: frame(current), refinedWindow: refinedWindow,
                excludedRegions: excludedRegions)
        }
        var restored = [ordered.first ?? first]
        for current in ordered.dropFirst() {
            let previous = restored.last!
            let bridge = Array(Set(candidateIndices.filter { $0 > previous && $0 < current })).sorted()
            guard !bridge.isEmpty else {
                restored.append(current)
                continue
            }
            let direct = try match(previous, current)
            let chain = [previous] + bridge + [current]
            var displacement = 0
            var confident = true
            for pair in zip(chain, chain.dropFirst()) {
                let link = try match(pair.0, pair.1)
                if link.score < 0.85 || link.offset <= 0 {
                    confident = false
                    break
                }
                displacement += link.offset
            }
            if confident
                && (direct.score < 0.7
                    || abs(displacement - direct.offset) > max(2, Int(Double(refinedWindow.height) * 0.01)))
            {
                restored.append(contentsOf: bridge)
            }
            restored.append(current)
        }
        return restored
    }
}
