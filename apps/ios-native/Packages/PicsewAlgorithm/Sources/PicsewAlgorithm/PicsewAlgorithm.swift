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

public struct PicsewFilteredKeyframes: Sendable, Equatable {
    public let cleanIndices: [Int]

    public init(cleanIndices: [Int]) {
        self.cleanIndices = cleanIndices
    }
}

public struct PicsewStitchOffset: Sendable, Equatable {
    public let vOffset: Int
    public let hOffset: Int

    public init(vOffset: Int, hOffset: Int) {
        self.vOffset = vOffset
        self.hOffset = hOffset
    }
}

public struct PicsewOffsetCalculation: Sendable, Equatable {
    public let offsets: [PicsewStitchOffset]
    public let headerHeight: Int
    public let footerHeight: Int
    public let totalHeight: Int

    public init(
        offsets: [PicsewStitchOffset],
        headerHeight: Int,
        footerHeight: Int,
        totalHeight: Int
    ) {
        self.offsets = offsets
        self.headerHeight = headerHeight
        self.footerHeight = footerHeight
        self.totalHeight = totalHeight
    }
}

public struct PicsewStitchedImage: Sendable, Equatable {
    public let width: Int
    public let height: Int
    public let bytesPerRow: Int
    public let pixels: Data

    public init(width: Int, height: Int, bytesPerRow: Int, pixels: Data) {
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
        self.pixels = pixels
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

public enum PicsewKeyframeFilteringError: Error, LocalizedError {
    case invalidOutsideMask
    case mismatchedFrameDimensions

    public var errorDescription: String? {
        switch self {
        case .invalidOutsideMask:
            return "The outside mask is invalid for keyframe filtering."
        case .mismatchedFrameDimensions:
            return "Low-resolution frame dimensions do not match for keyframe filtering."
        }
    }
}

public enum PicsewOffsetCalculationError: Error, LocalizedError {
    case unreliableOverlap
    case noFrames
    case invalidRefinedWindow
    case mismatchedFrameDimensions

    public var errorDescription: String? {
        switch self {
        case .unreliableOverlap:
            return "The video frames do not have reliable overlap. Try recording with slower scrolling."
        case .noFrames:
            return "No full-resolution keyframes were provided for offset calculation."
        case .invalidRefinedWindow:
            return "The refined window is outside the full-resolution frame bounds."
        case .mismatchedFrameDimensions:
            return "Full-resolution keyframe dimensions do not match."
        }
    }
}

public enum PicsewStitchingError: Error, LocalizedError {
    case noFrames
    case invalidRefinedWindow
    case invalidOffsetCount
    case mismatchedFrameDimensions

    public var errorDescription: String? {
        switch self {
        case .noFrames:
            return "No full-resolution color keyframes were provided for stitching."
        case .invalidRefinedWindow:
            return "The refined window is outside the full-resolution color frame bounds."
        case .invalidOffsetCount:
            return "The number of stitch offsets does not match the provided keyframes."
        case .mismatchedFrameDimensions:
            return "Full-resolution color keyframe dimensions do not match."
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
        return PicsewVerticalCorrelation.bestMatch(template: template, search: searchRegion, width: templateWidth)
    }
}

public struct PicsewKeyframeFilter: Sendable {
    public let differenceThreshold: UInt8
    public let outsideChangeThresholdPercent: Double

    public init(
        differenceThreshold: UInt8 = 30,
        outsideChangeThresholdPercent: Double = 1
    ) {
        self.differenceThreshold = differenceThreshold
        self.outsideChangeThresholdPercent = outsideChangeThresholdPercent
    }

    public func filter(
        candidateIndices: [Int],
        in batch: PicsewLowResolutionFrameBatch,
        outsideMask: PicsewOutsideMask
    ) throws -> PicsewFilteredKeyframes {
        try filter(
            candidateIndices: candidateIndices,
            frames: batch.frames,
            outsideMask: outsideMask
        )
    }

    public func filter(
        candidateIndices: [Int],
        frames: [PicsewLowResolutionGrayFrame],
        outsideMask: PicsewOutsideMask
    ) throws -> PicsewFilteredKeyframes {
        guard !candidateIndices.isEmpty else {
            return PicsewFilteredKeyframes(cleanIndices: [])
        }

        guard let firstFrame = frames.first else {
            return PicsewFilteredKeyframes(cleanIndices: [])
        }

        guard outsideMask.width == firstFrame.width,
              outsideMask.height == firstFrame.height else {
            throw PicsewKeyframeFilteringError.invalidOutsideMask
        }

        let lowResWidth = firstFrame.width
        let lowResHeight = firstFrame.height
        guard frames.allSatisfy({ $0.width == lowResWidth && $0.height == lowResHeight }) else {
            throw PicsewKeyframeFilteringError.mismatchedFrameDimensions
        }

        let maskPixels = [UInt8](outsideMask.pixels)
        let totalOutsidePixels = maskPixels.reduce(0) { partialResult, value in
            partialResult + (value > 0 ? 1 : 0)
        }

        guard totalOutsidePixels > 0 else {
            return PicsewFilteredKeyframes(cleanIndices: candidateIndices)
        }

        var cleanIndices = [candidateIndices[0]]

        for index in 1..<candidateIndices.count {
            let previousIndex = candidateIndices[index - 1]
            let currentIndex = candidateIndices[index]
            guard previousIndex < frames.count, currentIndex < frames.count else {
                continue
            }

            let previousPixels = [UInt8](frames[previousIndex].pixels)
            let currentPixels = [UInt8](frames[currentIndex].pixels)
            var changedOutsidePixels = 0

            for pixelIndex in 0..<maskPixels.count {
                guard maskPixels[pixelIndex] > 0 else {
                    continue
                }

                let difference = abs(Int(previousPixels[pixelIndex]) - Int(currentPixels[pixelIndex]))
                if difference > Int(differenceThreshold) {
                    changedOutsidePixels += 1
                }
            }

            let outsideChangePercent = (Double(changedOutsidePixels) / Double(totalOutsidePixels)) * 100
            if outsideChangePercent < outsideChangeThresholdPercent {
                cleanIndices.append(currentIndex)
            }
        }

        return PicsewFilteredKeyframes(cleanIndices: cleanIndices)
    }
}

public struct PicsewOffsetCalculator: Sendable {
    public init() {}

    public func calculate(
        in batch: PicsewFullResolutionKeyframeBatch,
        refinedWindow: PicsewRect,
        excludedRegions: [PicsewRect] = [],
        minimumConfidence: Double? = nil
    ) throws -> PicsewOffsetCalculation {
        try calculate(frames: batch.frames, refinedWindow: refinedWindow, excludedRegions: excludedRegions, minimumConfidence: minimumConfidence)
    }

    public func calculate(
        frames: [PicsewFullResolutionGrayFrame],
        refinedWindow: PicsewRect,
        excludedRegions: [PicsewRect] = [],
        minimumConfidence: Double? = nil
    ) throws -> PicsewOffsetCalculation {
        guard let firstFrame = frames.first else {
            throw PicsewOffsetCalculationError.noFrames
        }

        let frameWidth = firstFrame.width
        let frameHeight = firstFrame.height
        guard frames.allSatisfy({ $0.width == frameWidth && $0.height == frameHeight }) else {
            throw PicsewOffsetCalculationError.mismatchedFrameDimensions
        }

        let x = refinedWindow.x
        let y = refinedWindow.y
        let width = refinedWindow.width
        let height = refinedWindow.height

        guard x >= 0, y >= 0, width > 0, height > 0,
              x + width <= frameWidth,
              y + height <= frameHeight else {
            throw PicsewOffsetCalculationError.invalidRefinedWindow
        }

        let headerHeight = y
        let footerHeight = max(0, frameHeight - (y + height))
        var offsets = [PicsewStitchOffset]()
        for index in 1..<frames.count {
            let match = try alignment(previous: frames[index - 1], current: frames[index], refinedWindow: refinedWindow, excludedRegions: excludedRegions)
            if let minimumConfidence, match.score < minimumConfidence {
                throw PicsewOffsetCalculationError.unreliableOverlap
            }
            offsets.append(PicsewStitchOffset(vOffset: match.offset, hOffset: 0))
        }

        let totalHeight = headerHeight + height + footerHeight + offsets.reduce(0) { partialResult, offset in
            partialResult + max(0, offset.vOffset)
        }

        return PicsewOffsetCalculation(
            offsets: offsets,
            headerHeight: headerHeight,
            footerHeight: footerHeight,
            totalHeight: totalHeight
        )
    }

    // Use identical source columns in both frames so fixed controls cannot
    // become the strongest match. This mirrors cleanTemplateColumn in Web.
    func alignment(
        previous: PicsewFullResolutionGrayFrame,
        current: PicsewFullResolutionGrayFrame,
        refinedWindow: PicsewRect,
        excludedRegions: [PicsewRect] = []
    ) throws -> (offset: Int, score: Double) {
        let x = refinedWindow.x, y = refinedWindow.y
        let width = refinedWindow.width, height = refinedWindow.height
        guard previous.width == current.width, previous.height == current.height else {
            throw PicsewOffsetCalculationError.mismatchedFrameDimensions
        }
        guard x >= 0, y >= 0, width > 0, height > 0,
              x + width <= previous.width, y + height <= previous.height else {
            throw PicsewOffsetCalculationError.invalidRefinedWindow
        }
        let templateHeight = max(1, height / 3)
        let templateY = y + height - templateHeight
        var spans = [(start: x, end: x + width)]
        for rect in excludedRegions where rect.y < y + height && rect.y + rect.height > templateY {
            spans = spans.flatMap { span -> [(start: Int, end: Int)] in
                if rect.x >= span.end || rect.x + rect.width <= span.start { return [span] }
                return [(span.start, min(span.end, rect.x)), (max(span.start, rect.x + rect.width), span.end)].filter { $0.1 > $0.0 }
            }
        }
        guard let column = spans.max(by: { $0.end - $0.start < $1.end - $1.start }),
              column.end - column.start >= max(1, width / 4) else {
            throw PicsewOffsetCalculationError.unreliableOverlap
        }
        let template = extractRegion(from: previous, x: column.start, y: templateY, width: column.end - column.start, height: templateHeight)
        let search = extractRegion(from: current, x: column.start, y: y, width: column.end - column.start, height: height)
        let match = bestTemplateMatch(template: template, templateWidth: column.end - column.start, templateHeight: templateHeight,
                                      searchRegion: search, searchWidth: column.end - column.start, searchHeight: height)
        return (height - templateHeight - match.y, match.score)
    }

    private func extractRegion(
        from frame: PicsewFullResolutionGrayFrame,
        x: Int,
        y: Int,
        width: Int,
        height: Int
    ) -> [UInt8] {
        extractRegion(
            pixels: [UInt8](frame.pixels),
            frameWidth: frame.width,
            x: x,
            y: y,
            width: width,
            height: height
        )
    }

    private func extractRegion(
        pixels: [UInt8],
        frameWidth: Int,
        x: Int,
        y: Int,
        width: Int,
        height: Int
    ) -> [UInt8] {
        var region = Array<UInt8>()
        region.reserveCapacity(width * height)

        for row in y..<(y + height) {
            let rowStart = row * frameWidth
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
    ) -> (x: Int, y: Int, score: Double) {
        precondition(searchWidth == templateWidth && searchHeight >= templateHeight)
        guard let match = PicsewVerticalCorrelation.bestMatch(
            template: template, search: searchRegion, width: templateWidth
        ) else { return (0, 0, 0) }
        return (0, match.y, match.score)
    }
}

public struct PicsewStitcher: Sendable {
    private let bytesPerPixel = 4

    public init() {}

    public func stitch(
        in batch: PicsewFullResolutionColorKeyframeBatch,
        refinedWindow: PicsewRect,
        offsets: PicsewOffsetCalculation,
        floatingControls: [PicsewRect] = []
    ) throws -> PicsewStitchedImage {
        try stitch(frames: batch.frames, refinedWindow: refinedWindow, offsets: offsets, floatingControls: floatingControls)
    }

    public func stitch(
        frames: [PicsewFullResolutionColorFrame],
        refinedWindow: PicsewRect,
        offsets: PicsewOffsetCalculation,
        floatingControls: [PicsewRect] = []
    ) throws -> PicsewStitchedImage {
        guard let firstFrame = frames.first else {
            throw PicsewStitchingError.noFrames
        }

        let frameWidth = firstFrame.width
        let frameHeight = firstFrame.height
        let frameBytesPerRow = firstFrame.bytesPerRow
        guard frames.allSatisfy({
            $0.width == frameWidth && $0.height == frameHeight && $0.bytesPerRow == frameBytesPerRow
        }) else {
            throw PicsewStitchingError.mismatchedFrameDimensions
        }

        let x = refinedWindow.x
        let y = refinedWindow.y
        let width = refinedWindow.width
        let height = refinedWindow.height
        guard x >= 0, y >= 0, width > 0, height > 0,
              x + width <= frameWidth,
              y + height <= frameHeight else {
            throw PicsewStitchingError.invalidRefinedWindow
        }

        guard offsets.offsets.count == max(0, frames.count - 1) else {
            throw PicsewStitchingError.invalidOffsetCount
        }

        let outputWidth = frameWidth
        let outputHeight = offsets.totalHeight
        let outputBytesPerRow = outputWidth * bytesPerPixel
        var outputPixels = Array<UInt8>(
            repeating: 0,
            count: outputHeight * outputBytesPerRow
        )

        var currentY = 0
        var pending = [PicsewRect]()
        func track(_ source: PicsewRect, bodyStart: Int) {
            for control in floatingControls {
                if let copied = picsewIntersection(source, control) {
                    pending.append(PicsewRect(x: copied.x, y: bodyStart + copied.y - y, width: copied.width, height: copied.height))
                }
            }
        }
        func recover(from frame: PicsewFullResolutionColorFrame, bodyStart: Int) {
            guard !pending.isEmpty else { return }
            let coverage = PicsewRect(x: x, y: bodyStart, width: width, height: height)
            let occlusions = floatingControls.map { PicsewRect(x: $0.x, y: bodyStart + $0.y - y, width: $0.width, height: $0.height) }
            var remaining = [PicsewRect]()
            for target in pending {
                var clean = picsewIntersection(target, coverage).map { [$0] } ?? []
                for control in occlusions { clean = clean.flatMap { picsewSubtract($0, control) } }
                var unrecovered = [target]
                for rect in clean {
                    let band = PicsewRect(x: x, y: rect.y, width: width, height: rect.height)
                    let copy = occlusions.contains { picsewIntersection(band, $0) != nil } ? rect : band
                    copyRegion(sourcePixels: [UInt8](frame.pixels), sourceBytesPerRow: frameBytesPerRow,
                               sourceX: copy.x, sourceY: copy.y - bodyStart + y, width: copy.width, height: copy.height,
                               destinationPixels: &outputPixels, destinationBytesPerRow: outputBytesPerRow,
                               destinationX: copy.x, destinationY: copy.y)
                    unrecovered = unrecovered.flatMap { picsewSubtract($0, rect) }
                }
                remaining.append(contentsOf: unrecovered)
            }
            pending = remaining
        }

        if offsets.headerHeight > 0 {
            copyRegion(
                sourcePixels: [UInt8](firstFrame.pixels),
                sourceBytesPerRow: frameBytesPerRow,
                sourceX: 0,
                sourceY: 0,
                width: frameWidth,
                height: offsets.headerHeight,
                destinationPixels: &outputPixels,
                destinationBytesPerRow: outputBytesPerRow,
                destinationX: 0,
                destinationY: currentY
            )
            currentY += offsets.headerHeight
        }

        copyRegion(
            sourcePixels: [UInt8](firstFrame.pixels),
            sourceBytesPerRow: frameBytesPerRow,
            sourceX: x,
            sourceY: y,
            width: width,
            height: height,
            destinationPixels: &outputPixels,
            destinationBytesPerRow: outputBytesPerRow,
            destinationX: x,
            destinationY: currentY
        )
        track(refinedWindow, bodyStart: offsets.headerHeight)
        currentY += height
        var previousBodyStart = offsets.headerHeight

        for index in 0..<offsets.offsets.count {
            let offset = offsets.offsets[index]
            let frame = frames[index + 1]
            let safeVOffset = max(0, min(offset.vOffset, height))
            let bodyStart = currentY - height + safeVOffset
            if offset.hOffset == 0 { recover(from: frame, bodyStart: bodyStart) }
            else { pending = [] }
            guard safeVOffset > 0 else { previousBodyStart = bodyStart; continue }

            let sourceX = offset.hOffset < 0 ? min(-offset.hOffset, width) : 0
            let targetX = max(0, offset.hOffset)
            let copyWidth = min(width - sourceX, max(0, width - targetX))
            guard copyWidth > 0 else { continue }

            copyRegion(
                sourcePixels: [UInt8](frame.pixels),
                sourceBytesPerRow: frameBytesPerRow,
                sourceX: x + sourceX,
                sourceY: y + height - safeVOffset,
                width: copyWidth,
                height: safeVOffset,
                destinationPixels: &outputPixels,
                destinationBytesPerRow: outputBytesPerRow,
                destinationX: x + targetX,
                destinationY: currentY
            )
            if offset.hOffset == 0 {
                track(PicsewRect(x: x, y: y + height - safeVOffset, width: width, height: safeVOffset), bodyStart: bodyStart)
                recover(from: frames[index], bodyStart: previousBodyStart)
            }
            currentY += safeVOffset
            previousBodyStart = bodyStart
        }

        if offsets.footerHeight > 0, let lastFrame = frames.last {
            copyRegion(
                sourcePixels: [UInt8](lastFrame.pixels),
                sourceBytesPerRow: frameBytesPerRow,
                sourceX: 0,
                sourceY: y + height,
                width: frameWidth,
                height: offsets.footerHeight,
                destinationPixels: &outputPixels,
                destinationBytesPerRow: outputBytesPerRow,
                destinationX: 0,
                destinationY: currentY
            )
        }

        return PicsewStitchedImage(
            width: outputWidth,
            height: outputHeight,
            bytesPerRow: outputBytesPerRow,
            pixels: Data(outputPixels)
        )
    }

    private func copyRegion(
        sourcePixels: [UInt8],
        sourceBytesPerRow: Int,
        sourceX: Int,
        sourceY: Int,
        width: Int,
        height: Int,
        destinationPixels: inout [UInt8],
        destinationBytesPerRow: Int,
        destinationX: Int,
        destinationY: Int
    ) {
        let byteWidth = width * bytesPerPixel

        for row in 0..<height {
            let sourceStart = ((sourceY + row) * sourceBytesPerRow) + (sourceX * bytesPerPixel)
            let destinationStart = ((destinationY + row) * destinationBytesPerRow) + (destinationX * bytesPerPixel)
            destinationPixels[destinationStart..<(destinationStart + byteWidth)] =
                sourcePixels[sourceStart..<(sourceStart + byteWidth)]
        }
    }
}
