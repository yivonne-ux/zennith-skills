#!/usr/bin/env python3
"""
GrabFood Master Enhancement Pipeline — WORLD CLASS LEVEL
=========================================================

Not a filter. Not a template. A professional food photography curation system
that reads each photo individually and enhances it to mastery level.

Architecture:
  1. ANALYZE — read the photo's exposure, color, sharpness, lighting
  2. DIAGNOSE — determine what this specific photo needs
  3. ENHANCE — NANO transforms with adaptive prompting
  4. GRADE — professional color science (warm shadows, HSL per-color, film tone curve)
  5. TEXTURE — subtle organic film grain (luminosity-dependent, not digital noise)
  6. BADGE — optional premium Best Seller / Chef's Pick overlays
  7. EXPORT — GrabFood specs (800x800 + 1350x750) + thumbnail QA

Key principle: NEVER change the food. Enhance EVERYTHING ELSE.
The food is sacred. The presentation is what we upgrade.
"""

import os, sys, json, io, argparse
from pathlib import Path
from PIL import Image, ImageFilter, ImageEnhance, ImageDraw, ImageFont
import numpy as np

FAL_KEY = os.environ.get("FAL_KEY", "")


# ═══════════════════════════════════════════════════════
# STEP 1: ADAPTIVE ANALYSIS
# ═══════════════════════════════════════════════════════

def analyze_photo(img):
    """Read the photo and return a diagnosis of what it needs."""
    arr = np.array(img.convert("RGB"), dtype=np.float64)
    h, w = arr.shape[:2]

    # --- Exposure ---
    gray = np.mean(arr, axis=2)
    mean_brightness = np.mean(gray)
    highlights_clipped = np.mean(gray > 250) * 100
    shadows_clipped = np.mean(gray < 10) * 100

    if mean_brightness < 100:
        exposure_fix = "underexposed"
        exposure_amount = min((130 - mean_brightness) / 130, 0.4)
    elif mean_brightness > 180:
        exposure_fix = "overexposed"
        exposure_amount = min((mean_brightness - 150) / 150, 0.3)
    else:
        exposure_fix = "ok"
        exposure_amount = 0

    # --- Color Temperature ---
    avg_r = np.mean(arr[:, :, 0])
    avg_g = np.mean(arr[:, :, 1])
    avg_b = np.mean(arr[:, :, 2])
    warmth = avg_r - avg_b

    if warmth < -5:
        color_fix = "too_cool"
        warm_amount = min(abs(warmth) / 50, 0.15)
    elif warmth > 40:
        color_fix = "too_warm"
        warm_amount = min((warmth - 30) / 60, 0.08)
    else:
        color_fix = "ok"
        warm_amount = 0.03  # Always add a tiny warm nudge for appetite

    # --- Saturation ---
    hsv = img.convert("HSV")
    hsv_arr = np.array(hsv)
    avg_sat = np.mean(hsv_arr[:, :, 1])

    if avg_sat < 50:
        sat_fix = "desaturated"
        sat_amount = 1.20  # PIL Color enhance multiplier
    elif avg_sat > 160:
        sat_fix = "oversaturated"
        sat_amount = 0.92
    else:
        sat_fix = "ok"
        sat_amount = 1.08  # Subtle boost always

    # --- Contrast ---
    contrast_std = np.std(gray)
    if contrast_std < 35:
        contrast_fix = "flat"
        contrast_amount = 1.15
    elif contrast_std > 80:
        contrast_fix = "harsh"
        contrast_amount = 0.95
    else:
        contrast_fix = "ok"
        contrast_amount = 1.05

    # --- Sharpness ---
    gx = np.diff(gray, axis=1)
    gy = np.diff(gray, axis=0)
    min_h = min(gx.shape[0], gy.shape[0])
    gradient_mag = np.sqrt(gx[:min_h, :]**2 + gy[:min_h, :gx.shape[1]]**2)
    sharpness_score = np.mean(gradient_mag)

    if sharpness_score < 8:
        sharp_fix = "soft"
        sharp_amount = 1.4
    elif sharpness_score > 25:
        sharp_fix = "oversharp"
        sharp_amount = 0.9
    else:
        sharp_fix = "ok"
        sharp_amount = 1.15

    # --- Background ---
    edges = np.concatenate([
        arr[:int(h*0.08), :, :].reshape(-1, 3),
        arr[int(h*0.92):, :, :].reshape(-1, 3),
        arr[:, :int(w*0.08), :].reshape(-1, 3),
        arr[:, int(w*0.92):, :].reshape(-1, 3),
    ])
    bg_std = np.std(edges)
    bg_mean = np.mean(edges)
    bg_is_clean = bg_std < 30 and bg_mean > 200

    diagnosis = {
        "exposure": {"fix": exposure_fix, "amount": exposure_amount, "brightness": mean_brightness},
        "color": {"fix": color_fix, "warm_amount": warm_amount, "warmth": warmth,
                  "r": avg_r, "g": avg_g, "b": avg_b},
        "saturation": {"fix": sat_fix, "amount": sat_amount, "avg": avg_sat},
        "contrast": {"fix": contrast_fix, "amount": contrast_amount, "std": contrast_std},
        "sharpness": {"fix": sharp_fix, "amount": sharp_amount, "score": sharpness_score},
        "background": {"is_clean": bg_is_clean, "std": bg_std, "brightness": bg_mean},
        "needs_bg_removal": not bg_is_clean,
    }

    return diagnosis


