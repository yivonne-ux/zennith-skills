#!/usr/bin/env python3
"""GrabFood Photo Refiner — AI-powered per-dish refinement via Gemini.

NOT batch processing. Each dish gets individual Gemini edit:
1. Clean white background
2. 45-degree hero angle (diner's perspective)
3. Warm, appetizing food photography look
4. 800x800 Grab-ready output

Uses Gemini 2.0 Flash image editing (native image generation).

Usage:
  refine-photos.py --input <folder> --merchant <name> [--output <dir>]
  refine-photos.py --single <photo> --name "Dish Name" [--output <dir>]
"""

import argparse
import base64
import json
import os
import sys
import time
import httpx
from pathlib import Path
from PIL import Image, ImageEnhance

# ── CONFIG ──
GEMINI_KEY = os.environ.get("GEMINI_API_KEY", "")
if not GEMINI_KEY:
    # Check multiple locations for Gemini key
    key_locations = [
        Path.home() / ".openclaw" / ".env",
        Path.home() / ".openclaw" / "secrets" / "gemini.env",
        Path.home() / ".env",
    ]
    for env_file in key_locations:
        if env_file.exists():
            for line in env_file.read_text().splitlines():
                if line.startswith("GEMINI_API_KEY="):
                    GEMINI_KEY = line.split("=", 1)[1].strip()
                    break
        if GEMINI_KEY:
            break

GEMINI_MODEL = "gemini-2.5-flash-image"  # Native image generation model
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{GEMINI_MODEL}:generateContent?key={GEMINI_KEY}"

GRAB_SIZE = (800, 800)
THUMB_SIZE = (80, 80)

# ── GEMINI PROMPT ──
# This is the core — each photo gets this treatment
REFINE_PROMPT = """Edit this food photo for a professional food delivery app menu listing.

REQUIREMENTS:
1. BACKGROUND: Change to clean, warm white background (slightly off-white, RGB ~248,246,240). Remove ALL existing background — no table, no restaurant, no clutter. Just the dish on clean white.

2. ANGLE: If the food is shot from directly above (flat-lay/overhead), re-render it from a 45-degree hero angle (diner's perspective looking down at the plate). Keep the food and plating EXACTLY as shown.

3. LIGHTING: Soft natural side light from upper-left. Warm color temperature (slightly golden, 5500-6000K feel). Gentle highlight on food surface. Soft drop shadow under the plate/bowl.

4. FOOD: Preserve the food EXACTLY as provided — same dish, same ingredients, same plating. Make colors warmer and more appetizing. Enhance:
   - Reds and oranges (sauces, prawns, meat) — richer
   - Greens (vegetables, herbs) — fresher
   - Sauce sheen and gloss — more visible
   - Texture (crispy edges, steam if hot dish)

5. COMPOSITION: Food centered, filling 65-75% of frame. Clean, minimal — no props, no text, no extra garnish.

6. OUTPUT: Professional food delivery menu photo. Must look appetizing even at 80px thumbnail size. Clean white background with soft drop shadow only.

CRITICAL: Do NOT change what the food IS. Only change the background, lighting, and color warmth. The dish must be recognizable as the same food."""


def refine_with_gemini(input_path: str, output_path: str, dish_name: str = "") -> bool:
    """Send photo to Gemini for AI refinement."""
    if not GEMINI_KEY:
        print("  ERROR: No GEMINI_API_KEY found")
        return False

    # Read and resize input (Gemini has size limits)
    img = Image.open(input_path).convert("RGB")
    # Resize to max 1024 on longest side for API
    max_dim = 1024
    if max(img.size) > max_dim:
        ratio = max_dim / max(img.size)
        new_size = (int(img.size[0] * ratio), int(img.size[1] * ratio))
        img = img.resize(new_size, Image.LANCZOS)

    # Convert to base64
    import io
    buf = io.BytesIO()
    img.save(buf, format="JPEG", quality=90)
    img_b64 = base64.b64encode(buf.getvalue()).decode()

    # Add dish name context to prompt if provided
    prompt = REFINE_PROMPT
    if dish_name:
        prompt = f"This dish is: {dish_name}\n\n{prompt}"

    payload = {
        "contents": [{
            "parts": [
                {"text": prompt},
                {"inline_data": {"mime_type": "image/jpeg", "data": img_b64}},
            ]
        }],
        "generationConfig": {
            "responseModalities": ["TEXT", "IMAGE"],
        },
    }

    try:
        resp = httpx.post(
            GEMINI_URL,
            json=payload,
            timeout=90,
        )

        if resp.status_code == 200:
            result = resp.json()
            candidates = result.get("candidates", [])
            if candidates:
                parts = candidates[0].get("content", {}).get("parts", [])
                for part in parts:
                    if "inlineData" in part:
                        img_data = base64.b64decode(part["inlineData"]["data"])
                        # Save raw Gemini output
                        raw_path = Path(output_path).parent / f"{Path(output_path).stem}_raw.jpg"
                        raw_path.write_bytes(img_data)

                        # Post-process: crop to 800x800 + slight enhance
                        refined = Image.open(raw_path).convert("RGB")
                        refined = smart_crop(refined, GRAB_SIZE)

                        # Subtle final enhance
                        refined = ImageEnhance.Sharpness(refined).enhance(1.10)
                        refined = ImageEnhance.Color(refined).enhance(1.05)

                        refined.save(output_path, "JPEG", quality=92)

                        # Generate thumbnail
                        thumb = smart_crop(Image.open(output_path), THUMB_SIZE)
                        thumb_path = Path(output_path).parent / f"{Path(output_path).stem}_thumb.jpg"
                        thumb.save(str(thumb_path), "JPEG", quality=85)

                        # Clean up raw
                        raw_path.unlink(missing_ok=True)

                        kb = Path(output_path).stat().st_size / 1024
                        print(f"  REFINED: {Path(output_path).name} ({kb:.0f}KB)")
                        return True

            print(f"  WARN: Gemini returned no image for {Path(input_path).name}")
            # Print text response if any
            for part in parts:
                if "text" in part:
                    print(f"    Gemini says: {part['text'][:200]}")
            return False
        else:
            print(f"  ERROR: Gemini API {resp.status_code}: {resp.text[:200]}")
            return False

    except Exception as e:
        print(f"  ERROR: Gemini request failed: {e}")
        return False


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


