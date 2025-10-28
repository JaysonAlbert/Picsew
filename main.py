import cv2
import numpy as np
import argparse

def stitch_keyframes(keyframes, refined_window, frame_width):
    """Stitches the keyframes together to create a long screenshot of the entire screen."""
    if not keyframes:
        return None

    x, y, w, h = refined_window

    # --- 1. Calculate Offsets ---
    offsets = []
    for i in range(len(keyframes) - 1):
        frame1 = keyframes[i]
        frame2 = keyframes[i+1]

        window1 = frame1[y:y+h, x:x+w]
        window2 = frame2[y:y+h, x:x+w]

        template_height = h // 3
        template = window1[h - template_height:, :]

        res = cv2.matchTemplate(window2, template, cv2.TM_CCOEFF_NORMED)
        _, _, _, max_loc = cv2.minMaxLoc(res)

        # Calculate both vertical and horizontal offsets
        v_offset = (h - template_height) - max_loc[1]
        h_offset = max_loc[0]
        offsets.append((v_offset, h_offset))

    # --- 2. Stitch the Images ---
    header = keyframes[0][0:y, :]
    footer = keyframes[-1][y+h:, :]

    total_height = header.shape[0] + h + sum([v for v, h_off in offsets]) + footer.shape[0]
    stitched_image = np.zeros((total_height, frame_width, 3), dtype=np.uint8)

    stitched_image[0:header.shape[0], :] = header
    current_y = header.shape[0]

    stitched_image[current_y : current_y + h, :] = keyframes[0][y:y+h, :]
    current_y += h

    for i, (v_offset, h_offset) in enumerate(offsets):
        keyframe = keyframes[i+1]
        scrolling_window = keyframe[y:y+h, x:x+w]

        new_part = scrolling_window[h - v_offset:, :]

        if new_part.shape[0] > 0:
            # Create a new slice and paste the new part with the horizontal offset
            new_slice = np.zeros((new_part.shape[0], w, 3), dtype=np.uint8)
            new_slice[:, h_offset:h_offset+new_part.shape[1]] = new_part

            stitched_image[current_y : current_y + new_slice.shape[0], :] = new_slice
            current_y += new_slice.shape[0]

    stitched_image[current_y : current_y + footer.shape[0], :] = footer
    current_y += footer.shape[0]

    return stitched_image[:current_y, :]

def main():
    parser = argparse.ArgumentParser(description='Create a long screenshot from a scrolling video.')
    parser.add_argument('video_path', nargs='?', default='demo.MP4', help='Path to the video file.')
    args = parser.parse_args()

    cap = cv2.VideoCapture(args.video_path)

    if not cap.isOpened():
        print(f"Error: Could not open video file: {args.video_path}")
        return

    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frames = []
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        frames.append(frame)

    if len(frames) < 2:
        print("Not enough frames to process.")
        cap.release()
        return

    # --- Find the refined scrolling window ---
    motion_accumulator = np.zeros((frames[0].shape[0], frames[0].shape[1]), dtype=np.float32)
    for i in range(len(frames) - 1):
        gray1 = cv2.cvtColor(frames[i], cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(frames[i+1], cv2.COLOR_BGR2GRAY)
        diff = cv2.absdiff(gray1, gray2)
        _, thresh = cv2.threshold(diff, 30, 255, cv2.THRESH_BINARY)
        motion_accumulator += thresh
    
    motion_accumulator = cv2.normalize(motion_accumulator, None, 0, 255, cv2.NORM_MINMAX)
    _, motion_mask = cv2.threshold(motion_accumulator.astype(np.uint8), 50, 255, cv2.THRESH_BINARY)
    contours, _ = cv2.findContours(motion_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    if not contours:
        print("No consistent motion detected.")
        cap.release()
        return

    largest_contour = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(largest_contour)

    # Create the outside mask from the original, full-sized scrolling window
    outside_mask = np.ones(frames[0].shape[:2], dtype=np.uint8) * 255
    outside_mask[y:y+h, x:x+w] = 0

    # Inset the window to avoid sticky headers/footers
    inset_pixels = int(h * 0.1)
    y += inset_pixels
    h -= inset_pixels * 2

    refined_window = (0, y, frame_width, h)
    print(f"Detected refined window: {refined_window}")

    # --- Keyframe Selection ---
    candidate_keyframes = [frames[0]]
    last_keyframe_index = 0

    while last_keyframe_index < len(frames) - 1:
        accumulated_offset = 0
        last_frame_in_chunk = frames[last_keyframe_index]

        found_next_keyframe = False
        for i in range(last_keyframe_index + 1, len(frames)):
            current_frame = frames[i]

            template_height = h // 4
            template_y_start = y + h // 2 - template_height // 2
            template = last_frame_in_chunk[template_y_start:template_y_start+template_height, x:x+w]
            
            scrolling_window_content = current_frame[y:y+h, x:x+w]
            res = cv2.matchTemplate(scrolling_window_content, template, cv2.TM_CCOEFF_NORMED)
            _, max_val, _, max_loc = cv2.minMaxLoc(res)

            if max_val > 0.7:
                offset_since_last_frame = (template_y_start - y) - max_loc[1]
                if offset_since_last_frame > 0:
                    accumulated_offset += offset_since_last_frame

            last_frame_in_chunk = current_frame

            if accumulated_offset > h * 0.5:
                candidate_keyframes.append(current_frame)
                last_keyframe_index = i
                found_next_keyframe = True
                break
        
        if not found_next_keyframe:
            break

    if last_keyframe_index != len(frames) - 1:
        candidate_keyframes.append(frames[-1])
    
    print(f"Selected {len(candidate_keyframes)} candidate keyframes.")

    # --- Filter candidate keyframes ---
    clean_keyframes = [candidate_keyframes[0]]
    for i in range(1, len(candidate_keyframes)):
        gray1 = cv2.cvtColor(candidate_keyframes[i-1], cv2.COLOR_BGR2GRAY)
        gray2 = cv2.cvtColor(candidate_keyframes[i], cv2.COLOR_BGR2GRAY)
        diff = cv2.absdiff(gray1, gray2)
        _, thresh = cv2.threshold(diff, 30, 255, cv2.THRESH_BINARY)
        
        changes_outside = cv2.bitwise_and(thresh, thresh, mask=outside_mask)
        
        total_outside_pixels = np.sum(outside_mask) / 255
        changed_outside_pixels = np.sum(changes_outside) / 255
        change_percentage = (changed_outside_pixels / total_outside_pixels) * 100

        if change_percentage < 1:
            clean_keyframes.append(candidate_keyframes[i])

    print(f"Selected {len(clean_keyframes)} final keyframes after filtering.")

    # --- Stitching ---
    stitched_image = stitch_keyframes(clean_keyframes, refined_window, frame_width)

    if stitched_image is not None:
        output_path = 'dist/stitched_screenshot.jpg'
        cv2.imwrite(output_path, stitched_image)
        print(f"Stitched screenshot saved to {output_path}")
    else:
        print("Stitching failed.")

    cap.release()

if __name__ == "__main__":
    main()
