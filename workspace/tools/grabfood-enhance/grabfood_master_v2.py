#!/usr/bin/env python3
"""
GrabFood Master Enhancement Pipeline V2 — WORLD CLASS
======================================================

Reference-driven. Mood-consistent. Never crops food.

Architecture:
  1. ANALYZE each photo individually (exposure, color, sharpness, lighting)
  2. SELECT dish-type reference (noodle/soup/rice/fried/curry)
  3. ENHANCE via NANO: reference mood + original food preserved
  4. WHITE BG via NANO: second pass, clean background swap
  5. FIT into frame: food sits IN the canvas, never cropped
  6. GRADE: adaptive color science + film grain
  7. CONSISTENCY CHECK: all photos in batch share mood profile
  8. EXPORT: GrabFood sizes + thumbnail QA

Consistency model: Same MOOD PROFILE across batch, different DISH REFERENCE per type.
Like a pro photographer: same studio setup, different angles per dish.
"""

import os, sys, json, io, argparse, time
from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw, ImageFont
import numpy as np
import urllib.request

FAL_KEY = os.environ.get("FAL_KEY", "")

# ═══════════════════════════════════════════════════════
# MOOD PROFILE — constant per store batch
# ═══════════════════════════════════════════════════════

MOOD_PROFILE = {
    "color_temp": "warm golden, 5500-6000K feel, late afternoon natural light",
    "light_direction": "soft diffused light from upper-left, gentle shadows on right side",
    "background": "clean warm off-white (not clinical pure white — slightly cream like fine paper)",
    "shadow": "soft natural drop shadow under plate, connecting food to surface",
    "overall_feel": "refined hawker — elevated but honest, sophisticated but not pretentious",
    "grain_strength": 0.012,
    "bg_rgb": (248, 246, 240),
}

# ═══════════════════════════════════════════════════════
# DISH REFERENCE PROMPTS — varies per dish type
# ═══════════════════════════════════════════════════════

DISH_DNA = {
    "noodle": {
        "angle": "45-degree angle showing the noodle tangle and toppings",
        "texture": "glossy sauce coating on noodles, visible spring onion, char siu glistening",
        "enhance": "make the sauce look rich and glossy, noodles should look springy and fresh",
        "steam": "",
    },
    "noodle_soup": {
        "angle": "slightly above, showing broth surface and noodles submerged",
        "texture": "clear/rich broth with visible depth, noodles peeking through, toppings arranged",
        "enhance": "broth should look rich and inviting, slight sheen on surface",
        "steam": "gentle visible steam rising from the broth",
    },
    "soup": {
        "angle": "slightly above showing into the bowl, revealing broth and ingredients",
        "texture": "rich broth color, visible herbs and ingredients floating, depth in bowl",
        "enhance": "broth should look deeply flavored, ingredients clearly visible",
        "steam": "visible steam rising, suggesting just-served hotness",
    },
    "rice": {
        "angle": "45-degree angle showing fluffy rice mound and toppings",
        "texture": "individual rice grains visible, glistening slightly, toppings neatly arranged",
        "enhance": "rice should look fluffy and freshly cooked, toppings vibrant",
        "steam": "subtle heat haze from fresh rice",
    },
    "fried": {
        "angle": "45-degree or slightly lower to show golden crispy surface",
        "texture": "golden brown crust, visible crunch texture, crispy edges",
        "enhance": "emphasize the golden crispiness, make it look hot and freshly fried",
        "steam": "",
    },
    "curry": {
        "angle": "45-degree showing the rich gravy and ingredients",
        "texture": "thick glossy gravy coating ingredients, oil sheen on surface, rich color",
        "enhance": "gravy should look thick, rich, deeply spiced. Oil shimmer on surface.",
        "steam": "gentle steam from hot curry",
    },
    "dimsum": {
        "angle": "45-degree or slightly above, showing delicate wrapping",
        "texture": "translucent dumpling skin, visible filling, bamboo steamer texture",
        "enhance": "skin should look delicate and fresh, filling visible through skin",
        "steam": "steam from just-opened steamer basket",
    },
    "default": {
        "angle": "45-degree angle, the most flattering for most dishes",
        "texture": "enhance all visible textures — make food look fresh and just-prepared",
        "enhance": "boost appetite appeal while keeping the food completely authentic",
        "steam": "",
    },
}


