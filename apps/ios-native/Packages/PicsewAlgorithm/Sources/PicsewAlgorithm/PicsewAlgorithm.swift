import Foundation
import PicsewMedia

public enum PicsewPipelineStage: String, CaseIterable, Sendable {
    case metadata
    case lowResolutionFrames
    case scrollingWindow
    case keyframes
    case offsets
    case stitch
}

public struct PicsewReferenceAlgorithm: Sendable, Equatable {
    public let referenceFiles: [String]
    public let stages: [PicsewPipelineStage]

    public init(
        referenceFiles: [String] = [
            "src/lib/picsew.ts",
            "src/lib/picsew-utils.ts",
            "src/lib/opencv.ts",
        ],
        stages: [PicsewPipelineStage] = PicsewPipelineStage.allCases
    ) {
        self.referenceFiles = referenceFiles
        self.stages = stages
    }
}

public enum PicsewAlgorithmMigrationRule: String, Sendable {
    case preserveReferenceBehavior
    case validateWithFixtures
}

public struct PicsewAlgorithmBaseline: Sendable, Equatable {
    public let reference: PicsewReferenceAlgorithm
    public let rules: [PicsewAlgorithmMigrationRule]

    public init(
        reference: PicsewReferenceAlgorithm = PicsewReferenceAlgorithm(),
        rules: [PicsewAlgorithmMigrationRule] = [
            .preserveReferenceBehavior,
            .validateWithFixtures,
        ]
    ) {
        self.reference = reference
        self.rules = rules
    }
}

public struct PicsewRect: Sendable, Equatable {
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct PicsewOutsideMask: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public let pixels: Data

    public init(width: Int, height: Int, pixels: Data) {
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}

public struct PicsewScrollingWindowDetection: Sendable, Equatable {
    public let originalFullWidthWindow: PicsewRect
    public let refinedWindow: PicsewRect
    public let outsideMask: PicsewOutsideMask

    public init(
        originalFullWidthWindow: PicsewRect,
        refinedWindow: PicsewRect,
        outsideMask: PicsewOutsideMask
    ) {
        self.originalFullWidthWindow = originalFullWidthWindow
        self.refinedWindow = refinedWindow
        self.outsideMask = outsideMask
    }
}

public struct PicsewKeyframeSelection: Sendable, Equatable {
    public let candidateIndices: [Int]

    public init(candidateIndices: [Int]) {
        self.candidateIndices = candidateIndices
    }
}

public enum PicsewKeyframeSelectionError: Error, LocalizedError {
    case noFrames
    case invalidRefinedWindow
    case mismatchedFrameDimensions

    public var errorDescription: String? {
        switch self {
        case .noFrames:
            return "No low-resolution frames were provided for keyframe selection."
        case .invalidRefinedWindow:
            return "The refined window is outside the low-resolution frame bounds."
        case .mismatchedFrameDimensions:
            return "Low-resolution frame dimensions do not match."
        }
    }
}

public enum PicsewScrollingWindowError: Error, LocalizedError {
    case noFrames
    case mismatchedFrameDimensions
    case noConsistentMotion

    public var errorDescription: String? {
        switch self {
        case .noFrames:
            return "No valid low-resolution frames were provided."
        case .mismatchedFrameDimensions:
            return "Low-resolution frame dimensions do not match."
        case .noConsistentMotion:
            return "No consistent motion was detected."
        }
    }
}

public struct PicsewScrollingWindowDetector: Sendable {
    public let differenceThreshold: UInt8
    public let normalizedThreshold: Float
    public let connectivity: Int

    public init(
        differenceThreshold: UInt8 = 30,
        normalizedThreshold: Float = 50,
        connectivity: Int = 8
    ) {
        self.differenceThreshold = differenceThreshold
        self.normalizedThreshold = normalizedThreshold
        self.connectivity = connectivity
    }

