export type Rect = { x: number; y: number; width: number; height: number };
export type GrayFrame = { data: Uint8Array; cols: number; rows: number };

/** Fixed edges surrounded by scrolling pixels identify an occlusion, irrespective of its icon. */
export function findFloatingOverlays(
  frames: GrayFrame[],
  window: Rect,
): Rect[] {
  if (frames.length < 3) return [];
  const samples = Array.from(
    { length: Math.min(8, frames.length) },
    (_, i) =>
      frames[
        Math.round((i * (frames.length - 1)) / (Math.min(8, frames.length) - 1))
      ]!,
  );
  const { cols, rows } = samples[0]!;
  const required = Math.max(3, Math.ceil(samples.length * 0.875));
  const x0 = Math.max(3, Math.ceil(window.x));
  const y0 = Math.max(3, Math.ceil(window.y));
  const x1 = Math.min(cols - 3, Math.floor(window.x + window.width));
  const y1 = Math.min(rows - 3, Math.floor(window.y + window.height));
  const edges = new Uint8Array(cols * rows);
  const moving = new Uint8Array(cols * rows);
  for (let y = y0; y < y1; y++) {
    for (let x = x0; x < x1; x++) {
      const at = y * cols + x;
      const values = samples
        .map((frame) => frame.data[at]!)
        .sort((a, b) => a - b);
      if (values[values.length - 1]! - values[0]! > 40) moving[at] = 1;
      let low = 0;
      let range = Infinity;
      for (let i = 0; i <= values.length - required; i++) {
        const span = values[i + required - 1]! - values[i]!;
        if (span < range) {
          low = values[i]!;
          range = span;
        }
      }
      if (range > 14) continue;
      let votes = 0;
      for (const frame of samples) {
        const value = frame.data[at]!;
        if (value < low || value > low + 14) continue;
        // A fixed edge keeps its signed contrast as well as its intensity. White
        // gaps in repeating text are stable pixels, but their neighbours move.
        if (
          [-3, 3, -3 * cols, 3 * cols].some((offset) => {
            const difference = value - frame.data[at + offset]!;
            if (Math.abs(difference) < 28) return false;
            return (
              samples.filter(
                (sample) =>
                  Math.abs(sample.data[at]! - value) <= 14 &&
                  Math.abs(
                    sample.data[at]! - sample.data[at + offset]! - difference,
                  ) <= 14,
              ).length >= required
            );
          })
        )
          votes++;
      }
      if (votes >= required) edges[at] = 1;
    }
  }
  // Connect strokes belonging to the same compact control, without OpenCV allocations.
  const connected = new Uint8Array(edges.length);
  for (let y = y0; y < y1; y++) {
    for (let x = x0; x < x1; x++) {
      if (!edges[y * cols + x]) continue;
      for (let dy = -2; dy <= 2; dy++) {
        for (let dx = -2; dx <= 2; dx++)
          connected[(y + dy) * cols + x + dx] = 1;
      }
    }
  }
  const boxes: Rect[] = [];
  for (let y = y0; y < y1; y++) {
    for (let x = x0; x < x1; x++) {
      const start = y * cols + x;
      if (!connected[start]) continue;
      const queue = [start];
      connected[start] = 0;
      let minX = x,
        maxX = x,
        minY = y,
        maxY = y,
        support = 0;
      for (let i = 0; i < queue.length; i++) {
        const at = queue[i]!;
        const cx = at % cols,
          cy = Math.floor(at / cols);
        minX = Math.min(minX, cx);
        maxX = Math.max(maxX, cx);
        minY = Math.min(minY, cy);
        maxY = Math.max(maxY, cy);
        support += edges[at]!;
        for (const next of [at - 1, at + 1, at - cols, at + cols]) {
          const nx = next % cols,
            ny = Math.floor(next / cols);
          if (nx < x0 || nx >= x1 || ny < y0 || ny >= y1 || !connected[next])
            continue;
          connected[next] = 0;
          queue.push(next);
        }
      }
      const w = maxX - minX + 1,
        h = maxY - minY + 1;
      if (
        support < 12 ||
        w < 6 ||
        h < 6 ||
        w > window.width * 0.2 ||
        h > window.height * 0.2 ||
        w / h > 3 ||
        h / w > 3
      )
        continue;
      const pad = Math.max(5, Math.ceil(Math.max(w, h) * 0.35));
      const left = Math.max(x0, minX - pad),
        right = Math.min(x1, maxX + pad + 1);
      const top = Math.max(y0, minY - pad),
        bottom = Math.min(y1, maxY + pad + 1);
      let motion = 0,
        surroundings = 0;
      for (let sy = top; sy < bottom; sy++) {
        for (let sx = left; sx < right; sx++) {
          if (sx >= minX && sx <= maxX && sy >= minY && sy <= maxY) continue;
          surroundings++;
          motion += moving[sy * cols + sx]!;
        }
      }
      if (motion < surroundings * 0.08) continue;
      boxes.push({
        x: left,
        y: top,
        width: right - left,
        height: bottom - top,
      });
    }
  }
  return boxes;
}

export function intersect(a: Rect, b: Rect): Rect | null {
  const x = Math.max(a.x, b.x),
    y = Math.max(a.y, b.y);
  const right = Math.min(a.x + a.width, b.x + b.width);
  const bottom = Math.min(a.y + a.height, b.y + b.height);
  return right > x && bottom > y
    ? { x, y, width: right - x, height: bottom - y }
    : null;
}

/** Split a rectangle around an occlusion; returned pieces contain source pixels only. */
export function subtract(rect: Rect, occlusion: Rect): Rect[] {
  const overlap = intersect(rect, occlusion);
  if (!overlap) return [rect];
  return [
    { x: rect.x, y: rect.y, width: rect.width, height: overlap.y - rect.y },
    {
      x: rect.x,
      y: overlap.y + overlap.height,
      width: rect.width,
      height: rect.y + rect.height - overlap.y - overlap.height,
    },
    {
      x: rect.x,
      y: overlap.y,
      width: overlap.x - rect.x,
      height: overlap.height,
    },
    {
      x: overlap.x + overlap.width,
      y: overlap.y,
      width: rect.x + rect.width - overlap.x - overlap.width,
      height: overlap.height,
    },
  ].filter((piece) => piece.width > 0 && piece.height > 0);
}

/** A vertical match can use a narrower strip, but must keep its source columns. */
export function cleanTemplateColumn(
  template: Rect,
  occlusions: Rect[],
): Rect | null {
  let spans = [template];
  for (const occlusion of occlusions) {
    if (!intersect(template, occlusion)) continue;
    spans = spans.flatMap((span) =>
      subtract(span, { ...occlusion, y: template.y, height: template.height }),
    );
  }
  const widest = spans.sort((a, b) => b.width - a.width)[0];
  return widest && widest.width >= template.width / 4 ? widest : null;
}
