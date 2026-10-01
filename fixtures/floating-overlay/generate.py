"""Regenerate public synthetic fixtures; requires Pillow and ffmpeg."""

import pathlib
import random
import shutil
import subprocess
import tempfile

from PIL import Image, ImageDraw

OUTPUT = pathlib.Path(__file__).resolve().parent
FFMPEG = shutil.which("ffmpeg")
if not FFMPEG:
    raise SystemExit("ffmpeg is required to regenerate fixtures")

rng = random.Random(314)
document = Image.new("RGB", (480, 2200), "white")
draw = ImageDraw.Draw(document)
for y in range(0, 2200, 28):
    colour = tuple(rng.randrange(30, 150) for _ in range(3))
    for x in range(15, 465, 14):
        draw.rectangle((x, y + 5, x + 8, y + rng.randrange(12, 21)), fill=colour)
    draw.rectangle((4, y + 3, 10, y + 22), fill=(30, 80, 210))
for y in (150, 430, 710, 990):
    # Genuine document arrows, deliberately near the floating control's column.
    draw.rectangle((215, y, 265, y + 23), fill="white")
    draw.line((240, y + 2, 240, y + 18), fill=(0, 170, 50), width=5)
    draw.line((231, y + 10, 240, y + 19, 249, y + 10), fill=(0, 170, 50), width=5)
for y in range(0, 2200, 20):
    # A connected moving region isolates this test from the legacy window heuristic.
    colour = (40, 40, 40) if (y // 20) % 2 else (220, 220, 220)
    draw.rectangle((0, y, 50, y + 19), fill=colour)
document.save(OUTPUT / "document.png")

with tempfile.TemporaryDirectory() as temporary:
    frames = pathlib.Path(temporary)
    for kind in ("fixed", "clean", "white", "dark", "glass"):
        for index in range(36):
            frame = Image.new("RGB", (480, 720), (235, 235, 235))
            position = min(index, 34) * 20  # Hold the last position across the codec boundary.
            frame.paste(document.crop((0, position, 480, position + 560)), (0, 80))
            draw = ImageDraw.Draw(frame)
            draw.text((20, 25), "SCROLLING DOCUMENT", fill=(40, 40, 40))
            draw.text((20, 670), "FIXED FOOTER", fill=(40, 40, 40))
            if kind == "glass":
                # Viewport-fixed glass shading changes brightness, not document
                # coordinates. Recovering tiny rectangles leaves visible seams.
                shade = Image.new("RGBA", frame.size, (0, 0, 0, 0))
                shade_draw = ImageDraw.Draw(shade)
                for row in range(530, 640):
                    shade_draw.line((0, row, 479, row), fill=(0, 0, 0, round((row - 530) / 110 * 70)))
                frame = Image.alpha_composite(frame.convert("RGBA"), shade).convert("RGB")
                draw = ImageDraw.Draw(frame)
                # A separate changing footer patch models content visible through
                # glass UI; early candidates fail the outside-motion filter.
                draw.rectangle((15, 650, 135, 690), fill=(min(index, 24) * 10,) * 3)
            if kind != "clean":
                colour = {"fixed": (255, 0, 180), "white": (245, 245, 245), "dark": (35, 35, 35), "glass": (245, 245, 245)}[kind]
                shift = 65 if kind == "glass" else 0
                draw.ellipse((214, 484 + shift, 266, 536 + shift), fill=colour, outline=(100, 100, 100), width=1)
                arrow = (230, 230, 230) if kind == "dark" else (25, 25, 25)
                draw.line((240, 496 + shift, 240, 524 + shift), fill=arrow, width=5)
                draw.line((229, 513 + shift, 240, 524 + shift, 251, 513 + shift), fill=arrow, width=5)
            frame.save(frames / f"{index:03}.png")
        codecs = {
            "mp4": ["-c:v", "libx264", "-crf", "10", "-g", "1", "-bf", "0", "-pix_fmt", "yuv420p"],
            "webm": ["-c:v", "libvpx-vp9", "-lossless", "1", "-pix_fmt", "yuv444p"],
        }
        for extension, options in codecs.items():
            subprocess.run([
                FFMPEG, "-hide_banner", "-loglevel", "error", "-y", "-framerate", "6",
                "-i", str(frames / "%03d.png"), *options, str(OUTPUT / f"{kind}.{extension}"),
            ], check=True)
