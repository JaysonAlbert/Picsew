# Picsew - Automatic Scrolling Screenshot Stitcher

This project is a Python application that automatically analyzes a screen recording of a scrolling window and stitches the content together to create a single, long screenshot.

## Algorithm

The process for creating the long screenshot is as follows:

### 1. Refined Scrolling Window Detection

The first step is to accurately identify the area of the screen that is actually scrolling.

1.  **Motion Accumulation:** The algorithm processes the video frame by frame and calculates the difference between each consecutive frame. These differences are added together into a single image, or "motion heat map."
2.  **Thresholding:** This heat map is then thresholded to create a binary mask that isolates the areas with the most consistent motion.
3.  **Bounding Box:** The largest contour in this mask is found, and its bounding box is used as the precise, refined scrolling window for the rest of the process. The window is set to the full width of the video frame.

### 2. Keyframe Selection

To avoid processing every single frame, a few keyframes are intelligently selected from the video.

1.  **Accumulated Scroll:** The algorithm starts with the first frame as the first keyframe. It then processes the subsequent frames, calculating the incremental scroll distance between each one using template matching.
2.  **50% Threshold:** When the *accumulated* scroll distance since the last keyframe exceeds 50% of the scrolling window's height, the current frame is selected as a new "candidate" keyframe.
3.  **Add Last Frame:** This process continues until the end of the video. To ensure the entire scroll is captured, the very last frame of the video is always added to the list of candidates.

### 3. Interruption Filtering

Candidate keyframes are then filtered to remove any that contain interruptions (like notifications) outside the main scrolling window.

1.  **Exterior Change Detection:** For each candidate keyframe, the algorithm checks for any significant visual changes in the area *outside* the scrolling window by comparing it to the previous keyframe.
2.  **Lenient Thresholding:** To avoid false positives from minor visual noise, a keyframe is only discarded if more than 1% of the pixels in the exterior area have changed.

This results in a final, small list of clean keyframes that are ready for stitching.

### 4. Stitching

The final step is to stitch the clean keyframes together into a single, seamless image.

1.  **Header and Footer:** The static header (everything above the scrolling window) is taken from the first keyframe, and the static footer (everything below) is taken from the last keyframe.
2.  **Offset Calculation:** For each consecutive pair of keyframes, the precise vertical and horizontal scroll offset is calculated using template matching.
3.  **Canvas Assembly:** A new, blank canvas is created. The header is pasted at the top. The scrolling content from the first keyframe is pasted below it. Then, for each subsequent keyframe, the new, non-overlapping portion of the scrolling content is shifted horizontally to correct for any wobble and then appended to the canvas. Finally, the footer is pasted at the very bottom.

This process results in a single, perfectly aligned long screenshot.

## How to Run

This project uses `uv` for environment and package management, with dependencies defined in `pyproject.toml`.

1.  **Install Dependencies:**
    ```bash
    uv pip install -e .
    ```
2.  **Run the Script:**
    ```bash
    uv run python main.py /path/to/your/video.mp4
    ```
    If no path is provided, it will default to using `demo.MP4` in the project root.
