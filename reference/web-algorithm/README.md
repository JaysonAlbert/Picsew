# Web Algorithm Reference

This directory documents the current behavior baseline for the future Swift migration.

## Reference files

- `/Volumes/data/Projects/Picsew/src/lib/picsew.ts`
- `/Volumes/data/Projects/Picsew/src/lib/picsew-utils.ts`
- `/Volumes/data/Projects/Picsew/src/lib/opencv.ts`

## Migration rule

The native iOS implementation should preserve the logical behavior of this pipeline during the initial port:

1. Read metadata
2. Extract low-resolution frames
3. Detect the scrolling window
4. Select and filter keyframes
5. Compute offsets
6. Stitch the final image

Any intentional algorithm change after parity is reached should be documented as a separate design change, not folded into the baseline port.
