# Floating-control regression document

These recordings are synthetic, generated from `document.png`. Nothing here comes
from a user recording. Each clip contains 36 frames at 6 fps, a document moving up
20 pixels per frame (the last frame repeats), and a fixed header/footer. Four green arrows belong to the
document. `fixed` adds a pink down-button, `white` and `dark` use neutral button
colours, and `clean` has no control. The control covers one genuine document arrow. A wide moving stripe at the left
provides a connected motion region for the existing window-selection heuristic.

The known output is 480 × 1400: 80 pixels of header, the first 1240 document rows,
and 80 pixels of footer. Earlier occlusions can be restored from later frames;
the last control has no clean source and must be preserved. Tests compare repaired
patches to the original document, with encoding tolerance, and count all four
moving document arrows. They run through the public processing API with real
video decoding and OpenCV, without mocking algorithm stages.

VP9 lossless WebM runs in bundled Chromium; intra-frame H.264 MP4 runs in WebKit.
Fixtures are committed so CI does not need media-generation tools. To regenerate,
install Pillow and ffmpeg and run `python3 fixtures/floating-overlay/generate.py`.
The two formats may have small colour differences from RGB/YUV conversion.
