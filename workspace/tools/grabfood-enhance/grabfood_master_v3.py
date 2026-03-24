#!/usr/bin/env python3
"""
GrabFood Master V3 — Deterministic White Background
====================================================

V2 problem: NANO produces grey background, not white. Unreliable.
V3 fix: NANO only enhances food. rembg removes bg. PIL places on white.

Pipeline:
  1. ANALYZE photo (adaptive)
  2. NANO PASS 1: enhance food+plate to reference level (keep original bg)
  3. REMBG: remove background → transparent PNG cutout
  4. PIL: place on GUARANTEED white canvas (248,246,240)
  5. PIL: add programmatic drop shadow
  6. PIL: adaptive color grade + film grain
  7. FIT into frame (never crop)
  8. EXPORT + QA

White background is 100% controlled by PIL, not AI. No variability.
"""

import os, sys, json, io, argparse, time
from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw
import numpy as np
import urllib.request

FAL_KEY = os.environ.get("FAL_KEY", "")

BG_COLOR = (248, 246, 240)  # Warm white — guaranteed consistent
FOOD_FILL = 0.72            # Food fills 72% of frame


# ═══════════════════════════════════════════════════════
# ANALYSIS
# ═══════════════════════════════════════════════════════

def analyze(img):
    arr = np.array(img.convert("RGB"), dtype=np.float64)
    gray = np.mean(arr, axis=2)
    brightness = np.mean(gray)
    r, g, b = np.mean(arr[:,:,0]), np.mean(arr[:,:,1]), np.mean(arr[:,:,2])
    warmth = r - b
    hsv = img.convert("HSV")
    sat = np.mean(np.array(hsv)[:,:,1])
    con = np.std(gray)

    gx = np.diff(gray, axis=1)
    gy = np.diff(gray, axis=0)
    mn = min(gx.shape[0], gy.shape[0])
    sharp = np.mean(np.sqrt(gx[:mn,:]**2 + gy[:mn,:gx.shape[1]]**2))

    return {
        "brightness": brightness,
        "warmth": warmth, "r": r, "g": g, "b": b,
        "sat": sat, "contrast": con, "sharpness": sharp,
        "is_dark": brightness < 100,
        "is_bright": brightness > 180,
        "is_cool": warmth < -5,
        "is_very_warm": warmth > 50,
        "is_flat": con < 35,
        "is_soft": sharp < 8,
        "is_desaturated": sat < 50,
    }


# ═══════════════════════════════════════════════════════
# NANO API
# ═══════════════════════════════════════════════════════