def refine_folder(input_dir: Path, merchant: str, output_dir: Path):
    """Refine all photos in a folder — one Gemini call per photo."""
    out_photos = output_dir / "photos-refined"
    out_photos.mkdir(parents=True, exist_ok=True)

    image_exts = {'.jpg', '.jpeg', '.png'}
    photos = sorted([
        f for f in input_dir.iterdir()
        if f.is_file() and f.suffix.lower() in image_exts
        and not f.name.startswith('.') and not f.name.startswith('_')
        and 'thumb' not in f.name.lower()
    ])

    print(f"\n{'='*60}")
    print(f"REFINING: {merchant} ({len(photos)} photos)")
    print(f"Using Gemini AI — white bg + 45° angle + warm food photography")
    print(f"{'='*60}\n")

    refined = 0
    failed = 0

    for i, photo in enumerate(photos):
        print(f"[{i+1}/{len(photos)}] {photo.name}")

        # Build output name
        slug = photo.stem.replace(" ", "-").lower()[:60]
        out_path = out_photos / f"{merchant}_{slug}_refined.jpg"

        # Extract dish name from filename if possible
        dish_name = photo.stem.replace("_", " ").replace("-", " ")
        # Remove common prefixes
        for prefix in [merchant, "grab-800", "banner", "thumb", "copy of"]:
            dish_name = dish_name.replace(prefix, "").strip()

        success = refine_with_gemini(str(photo), str(out_path), dish_name)

        if success:
            refined += 1
        else:
            failed += 1

        # Rate limit: Gemini free tier = 15 req/min
        if i < len(photos) - 1:
            time.sleep(4.5)  # ~13 req/min, safe margin

    print(f"\n{'='*60}")
    print(f"DONE: {refined} refined, {failed} failed")
    print(f"Output: {out_photos}")
    print(f"{'='*60}")


def refine_single(photo_path: str, dish_name: str, output_dir: Path):
    """Refine a single photo."""
    output_dir.mkdir(parents=True, exist_ok=True)
    slug = dish_name.replace(" ", "-").lower()[:40]
    out_path = output_dir / f"{slug}_refined.jpg"

    print(f"\nRefining: {Path(photo_path).name} as '{dish_name}'")
    success = refine_with_gemini(photo_path, str(out_path), dish_name)

    if success:
        print(f"Output: {out_path}")
    else:
        print("Failed — check Gemini API key and try again")


def main():
    parser = argparse.ArgumentParser(description="GrabFood Photo Refiner — AI per-dish refinement")
    parser.add_argument("--input", "-i", help="Input folder of photos to refine")
    parser.add_argument("--single", "-s", help="Single photo path to refine")
    parser.add_argument("--name", "-n", help="Dish name (for single mode)")
    parser.add_argument("--merchant", "-m", default="merchant", help="Merchant name slug")
    parser.add_argument("--output", "-o", help="Output directory")
    args = parser.parse_args()

    output_dir = Path(args.output) if args.output else Path.home() / "Desktop" / "Grab Listing Output" / args.merchant

    if args.single:
        dish_name = args.name or Path(args.single).stem
        refine_single(args.single, dish_name, output_dir)
    elif args.input:
        refine_folder(Path(args.input), args.merchant, output_dir)
    else:
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
