import Accelerate
import Foundation

// Both callers search identical columns: each vertical candidate is contiguous.
// Keep the complete integer search and use the original NCC for close winners.
enum PicsewVerticalCorrelation {
    static func bestMatch(template: [UInt8], search: [UInt8], width: Int) -> (score: Double, y: Int)? {
        precondition(width > 0 && !template.isEmpty && template.count % width == 0)
        precondition(search.count >= template.count && search.count % width == 0)
        let count = template.count
        let templateHeight = count / width
        let searchHeight = search.count / width
        let templateSum = template.reduce(0.0) { $0 + Double($1) }
        let templateMean = templateSum / Double(count)
        let templateVariance = template.reduce(0.0) {
            let centered = Double($1) - templateMean
            return $0 + centered * centered
        }
        guard templateVariance > 0 else { return nil }

        let templateValues = template.map { Double($0) }
        let searchValues = search.map { Double($0) }
        var sums = [Double](repeating: 0, count: searchHeight + 1)
        var squares = sums
        for row in 0..<searchHeight {
            var sum = 0.0
            var square = 0.0
            for column in 0..<width {
                let value = searchValues[row * width + column]
                sum += value
                square += value * value
            }
            sums[row + 1] = sums[row] + sum
            squares[row + 1] = squares[row] + square
        }

        var scores = [Double](repeating: -.infinity, count: searchHeight - templateHeight + 1)
        let templateSquares = templateValues.reduce(0.0) { $0 + $1 * $1 }
        templateValues.withUnsafeBufferPointer { templateBuffer in
            searchValues.withUnsafeBufferPointer { searchBuffer in
                for y in scores.indices {
                    let sum = sums[y + templateHeight] - sums[y]
                    let square = squares[y + templateHeight] - squares[y]
                    let variance = square - sum * sum / Double(count)
                    guard variance > 0 else { continue }
                    // Subtraction can lose precision for almost-constant images.
                    // Use the original centered formula in that uncommon case.
                    if variance < square * 1e-7 || templateVariance < templateSquares * 1e-7 {
                        scores[y] = scalarScore(
                            template: template, search: search, start: y * width,
                            templateMean: templateMean, templateVariance: templateVariance)
                        continue
                    }
                    var cross = 0.0
                    vDSP_dotprD(
                        templateBuffer.baseAddress!, 1, searchBuffer.baseAddress! + y * width, 1,
                        &cross, vDSP_Length(count))
                    let numerator = cross - templateSum * sum / Double(count)
                    scores[y] = numerator / sqrt(templateVariance * variance)
                }
            }
        }

        guard let maximum = scores.max(), maximum.isFinite else { return nil }
        var bestScore = -Double.infinity
        var bestY = 0
        // Re-evaluate close winners in ascending order, keeping the previous
        // scalar floating-point tie behavior rather than selecting a new seam.
        for y in scores.indices where maximum - scores[y] <= 1e-7 {
            let score = scalarScore(
                template: template, search: search, start: y * width,
                templateMean: templateMean, templateVariance: templateVariance)
            if score > bestScore {
                bestScore = score
                bestY = y
            }
        }
        return bestScore.isFinite ? (bestScore, bestY) : nil
    }

    private static func scalarScore(
        template: [UInt8], search: [UInt8], start: Int,
        templateMean: Double, templateVariance: Double
    ) -> Double {
        let window = search[start..<(start + template.count)]
        let mean = window.reduce(0.0) { $0 + Double($1) } / Double(template.count)
        let variance = window.reduce(0.0) {
            let centered = Double($1) - mean
            return $0 + centered * centered
        }
        guard variance > 0 else { return -.infinity }
        var numerator = 0.0
        for index in template.indices {
            numerator += (Double(template[index]) - templateMean) * (Double(search[start + index]) - mean)
        }
        return numerator / sqrt(templateVariance * variance)
    }
}
