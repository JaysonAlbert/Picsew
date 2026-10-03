import Foundation
import PicsewMedia

/// Port of reference/web fixed-edge detection for excluding controls from alignment.
/// This does not reconstruct pixels hidden by a control.
public struct PicsewFloatingControls: Sendable {
    public init() {}

    public func detect(frames: [PicsewLowResolutionGrayFrame], window: PicsewRect) -> [PicsewRect] {
        guard frames.count >= 3, let first = frames.first else { return [] }
        let width = first.width
        let height = first.height
        guard frames.allSatisfy({ $0.width == width && $0.height == height && $0.pixels.count == width * height })
        else { return [] }
        let count = min(8, frames.count)
        let samples = (0..<count).map {
            [UInt8](frames[Int((Double($0) * Double(frames.count - 1) / Double(count - 1)).rounded())].pixels)
        }
        let required = max(3, Int(ceil(Double(count) * 0.875)))
        let x0 = max(3, window.x)
        let y0 = max(3, window.y)
        let x1 = min(width - 3, window.x + window.width)
        let y1 = min(height - 3, window.y + window.height)
        guard x0 < x1, y0 < y1 else { return [] }
        var edges = [UInt8](repeating: 0, count: width * height)
        var moving = edges
        for y in y0..<y1 {
            for x in x0..<x1 {
                let at = y * width + x
                let values = samples.map { Int($0[at]) }.sorted()
                if values.last! - values.first! > 40 { moving[at] = 1 }
                var low = 0
                var range = Int.max
                for i in 0...(count - required) {
                    let span = values[i + required - 1] - values[i]
                    if span < range {
                        low = values[i]
                        range = span
                    }
                }
                if range > 14 { continue }
                var votes = 0
                for sample in samples {
                    let value = Int(sample[at])
                    if value < low || value > low + 14 { continue }
                    if [-3, 3, -3 * width, 3 * width].contains(where: { offset in
                        let difference = value - Int(sample[at + offset])
                        if abs(difference) < 28 { return false }
                        return samples.filter {
                            abs(Int($0[at]) - value) <= 14 && abs(Int($0[at]) - Int($0[at + offset]) - difference) <= 14
                        }.count >= required
                    }) {
                        votes += 1
                    }
                }
                if votes >= required { edges[at] = 1 }
            }
        }
        var connected = edges.map { _ in UInt8(0) }
        for y in y0..<y1 {
            for x in x0..<x1 where edges[y * width + x] != 0 {
                for dy in -2...2 {
                    for dx in -2...2 { connected[(y + dy) * width + x + dx] = 1 }
                }
            }
        }
        var boxes = [PicsewRect]()
        for y in y0..<y1 {
            for x in x0..<x1 {
                let start = y * width + x
                if connected[start] == 0 { continue }
                var queue = [start]
                var index = 0
                connected[start] = 0
                var minX = x
                var maxX = x
                var minY = y
                var maxY = y
                var support = 0
                while index < queue.count {
                    let at = queue[index]
                    index += 1
                    let cx = at % width
                    let cy = at / width
                    minX = min(minX, cx)
                    maxX = max(maxX, cx)
                    minY = min(minY, cy)
                    maxY = max(maxY, cy)
                    support += Int(edges[at])
                    for next in [at - 1, at + 1, at - width, at + width] {
                        let nx = next % width
                        let ny = next / width
                        guard nx >= x0, nx < x1, ny >= y0, ny < y1, connected[next] != 0 else { continue }
                        connected[next] = 0
                        queue.append(next)
                    }
                }
                let w = maxX - minX + 1
                let h = maxY - minY + 1
                guard support >= 12, w >= 6, h >= 6,
                    Double(w) <= Double(window.width) * 0.2, Double(h) <= Double(window.height) * 0.2,
                    Double(w) / Double(h) <= 3, Double(h) / Double(w) <= 3
                else { continue }
                let pad = max(5, Int(ceil(Double(max(w, h)) * 0.35)))
                let left = max(3, minX - pad)
                let right = min(width - 3, maxX + pad + 1)
                let top = max(3, minY - pad)
                let bottom = min(height - 3, maxY + pad + 1)
                var motion = 0
                var surroundings = 0
                for sy in top..<bottom {
                    for sx in left..<right {
                        if sx >= minX && sx <= maxX && sy >= minY && sy <= maxY { continue }
                        surroundings += 1
                        motion += Int(moving[sy * width + sx])
                    }
                }
                guard Double(motion) >= Double(surroundings) * 0.08 else { continue }
                boxes.append(PicsewRect(x: left, y: top, width: right - left, height: bottom - top))
            }
        }
        return boxes
    }
}

func picsewIntersection(_ a: PicsewRect, _ b: PicsewRect) -> PicsewRect? {
    let x = max(a.x, b.x)
    let y = max(a.y, b.y)
    let right = min(a.x + a.width, b.x + b.width)
    let bottom = min(a.y + a.height, b.y + b.height)
    guard right > x, bottom > y else { return nil }
    return PicsewRect(x: x, y: y, width: right - x, height: bottom - y)
}

func picsewSubtract(_ rect: PicsewRect, _ occlusion: PicsewRect) -> [PicsewRect] {
    guard let overlap = picsewIntersection(rect, occlusion) else { return [rect] }
    return [
        PicsewRect(x: rect.x, y: rect.y, width: rect.width, height: overlap.y - rect.y),
        PicsewRect(
            x: rect.x, y: overlap.y + overlap.height, width: rect.width,
            height: rect.y + rect.height - overlap.y - overlap.height),
        PicsewRect(x: rect.x, y: overlap.y, width: overlap.x - rect.x, height: overlap.height),
        PicsewRect(
            x: overlap.x + overlap.width, y: overlap.y, width: rect.x + rect.width - overlap.x - overlap.width,
            height: overlap.height),
    ].filter { $0.width > 0 && $0.height > 0 }
}