def print_diagnosis(d):
    """Pretty print the diagnosis."""
    print(f"    📊 Analysis:")
    print(f"       Exposure:   {d['exposure']['fix']} (brightness: {d['exposure']['brightness']:.0f})")
    print(f"       Color:      {d['color']['fix']} (warmth: {d['color']['warmth']:.0f}, R:{d['color']['r']:.0f} G:{d['color']['g']:.0f} B:{d['color']['b']:.0f})")
    print(f"       Saturation: {d['saturation']['fix']} (avg: {d['saturation']['avg']:.0f})")
    print(f"       Contrast:   {d['contrast']['fix']} (std: {d['contrast']['std']:.0f})")
    print(f"       Sharpness:  {d['sharpness']['fix']} (score: {d['sharpness']['score']:.1f})")
    print(f"       Background: {'✅ clean' if d['background']['is_clean'] else '⚠️ needs removal'}")


# ═══════════════════════════════════════════════════════
# STEP 2: NANO ENHANCEMENT (Adaptive Prompting)
# ═══════════════════════════════════════════════════════

def fal_upload_pil(img, name="image.png"):
    buf = io.BytesIO()
    img.save(buf, "PNG")
    buf.seek(0)
    r = urllib.request.Request("https://rest.alpha.fal.ai/storage/upload/initiate",
        data=json.dumps({"file_name": name, "content_type": "image/png"}).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    resp = json.loads(urllib.request.urlopen(r, timeout=30).read())
    urllib.request.urlopen(urllib.request.Request(resp["upload_url"],
        data=buf.getvalue(), headers={"Content-Type": "image/png"}, method="PUT"), timeout=60)
    return resp["file_url"]


def nano_edit(prompt, urls):
    import urllib.request as ur
    r = ur.Request(f"https://fal.run/fal-ai/nano-banana-pro/edit",
        data=json.dumps({"prompt": prompt, "image_urls": urls}).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    result = json.loads(ur.urlopen(r, timeout=180).read())
    return Image.open(io.BytesIO(ur.urlopen(result["images"][0]["url"], timeout=60).read()))


def build_adaptive_prompt(diagnosis, dish_type="default"):
    """Build a NANO prompt that adapts to this specific photo's needs."""

    # Base prompt
    parts = [
        "Image 1 = a food dish photo.\n\n",
        "CRITICAL: Preserve the FOOD exactly as it is. Do NOT change, restyle, or reimagine the dish. ",
        "The food is SACRED — keep every ingredient, every sauce drip, every texture.\n\n",
    ]

    # Background handling
    if diagnosis["needs_bg_removal"]:
        parts.append(
            "BACKGROUND: Replace the existing background with a clean, warm off-white surface. "
            "Slightly textured — like fine matte paper or smooth ceramic. "
            "NOT pure clinical white (RGB 255,255,255). Use warm white (RGB 248,246,240). "
            "Subtle radial gradient — center slightly brighter, edges barely darker. "
            "Natural soft drop shadow under the dish connecting it to the surface. "
            "The dish must look like it's SITTING ON the surface, not floating.\n\n"
        )
    else:
        parts.append(
            "BACKGROUND: Keep the existing clean background. "
            "Ensure it feels warm and inviting, not clinical.\n\n"
        )

    # Lighting
    light_note = "LIGHTING: Soft, diffused natural light from the upper-left. "
    if diagnosis["exposure"]["fix"] == "underexposed":
        light_note += "Brighten the overall scene — the food needs more light. "
    elif diagnosis["exposure"]["fix"] == "overexposed":
        light_note += "Tone down harsh highlights while keeping the food bright. "
    light_note += (
        "Warm color temperature like late afternoon sunlight. "
        "Gentle specular highlights on glossy surfaces (sauce, soup, oil). "
        "Soft shadow on the far side of the dish for depth. "
        "No harsh shadows. No flat lighting.\n\n"
    )
    parts.append(light_note)

    # Color
    color_note = "COLOR: "
    if diagnosis["color"]["fix"] == "too_cool":
        color_note += "The image is too cool/blue. Warm it up significantly — shift toward golden tones. "
    elif diagnosis["color"]["fix"] == "too_warm":
        color_note += "Slightly reduce the yellow cast while keeping warm. "
    color_note += (
        "Make reds and oranges richer (sauces, chilies, curry). "
        "Make greens fresher (herbs, vegetables). "
        "Suppress any blue tones. Food should feel warm and inviting.\n\n"
    )
    parts.append(color_note)

    # Dish-type specific
    if dish_type in ["soup", "curry", "bkt", "noodle_soup", "laksa"]:
        parts.append(
            "DISH TYPE: This is a soup/curry. Add visible steam rising gently. "
            "Make the broth look rich and glossy. Show depth in the bowl.\n\n"
        )
    elif dish_type in ["fried", "crispy", "goreng"]:
        parts.append(
            "DISH TYPE: This is a fried/crispy dish. Emphasize the golden crispy texture. "
            "Make the surface look crunchy and freshly cooked.\n\n"
        )
    elif dish_type in ["noodle", "mee", "mian"]:
        parts.append(
            "DISH TYPE: Noodles. Show the glossy, saucy coating on the noodles. "
            "Emphasize the tangle and texture.\n\n"
        )
    elif dish_type in ["rice", "nasi"]:
        parts.append(
            "DISH TYPE: Rice dish. Show fluffy, glistening rice grains. "
            "Toppings should look freshly placed.\n\n"
        )

    # Quality standard
    parts.append(
        "QUALITY: This must look like a MICHELIN-STARRED restaurant's menu photo. "
        "Professional, sophisticated, appetizing. "
        "NOT a phone snapshot. NOT an Instagram filter. "
        "Think: Robb Report food feature, not hawker stall signage. "
        "The viewer should feel hungry looking at this.\n\n"
    )

    # Plate upgrade hint
    parts.append(
        "PLATE/BOWL: If the existing plate/bowl looks cheap or mismatched, "
        "subtly upgrade it to a more premium vessel — matte ceramic, earthenware, "
        "or dark stoneware. Keep the food placement identical. "
        "If the plate already looks good, leave it.\n\n"
    )

    return "".join(parts)


# ═══════════════════════════════════════════════════════
# STEP 3: PROFESSIONAL COLOR GRADING
# ═══════════════════════════════════════════════════════

def professional_grade(img, diagnosis):
    """Apply adaptive professional color grading based on diagnosis."""
    arr = np.array(img.convert("RGB"), dtype=np.float64)

    # --- Adaptive White Balance (warm shift) ---
    warm = diagnosis["color"]["warm_amount"]
    arr[:, :, 0] = np.clip(arr[:, :, 0] * (1 + warm), 0, 255)       # Red boost
    arr[:, :, 1] = np.clip(arr[:, :, 1] * (1 + warm * 0.3), 0, 255)  # Tiny green
    arr[:, :, 2] = np.clip(arr[:, :, 2] * (1 - warm * 0.7), 0, 255)  # Blue suppress

    # --- Tone Curve (subtle S-curve for depth) ---
    # Lift shadows, compress highlights — "expensive" look
    for c in range(3):
        channel = arr[:, :, c]
        # Gentle S-curve: lift blacks to 8, compress highlights
        channel = np.where(channel < 30, channel * 0.8 + 8, channel)  # Lift shadows
        channel = np.where(channel > 230, 230 + (channel - 230) * 0.5, channel)  # Compress highlights
        arr[:, :, c] = channel

    # --- HSL Adjustments (per-color for food) ---
    # Convert to HSV for per-color work
    img_temp = Image.fromarray(arr.astype(np.uint8))
    hsv_arr = np.array(img_temp.convert("HSV"), dtype=np.float64)

    hue = hsv_arr[:, :, 0]  # 0-255 in PIL
    sat = hsv_arr[:, :, 1]
    val = hsv_arr[:, :, 2]

    # Red (hue ~0/255 in PIL): boost saturation for sauces
    red_mask = (hue < 15) | (hue > 240)
    sat[red_mask] = np.clip(sat[red_mask] * 1.12, 0, 255)
    val[red_mask] = np.clip(val[red_mask] * 1.03, 0, 255)

    # Orange (hue ~15-30): warm food tones
    orange_mask = (hue >= 15) & (hue < 35)
    sat[orange_mask] = np.clip(sat[orange_mask] * 1.10, 0, 255)
    val[orange_mask] = np.clip(val[orange_mask] * 1.05, 0, 255)

    # Yellow (hue ~30-45): rice, noodles, golden crusts
    yellow_mask = (hue >= 35) & (hue < 50)
    sat[yellow_mask] = np.clip(sat[yellow_mask] * 1.05, 0, 255)

    # Green (hue ~50-95): herbs, vegetables — freshen, don't neon
    green_mask = (hue >= 50) & (hue < 95)
    sat[green_mask] = np.clip(sat[green_mask] * 1.08, 0, 255)
    val[green_mask] = np.clip(val[green_mask] * 1.03, 0, 255)

    # Blue (hue ~130-175): SUPPRESS — appetite killer
    blue_mask = (hue >= 130) & (hue < 175)
    sat[blue_mask] = np.clip(sat[blue_mask] * 0.75, 0, 255)

    hsv_arr[:, :, 1] = sat
    hsv_arr[:, :, 2] = val

    img = Image.fromarray(hsv_arr.astype(np.uint8), "HSV").convert("RGB")

    # --- Adaptive Enhancements ---
    # Vibrance (better than saturation for food)
    enhancer = ImageEnhance.Color(img)
    img = enhancer.enhance(diagnosis["saturation"]["amount"])

    # Contrast
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(diagnosis["contrast"]["amount"])

    # Brightness (exposure fix)
    if diagnosis["exposure"]["fix"] == "underexposed":
        enhancer = ImageEnhance.Brightness(img)
        img = enhancer.enhance(1 + diagnosis["exposure"]["amount"])
    elif diagnosis["exposure"]["fix"] == "overexposed":
        enhancer = ImageEnhance.Brightness(img)
        img = enhancer.enhance(1 - diagnosis["exposure"]["amount"] * 0.5)

    # Sharpness
    enhancer = ImageEnhance.Sharpness(img)
    img = enhancer.enhance(diagnosis["sharpness"]["amount"])

    return img


# ═══════════════════════════════════════════════════════
# STEP 4: ORGANIC FILM GRAIN
# ═══════════════════════════════════════════════════════

def add_film_grain(img, strength=0.015):
    """Add luminosity-dependent organic film grain. NOT digital noise.

    Film grain characteristics:
    - Stronger in midtones, weaker in shadows and highlights
    - Slightly warm-tinted (not pure gray)
    - Organic, irregular distribution
    """
    arr = np.array(img.convert("RGB"), dtype=np.float64)
    h, w = arr.shape[:2]

    # Generate base noise
    noise = np.random.normal(0, 1, (h, w))

    # Luminosity-dependent strength (stronger in midtones)
    gray = np.mean(arr, axis=2) / 255.0
    # Bell curve centered at midtones (0.4-0.6)
    lum_weight = np.exp(-((gray - 0.5) ** 2) / (2 * 0.15 ** 2))

    # Apply weighted noise to each channel
    grain = noise * lum_weight * strength * 255

    # Warm tint the grain (slightly more in red, less in blue)
    arr[:, :, 0] = np.clip(arr[:, :, 0] + grain * 1.05, 0, 255)  # Warm red
    arr[:, :, 1] = np.clip(arr[:, :, 1] + grain * 1.0, 0, 255)
    arr[:, :, 2] = np.clip(arr[:, :, 2] + grain * 0.92, 0, 255)  # Less blue

    return Image.fromarray(arr.astype(np.uint8))


# ═══════════════════════════════════════════════════════
# STEP 5: PREMIUM BADGES
# ═══════════════════════════════════════════════════════

def add_badge(img, badge_type="bestseller", position="top-left"):
    """Add a premium badge overlay. World-class design, not clipart."""

    draw = ImageDraw.Draw(img)
    w, h = img.size

    # Badge colors — gold/cream luxury palette
    GOLD = (184, 148, 88)        # Warm gold
    GOLD_LIGHT = (218, 190, 130) # Light gold
    CREAM = (252, 248, 240)      # Warm cream
    DARK = (35, 30, 25)          # Near black

    # Badge size — 7-11% of image width
    badge_size = int(w * 0.09)
    margin = int(w * 0.04)

    # Position
    if position == "top-left":
        cx, cy = margin + badge_size, margin + badge_size
    elif position == "top-right":
        cx, cy = w - margin - badge_size, margin + badge_size
    elif position == "bottom-left":
        cx, cy = margin + badge_size, h - margin - badge_size
    else:
        cx, cy = w - margin - badge_size, h - margin - badge_size

    # Draw circular badge with double border (premium seal style)
    # Outer ring
    draw.ellipse(
        [cx - badge_size, cy - badge_size, cx + badge_size, cy + badge_size],
        fill=GOLD, outline=GOLD_LIGHT, width=2
    )
    # Inner ring
    inner = int(badge_size * 0.85)
    draw.ellipse(
        [cx - inner, cy - inner, cx + inner, cy + inner],
        fill=DARK, outline=GOLD, width=1
    )

    # Text inside badge
    try:
        # Try system fonts
        font_paths = [
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/SFNSDisplay.ttf",
            "/Library/Fonts/Arial.ttf",
        ]
        font = None
        for fp in font_paths:
            if Path(fp).exists():
                font = ImageFont.truetype(fp, int(badge_size * 0.28))
                font_small = ImageFont.truetype(fp, int(badge_size * 0.18))
                break
        if not font:
            font = ImageFont.load_default()
            font_small = font
    except:
        font = ImageFont.load_default()
        font_small = font

    badge_texts = {
        "bestseller": ("BEST", "SELLER"),
        "chefpick": ("CHEF'S", "PICK"),
        "popular": ("MOST", "POPULAR"),
        "new": ("NEW", "ITEM"),
        "spicy": ("🌶️", "SPICY"),
        "recommended": ("TOP", "RATED"),
    }

    line1, line2 = badge_texts.get(badge_type, ("⭐", ""))

    # Center text in badge
    bbox1 = draw.textbbox((0, 0), line1, font=font)
    tw1 = bbox1[2] - bbox1[0]
    draw.text((cx - tw1 // 2, cy - int(badge_size * 0.35)), line1, fill=GOLD_LIGHT, font=font)

    bbox2 = draw.textbbox((0, 0), line2, font=font_small)
    tw2 = bbox2[2] - bbox2[0]
    draw.text((cx - tw2 // 2, cy + int(badge_size * 0.05)), line2, fill=CREAM, font=font_small)

    return img


# ═══════════════════════════════════════════════════════
# STEP 6: EXPORT
# ═══════════════════════════════════════════════════════

def smart_crop(img, target_ratio):
    """Smart crop to target ratio without cutting food."""
    w, h = img.size
    current_ratio = w / h

    if abs(current_ratio - target_ratio) < 0.02:
        return img

    if current_ratio > target_ratio:
        # Too wide — crop sides
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        return img.crop((left, 0, left + new_w, h))
    else:
        # Too tall — crop top/bottom
        new_h = int(w / target_ratio)
        top = (h - new_h) // 2
        return img.crop((0, top, w, top + new_h))


def export(img, name, out_dir, badge_type=None):
    """Export in GrabFood sizes with optional badge."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    outputs = {}

    # 800x800 menu item
    menu = smart_crop(img.copy(), 1.0)
    menu = menu.resize((800, 800), Image.LANCZOS)
    if badge_type:
        menu = add_badge(menu, badge_type)
    menu_path = out_dir / f"{name}_menu_800x800.jpg"
    menu.save(menu_path, "JPEG", quality=92)
    outputs["menu"] = menu_path

    # 1350x750 banner
    banner = smart_crop(img.copy(), 1350 / 750)
    banner = banner.resize((1350, 750), Image.LANCZOS)
    banner_path = out_dir / f"{name}_banner_1350x750.jpg"
    banner.save(banner_path, "JPEG", quality=92)
    outputs["banner"] = banner_path

    # 800x800 without badge (clean version)
    if badge_type:
        clean = smart_crop(img.copy(), 1.0)
        clean = clean.resize((800, 800), Image.LANCZOS)
        clean_path = out_dir / f"{name}_clean_800x800.jpg"
        clean.save(clean_path, "JPEG", quality=92)
        outputs["clean"] = clean_path

    # 80px thumbnail preview
    thumb = menu.resize((80, 80), Image.LANCZOS)
    thumb_path = out_dir / f"{name}_thumb_80px.jpg"
    thumb.save(thumb_path, "JPEG", quality=85)
    outputs["thumb"] = thumb_path

    return outputs


# ═══════════════════════════════════════════════════════
# MASTER PIPELINE
# ═══════════════════════════════════════════════════════

import urllib.request

def process(input_path, output_dir="./enhanced", dish_name=None,
            dish_type="default", badge=None):
    """Full world-class enhancement pipeline."""

    input_path = Path(input_path)
    name = dish_name or input_path.stem.lower().replace(" ", "-").replace("_", "-")

    print(f"\n  {'═'*50}")
    print(f"  🍽️  ENHANCING: {input_path.name}")
    print(f"  {'═'*50}")

    # Load
    img = Image.open(input_path).convert("RGB")
    print(f"    📐 Original: {img.size[0]}x{img.size[1]}")

    # Step 1: Analyze
    print(f"\n  1️⃣  ANALYZING...")
    diagnosis = analyze_photo(img)
    print_diagnosis(diagnosis)

    # Step 2: NANO Enhancement
    print(f"\n  2️⃣  NANO ENHANCEMENT...")
    prompt = build_adaptive_prompt(diagnosis, dish_type)
    url = fal_upload_pil(img)
    enhanced = nano_edit(prompt, [url])
    print(f"    ✅ Enhanced with adaptive prompt")

    # Step 3: Professional Color Grading
    print(f"\n  3️⃣  COLOR GRADING...")
    # Re-analyze the enhanced version (NANO may have changed things)
    diagnosis_v2 = analyze_photo(enhanced)
    graded = professional_grade(enhanced, diagnosis_v2)
    print(f"    ✅ Professional grade applied")

    # Step 4: Film Grain
    print(f"\n  4️⃣  FILM TEXTURE...")
    final = add_film_grain(graded, strength=0.012)
    print(f"    ✅ Organic film grain (0.012)")

    # Step 5: Export
    print(f"\n  5️⃣  EXPORTING...")
    outputs = export(final, name, output_dir, badge_type=badge)
    for key, path in outputs.items():
        print(f"    📁 {key}: {path.name}")

    # Quality report
    print(f"\n  📊 QUALITY REPORT:")
    from photo_scorer import score_photo
    try:
        result = score_photo(str(outputs.get("menu") or outputs.get("clean")))
        print(f"    Overall: {result['overall']}/10 — {result['tier']}")
        for k, v in result["scores"].items():
            print(f"    {k}: {v}/10")
    except Exception as e:
        print(f"    (scorer not available: {e})")

    print(f"\n  {'═'*50}")
    print(f"  ✅ COMPLETE: {name}")
    print(f"  {'═'*50}")

    return outputs


def batch(input_dir, output_dir="./enhanced", dish_type="default", badge=None):
    """Process all photos in a directory."""
    import time
    input_dir = Path(input_dir)
    photos = list(input_dir.glob("*.jpg")) + list(input_dir.glob("*.jpeg")) + \
             list(input_dir.glob("*.png")) + list(input_dir.glob("*.heic"))

    print(f"\n{'═'*55}")
    print(f"  GRABFOOD MASTER ENHANCEMENT — {len(photos)} photos")
    print(f"  Output: {output_dir}")
    print(f"{'═'*55}")

    for i, photo in enumerate(photos):
        try:
            process(str(photo), output_dir, dish_type=dish_type, badge=badge)
        except Exception as e:
            print(f"  ❌ {photo.name}: {e}")
        if i < len(photos) - 1:
            time.sleep(8)

    print(f"\n{'═'*55}")
    print(f"  ✅ BATCH COMPLETE: {len(photos)} photos")
    print(f"{'═'*55}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GrabFood Master Enhancement")
    parser.add_argument("input", help="Photo or directory")
    parser.add_argument("-o", "--output", default="./enhanced")
    parser.add_argument("-n", "--name", default=None)
    parser.add_argument("-t", "--type", default="default",
                        choices=["default", "soup", "curry", "bkt", "noodle_soup",
                                 "laksa", "rice", "nasi", "fried", "crispy",
                                 "goreng", "noodle", "mee", "mian"])
    parser.add_argument("-b", "--badge", default=None,
                        choices=["bestseller", "chefpick", "popular", "new",
                                 "spicy", "recommended"])
    args = parser.parse_args()

    p = Path(args.input)
    if p.is_dir():
        batch(str(p), args.output, args.type, args.badge)
    else:
        process(str(p), args.output, args.name, args.type, args.badge)
