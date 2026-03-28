#!/usr/bin/env python3
"""
kinetic-frames.py — Generate text frames as PNG images using PIL
Then FFmpeg stitches them into a video (no drawtext filter needed)

Usage:
  python3 kinetic-frames.py word-by-word "The universe is listening" 6 /output/dir
  python3 kinetic-frames.py slide-reveal "Phrase 1|Phrase 2|Phrase 3" 12 /output/dir
  python3 kinetic-frames.py quote "Your daily oracle message" 10 /output/dir

Args: mode text duration_sec output_dir [bg_color] [font_color] [accent_color]
"""

import sys
import os
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("ERROR: Pillow not installed. Run: pip3 install Pillow", file=sys.stderr)
    sys.exit(1)

WIDTH = 1080
HEIGHT = 1920
FPS = 30


def get_font(size):
    """Find a bold font on macOS."""
    candidates = [
        "/System/Library/Fonts/Supplemental/Impact.ttf",
        "/System/Library/Fonts/Supplemental/Verdana Bold.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for f in candidates:
        if os.path.exists(f):
            try:
                return ImageFont.truetype(f, size)
            except Exception:
                continue
    return ImageFont.load_default()


def hex_to_rgb(h):
    """Convert hex color to RGB tuple."""
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))


def draw_centered_text(draw, text, font, color, y_offset=0):
    """Draw centered multiline text."""
    lines = text.split('\n')
    line_height = getattr(font, 'size', 40) + 10
    total_height = len(lines) * line_height
    start_y = (HEIGHT - total_height) // 2 + y_offset

    for i, line in enumerate(lines):
        bbox = draw.textbbox((0, 0), line, font=font)
        text_w = bbox[2] - bbox[0]
        x = (WIDTH - text_w) // 2
        y = start_y + i * line_height
        # Shadow
        draw.text((x + 2, y + 2), line, font=font, fill=(0, 0, 0, 128))
        # Main text
        draw.text((x, y), line, font=font, fill=color)


def wrap_text(text, max_chars=25):
    """Wrap text to fit within max characters per line."""
    words = text.split()
    lines = []
    current = ""
    for w in words:
        if len(current) + len(w) + 1 > max_chars and current:
            lines.append(current)
            current = w
        else:
            current = f"{current} {w}".strip()
    if current:
        lines.append(current)
    return '\n'.join(lines)


def gen_word_by_word(text, duration, output_dir, bg_color, font_color):
    """Generate frames where words appear one at a time."""
    words = text.split()
    total_frames = duration * FPS
    frames_per_word = max(1, total_frames // len(words))
    font = get_font(72)
    bg_rgb = hex_to_rgb(bg_color)
    fg_rgb = hex_to_rgb(font_color)

    frame_num = 0
    for word_idx in range(len(words)):
        # Show cumulative words
        visible = ' '.join(words[:word_idx + 1])
        wrapped = wrap_text(visible, 20)

        for f in range(frames_per_word):
            img = Image.new('RGB', (WIDTH, HEIGHT), bg_rgb)
            draw = ImageDraw.Draw(img)
            draw_centered_text(draw, wrapped, font, fg_rgb)
            img.save(f"{output_dir}/frame-{frame_num:05d}.png")
            frame_num += 1

    # Hold final frame for remaining duration
    while frame_num < total_frames:
        img = Image.new('RGB', (WIDTH, HEIGHT), bg_rgb)
        draw = ImageDraw.Draw(img)
        draw_centered_text(draw, wrap_text(text, 20), font, fg_rgb)
        img.save(f"{output_dir}/frame-{frame_num:05d}.png")
        frame_num += 1

    print(f"Generated {frame_num} frames in {output_dir}")
    return frame_num


def gen_slide_reveal(text, duration, output_dir, bg_color, font_color):
    """Generate frames for phrase-by-phrase reveal."""
    phrases = [p.strip() for p in text.split('|')]
    total_frames = duration * FPS
    frames_per_phrase = max(1, total_frames // len(phrases))
    font = get_font(80)
    bg_rgb = hex_to_rgb(bg_color)
    fg_rgb = hex_to_rgb(font_color)

    frame_num = 0
    for phrase in phrases:
        wrapped = wrap_text(phrase, 20)
        fade_frames = min(9, frames_per_phrase // 3)  # 0.3s fade at 30fps

        for f in range(frames_per_phrase):
            img = Image.new('RGB', (WIDTH, HEIGHT), bg_rgb)
            draw = ImageDraw.Draw(img)

            # Fade in effect (only use expensive RGBA composite during actual fade)
            alpha = min(255, int(255 * f / fade_frames)) if f < fade_frames else 255

            if alpha < 255:
                color = (*fg_rgb, alpha)
                overlay = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
                overlay_draw = ImageDraw.Draw(overlay)
                draw_centered_text(overlay_draw, wrapped, font, color)
                img = img.convert('RGBA')
                img = Image.alpha_composite(img, overlay)
                img = img.convert('RGB')
            else:
                draw_centered_text(draw, wrapped, font, fg_rgb)

            img.save(f"{output_dir}/frame-{frame_num:05d}.png")
            frame_num += 1

    print(f"Generated {frame_num} frames in {output_dir}")
    return frame_num


def gen_quote(text, duration, output_dir, bg_color, font_color):
    """Generate frames for a single quote with subtle animation."""
    total_frames = duration * FPS
    font = get_font(64)
    bg_rgb = hex_to_rgb(bg_color)
    fg_rgb = hex_to_rgb(font_color)
    wrapped = wrap_text(text, 25)

    for frame_num in range(total_frames):
        img = Image.new('RGB', (WIDTH, HEIGHT), bg_rgb)
        draw = ImageDraw.Draw(img)

        # Subtle scale animation (zoom 1.0 -> 1.02 over duration)
        draw_centered_text(draw, wrapped, font, fg_rgb)

        # Subtle vignette: darken edges with semi-transparent black
        vignette = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
        vdraw = ImageDraw.Draw(vignette)
        for edge in range(40):
            opacity = int(30 * (1 - edge / 40))
            vdraw.rectangle([edge, edge, WIDTH - edge, HEIGHT - edge],
                           outline=(0, 0, 0, opacity), width=1)
        img = img.convert('RGBA')
        img = Image.alpha_composite(img, vignette)
        img = img.convert('RGB')

        img.save(f"{output_dir}/frame-{frame_num:05d}.png")

    print(f"Generated {total_frames} frames in {output_dir}")
    return total_frames


if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("Usage: kinetic-frames.py <mode> <text> <duration_sec> <output_dir> [bg_hex] [fg_hex]")
        sys.exit(1)

    mode = sys.argv[1]
    text = sys.argv[2]
    duration = int(sys.argv[3])
    output_dir = sys.argv[4]
    bg_color = sys.argv[5] if len(sys.argv) > 5 else "1A1A1A"
    font_color = sys.argv[6] if len(sys.argv) > 6 else "FFFFFF"

    os.makedirs(output_dir, exist_ok=True)

    if mode == "word-by-word":
        gen_word_by_word(text, duration, output_dir, bg_color, font_color)
    elif mode == "slide-reveal":
        gen_slide_reveal(text, duration, output_dir, bg_color, font_color)
    elif mode == "quote":
        gen_quote(text, duration, output_dir, bg_color, font_color)
    else:
        print(f"Unknown mode: {mode}")
        sys.exit(1)
