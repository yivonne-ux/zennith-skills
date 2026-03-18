#!/usr/bin/env python3
"""smart-crop.py — 9:16 smart cropping with speaker tracking.

Detects speaker/subject position using FFmpeg cropdetect heuristics
and applies dynamic pan to follow the subject. Falls back to center
crop if no clear subject detected.

Input: landscape (16:9) video
Output: portrait (9:16) video at 1080x1920
"""

import argparse
import json
import os
import subprocess
import sys
import re


def get_video_info(input_path):
    """Get video dimensions and duration."""
    cmd = [
        "ffprobe", "-v", "quiet",
        "-select_streams", "v:0",
        "-show_entries", "stream=width,height,duration",
        "-show_entries", "format=duration",
        "-of", "json", input_path,
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)

    stream = data.get("streams", [{}])[0]
    width = int(stream.get("width", 1920))
    height = int(stream.get("height", 1080))
    duration = float(stream.get("duration", 0) or data.get("format", {}).get("duration", 0))

    return width, height, duration


def detect_face_regions(input_path, sample_interval=2.0):
    """Sample frames and detect face-like regions using FFmpeg cropdetect.

    Uses a simple heuristic: sample frames at intervals, use cropdetect
    to find the content region, and infer speaker position from that.
    """
    width, height, duration = get_video_info(input_path)

    if duration <= 0:
        return None, width, height

    # Sample frames at intervals and detect crop regions
    regions = []
    t = 0.0
    while t < duration:
        cmd = [
            "ffmpeg", "-ss", str(t), "-i", input_path,
            "-vframes", "1",
            "-vf", "cropdetect=24:2:0",
            "-f", "null", "-",
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)

        # Parse cropdetect output: crop=W:H:X:Y
        for line in result.stderr.split("\n"):
            match = re.search(r"crop=(\d+):(\d+):(\d+):(\d+)", line)
            if match:
                cw, ch, cx, cy = int(match.group(1)), int(match.group(2)), int(match.group(3)), int(match.group(4))
                # Center of detected content
                center_x = cx + cw // 2
                regions.append({"t": t, "center_x": center_x, "width": cw})
                break

        t += sample_interval

    if not regions:
        return None, width, height

    return regions, width, height


def build_crop_filter(regions, src_width, src_height, target_w=1080, target_h=1920):
    """Build FFmpeg crop filter that follows the detected subject.

    Returns a crop filter string that pans horizontally to follow
    the subject's position across the video.
    """
    # Calculate crop dimensions in source resolution
    # We want 9:16 from source, so crop_h = src_height, crop_w = src_height * 9 / 16
    crop_h = src_height
    crop_w = int(src_height * 9 / 16)

    if crop_w > src_width:
        # Source is already narrower than 9:16
        crop_w = src_width
        crop_h = int(src_width * 16 / 9)

    if not regions:
        # Center crop
        x = (src_width - crop_w) // 2
        y = (src_height - crop_h) // 2
        return f"crop={crop_w}:{crop_h}:{x}:{y},scale={target_w}:{target_h}"

    # Calculate average center position
    avg_center = sum(r["center_x"] for r in regions) / len(regions)

    # Check if subject moves significantly
    centers = [r["center_x"] for r in regions]
    movement_range = max(centers) - min(centers)

    if movement_range < src_width * 0.1:
        # Minimal movement — static crop centered on average position
        x = int(avg_center - crop_w // 2)
        x = max(0, min(x, src_width - crop_w))
        y = (src_height - crop_h) // 2
        return f"crop={crop_w}:{crop_h}:{x}:{y},scale={target_w}:{target_h}"

    # Dynamic pan: use expression to smoothly follow subject
    # Build keyframe-based x position with linear interpolation
    # FFmpeg expression: smooth pan using time-based interpolation
    min_x = 0
    max_x = src_width - crop_w

    # Clamp all centers to valid crop range
    keyframes = []
    for r in regions:
        x = int(r["center_x"] - crop_w // 2)
        x = max(min_x, min(x, max_x))
        keyframes.append((r["t"], x))

    if len(keyframes) < 2:
        x = int(avg_center - crop_w // 2)
        x = max(0, min(x, src_width - crop_w))
        y = (src_height - crop_h) // 2
        return f"crop={crop_w}:{crop_h}:{x}:{y},scale={target_w}:{target_h}"

    # Build a smooth pan expression using linear interpolation between keyframes
    # FFmpeg 'if(between(t,a,b), lerp, ...)' chain
    expr_parts = []
    for i in range(len(keyframes) - 1):
        t0, x0 = keyframes[i]
        t1, x1 = keyframes[i + 1]
        # Linear interpolation: x0 + (x1-x0) * (t-t0) / (t1-t0)
        if t1 > t0:
            lerp = f"{x0}+({x1}-{x0})*(t-{t0})/({t1}-{t0})"
            expr_parts.append(f"between(t\\,{t0}\\,{t1})*({lerp})")

    # Sum all parts (only one between() is true at any time)
    x_expr = "+".join(expr_parts) if expr_parts else str(int(avg_center - crop_w // 2))

    y = (src_height - crop_h) // 2
    return f"crop={crop_w}:{crop_h}:'{x_expr}':{y},scale={target_w}:{target_h}"


def smart_crop(input_path, output_path, target_w=1080, target_h=1920):
    """Apply smart 9:16 crop to video."""
    # Check if video is already portrait — skip crop if height > width * 1.5
    pre_w, pre_h, _ = get_video_info(input_path)
    if pre_h > pre_w * 1.5:
        print(f"Video is already portrait ({pre_w}x{pre_h}), skipping smart crop — scaling only", file=sys.stderr)
        cmd = [
            "ffmpeg", "-y", "-i", input_path,
            "-vf", f"scale={target_w}:{target_h}:force_original_aspect_ratio=decrease,pad={target_w}:{target_h}:(ow-iw)/2:(oh-ih)/2:black",
            "-c:v", "libx264", "-preset", "fast", "-crf", "23",
            "-c:a", "aac", "-b:a", "128k",
            output_path,
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            print(f"FFmpeg scale error: {result.stderr[-300:]}", file=sys.stderr)
            return False
        print(f"Portrait scale complete: {output_path}", file=sys.stderr)
        return True

    print(f"Analyzing video for subject tracking...", file=sys.stderr)

    regions, src_width, src_height = detect_face_regions(input_path)

    if regions:
        print(f"Detected {len(regions)} subject positions, applying dynamic crop", file=sys.stderr)
    else:
        print(f"No clear subject detected, using center crop", file=sys.stderr)

    vf = build_crop_filter(regions, src_width, src_height, target_w, target_h)

    cmd = [
        "ffmpeg", "-y", "-i", input_path,
        "-vf", vf,
        "-c:v", "libx264", "-preset", "fast", "-crf", "23",
        "-c:a", "aac", "-b:a", "128k",
        output_path,
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"FFmpeg error: {result.stderr[-300:]}", file=sys.stderr)
        return False

    print(f"Smart crop complete: {output_path}", file=sys.stderr)
    return True


def main():
    parser = argparse.ArgumentParser(description="Smart 9:16 crop with subject tracking")
    parser.add_argument("--input", required=True, help="Input video file")
    parser.add_argument("--output", required=True, help="Output video file")
    parser.add_argument("--width", type=int, default=1080, help="Target width (default: 1080)")
    parser.add_argument("--height", type=int, default=1920, help="Target height (default: 1920)")
    args = parser.parse_args()

    if not os.path.exists(args.input):
        print(f"Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    success = smart_crop(args.input, args.output, args.width, args.height)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
