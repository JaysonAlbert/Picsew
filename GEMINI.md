# Gemini Code Assistant Context

## Project Overview

This project, named "picsew", is a Python application designed to analyze video files to detect and identify moving or scrolling areas. It uses the OpenCV library to process video frames, calculate differences between them, and use image manipulation techniques like thresholding, dilation, and erosion to isolate the moving regions. The primary goal appears to be identifying a scrolling area within a screen recording, likely for applications such as creating a single panoramic screenshot from a video.

The main logic is contained within `main.py`, which reads a `demo.MP4` video file, processes it to find the largest moving contour, and saves the results as JPG images in the `dist/` directory. The script produces two main output files:
- `dist/detected_windows.jpg`: A debug image showing the first frame with the detected original (red) and inset (green) scrolling windows.
- `dist/stitched_screenshot.jpg`: The final, stitched long screenshot of the scrolling content.

## Building and Running

This project is a Python script and does not have a separate build process.

### Dependencies

The project's dependencies are listed in the `pyproject.toml` file and include:

*   `imagehash`
*   `numpy`
*   `opencv-python`

### Running the Application

To run the application, execute the main script from the project root directory using `uv`:

```bash
uv run python main.py
```

**Prerequisites:**

*   Ensure that a video file named `demo.MP4` exists in the project's root directory. If you want to use a different video file, you can pass its path as a command-line argument:
    ```bash
    uv run python main.py /path/to/your/video.mp4
    ```
*   The required Python packages must be installed. You can install them using `uv`:
    ```bash
    uv pip install imagehash numpy opencv-python
    ```

## Development Conventions

*   The project follows standard Python conventions.
*   The main script is self-contained and executed directly.
*   Output files are saved to the `dist/` directory.

## Development Workflow

This project follows an iterative development process. Each step will produce a visual result that will be confirmed by the user before proceeding to the next step. This ensures that the implementation is aligned with the user's expectations.