def fal_upload(img_or_path, name="image.png"):
    if isinstance(img_or_path, (str, Path)):
        data = Path(img_or_path).read_bytes()
        ct = "image/jpeg" if str(img_or_path).lower().endswith((".jpg",".jpeg")) else "image/png"
        name = Path(img_or_path).name
    else:
        buf = io.BytesIO(); img_or_path.save(buf, "PNG"); data = buf.getvalue()
        ct = "image/png"

    r = urllib.request.Request("https://rest.alpha.fal.ai/storage/upload/initiate",
        data=json.dumps({"file_name": name, "content_type": ct}).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    resp = json.loads(urllib.request.urlopen(r, timeout=30).read())
    urllib.request.urlopen(urllib.request.Request(resp["upload_url"],
        data=data, headers={"Content-Type": ct}, method="PUT"), timeout=60)
    return resp["file_url"]


def nano_edit(prompt, urls):
    r = urllib.request.Request("https://fal.run/fal-ai/nano-banana-pro/edit",
        data=json.dumps({"prompt": prompt, "image_urls": urls}).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    result = json.loads(urllib.request.urlopen(r, timeout=180).read())
    return Image.open(io.BytesIO(urllib.request.urlopen(
        result["images"][0]["url"], timeout=60).read()))


# ═══════════════════════════════════════════════════════
# DISH TYPE DNA
# ═══════════════════════════════════════════════════════

DISH_DNA = {
    "noodle": "glossy sauce coating, springy noodle texture, glistening toppings, fresh spring onion",
    "noodle_soup": "rich broth with visible depth, gentle steam rising, noodles in clear soup",
    "soup": "deeply colored broth, visible herbs and ingredients, steam rising, inviting warmth",
    "rice": "fluffy individual rice grains glistening, vibrant toppings neatly arranged",
    "fried": "golden crispy crust texture, crunchy edges visible, freshly fried look",
    "curry": "thick glossy gravy coating ingredients, oil sheen on surface, rich deep color",
    "dimsum": "delicate translucent dumpling skin, visible filling, steamer basket warmth",
    "default": "enhanced food textures, appetizing and fresh looking, just-prepared appearance",
}


# ═══════════════════════════════════════════════════════
# STEP 1: NANO ENHANCE (food quality only, keep bg)
# ═══════════════════════════════════════════════════════

def enhance_food(img, ref_path, dish_type, analysis):
    """NANO enhances food quality. Does NOT touch background."""

    dish_note = DISH_DNA.get(dish_type, DISH_DNA["default"])
    urls = []

    if ref_path and Path(ref_path).exists():
        ref_url = fal_upload(ref_path)
        img_url = fal_upload(img)
        urls = [ref_url, img_url]
        ref_line = "Image 1 = REFERENCE (match this quality level). Image 2 = photo to enhance.\n\n"
        food_ref = "Image 2"
    else:
        img_url = fal_upload(img)
        urls = [img_url]
        ref_line = "Image 1 = food photo to enhance.\n\n"
        food_ref = "Image 1"

    # Adaptive notes
    notes = []
    if analysis["is_dark"]: notes.append("Brighten — currently underexposed.")
    if analysis["is_cool"]: notes.append("Warm up — currently has cool/blue cast.")
    if analysis["is_very_warm"]: notes.append("Reduce yellow cast slightly, keep warm.")
    if analysis["is_soft"]: notes.append("Sharpen food textures.")
    if analysis["is_desaturated"]: notes.append("Boost color vibrancy.")
    adaptive = " ".join(notes) if notes else "Subtle enhancement only — photo quality is already decent."

    prompt = (
        f"{ref_line}"
        f"ENHANCE the food in {food_ref} to professional food photography level.\n\n"
        f"SACRED RULE: Do NOT change what the food IS. Keep every ingredient, "
        f"every topping, every sauce drip exactly as placed. "
        f"Only improve the QUALITY of how it looks.\n\n"
        f"LIGHTING: Improve to soft, warm directional light from upper-left. "
        f"Add gentle specular highlights on glossy surfaces. "
        f"Warm color temperature (golden hour feel). {adaptive}\n\n"
        f"FOOD TEXTURE: {dish_note}.\n\n"
        f"PLATE: If plate looks cheap (plastic, chipped), subtly upgrade to "
        f"premium ceramic/earthenware. Keep same shape and food placement.\n\n"
        f"KEEP the existing background — do NOT change or remove it. "
        f"Background will be handled separately.\n\n"
        f"Result should look like professional food magazine photography."
    )

    return nano_edit(prompt, urls)


# ═══════════════════════════════════════════════════════
# STEP 2: BACKGROUND REMOVAL (deterministic)
# ═══════════════════════════════════════════════════════

def remove_bg(img):
    """Remove background using rembg. Returns RGBA with transparent bg."""
    from rembg import remove
    result = remove(
        img,
        alpha_matting=True,
        alpha_matting_foreground_threshold=240,
        alpha_matting_background_threshold=20,
        alpha_matting_erode_size=10,
    )
    return result


# ═══════════════════════════════════════════════════════
# STEP 3: WHITE CANVAS + SHADOW (PIL — 100% controlled)
# ═══════════════════════════════════════════════════════

def create_drop_shadow(cutout, shadow_offset=(8, 12), shadow_blur=25, shadow_opacity=0.25):
    """Create a realistic soft drop shadow for the food cutout."""
    w, h = cutout.size

    # Create shadow from alpha channel
    if cutout.mode != "RGBA":
        return Image.new("RGBA", (w, h), (0, 0, 0, 0))

    alpha = cutout.split()[3]

    # Shadow layer — dark, offset, blurred
    shadow = Image.new("RGBA", (w + 40, h + 40), (0, 0, 0, 0))
    shadow_alpha = Image.new("L", (w + 40, h + 40), 0)

    # Paste alpha as shadow shape, offset
    ox, oy = shadow_offset
    shadow_alpha.paste(alpha, (20 + ox, 20 + oy))

    # Blur the shadow
    shadow_alpha = shadow_alpha.filter(ImageFilter.GaussianBlur(radius=shadow_blur))

    # Apply opacity
    shadow_alpha = shadow_alpha.point(lambda x: int(x * shadow_opacity))

    # Create warm shadow (not pure black — slightly warm brown)
    shadow_color = Image.new("RGBA", shadow_alpha.size, (40, 30, 20, 0))
    shadow_color.putalpha(shadow_alpha)

    return shadow_color


def place_on_white(cutout, target_size=800):
    """Place food cutout on guaranteed white canvas with shadow. Never crop."""

    w, h = cutout.size

    # Calculate size to fit within canvas with breathing room
    inner = int(target_size * FOOD_FILL)
    ratio = min(inner / w, inner / h)
    new_w = int(w * ratio)
    new_h = int(h * ratio)

    # Resize cutout
    food = cutout.resize((new_w, new_h), Image.LANCZOS)

    # Create shadow
    shadow = create_drop_shadow(food, shadow_offset=(6, 10), shadow_blur=20, shadow_opacity=0.20)

    # Create canvas
    canvas = Image.new("RGBA", (target_size, target_size), BG_COLOR + (255,))

    # Center positions
    food_x = (target_size - new_w) // 2
    food_y = (target_size - new_h) // 2

    # Shadow position (aligned with food, slightly offset)
    shadow_x = food_x - 20  # shadow has 20px padding
    shadow_y = food_y - 20

    # Paste shadow first, then food on top
    if shadow.size[0] <= target_size and shadow.size[1] <= target_size:
        canvas.paste(shadow, (shadow_x, shadow_y), shadow)

    canvas.paste(food, (food_x, food_y), food)

    return canvas.convert("RGB")


def place_on_white_banner(cutout, target_w=1350, target_h=750):
    """Place food on banner canvas. Never crop."""

    w, h = cutout.size
    inner_w = int(target_w * FOOD_FILL)
    inner_h = int(target_h * FOOD_FILL)
    ratio = min(inner_w / w, inner_h / h)
    new_w = int(w * ratio)
    new_h = int(h * ratio)

    food = cutout.resize((new_w, new_h), Image.LANCZOS)
    shadow = create_drop_shadow(food, shadow_offset=(5, 8), shadow_blur=18, shadow_opacity=0.18)

    canvas = Image.new("RGBA", (target_w, target_h), BG_COLOR + (255,))
    food_x = (target_w - new_w) // 2
    food_y = (target_h - new_h) // 2
    shadow_x = food_x - 20
    shadow_y = food_y - 20

    if shadow.size[0] <= target_w and shadow.size[1] <= target_h:
        canvas.paste(shadow, (shadow_x, shadow_y), shadow)
    canvas.paste(food, (food_x, food_y), food)

    return canvas.convert("RGB")


# ═══════════════════════════════════════════════════════
# STEP 4: COLOR GRADE + GRAIN
# ═══════════════════════════════════════════════════════

def color_grade(img, analysis):
    """Adaptive color grading. Light touch — NANO already enhanced."""
    img = img.convert("RGB")

    # Subtle vibrance boost
    enhancer = ImageEnhance.Color(img)
    mult = 1.12 if analysis["is_desaturated"] else 1.05
    img = enhancer.enhance(mult)

    # Subtle contrast
    enhancer = ImageEnhance.Contrast(img)
    mult = 1.08 if analysis["is_flat"] else 1.03
    img = enhancer.enhance(mult)

    # Subtle sharpening
    enhancer = ImageEnhance.Sharpness(img)
    mult = 1.2 if analysis["is_soft"] else 1.08
    img = enhancer.enhance(mult)

    return img


def film_grain(img, strength=0.010):
    """Subtle organic film grain — luminosity dependent, warm tinted."""
    arr = np.array(img.convert("RGB"), dtype=np.float64)
    h, w = arr.shape[:2]

    noise = np.random.normal(0, 1, (h, w))
    gray = np.mean(arr, axis=2) / 255.0
    lum_weight = np.exp(-((gray - 0.5) ** 2) / (2 * 0.15 ** 2))

    grain = noise * lum_weight * strength * 255

    # Don't apply grain to the white background area
    # Detect background (brightness > 240)
    bg_mask = gray > 0.92
    grain[bg_mask] = 0  # No grain on white bg

    arr[:, :, 0] = np.clip(arr[:, :, 0] + grain * 1.03, 0, 255)
    arr[:, :, 1] = np.clip(arr[:, :, 1] + grain, 0, 255)
    arr[:, :, 2] = np.clip(arr[:, :, 2] + grain * 0.95, 0, 255)

    return Image.fromarray(arr.astype(np.uint8))


# ═══════════════════════════════════════════════════════
# MASTER PIPELINE
# ═══════════════════════════════════════════════════════

def find_ref(dish_type, ref_dir):
    """Find best reference for this dish type."""
    if not ref_dir: return None
    ref_dir = Path(ref_dir)
    for pattern in [f"{dish_type}*ref*", f"{dish_type}*", f"*{dish_type}*"]:
        matches = list(ref_dir.glob(f"{pattern}.jpg")) + list(ref_dir.glob(f"{pattern}.png"))
        if matches: return str(matches[0])
    sub = ref_dir / dish_type
    if sub.exists():
        refs = list(sub.glob("*.jpg")) + list(sub.glob("*.png"))
        if refs: return str(refs[0])
    return None


def process(input_path, output_dir, dish_name=None, dish_type="default",
            ref_path=None, ref_dir=None):
    """Full V3 pipeline — deterministic white background."""

    input_path = Path(input_path)
    name = dish_name or input_path.stem.lower().replace(" ", "-").replace("_", "-")
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"\n  {'━'*50}")
    print(f"  🍽️  {input_path.name}")
    print(f"  {'━'*50}")

    img = Image.open(input_path).convert("RGB")
    print(f"    📐 {img.size[0]}×{img.size[1]}")

    # Analyze
    a = analyze(img)
    print(f"    🔍 Brightness:{a['brightness']:.0f} Warmth:{a['warmth']:.0f} Sat:{a['sat']:.0f} Sharp:{a['sharpness']:.1f}")
    flags = [k for k in ['is_dark','is_bright','is_cool','is_very_warm','is_flat','is_soft','is_desaturated'] if a[k]]
    if flags: print(f"    ⚠️  Issues: {', '.join(f.replace('is_','') for f in flags)}")
    else: print(f"    ✅ Photo quality: decent baseline")

    # Find reference
    ref = ref_path or find_ref(dish_type, ref_dir)
    if ref: print(f"    🎨 Reference: {Path(ref).name}")

    # Step 1: NANO enhance food
    print(f"    ✨ NANO: enhancing food quality...")
    enhanced = enhance_food(img, ref, dish_type, a)
    print(f"       ✅ Food enhanced")
    time.sleep(3)

    # Step 2: Remove background
    print(f"    ✂️  rembg: removing background...")
    cutout = remove_bg(enhanced)
    print(f"       ✅ Background removed ({cutout.mode})")

    # Step 3: Place on white canvas
    print(f"    ⬜ PIL: white canvas + shadow...")
    square = place_on_white(cutout, 800)
    banner = place_on_white_banner(cutout, 1350, 750)
    print(f"       ✅ Placed on white (RGB {BG_COLOR})")

    # Step 4: Color grade + grain
    print(f"    🎬 Color grade + film grain...")
    a2 = analyze(square)
    square = color_grade(square, a2)
    square = film_grain(square, 0.010)
    banner = color_grade(banner, a2)
    banner = film_grain(banner, 0.010)
    print(f"       ✅ Graded (grain on food only, not background)")

    # Export
    menu_path = output_dir / f"{name}_800x800.jpg"
    square.save(menu_path, "JPEG", quality=93)

    banner_path = output_dir / f"{name}_1350x750.jpg"
    banner.save(banner_path, "JPEG", quality=93)

    thumb = square.resize((80, 80), Image.LANCZOS)
    thumb_path = output_dir / f"{name}_80px.jpg"
    thumb.save(thumb_path, "JPEG", quality=85)

    print(f"    💾 {menu_path.name} | {banner_path.name} | {thumb_path.name}")
    print(f"    ✅ Done")

    return square, banner


def batch(input_dir, output_dir, dish_type="default", ref_path=None, ref_dir=None):
    """Batch process with consistent mood."""
    input_dir = Path(input_dir)
    photos = sorted(list(input_dir.glob("*.jpg")) + list(input_dir.glob("*.jpeg")) +
                    list(input_dir.glob("*.png")))

    # Filter out already-enhanced files
    photos = [p for p in photos if "enhanced" not in str(p) and "_800x800" not in p.name
              and "_1350x750" not in p.name and "_80px" not in p.name]

    print(f"\n{'═'*55}")
    print(f"  GRABFOOD MASTER V3 — {len(photos)} photos")
    print(f"  White BG: RGB{BG_COLOR} (PIL controlled, guaranteed)")
    print(f"  Food fill: {FOOD_FILL*100:.0f}% of frame")
    print(f"{'═'*55}")

    results = []
    for i, photo in enumerate(photos):
        try:
            sq, bn = process(str(photo), str(output_dir), dish_type=dish_type,
                             ref_path=ref_path, ref_dir=ref_dir)
            results.append(sq)
        except Exception as e:
            print(f"    ❌ {photo.name}: {e}")
            import traceback; traceback.print_exc()

        if i < len(photos) - 1:
            time.sleep(5)

    # Consistency check
    if len(results) > 1:
        temps = []
        for img in results:
            arr = np.array(img)
            # Only check food area (center), not white bg
            h, w = arr.shape[:2]
            center = arr[int(h*0.2):int(h*0.8), int(w*0.2):int(w*0.8)]
            r, b = np.mean(center[:,:,0]), np.mean(center[:,:,2])
            temps.append(r - b)
        rng = max(temps) - min(temps)
        print(f"\n  🔎 Consistency: warmth range {rng:.0f} ({'✅ consistent' if rng < 20 else '⚠️ check manually'})")

    print(f"\n{'═'*55}")
    print(f"  ✅ BATCH COMPLETE: {len(results)}/{len(photos)}")
    print(f"{'═'*55}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GrabFood Master V3")
    parser.add_argument("input", help="Photo or directory")
    parser.add_argument("-o", "--output", default="./enhanced-v3")
    parser.add_argument("-n", "--name", default=None)
    parser.add_argument("-t", "--type", default="default",
                        choices=["noodle","noodle_soup","soup","rice","fried","curry","dimsum","default"])
    parser.add_argument("-r", "--reference", default=None)
    parser.add_argument("--ref-dir", default=None)
    args = parser.parse_args()

    p = Path(args.input)
    if p.is_dir():
        batch(str(p), args.output, args.type, args.reference, args.ref_dir)
    else:
        process(str(p), args.output, args.name, args.type, args.reference, args.ref_dir)