    public func detect(
        in batch: PicsewLowResolutionFrameBatch
    ) throws -> PicsewScrollingWindowDetection {
        try detect(
            frames: batch.frames,
            fullResolutionWidth: batch.metadata.width,
            fullResolutionHeight: batch.metadata.height
        )
    }

    public func detect(
        frames: [PicsewLowResolutionGrayFrame],
        fullResolutionWidth: Int,
        fullResolutionHeight: Int
    ) throws -> PicsewScrollingWindowDetection {
        guard let firstFrame = frames.first else {
            throw PicsewScrollingWindowError.noFrames
        }

        let lowResWidth = firstFrame.width
        let lowResHeight = firstFrame.height
        let pixelCount = lowResWidth * lowResHeight

        guard frames.allSatisfy({ $0.width == lowResWidth && $0.height == lowResHeight }) else {
            throw PicsewScrollingWindowError.mismatchedFrameDimensions
        }

        var accumulator = Array<Float>(repeating: 0, count: pixelCount)

        for index in 0..<(frames.count - 1) {
            let currentPixels = [UInt8](frames[index].pixels)
            let nextPixels = [UInt8](frames[index + 1].pixels)

            for pixelIndex in 0..<pixelCount {
                let difference = abs(Int(currentPixels[pixelIndex]) - Int(nextPixels[pixelIndex]))
                if difference > Int(differenceThreshold) {
                    accumulator[pixelIndex] += 255
                }
            }
        }

        guard let maximum = accumulator.max(), maximum > 0 else {
            throw PicsewScrollingWindowError.noConsistentMotion
        }

        let normalizedMask = accumulator.map { value -> UInt8 in
            let normalized = (value / maximum) * 255
            return normalized > normalizedThreshold ? 255 : 0
        }

        guard let boundingRect = largestConnectedBoundingRect(
            in: normalizedMask,
            width: lowResWidth,
            height: lowResHeight
        ) else {
            throw PicsewScrollingWindowError.noConsistentMotion
        }

        let scaleFactor = max(
            1,
            Int(round(Double(fullResolutionWidth) / Double(lowResWidth)))
        )

        let originalWindow = PicsewRect(
            x: 0,
            y: boundingRect.y * scaleFactor,
            width: lowResWidth * scaleFactor,
            height: boundingRect.height * scaleFactor
        )

        let insetPixels = Int(floor(Double(boundingRect.height) * 0.1))
        let refinedHeight = max(1, boundingRect.height - (insetPixels * 2))
        let refinedWindow = PicsewRect(
            x: 0,
            y: (boundingRect.y + insetPixels) * scaleFactor,
            width: lowResWidth * scaleFactor,
            height: refinedHeight * scaleFactor
        )

        var outsideMask = Array<UInt8>(repeating: 255, count: pixelCount)
        if boundingRect.height > 0 {
            for row in boundingRect.y..<(boundingRect.y + boundingRect.height) {
                let rowStart = row * lowResWidth
                for column in 0..<lowResWidth {
                    outsideMask[rowStart + column] = 0
                }
            }
        }

        return PicsewScrollingWindowDetection(
            originalFullWidthWindow: originalWindow,
            refinedWindow: refinedWindow,
            outsideMask: PicsewOutsideMask(
                width: lowResWidth,
                height: lowResHeight,
                pixels: Data(outsideMask)
            )
        )
    }

