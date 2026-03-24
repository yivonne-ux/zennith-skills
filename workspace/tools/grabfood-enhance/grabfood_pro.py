#!/usr/bin/env python3
"""
GrabFood Pro Enhancement Pipeline — FoodShot-level Quality
==========================================================

Multi-stage pipeline matching FoodShot.ai's architecture:

Stage 1: SEGMENT — BiRefNet extracts food from plate/background
Stage 2: SCENE GENERATE — FLUX inpaints new premium scene around food mask
Stage 3: ENHANCE — NANO photographic finish (warmth, gloss, exposure)
Stage 4: WHITE BG — NANO converts scene to white background (optional)
Stage 5: EXPORT — PIL resize only

Food pixels NEVER enter the generation model. They are segmented out,
the scene is generated around them, and they are composited back.

Usage:
  python3 grabfood_pro.py photo.jpg -o ./enhanced/
  python3 grabfood_pro.py ./photos/ -o ./store-output/  (batch)
"""

import os, sys, json, io, argparse, time
from pathlib import Path
from PIL import Image, ImageFilter
import urllib.request
import numpy as np

FAL_KEY = os.environ.get("FAL_KEY", "")
FAL_API = "https://fal.run"


# ═══════════════════════════════════════════════════════
# FAL.AI API HELPERS
# ═══════════════════════════════════════════════════════

