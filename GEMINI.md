# Gemini Code Assistant Context

## Project Overview

This project, named "picsew", is a **TypeScript web application** that automatically analyzes a screen recording of a scrolling window and stitches the content together to create a single, long screenshot. It leverages browser-side computation using OpenCV.js.

The UI is built with **React**, **Next.js**, **Tailwind CSS**, and the **Shadcn/ui** component library.

The main logic for the web application is contained within `src/App.tsx` (the main application component) and `src/lib/picsew.ts` (the core video processing logic). The application processes a user-uploaded video file and displays the final stitched long screenshot directly in the browser.

**Python Version (Legacy):**

The original Python script, which provides the same core functionality, is now located in `scripts/main.py`. It reads a `demo.MP4` video file, processes it to find the largest moving contour, and saves the results as JPG images in the `dist/` directory. The script produces two main output files:
- `dist/detected_windows.jpg`: A debug image showing the first frame with the detected original (red) and inset (green) scrolling windows.
- `dist/stitched_screenshot.jpg`: The final, stitched long screenshot of the scrolling content.

## Building and Running the TypeScript Web Application

This project is a Next.js application and uses npm for package management.

### Dependencies

The project's dependencies are listed in `package.json`. The UI is built with **React**, **Next.js**, **Tailwind CSS**, and **Shadcn/ui**.

Additionally, it uses `OpenCV.js` loaded via CDN for image processing.

### Running the Application

To run the web application, execute the following commands from the project root directory:

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

## Building and Running the Python Version (Legacy)

This project's Python version is a script and does not have a separate build process. It uses `uv` for environment and package management, with dependencies defined in `pyproject.toml`.

### Dependencies (Python)

The Python project's dependencies are listed in the `pyproject.toml` file and include:

*   `imagehash`
*   `numpy`
*   `opencv-python`

### Running the Python Script

To run the Python script, execute the following commands from the project root directory using `uv`:

```bash
    uv run python scripts/main.py /path/to/your/video.mp4
```

**Prerequisites (Python):**

*   Ensure that a video file named `demo.MP4` exists in the project's root directory. If you want to use a different video file, you can pass its path as a command-line argument:
    ```bash
    uv run python scripts/main.py /path/to/your/video.mp4
    ```
*   The required Python packages must be installed. You can install them using `uv`:
    ```bash
    uv pip install imagehash numpy opencv-python
    ```

## Development Conventions

*   The TypeScript web application follows standard Next.js/React/TypeScript conventions.
*   The Python script follows standard Python conventions.
*   Output files for the Python script are saved to the `dist/` directory.

## Development Workflow

This project follows an iterative development process. Each step will produce a visual result that will be confirmed by the user before proceeding to the next step. This ensures that the implementation is aligned with the user's expectations.