# ═══════════════════════════════════════════════════════
# ANALYSIS ENGINE
# ═══════════════════════════════════════════════════════

def analyze(img):
    """Analyze photo and return what it needs."""
    arr = np.array(img.convert("RGB"), dtype=np.float64)
    h, w = arr.shape[:2]
    gray = np.mean(arr, axis=2)

    # Exposure
    brightness = np.mean(gray)
    if brightness < 100: exp = ("dark", min((130 - brightness) / 130, 0.4))
    elif brightness > 180: exp = ("bright", min((brightness - 150) / 150, 0.3))
    else: exp = ("ok", 0)

    # Color
    r, g, b = np.mean(arr[:,:,0]), np.mean(arr[:,:,1]), np.mean(arr[:,:,2])
    warmth = r - b
    if warmth < -5: col = ("cool", "needs warming")
    elif warmth > 50: col = ("very_warm", "slightly reduce yellow, keep warm")
    elif warmth > 25: col = ("warm", "good, maintain")
    else: col = ("neutral", "add warmth")

    # Saturation
    hsv = img.convert("HSV")
    sat = np.mean(np.array(hsv)[:,:,1])
    if sat < 50: sat_fix = ("flat", 1.20)
    elif sat > 160: sat_fix = ("oversaturated", 0.90)
    else: sat_fix = ("ok", 1.08)

    # Contrast
    con = np.std(gray)
    if con < 35: con_fix = ("flat", 1.15)
    elif con > 80: con_fix = ("harsh", 0.95)
    else: con_fix = ("ok", 1.05)

    # Sharpness
    gx = np.diff(gray, axis=1)
    gy = np.diff(gray, axis=0)
    mn = min(gx.shape[0], gy.shape[0])
    sharp = np.mean(np.sqrt(gx[:mn,:]**2 + gy[:mn,:gx.shape[1]]**2))
    if sharp < 8: sh = ("soft", 1.4)
    elif sharp > 25: sh = ("oversharp", 0.9)
    else: sh = ("ok", 1.15)

    return {
        "exposure": exp, "color": col, "warmth": warmth,
        "saturation": sat_fix, "contrast": con_fix, "sharpness": sh,
        "brightness": brightness, "r": r, "g": g, "b": b, "sat_avg": sat,
    }


# ═══════════════════════════════════════════════════════
# NANO API
# ═══════════════════════════════════════════════════════

