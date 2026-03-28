#!/usr/bin/env python3
"""GrabFood Listing Optimizer — End-to-end pipeline.

Usage:
  grab-listing.py audit     --input <folder> --merchant <name>
  grab-listing.py process   --input <folder> --merchant <name> [--output <dir>]
  grab-listing.py full      --input <folder> --merchant <name> [--output <dir>]

Modes:
  audit    — Map files, identify quality tiers, report gaps
  process  — Convert HEIC, crop 800x800, enhance, generate thumbnails
  full     — audit + process + copy output to Desktop
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from PIL import Image, ImageEnhance, ImageDraw


# ── PHOTO ENHANCEMENT ────────────────────────────────────

GRAB_SIZE = (800, 800)
BANNER_SIZE = (1350, 750)
THUMB_SIZE = (80, 80)


def smart_crop(img, target_size):
    """Center-crop to target aspect ratio, then resize."""
    tw, th = target_size
    target_ratio = tw / th
    iw, ih = img.size
    img_ratio = iw / ih
    if img_ratio > target_ratio:
        new_w = int(ih * target_ratio)
        left = (iw - new_w) // 2
        img = img.crop((left, 0, left + new_w, ih))
    elif img_ratio < target_ratio:
        new_h = int(iw / target_ratio)
        top = (ih - new_h) // 2
        img = img.crop((0, top, iw, top + new_h))
    return img.resize(target_size, Image.LANCZOS)


def detect_background(img):
    """Detect if background is white, black, or mixed."""
    w, h = img.size
    corners = []
    for x, y in [(10, 10), (w-10, 10), (10, h-10), (w-10, h-10)]:
        if 0 <= x < w and 0 <= y < h:
            corners.append(img.getpixel((x, y)))
    avg = tuple(int(sum(c[i] for c in corners) / len(corners)) for i in range(3))
    brightness = sum(avg) / 3
    if brightness > 200:
        return "white"
    elif brightness < 60:
        return "black"
    else:
        return "mixed"


def enhance_photo(img, bg_type="auto"):
    """Color enhance for food photos based on background type."""
    img = img.convert("RGB")

    if bg_type == "auto":
        bg_type = detect_background(img)

    settings = {
        "white":  {"brightness": 1.05, "warmth_r": 6,  "warmth_g": 2, "saturation": 1.15, "contrast": 1.08, "sharpness": 1.15},
        "black":  {"brightness": 1.25, "warmth_r": 10, "warmth_g": 4, "saturation": 1.20, "contrast": 1.12, "sharpness": 1.20},
        "mixed":  {"brightness": 1.15, "warmth_r": 8,  "warmth_g": 3, "saturation": 1.18, "contrast": 1.10, "sharpness": 1.15},
    }
    s = settings.get(bg_type, settings["mixed"])

    # Warmth
    r, g, b = img.split()
    r = r.point(lambda x: min(255, x + s["warmth_r"]))
    g = g.point(lambda x: min(255, x + s["warmth_g"]))
    img = Image.merge("RGB", (r, g, b))

    img = ImageEnhance.Color(img).enhance(s["saturation"])
    img = ImageEnhance.Contrast(img).enhance(s["contrast"])
    img = ImageEnhance.Brightness(img).enhance(s["brightness"])
    img = ImageEnhance.Sharpness(img).enhance(s["sharpness"])
    return img


def process_single(src_path, prefix, out_dir, bg_type="auto"):
    """Process one photo → grab-800 + banner + thumb."""
    try:
        img = Image.open(str(src_path)).convert("RGB")
    except Exception as e:
        print(f"  SKIP: {src_path.name}: {e}")
        return None

    enhanced = enhance_photo(img, bg_type)

    grab = smart_crop(enhanced, GRAB_SIZE)
    grab_path = out_dir / f"{prefix}_grab-800.jpg"
    grab.save(str(grab_path), "JPEG", quality=92)

    banner = smart_crop(enhanced, BANNER_SIZE)
    banner_path = out_dir / f"{prefix}_banner-1350.jpg"
    banner.save(str(banner_path), "JPEG", quality=90)

    thumb = smart_crop(enhanced, THUMB_SIZE)
    thumb_path = out_dir / f"{prefix}_thumb-80.jpg"
    thumb.save(str(thumb_path), "JPEG", quality=85)

    kb = grab_path.stat().st_size / 1024
    bg = bg_type if bg_type != "auto" else detect_background(img)
    print(f"  OK: {prefix} ({bg} bg) -> 800x800 ({kb:.0f}KB)")
    return grab_path


def generate_grid(out_dir):
    """Generate thumbnail test grid from all thumb files."""
    thumbs = sorted(out_dir.glob("*_thumb-80.jpg"))
    if not thumbs:
        return
    cols = min(8, len(thumbs))
    rows = (len(thumbs) + cols - 1) // cols
    padding = 4
    label_h = 14
    cell_w = THUMB_SIZE[0] + padding
    cell_h = THUMB_SIZE[1] + padding + label_h
    grid = Image.new("RGB", (cols * cell_w + padding, rows * cell_h + padding), (255, 255, 255))
    draw = ImageDraw.Draw(grid)
    for i, tp in enumerate(thumbs):
        row, col = divmod(i, cols)
        x = col * cell_w + padding
        y = row * cell_h + padding
        thumb = Image.open(tp)
        grid.paste(thumb, (x, y))
        label = tp.stem.replace("_thumb-80", "")
        label = label.split("_", 1)[-1][:14] if "_" in label else label[:14]
        draw.text((x, y + THUMB_SIZE[1] + 1), label, fill=(0, 0, 0))
    grid_path = out_dir / "_THUMBNAIL_TEST_GRID.jpg"
    grid.save(str(grid_path), "JPEG", quality=95)
    print(f"  Grid: {grid_path} ({len(thumbs)} items)")


# ── HEIC CONVERSION ──────────────────────────────────────

def convert_heic_files(input_dir):
    """Convert all HEIC files in directory to JPG using macOS sips."""
    heic_files = list(input_dir.glob("**/*.HEIC")) + list(input_dir.glob("**/*.heic"))
    converted = 0
    for hf in heic_files:
        jpg_path = hf.parent / f"{hf.stem}_converted.jpg"
        if jpg_path.exists():
            continue
        result = subprocess.run(
            ["sips", "-s", "format", "jpeg", str(hf), "--out", str(jpg_path)],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print(f"  HEIC: {hf.name} -> {jpg_path.name}")
            converted += 1
    return converted


# ── AUDIT ────────────────────────────────────────────────

def audit(input_dir, merchant):
    """Map all files, categorize by quality tier, report."""
    print(f"\n{'='*60}")
    print(f"AUDIT: {merchant}")
    print(f"Input: {input_dir}")
    print(f"{'='*60}\n")

    all_files = []
    image_exts = {'.jpg', '.jpeg', '.png', '.heic', '.jfif', '.webp'}
    for f in input_dir.rglob("*"):
        if f.is_file() and f.suffix.lower() in image_exts and not f.name.startswith('.'):
            all_files.append(f)

    print(f"Total image files: {len(all_files)}")

    # Categorize
    by_ext = {}
    by_folder = {}
    for f in all_files:
        ext = f.suffix.lower()
        by_ext[ext] = by_ext.get(ext, 0) + 1
        folder = f.parent.name
        by_folder[folder] = by_folder.get(folder, 0) + 1

    print(f"\nBy extension:")
    for ext, count in sorted(by_ext.items(), key=lambda x: -x[1]):
        print(f"  {ext}: {count}")

    print(f"\nBy folder (top 15):")
    for folder, count in sorted(by_folder.items(), key=lambda x: -x[1])[:15]:
        print(f"  {count:4d} files: {folder}")

    # Find named product files
    named = [f for f in all_files if any(k in f.name.lower() for k in ['copy of', 'quality', 'edited', 'confirm', 'final'])]
    if named:
        print(f"\nNamed/edited files ({len(named)}):")
        for f in named[:20]:
            print(f"  {f.name}")

    heic_count = sum(1 for f in all_files if f.suffix.lower() == '.heic')
    if heic_count:
        print(f"\nHEIC files needing conversion: {heic_count}")

    return all_files


# ── PROCESS ──────────────────────────────────────────────

def process(input_dir, merchant, output_dir):
    """Full processing pipeline."""
    print(f"\n{'='*60}")
    print(f"PROCESS: {merchant}")
    print(f"{'='*60}\n")

    out_photos = output_dir / "photos"
    out_reports = output_dir / "reports"
    out_photos.mkdir(parents=True, exist_ok=True)
    out_reports.mkdir(parents=True, exist_ok=True)

    # Step 1: Convert HEIC
    print("Step 1: Converting HEIC files...")
    converted = convert_heic_files(input_dir)
    print(f"  Converted: {converted} files\n")

    # Step 2: Find and process all usable images
    print("Step 2: Processing photos...")
    image_exts = {'.jpg', '.jpeg', '.png'}
    processed = 0

    for f in sorted(input_dir.rglob("*")):
        if not f.is_file() or f.suffix.lower() not in image_exts:
            continue
        if f.name.startswith('.') or 'Screenshot' in f.name:
            continue

        # Build prefix from filename
        slug = f.stem.replace(" ", "-").replace("(", "").replace(")", "")
        slug = slug[:50]
        prefix = f"{merchant}_{slug}"

        result = process_single(f, prefix, out_photos)
        if result:
            processed += 1

    print(f"\n  Processed: {processed} photos")

    # Step 3: Generate grid
    print("\nStep 3: Generating thumbnail grid...")
    generate_grid(out_photos)

    # Summary
    grab_files = list(out_photos.glob("*_grab-800.jpg"))
    total_kb = sum(f.stat().st_size for f in grab_files) / 1024
    print(f"\n{'='*60}")
    print(f"DONE: {len(grab_files)} Grab-ready photos ({total_kb/1024:.1f}MB)")
    print(f"Output: {output_dir}")
    print(f"{'='*60}")


# ── MAIN ─────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="GrabFood Listing Optimizer")
    parser.add_argument("mode", choices=["audit", "process", "full"], help="Pipeline mode")
    parser.add_argument("--input", "-i", required=True, help="Input photo folder")
    parser.add_argument("--merchant", "-m", required=True, help="Merchant name slug")
    parser.add_argument("--output", "-o", help="Output directory (default: ~/Desktop/Grab Listing Output/<merchant>)")
    args = parser.parse_args()

    input_dir = Path(args.input).expanduser()
    if not input_dir.exists():
        print(f"ERROR: Input directory not found: {input_dir}")
        sys.exit(1)

    output_dir = Path(args.output) if args.output else Path.home() / "Desktop" / "Grab Listing Output" / args.merchant
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.mode == "audit":
        audit(input_dir, args.merchant)
    elif args.mode == "process":
        process(input_dir, args.merchant, output_dir)
    elif args.mode == "full":
        audit(input_dir, args.merchant)
        process(input_dir, args.merchant, output_dir)


if __name__ == "__main__":
    main()