    private func largestConnectedBoundingRect(
        in mask: [UInt8],
        width: Int,
        height: Int
    ) -> PicsewRect? {
        let neighborOffsets: [(Int, Int)] = connectivity == 4
            ? [(-1, 0), (1, 0), (0, -1), (0, 1)]
            : [
                (-1, -1), (-1, 0), (-1, 1),
                (0, -1),           (0, 1),
                (1, -1),  (1, 0),  (1, 1),
            ]

        var visited = Array(repeating: false, count: mask.count)
        var bestRect: PicsewRect?
        var bestArea = 0

        for row in 0..<height {
            for column in 0..<width {
                let startIndex = row * width + column
                guard mask[startIndex] > 0, !visited[startIndex] else {
                    continue
                }

                var queue = [(row, column)]
                visited[startIndex] = true
                var queueIndex = 0
                var minRow = row
                var maxRow = row
                var minColumn = column
                var maxColumn = column
                var area = 0

                while queueIndex < queue.count {
                    let (currentRow, currentColumn) = queue[queueIndex]
                    queueIndex += 1
                    area += 1

                    minRow = min(minRow, currentRow)
                    maxRow = max(maxRow, currentRow)
                    minColumn = min(minColumn, currentColumn)
                    maxColumn = max(maxColumn, currentColumn)

                    for (rowOffset, columnOffset) in neighborOffsets {
                        let neighborRow = currentRow + rowOffset
                        let neighborColumn = currentColumn + columnOffset

                        guard neighborRow >= 0, neighborRow < height,
                              neighborColumn >= 0, neighborColumn < width else {
                            continue
                        }

                        let neighborIndex = neighborRow * width + neighborColumn
                        guard mask[neighborIndex] > 0, !visited[neighborIndex] else {
                            continue
                        }

                        visited[neighborIndex] = true
                        queue.append((neighborRow, neighborColumn))
                    }
                }

                if area > bestArea {
                    bestArea = area
                    bestRect = PicsewRect(
                        x: minColumn,
                        y: minRow,
                        width: (maxColumn - minColumn) + 1,
                        height: (maxRow - minRow) + 1
                    )
                }
            }
        }

        return bestRect
    }
}

public struct PicsewKeyframeSelector: Sendable {
    public let matchThreshold: Double

    public init(matchThreshold: Double = 0.7) {
        self.matchThreshold = matchThreshold
    }

    public func selectCandidates(
        in batch: PicsewLowResolutionFrameBatch,
        refinedWindow: PicsewRect
    ) throws -> PicsewKeyframeSelection {
        try selectCandidates(
            frames: batch.frames,
            fullResolutionWidth: batch.metadata.width,
            fullResolutionHeight: batch.metadata.height,
            refinedWindow: refinedWindow
        )
    }

    public func selectCandidates(
        frames: [PicsewLowResolutionGrayFrame],
        fullResolutionWidth: Int,
        fullResolutionHeight: Int,
        refinedWindow: PicsewRect
    ) throws -> PicsewKeyframeSelection {
        guard let firstFrame = frames.first else {
            throw PicsewKeyframeSelectionError.noFrames
        }

        let lowResWidth = firstFrame.width
        let lowResHeight = firstFrame.height
        guard frames.allSatisfy({ $0.width == lowResWidth && $0.height == lowResHeight }) else {
            throw PicsewKeyframeSelectionError.mismatchedFrameDimensions
        }

        let scaleX = Double(lowResWidth) / Double(fullResolutionWidth)
        let scaleY = Double(lowResHeight) / Double(fullResolutionHeight)
        let x = Int((Double(refinedWindow.x) * scaleX).rounded())
        let y = Int((Double(refinedWindow.y) * scaleY).rounded())
        let width = max(1, Int((Double(refinedWindow.width) * scaleX).rounded()))
        let height = max(1, Int((Double(refinedWindow.height) * scaleY).rounded()))

        guard x >= 0, y >= 0, x + width <= lowResWidth, y + height <= lowResHeight else {
            throw PicsewKeyframeSelectionError.invalidRefinedWindow
        }

        var candidateIndices = [0]
        var lastKeyframeIndex = 0

        while lastKeyframeIndex < frames.count - 1 {
            var accumulatedOffset = 0
            var lastFrameInChunk = frames[lastKeyframeIndex]
            var foundNextKeyframe = false

            for index in (lastKeyframeIndex + 1)..<frames.count {
                let currentFrame = frames[index]
                let templateHeight = max(1, height / 4)
                let templateYStart = y + (height / 2) - (templateHeight / 2)

                let template = extractRegion(
                    from: lastFrameInChunk,
                    x: x,
                    y: templateYStart,
                    width: width,
                    height: templateHeight
                )
                let content = extractRegion(
                    from: currentFrame,
                    x: x,
                    y: y,
                    width: width,
                    height: height
                )

                if let match = bestTemplateMatch(
                    template: template,
                    templateWidth: width,
                    templateHeight: templateHeight,
                    searchRegion: content,
                    searchWidth: width,
                    searchHeight: height
                ), match.score > matchThreshold {
                    let offsetSinceLastFrame = (templateYStart - y) - match.y
                    if offsetSinceLastFrame > 0 {
                        accumulatedOffset += offsetSinceLastFrame
                    }
                }

                lastFrameInChunk = currentFrame

                if Double(accumulatedOffset) > Double(height) * 0.5 {
                    candidateIndices.append(index)
                    lastKeyframeIndex = index
                    foundNextKeyframe = true
                    break
                }
            }

            if !foundNextKeyframe {
                break
            }
        }

        if lastKeyframeIndex != frames.count - 1 {
            candidateIndices.append(frames.count - 1)
        }

        return PicsewKeyframeSelection(candidateIndices: candidateIndices)
    }