def fal_upload_pil(img, name="image.png"):
    buf = io.BytesIO(); img.save(buf, "PNG"); buf.seek(0)
    r = urllib.request.Request("https://rest.alpha.fal.ai/storage/upload/initiate",
        data=json.dumps({"file_name": name, "content_type": "image/png"}).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    resp = json.loads(urllib.request.urlopen(r, timeout=30).read())
    urllib.request.urlopen(urllib.request.Request(resp["upload_url"],
        data=buf.getvalue(), headers={"Content-Type": "image/png"}, method="PUT"), timeout=60)
    return resp["file_url"]

def fal_upload_file(path):
    d = Path(path).read_bytes()
    ct = "image/jpeg" if str(path).lower().endswith((".jpg",".jpeg")) else "image/png"
    r = urllib.request.Request("https://rest.alpha.fal.ai/storage/upload/initiate",
        data=json.dumps({"file_name": Path(path).name, "content_type": ct}).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    resp = json.loads(urllib.request.urlopen(r, timeout=30).read())
    urllib.request.urlopen(urllib.request.Request(resp["upload_url"],
        data=d, headers={"Content-Type": ct}, method="PUT"), timeout=60)
    return resp["file_url"]

def nano_edit(prompt, urls):
    r = urllib.request.Request("https://fal.run/fal-ai/nano-banana-pro/edit",
        data=json.dumps({"prompt": prompt, "image_urls": urls}).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    result = json.loads(urllib.request.urlopen(r, timeout=180).read())
    return Image.open(io.BytesIO(urllib.request.urlopen(
        result["images"][0]["url"], timeout=60).read()))


# ═══════════════════════════════════════════════════════
# STEP 1: ENHANCE TO REFERENCE LEVEL
# ═══════════════════════════════════════════════════════

def enhance_to_reference(original_img, reference_path, dish_type, analysis):
    """NANO pass 1: enhance food photo to Pinterest reference level."""

    dish = DISH_DNA.get(dish_type, DISH_DNA["default"])
    mood = MOOD_PROFILE

    # Upload both images
    ref_url = fal_upload_file(reference_path) if reference_path else None
    orig_url = fal_upload_pil(original_img)

    # Build adaptive prompt
    urls = [ref_url, orig_url] if ref_url else [orig_url]
    ref_instruction = "Image 1 = REFERENCE (the quality standard to match). Image 2 = the food photo to enhance.\n\n" if ref_url else "Image 1 = the food photo to enhance.\n\n"
    food_image = "Image 2" if ref_url else "Image 1"

    # Exposure-specific instruction
    exp_note = ""
    if analysis["exposure"][0] == "dark":
        exp_note = "The photo is underexposed — brighten it to look naturally well-lit. "
    elif analysis["exposure"][0] == "bright":
        exp_note = "The photo is slightly overexposed — recover highlights while keeping it bright. "

    # Color-specific instruction
    col_note = ""
    if analysis["color"][0] == "cool":
        col_note = "The photo has a cool/blue cast — warm it up significantly to golden tones. "
    elif analysis["color"][0] == "very_warm":
        col_note = "The photo is very yellow — reduce the yellow cast slightly while keeping warm. "
    elif analysis["color"][0] == "neutral":
        col_note = "Add warm golden tones — food should feel inviting and cozy. "

    prompt = (
        f"{ref_instruction}"
        f"TASK: Enhance {food_image} to professional food photography level.\n"
        f"{'Match the lighting quality, color warmth, and sophistication of Image 1 (the reference).' if ref_url else ''}\n\n"
        f"CRITICAL: The FOOD in {food_image} is SACRED. "
        f"Do NOT change what the food is, do NOT rearrange ingredients, "
        f"do NOT add or remove any food items. Keep the exact same dish.\n\n"
        f"LIGHTING: {mood['light_direction']}. "
        f"{exp_note}"
        f"Create gentle specular highlights on glossy surfaces (sauce, broth, oil). "
        f"Soft shadow depth on the far side of the dish.\n\n"
        f"COLOR: {mood['color_temp']}. "
        f"{col_note}"
        f"Make reds and oranges richer (sauces, meat, chili). "
        f"Make greens fresher (herbs, vegetables). "
        f"Suppress any blue tones — blue kills appetite.\n\n"
        f"FOOD TEXTURE: {dish['texture']}. "
        f"{dish['enhance']}. "
        f"{'Add ' + dish['steam'] + '.' if dish['steam'] else ''}\n\n"
        f"PLATE: If the plate/bowl looks cheap (plastic, chipped, mismatched), "
        f"subtly upgrade to premium-looking dishware — matte ceramic, earthenware, "
        f"or clean white porcelain. Keep the same shape and food placement.\n\n"
        f"KEEP the existing background for now (will be replaced in next step). "
        f"Focus on making the FOOD look world-class.\n\n"
        f"The result should look like a photo from a premium food magazine — "
        f"sophisticated, appetizing, honest. Not over-processed, not Instagram-filtered."
    )

    return nano_edit(prompt, urls)


# ═══════════════════════════════════════════════════════
# STEP 2: WHITE BACKGROUND
# ═══════════════════════════════════════════════════════

def apply_white_background(enhanced_img):
    """NANO pass 2: replace background with clean warm white."""

    url = fal_upload_pil(enhanced_img)

    prompt = (
        "Image 1 = an enhanced food photo.\n\n"
        "TASK: Replace the background with a clean, warm off-white.\n\n"
        "BACKGROUND: Warm off-white — NOT pure clinical white. "
        "Think fine matte paper or smooth porcelain surface. "
        "Slightly cream toned (RGB approximately 248, 246, 240). "
        "Subtle radial gradient — center slightly brighter, edges barely darker. "
        "This gives depth and prevents the sterile 'passport photo' look.\n\n"
        "FOOD & PLATE: Keep EXACTLY as they are. Do NOT change the food, "
        "the plate, the lighting on the food, or any detail of the dish. "
        "Only the BACKGROUND changes.\n\n"
        "SHADOW: Add a soft, natural drop shadow under the plate/bowl. "
        "The shadow should connect the dish to the surface — it must look like "
        "the dish is SITTING ON the white surface, not floating. "
        "Shadow direction: lower-right, soft spread, 30% opacity.\n\n"
        "EDGE: Clean, smooth transition between dish and background. "
        "No halos, no hard edges, no visible cutout artifacts."
    )

    return nano_edit(prompt, [url])


# ═══════════════════════════════════════════════════════
# STEP 3: FIT INTO FRAME (never crop food)
# ═══════════════════════════════════════════════════════

def fit_into_frame(img, target_size=800):
    """Fit food into square frame WITHOUT cropping. Pad with white if needed."""

    w, h = img.size
    bg_color = MOOD_PROFILE["bg_rgb"]

    # Calculate scale to fit WITHIN the target, with 10-15% breathing room
    food_area = 0.72  # Food fills 72% of frame
    inner_size = int(target_size * food_area)

    # Scale to fit within inner_size (preserving aspect ratio)
    ratio = min(inner_size / w, inner_size / h)
    new_w = int(w * ratio)
    new_h = int(h * ratio)

    # Resize food
    food = img.resize((new_w, new_h), Image.LANCZOS)

    # Create square canvas with warm white
    canvas = Image.new("RGB", (target_size, target_size), bg_color)

    # Center food on canvas
    x = (target_size - new_w) // 2
    y = (target_size - new_h) // 2
    canvas.paste(food, (x, y))

    return canvas


def fit_into_banner(img, target_w=1350, target_h=750):
    """Fit food into banner frame WITHOUT cropping."""

    w, h = img.size
    bg_color = MOOD_PROFILE["bg_rgb"]

    food_area = 0.75
    inner_w = int(target_w * food_area)
    inner_h = int(target_h * food_area)

    ratio = min(inner_w / w, inner_h / h)
    new_w = int(w * ratio)
    new_h = int(h * ratio)

    food = img.resize((new_w, new_h), Image.LANCZOS)

    canvas = Image.new("RGB", (target_w, target_h), bg_color)
    x = (target_w - new_w) // 2
    y = (target_h - new_h) // 2
    canvas.paste(food, (x, y))

    return canvas


# ═══════════════════════════════════════════════════════
# STEP 4: PROFESSIONAL COLOR GRADE + GRAIN
# ═══════════════════════════════════════════════════════

def professional_grade(img, analysis):
    """Adaptive color grading based on photo analysis."""
    img = img.convert("RGB")

    # Vibrance (preferred over saturation for food)
    enhancer = ImageEnhance.Color(img)
    img = enhancer.enhance(analysis["saturation"][1])

    # Contrast
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(analysis["contrast"][1])

    # Exposure correction
    if analysis["exposure"][0] == "dark":
        enhancer = ImageEnhance.Brightness(img)
        img = enhancer.enhance(1 + analysis["exposure"][1])
    elif analysis["exposure"][0] == "bright":
        enhancer = ImageEnhance.Brightness(img)
        img = enhancer.enhance(1 - analysis["exposure"][1] * 0.5)

    # Sharpness
    enhancer = ImageEnhance.Sharpness(img)
    img = enhancer.enhance(analysis["sharpness"][1])

    return img


def add_film_grain(img, strength=0.012):
    """Luminosity-dependent organic film grain."""
    arr = np.array(img.convert("RGB"), dtype=np.float64)
    h, w = arr.shape[:2]

    noise = np.random.normal(0, 1, (h, w))
    gray = np.mean(arr, axis=2) / 255.0
    lum_weight = np.exp(-((gray - 0.5) ** 2) / (2 * 0.15 ** 2))

    grain = noise * lum_weight * strength * 255
    arr[:, :, 0] = np.clip(arr[:, :, 0] + grain * 1.05, 0, 255)
    arr[:, :, 1] = np.clip(arr[:, :, 1] + grain * 1.0, 0, 255)
    arr[:, :, 2] = np.clip(arr[:, :, 2] + grain * 0.92, 0, 255)

    return Image.fromarray(arr.astype(np.uint8))


# ═══════════════════════════════════════════════════════
# STEP 5: CONSISTENCY CHECK
# ═══════════════════════════════════════════════════════

def check_consistency(images):
    """Check if all batch images share consistent mood."""
    if len(images) < 2:
        return True, "Single image — no consistency check needed"

    temps = []
    brights = []
    for img in images:
        arr = np.array(img.convert("RGB"), dtype=np.float64)
        r, g, b = np.mean(arr[:,:,0]), np.mean(arr[:,:,1]), np.mean(arr[:,:,2])
        temps.append(r - b)  # Warmth
        brights.append(np.mean(arr))

    temp_range = max(temps) - min(temps)
    bright_range = max(brights) - min(brights)

    consistent = temp_range < 15 and bright_range < 20
    report = (
        f"Color warmth range: {temp_range:.0f} ({'✅' if temp_range < 15 else '⚠️ inconsistent'})\n"
        f"Brightness range: {bright_range:.0f} ({'✅' if bright_range < 20 else '⚠️ inconsistent'})"
    )
    return consistent, report


# ═══════════════════════════════════════════════════════
# STEP 6: EXPORT
# ═══════════════════════════════════════════════════════

def export(img_square, img_banner, name, out_dir):
    """Export final images."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    menu_path = out_dir / f"{name}_800x800.jpg"
    img_square.save(menu_path, "JPEG", quality=92)

    banner_path = out_dir / f"{name}_1350x750.jpg"
    img_banner.save(banner_path, "JPEG", quality=92)

    thumb = img_square.resize((80, 80), Image.LANCZOS)
    thumb_path = out_dir / f"{name}_80px.jpg"
    thumb.save(thumb_path, "JPEG", quality=85)

    return {"menu": menu_path, "banner": banner_path, "thumb": thumb_path}


# ═══════════════════════════════════════════════════════
# MASTER PIPELINE
# ═══════════════════════════════════════════════════════

def find_reference(dish_type, ref_dir=None):
    """Find best matching reference image for this dish type."""
    if ref_dir:
        ref_dir = Path(ref_dir)
        # Look for dish-type specific reference
        for pattern in [f"{dish_type}*", f"*{dish_type}*", "*ref*"]:
            matches = list(ref_dir.glob(pattern + ".jpg")) + list(ref_dir.glob(pattern + ".png"))
            if matches:
                return str(matches[0])

        # Look in subcategory folders
        sub = ref_dir / dish_type
        if sub.exists():
            refs = list(sub.glob("*.jpg")) + list(sub.glob("*.png"))
            if refs:
                return str(refs[0])

    return None  # No reference found — will enhance without


def process_single(input_path, output_dir, dish_name=None, dish_type="default",
                   reference_path=None, ref_dir=None):
    """Process one photo through the full pipeline."""

    input_path = Path(input_path)
    name = dish_name or input_path.stem.lower().replace(" ", "-").replace("_", "-")

    print(f"\n  {'━'*50}")
    print(f"  🍽️  {input_path.name}")
    print(f"  {'━'*50}")

    # Load
    img = Image.open(input_path).convert("RGB")
    print(f"    📐 {img.size[0]}×{img.size[1]}")

    # Analyze
    print(f"    🔍 Analyzing...")
    a = analyze(img)
    print(f"       Exposure: {a['exposure'][0]} (brightness {a['brightness']:.0f})")
    print(f"       Color: {a['color'][0]} (warmth {a['warmth']:.0f})")
    print(f"       Saturation: {a['saturation'][0]} | Contrast: {a['contrast'][0]} | Sharp: {a['sharpness'][0]}")

    # Find reference
    ref = reference_path or find_reference(dish_type, ref_dir)
    if ref:
        print(f"    🎨 Reference: {Path(ref).name}")
    else:
        print(f"    🎨 No reference — enhancing with mood profile only")

    # Step 1: Enhance to reference level
    print(f"    ✨ Pass 1: Enhancing to reference level...")
    enhanced = enhance_to_reference(img, ref, dish_type, a)
    time.sleep(3)

    # Step 2: White background
    print(f"    ⬜ Pass 2: White background...")
    white_bg = apply_white_background(enhanced)
    time.sleep(3)

    # Step 3: Fit into frame (never crop)
    print(f"    📏 Fitting into frame (no crop)...")
    square = fit_into_frame(white_bg, 800)
    banner = fit_into_banner(white_bg, 1350, 750)

    # Step 4: Color grade + grain
    print(f"    🎬 Color grading + film grain...")
    a2 = analyze(square)  # Re-analyze after NANO
    square = professional_grade(square, a2)
    square = add_film_grain(square, MOOD_PROFILE["grain_strength"])
    banner = professional_grade(banner, a2)
    banner = add_film_grain(banner, MOOD_PROFILE["grain_strength"])

    # Step 5: Export
    print(f"    💾 Exporting...")
    outputs = export(square, banner, name, output_dir)
    for k, v in outputs.items():
        print(f"       {k}: {v.name}")

    print(f"    ✅ Done")

    return square, outputs


def batch_process(input_dir, output_dir, dish_type="default",
                  reference_path=None, ref_dir=None):
    """Process all photos with consistent mood."""

    input_dir = Path(input_dir)
    output_dir = Path(output_dir)
    photos = sorted(
        list(input_dir.glob("*.jpg")) + list(input_dir.glob("*.jpeg")) +
        list(input_dir.glob("*.png"))
    )

    print(f"\n{'═'*55}")
    print(f"  GRABFOOD MASTER V2 — {len(photos)} photos")
    print(f"  Mood: {MOOD_PROFILE['overall_feel']}")
    print(f"  Dish type: {dish_type}")
    if reference_path:
        print(f"  Reference: {Path(reference_path).name}")
    elif ref_dir:
        print(f"  Ref dir: {ref_dir}")
    print(f"  Output: {output_dir}")
    print(f"{'═'*55}")

    results = []
    result_images = []

    for i, photo in enumerate(photos):
        try:
            square, outputs = process_single(
                str(photo), str(output_dir),
                dish_type=dish_type,
                reference_path=reference_path,
                ref_dir=ref_dir,
            )
            results.append(outputs)
            result_images.append(square)
        except Exception as e:
            print(f"    ❌ {photo.name}: {e}")

        if i < len(photos) - 1:
            time.sleep(5)  # Rate limit between photos

    # Consistency check
    if len(result_images) > 1:
        print(f"\n  🔎 CONSISTENCY CHECK:")
        ok, report = check_consistency(result_images)
        for line in report.split("\n"):
            print(f"     {line}")
        if not ok:
            print(f"     ⚠️ Some photos may need manual adjustment for consistency")

    print(f"\n{'═'*55}")
    print(f"  ✅ BATCH COMPLETE: {len(results)}/{len(photos)} photos")
    print(f"  📁 Output: {output_dir}")
    print(f"{'═'*55}")

    return results


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GrabFood Master Enhancement V2")
    parser.add_argument("input", help="Photo or directory")
    parser.add_argument("-o", "--output", default="./enhanced")
    parser.add_argument("-n", "--name", default=None)
    parser.add_argument("-t", "--type", default="default",
                        choices=list(DISH_DNA.keys()))
    parser.add_argument("-r", "--reference", default=None,
                        help="Path to reference image (same for all batch)")
    parser.add_argument("--ref-dir", default=None,
                        help="Directory of references (auto-matched by dish type)")
    args = parser.parse_args()

    p = Path(args.input)
    if p.is_dir():
        batch_process(str(p), args.output, args.type, args.reference, args.ref_dir)
    else:
        process_single(str(p), args.output, args.name, args.type, args.reference, args.ref_dir)
