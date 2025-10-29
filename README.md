# Picsew - Automatic Scrolling Screenshot Stitcher

This project is a **TypeScript web application** that automatically analyzes a screen recording of a scrolling window and stitches the content together to create a single, long screenshot. It leverages browser-side computation using OpenCV.js.

It produces one main output:
- The final, stitched long screenshot, displayed directly in the browser.

## Algorithm

The process for creating the long screenshot is as follows:

### 1. Scrolling Area Detection

The first step is to accurately identify the vertical zone of the screen that is scrolling.

1.  **Motion Accumulation:** The algorithm processes the video frame by frame and calculates the difference between each consecutive frame. These differences are added together into a single "motion heat map."
2.  **Contour Detection:** This heat map is then thresholded to create a binary mask that isolates the areas with the most consistent motion. The largest contour in this mask is assumed to be the scrolling content.
3.  **Vertical Zone Identification:** The vertical bounds (`y` coordinate and `height`) of the largest contour's bounding box define the primary scrolling zone. For robustness against issues like static margins, this zone is always treated as being the **full width** of the video frame in all subsequent steps.
4.  **Visualization (Debug - Removed by default):** The original Python script included a debug image showing the first frame with detected scrolling windows. This visualization is now removed by default in the TypeScript version to streamline the output.

### 2. Keyframe Selection

To avoid processing every single frame, a few keyframes are intelligently selected from the video. This process uses a vertically "inset" version of the scrolling window to avoid issues with "sticky" headers or footers that might be part of the scrolling content.

1.  **Accumulated Scroll:** The algorithm starts with the first frame as the first keyframe. It then processes the subsequent frames, calculating the incremental scroll distance between each one using template matching within the inset scrolling window.
2.  **50% Threshold:** When the *accumulated* scroll distance since the last keyframe exceeds 50% of the inset window's height, the current frame is selected as a new "candidate" keyframe.
3.  **Add Last Frame:** This process continues until the end of the video. To ensure the entire scroll is captured, the very last frame of the video is always added to the list of candidates.

### 3. Interruption Filtering

Candidate keyframes are then filtered to remove any that contain interruptions (like notifications or pop-ups) outside the main scrolling content.

1.  **Exterior Change Detection:** For each candidate keyframe, the algorithm checks for any significant visual changes in the area *outside* the scrolling zone by comparing it to the previous keyframe.
2.  **Masking:** The "outside" area is defined as everything above and below the *initial* (pre-inset) full-width scrolling zone. This ensures that motion at the edges of the scrolling content does not cause a keyframe to be incorrectly discarded.
3.  **Lenient Thresholding:** To avoid false positives from minor visual noise, a keyframe is only discarded if more than 1% of the pixels in the exterior area have changed.

This results in a final, small list of clean keyframes that are ready for stitching.

### 4. Stitching

The final step is to stitch the clean keyframes together into a single, seamless image. This step uses the final, **inset** scrolling window.

1.  **Header and Footer:** The static header (everything above the inset scrolling window) is taken from the first keyframe, and the static footer (everything below) is taken from the last keyframe.
2.  **Offset Calculation:** For each consecutive pair of keyframes, the precise vertical and horizontal scroll offset is calculated using template matching.
3.  **Canvas Assembly:** A new, blank canvas is created. The header is pasted at the top. The scrolling content from the first keyframe is pasted below it. Then, for each subsequent keyframe, the new, non-overlapping portion of the scrolling content is shifted horizontally to correct for any wobble and then appended to the canvas. Finally, the footer is pasted at the very bottom.

This process results in a single, perfectly aligned long screenshot.

## How to Run the TypeScript Web Application

This project uses Next.js and npm for environment and package management.

1.  **Install Dependencies:**
    ```bash
    npm install
    ```
2.  **Run the Development Server:**
    ```bash
    npm run dev
    ```
3.  Open your browser to `http://localhost:3000`.
4.  Upload a video file and click "Process Video".

## Python Version (Legacy)

The original Python script is now located in the `scripts/` directory. It uses `uv` for environment and package management, with dependencies defined in `pyproject.toml`.

1.  **Install Dependencies (Python):**
    ```bash
    uv pip install -e .
    ```
2.  **Run the Python Script:**
    ```bash
    uv run python scripts/main.py /path/to/your/video.mp4
    ```
    If no path is provided, it will default to using `demo.MP4` in the project root.