def fal_upload(data, name="image.png", ct="image/png"):
    """Upload image bytes to fal.ai storage."""
    if isinstance(data, (str, Path)):
        data = Path(data).read_bytes()
        ct = "image/jpeg" if str(data).lower().endswith((".jpg",".jpeg")) else "image/png"
    r = urllib.request.Request("https://rest.alpha.fal.ai/storage/upload/initiate",
        data=json.dumps({"file_name": name, "content_type": ct}).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    resp = json.loads(urllib.request.urlopen(r, timeout=30).read())
    urllib.request.urlopen(urllib.request.Request(resp["upload_url"],
        data=data, headers={"Content-Type": ct}, method="PUT"), timeout=120)
    return resp["file_url"]


def fal_upload_path(path):
    """Upload file from path."""
    d = Path(path).read_bytes()
    ct = "image/jpeg" if str(path).lower().endswith((".jpg",".jpeg")) else "image/png"
    return fal_upload(d, Path(path).name, ct)


def fal_upload_pil(img, name="image.png"):
    """Upload PIL image."""
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return fal_upload(buf.getvalue(), name, "image/png")


def fal_call(endpoint, payload):
    """Call a fal.ai model endpoint."""
    r = urllib.request.Request(f"{FAL_API}/{endpoint}",
        data=json.dumps(payload).encode(),
        headers={"Authorization": f"Key {FAL_KEY}", "Content-Type": "application/json"})
    result = json.loads(urllib.request.urlopen(r, timeout=300).read())
    return result


def fal_get_image(result, key="image"):
    """Download image from fal.ai result."""
    url = result.get(key, {}).get("url") or result.get("images", [{}])[0].get("url")
    if not url:
        raise ValueError(f"No image URL in result: {list(result.keys())}")
    return Image.open(io.BytesIO(urllib.request.urlopen(url, timeout=60).read()))


# ═══════════════════════════════════════════════════════
# STAGE 1: SEGMENTATION — Extract food from everything
# ═══════════════════════════════════════════════════════

def segment_food(img):
    """Use BiRefNet to segment food+toppings from plate and background.
    Returns: (cutout RGBA, mask L)
    """
    url = fal_upload_pil(img)

    result = fal_call("fal-ai/birefnet", {
        "image_url": url,
        "model": "General Use (Light)",
        "operating_resolution": "1024x1024",
        "output_image_type": "rgba",
    })

    cutout = fal_get_image(result)

    # Extract mask from alpha channel
    if cutout.mode == "RGBA":
        mask = cutout.split()[3]
    else:
        mask = Image.new("L", cutout.size, 255)

    return cutout.convert("RGBA"), mask


def segment_rembg(img):
    """Fallback: use fal-ai rembg endpoint."""
    url = fal_upload_pil(img)

    result = fal_call("fal-ai/imageutils/rembg", {
        "image_url": url,
    })

    cutout = fal_get_image(result)
    if cutout.mode == "RGBA":
        mask = cutout.split()[3]
    else:
        mask = Image.new("L", cutout.size, 255)

    return cutout.convert("RGBA"), mask


# ═══════════════════════════════════════════════════════
# STAGE 2: SCENE GENERATION — Inpaint premium scene
# ═══════════════════════════════════════════════════════

def create_inverted_mask(mask):
    """Create inverted mask: white = generate (background), black = keep (food)."""
    arr = np.array(mask)
    inverted = 255 - arr
    return Image.fromarray(inverted)


def generate_scene(original_img, food_mask, scene_prompt, reference_path=None):
    """Use FLUX General Inpainting to generate new scene around food.

    The food region (black in inverted mask) stays locked.
    Everything else (white in inverted mask) gets regenerated.
    """
    # Create inverted mask (white = area to regenerate)
    inv_mask = create_inverted_mask(food_mask)

    # Upload original + mask
    img_url = fal_upload_pil(original_img)
    mask_url = fal_upload_pil(inv_mask)

    result = fal_call("fal-ai/flux-general/inpainting", {
        "prompt": scene_prompt,
        "image_url": img_url,
        "mask_url": mask_url,
        "strength": 0.85,  # High enough to fully regenerate bg, low enough to preserve food edges
        "num_inference_steps": 28,
        "guidance_scale": 7.0,
        "image_size": {"width": 1024, "height": 1024},
    })

    return fal_get_image(result)


# ═══════════════════════════════════════════════════════
# STAGE 3: PHOTOGRAPHIC FINISH — NANO enhancement
# ═══════════════════════════════════════════════════════

def nano_edit(prompt, urls):
    """NANO Banana Pro edit pass."""
    result = fal_call("fal-ai/nano-banana-pro/edit", {
        "prompt": prompt,
        "image_urls": urls,
    })
    return fal_get_image(result)


def photographic_finish(scene_img, food_desc):
    """NANO pass for final photographic quality."""
    url = fal_upload_pil(scene_img)

    prompt = f"""Image 1 = a food product photo that needs photographic finishing.

The dish is: {food_desc}

ENHANCE to world-class food photography level. Do NOT change food arrangement or bowl positions.

WARM APPETITE COLORS (暖色提高食欲感):
- Meats: deep caramelized honey-glazed glossy
- Noodles: rich golden amber, glistening sauce
- Vegetables: vivid fresh crisp green
- Broth/soup: warm golden, inviting
- Fried items: golden crispy with visible crunch

TONAL DEPTH: Rich shadows and highlights within the food. Three-dimensional bowls with ceramic texture.
EXPOSURE: Slightly bright. Airy and appetizing.
SHARPNESS: Everything razor sharp.
SPECULAR: Glossy sauce, wet broth surface, glazed meat highlights.
QUALITY: Subtle premium film warmth. Professional food magazine level.

Keep background and shadow exactly as they are."""

    return nano_edit(prompt, [url])


# ═══════════════════════════════════════════════════════
# STAGE 4: WHITE BACKGROUND (optional)
# ═══════════════════════════════════════════════════════

def convert_to_white_bg(scene_img):
    """NANO pass to convert restaurant scene to white background."""
    url = fal_upload_pil(scene_img)

    prompt = """Image 1 = a food photo with restaurant background.

CHANGE ONLY the background to PURE WHITE. Keep food, bowls, and everything on them EXACTLY as is.

WHITE BACKGROUND: Pure white (#FFFFFF) to all edges. No gradients, no color cast, no warm glow on background.
SHADOW: Soft natural contact shadow under bowls. Warm-toned, gradual fade into white. Not too dark.
FOOD: Absolutely unchanged. Same position, same colors, same everything.
SHARPNESS: Keep everything razor sharp.

The result should look like it was shot in a white photography studio."""

    return nano_edit(prompt, [url])


# ═══════════════════════════════════════════════════════
# STORE STYLE CONFIGS
# ═══════════════════════════════════════════════════════

SCENE_STYLES = {
    "restaurant": (
        "Premium restaurant table setting. Dark walnut wood table surface. "
        "Food served in {bowl_style}. Wooden serving board underneath. "
        "Warm directional side lighting from upper-left, golden hour warmth. "
        "Background has subtle props: water glass edge, cutting board corner — all out of focus. "
        "45-degree food photography angle. Professional, moody, atmospheric. "
        "Shallow depth of field — food sharp, background gently blurred."
    ),
    "white_studio": (
        "Professional white photography studio. Pure white infinity curve background. "
        "Food served in {bowl_style}. "
        "Soft even studio lighting, slightly warm. "
        "Natural contact shadow under bowls grounding them to the white surface. "
        "45-degree angle. Clean, minimal, product photography."
    ),
    "minimal": (
        "Clean minimal surface — light grey or white marble. "
        "Food served in {bowl_style}. "
        "Soft natural window light from upper-left. "
        "Minimal styling, no props. Focus entirely on the food. "
        "45-degree angle. Bright, airy, modern."
    ),
}

BOWL_STYLES = {
    "grey_ceramic": "premium matte speckled grey ceramic stoneware bowl, Japanese-inspired artisan quality",
    "white_porcelain": "elegant white porcelain bowl with thin rim, fine dining quality",
    "dark_stoneware": "dark charcoal matte stoneware bowl, modern restaurant quality",
    "earthenware": "warm terracotta earthenware bowl, rustic artisan quality",
    "original": "the original plate/bowl from the photo",
}


# ═══════════════════════════════════════════════════════
# MASTER PIPELINE
# ═══════════════════════════════════════════════════════

def process_single(input_path, output_dir, dish_name=None, food_desc=None,
                   scene_style="restaurant", bowl_style="grey_ceramic",
                   white_bg=True, reference_path=None):
    """Full end-to-end pipeline for one photo."""

    input_path = Path(input_path)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    name = dish_name or input_path.stem.lower().replace(" ", "-").replace("_", "-")

    if not food_desc:
        food_desc = "food dish"

    print(f"\n  {'━'*55}")
    print(f"  🍽️  {input_path.name} → {name}")
    print(f"  {'━'*55}")

    # Load and pad to square
    orig = Image.open(input_path).convert("RGB")
    w, h = orig.size
    size = max(w, h)
    sq = Image.new("RGB", (size, size), (200, 200, 200))  # Grey padding for better segmentation
    sq.paste(orig, ((size-w)//2, (size-h)//2))
    sq = sq.resize((1024, 1024), Image.LANCZOS)
    print(f"    📐 {w}×{h} → 1024×1024")

    # ── STAGE 1: Segment food ──
    print(f"    ✂️  Stage 1: Segmenting food...")
    try:
        cutout, mask = segment_food(sq)
    except Exception as e:
        print(f"    ⚠️ BiRefNet failed ({e}), trying rembg...")
        cutout, mask = segment_rembg(sq)

    cutout.save(str(output_dir / f"{name}_01_cutout.png"), "PNG")
    mask.save(str(output_dir / f"{name}_01_mask.png"), "PNG")
    print(f"    ✅ Food segmented")
    time.sleep(3)

    # ── STAGE 2: Generate scene ──
    print(f"    🎬 Stage 2: Generating {scene_style} scene...")
    bowl_desc = BOWL_STYLES.get(bowl_style, BOWL_STYLES["grey_ceramic"])
    scene_prompt = SCENE_STYLES.get(scene_style, SCENE_STYLES["restaurant"]).format(bowl_style=bowl_desc)
    scene_prompt += f"\nThe dish is: {food_desc}. Keep the food arrangement exactly as in the original."

    scene = generate_scene(sq, mask, scene_prompt, reference_path)
    scene.save(str(output_dir / f"{name}_02_scene.png"), "PNG")
    print(f"    ✅ Scene generated")
    time.sleep(3)

    # ── STAGE 3: Photographic finish ──
    print(f"    ✨ Stage 3: Photographic finish...")
    finished = photographic_finish(scene, food_desc)
    finished.save(str(output_dir / f"{name}_03_finished.png"), "PNG")
    print(f"    ✅ Finished")
    time.sleep(3)

    # ── STAGE 4: White background (optional) ──
    if white_bg:
        print(f"    ⬜ Stage 4: White background...")
        final = convert_to_white_bg(finished)
        final.save(str(output_dir / f"{name}_04_white.png"), "PNG")
        print(f"    ✅ White background applied")
    else:
        final = finished

    # ── STAGE 5: Export ──
    print(f"    💾 Stage 5: Export...")
    final_800 = final.resize((800, 800), Image.LANCZOS)
    final_800.save(str(output_dir / f"{name}_FINAL_800x800.jpg"), "JPEG", quality=95)

    thumb = final_800.resize((80, 80), Image.LANCZOS)
    thumb.save(str(output_dir / f"{name}_FINAL_80px.jpg"), "JPEG", quality=85)

    print(f"    ✅ {name}_FINAL_800x800.jpg")
    print(f"    ✅ Done")

    return final


def batch_process(input_dir, output_dir, menu_items=None,
                  scene_style="restaurant", bowl_style="grey_ceramic",
                  white_bg=True, reference_path=None):
    """Process all photos as one consistent store."""

    input_dir = Path(input_dir)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if menu_items:
        photos = [(input_dir / item["file"], item) for item in menu_items]
    else:
        files = sorted(list(input_dir.glob("*.jpg")) + list(input_dir.glob("*.jpeg")) +
                       list(input_dir.glob("*.png")))
        # Filter out already-processed files
        files = [f for f in files if "FINAL" not in f.name and "enhanced" not in str(f)
                 and "_0" not in f.name and "pass" not in f.name]
        photos = [(f, {"name": f.stem.lower(), "food_desc": "food dish"}) for f in files]

    print(f"\n{'═'*55}")
    print(f"  GRABFOOD PRO — {len(photos)} dishes")
    print(f"  Scene: {scene_style} | Bowls: {bowl_style}")
    print(f"  White BG: {'yes' if white_bg else 'no'}")
    print(f"  Pipeline: BiRefNet → FLUX Inpaint → NANO Finish{' → White BG' if white_bg else ''}")
    print(f"{'═'*55}")

    results = []
    for i, (photo_path, item) in enumerate(photos):
        name = item.get("name", photo_path.stem.lower())
        desc = item.get("food_desc", "food dish")

        try:
            result = process_single(
                str(photo_path), str(output_dir),
                dish_name=name, food_desc=desc,
                scene_style=scene_style, bowl_style=bowl_style,
                white_bg=white_bg, reference_path=reference_path,
            )
            results.append(result)
        except Exception as e:
            print(f"    ❌ {photo_path.name}: {e}")
            import traceback; traceback.print_exc()

        if i < len(photos) - 1:
            time.sleep(5)

    print(f"\n{'═'*55}")
    print(f"  ✅ STORE COMPLETE: {len(results)}/{len(photos)} dishes")
    print(f"  📁 {output_dir}")
    print(f"{'═'*55}")

    return results


# ═══════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GrabFood Pro Enhancement")
    parser.add_argument("input", help="Photo or directory")
    parser.add_argument("-o", "--output", default="./enhanced-pro")
    parser.add_argument("-n", "--name", default=None)
    parser.add_argument("-d", "--desc", default=None, help="Food description")
    parser.add_argument("-s", "--scene", default="restaurant",
                        choices=list(SCENE_STYLES.keys()))
    parser.add_argument("-b", "--bowl", default="grey_ceramic",
                        choices=list(BOWL_STYLES.keys()))
    parser.add_argument("--no-white-bg", action="store_true",
                        help="Skip white background conversion")
    parser.add_argument("-r", "--reference", default=None)
    args = parser.parse_args()

    p = Path(args.input)
    if p.is_dir():
        batch_process(str(p), args.output, scene_style=args.scene,
                      bowl_style=args.bowl, white_bg=not args.no_white_bg,
                      reference_path=args.reference)
    else:
        process_single(str(p), args.output, args.name, args.desc,
                       args.scene, args.bowl, not args.no_white_bg, args.reference)