    private func extractRegion(
        from frame: PicsewLowResolutionGrayFrame,
        x: Int,
        y: Int,
        width: Int,
        height: Int
    ) -> [UInt8] {
        let pixels = [UInt8](frame.pixels)
        var region = Array<UInt8>()
        region.reserveCapacity(width * height)

        for row in y..<(y + height) {
            let rowStart = row * frame.width
            region.append(contentsOf: pixels[(rowStart + x)..<(rowStart + x + width)])
        }

        return region
    }

    private func bestTemplateMatch(
        template: [UInt8],
        templateWidth: Int,
        templateHeight: Int,
        searchRegion: [UInt8],
        searchWidth: Int,
        searchHeight: Int
    ) -> (score: Double, y: Int)? {
        guard searchWidth == templateWidth, searchHeight >= templateHeight else {
            return nil
        }

        let templateMean = mean(of: template)
        let templateVariance = variance(of: template, mean: templateMean)
        guard templateVariance > 0 else {
            return nil
        }

        let maxY = searchHeight - templateHeight
        var bestScore = -Double.infinity
        var bestY = 0

        for offsetY in 0...maxY {
            var window = Array<UInt8>()
            window.reserveCapacity(template.count)

            for row in 0..<templateHeight {
                let sourceStart = (offsetY + row) * searchWidth
                window.append(contentsOf: searchRegion[sourceStart..<(sourceStart + searchWidth)])
            }

            let windowMean = mean(of: window)
            let windowVariance = variance(of: window, mean: windowMean)
            guard windowVariance > 0 else {
                continue
            }

            var numerator = 0.0
            for index in 0..<template.count {
                numerator += (Double(template[index]) - templateMean) * (Double(window[index]) - windowMean)
            }

            let denominator = sqrt(templateVariance * windowVariance)
            guard denominator > 0 else {
                continue
            }

            let score = numerator / denominator
            if score > bestScore {
                bestScore = score
                bestY = offsetY
            }
        }

        guard bestScore.isFinite else {
            return nil
        }

        return (bestScore, bestY)
    }

    private func mean(of values: [UInt8]) -> Double {
        guard !values.isEmpty else { return 0 }
        let sum = values.reduce(0.0) { partialResult, value in
            partialResult + Double(value)
        }
        return sum / Double(values.count)
    }

    private func variance(of values: [UInt8], mean: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0.0) { partialResult, value in
            let centered = Double(value) - mean
            return partialResult + centered * centered
        }
    }
}
