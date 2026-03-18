#!/usr/bin/env python3
"""
stitch-refs.py — Multi-angle product reference compositor for GAIA CORP-OS.

Stitches 2-3 product photos into 1 composite for ref_image injection.
Both Sora 2 and Kling only accept 1 reference image — this solves the
"bento shape distortion" problem by showing the model multiple angles.

Usage:
  python3 stitch-refs.py --images top.jpg front.jpg --output composite.jpg
  python3 stitch-refs.py --product "Japanese Curry Katsu" --brand mirra --output composite.jpg
  python3 stitch-refs.py --brand mirra --all  # batch all products

Output: 720x1280 portrait composite (matches Reels/Sora input format)

Layout options:
  --layout stack    (default) Top image above, front/side below
  --layout grid     2x2 grid for 3-4 angles
  --layout side     Side-by-side panels
"""
import argparse
import glob
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("ERROR: Pillow required. Install: pip3 install Pillow", file=sys.stderr)
    sys.exit(1)

BRANDS_DIR = Path.home() / ".openclaw" / "brands"
OUTPUT_SIZE = (720, 1280)  # Portrait format for Reels/video gen
BG_COLOR = (15, 15, 20)  # Near-black background
LABEL_COLOR = (200, 200, 200)  # Light gray text
PADDING = 12
LABEL_HEIGHT = 28


def load_font(size=18):
    """Load system font, fallback to default."""
    font_paths = [
        "/System/Library/Fonts/Helvetica.ttc",
        "/System/Library/Fonts/SFNSText.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for fp in font_paths:
        try:
            return ImageFont.truetype(fp, size)
        except (IOError, OSError):
            continue
    return ImageFont.load_default()


def fit_image(img, target_w, target_h):
    """Resize image to fit within target dimensions, maintaining aspect ratio."""
    ratio = min(target_w / img.width, target_h / img.height)
    new_w = int(img.width * ratio)
    new_h = int(img.height * ratio)
    return img.resize((new_w, new_h), Image.LANCZOS)


def stitch_stack(images, labels, output_path):
    """Stack layout: first image on top (larger), remaining below side-by-side."""
    canvas = Image.new("RGB", OUTPUT_SIZE, BG_COLOR)
    draw = ImageDraw.Draw(canvas)
    font = load_font(16)
    label_font = load_font(14)

    w, h = OUTPUT_SIZE
    usable_h = h - PADDING * 2

    if len(images) == 1:
        # Single image: center it
        img = fit_image(images[0], w - PADDING * 2, usable_h - LABEL_HEIGHT)
        x = (w - img.width) // 2
        y = (h - img.height - LABEL_HEIGHT) // 2
        canvas.paste(img, (x, y))
        if labels:
            draw.text((x, y + img.height + 4), labels[0], fill=LABEL_COLOR, font=label_font)

    elif len(images) == 2:
        # Top image takes 55% height, bottom takes 40%
        top_h = int(usable_h * 0.55) - LABEL_HEIGHT
        bot_h = int(usable_h * 0.40) - LABEL_HEIGHT

        # Top image
        top_img = fit_image(images[0], w - PADDING * 2, top_h)
        tx = (w - top_img.width) // 2
        ty = PADDING
        canvas.paste(top_img, (tx, ty))
        if len(labels) > 0:
            draw.text((tx, ty + top_img.height + 2), labels[0], fill=LABEL_COLOR, font=label_font)

        # Bottom image
        bot_img = fit_image(images[1], w - PADDING * 2, bot_h)
        bx = (w - bot_img.width) // 2
        by = ty + top_h + LABEL_HEIGHT + PADDING
        canvas.paste(bot_img, (bx, by))
        if len(labels) > 1:
            draw.text((bx, by + bot_img.height + 2), labels[1], fill=LABEL_COLOR, font=label_font)

    else:
        # 3+ images: top image takes 50%, bottom row splits remaining
        top_h = int(usable_h * 0.50) - LABEL_HEIGHT
        bot_h = int(usable_h * 0.45) - LABEL_HEIGHT
        n_bottom = len(images) - 1
        panel_w = (w - PADDING * (n_bottom + 1)) // n_bottom

        # Top image (primary angle)
        top_img = fit_image(images[0], w - PADDING * 2, top_h)
        tx = (w - top_img.width) // 2
        ty = PADDING
        canvas.paste(top_img, (tx, ty))
        if len(labels) > 0:
            draw.text((tx, ty + top_img.height + 2), labels[0], fill=LABEL_COLOR, font=label_font)

        # Bottom row
        by = ty + top_h + LABEL_HEIGHT + PADDING
        for i, img in enumerate(images[1:], 1):
            bot_img = fit_image(img, panel_w, bot_h)
            bx = PADDING + (i - 1) * (panel_w + PADDING) + (panel_w - bot_img.width) // 2
            canvas.paste(bot_img, (bx, by))
            if i < len(labels):
                draw.text((bx, by + bot_img.height + 2), labels[i], fill=LABEL_COLOR, font=label_font)

    canvas.save(output_path, quality=92)
    return output_path


def stitch_grid(images, labels, output_path):
    """Grid layout: 2x2 for 4 images, 2-col for 2-3."""
    canvas = Image.new("RGB", OUTPUT_SIZE, BG_COLOR)
    draw = ImageDraw.Draw(canvas)
    label_font = load_font(14)

    w, h = OUTPUT_SIZE
    cols = 2
    rows = (len(images) + 1) // 2
    cell_w = (w - PADDING * (cols + 1)) // cols
    cell_h = (h - PADDING * (rows + 1) - LABEL_HEIGHT * rows) // rows

    for idx, img in enumerate(images):
        row = idx // cols
        col = idx % cols
        fitted = fit_image(img, cell_w, cell_h)
        x = PADDING + col * (cell_w + PADDING) + (cell_w - fitted.width) // 2
        y = PADDING + row * (cell_h + LABEL_HEIGHT + PADDING)
        canvas.paste(fitted, (x, y))
        if idx < len(labels):
            draw.text((x, y + fitted.height + 2), labels[idx], fill=LABEL_COLOR, font=label_font)

    canvas.save(output_path, quality=92)
    return output_path


def stitch_side(images, labels, output_path):
    """Side-by-side panels (vertical strips)."""
    canvas = Image.new("RGB", OUTPUT_SIZE, BG_COLOR)
    draw = ImageDraw.Draw(canvas)
    label_font = load_font(14)

    w, h = OUTPUT_SIZE
    n = len(images)
    panel_w = (w - PADDING * (n + 1)) // n
    panel_h = h - PADDING * 2 - LABEL_HEIGHT

    for idx, img in enumerate(images):
        fitted = fit_image(img, panel_w, panel_h)
        x = PADDING + idx * (panel_w + PADDING) + (panel_w - fitted.width) // 2
        y = PADDING + (panel_h - fitted.height) // 2
        canvas.paste(fitted, (x, y))
        if idx < len(labels):
            draw.text((x, y + fitted.height + 4), labels[idx], fill=LABEL_COLOR, font=label_font)

    canvas.save(output_path, quality=92)
    return output_path


def auto_label(filepath):
    """Infer angle label from filename."""
    name = os.path.basename(filepath).lower()
    if "top" in name or "flat" in name:
        return "TOP VIEW"
    if "side" in name:
        return "SIDE VIEW"
    if "front" in name:
        return "FRONT VIEW"
    if "portrait" in name or "720x1280" in name:
        return "FRONT VIEW"
    if "bowl" in name:
        return "BOWL VIEW"
    return "PRODUCT"


def _extract_core_words(filename, brand=""):
    """Extract core product words from a filename, stripping noise."""
    name = filename.lower()
    # Strip common noise words
    noise = [brand.lower(), "720x1280", "1080x1920", "top-view", "top view",
             "bento-box", "bento box", "mirra", "bowl", "group image",
             ".jpg", ".jpeg", ".png", ".webp", "_", "-"]
    for n in noise:
        name = name.replace(n, " ")
    # Keep only meaningful words (3+ chars)
    words = [w for w in name.split() if len(w) >= 3]
    return set(words)


def _match_score(words_a, words_b):
    """Score how well two word sets match (0.0-1.0)."""
    if not words_a or not words_b:
        return 0.0
    overlap = words_a & words_b
    # Jaccard-like: overlap / smaller set
    return len(overlap) / min(len(words_a), len(words_b))


def find_product_images(brand, product_name=None):
    """Find matching product images across portrait and flat directories.
    Uses fuzzy word matching to group images of the same product."""
    brand_dir = BRANDS_DIR / brand / "references"
    # Collect all images with their metadata
    all_images = []  # [(path, label, core_words)]

    for subdir in ["products-portrait", "products-flat"]:
        img_dir = brand_dir / subdir
        if not img_dir.is_dir():
            continue
        for ext in ["*.jpg", "*.jpeg", "*.png", "*.webp"]:
            for fp in img_dir.glob(ext):
                if fp.stem.lower() in ["group image", "group"]:
                    continue  # Skip generic group shots
                label = auto_label(str(fp))
                words = _extract_core_words(fp.stem, brand)
                if product_name:
                    search_words = set(product_name.lower().split())
                    if _match_score(words, search_words) < 0.5:
                        continue
                all_images.append((str(fp), label, words))

    # Group by fuzzy matching: merge images with >= 60% word overlap
    groups = []  # [(key_name, [(path, label)])]
    used = set()

    for i, (path_a, label_a, words_a) in enumerate(all_images):
        if i in used:
            continue
        group = [(path_a, label_a)]
        used.add(i)
        group_words = set(words_a)
        key_name = " ".join(sorted(words_a))

        for j, (path_b, label_b, words_b) in enumerate(all_images):
            if j in used:
                continue
            if label_a == label_b:
                continue  # Don't group same-angle images
            if _match_score(group_words, words_b) >= 0.5:
                group.append((path_b, label_b))
                used.add(j)
                group_words |= words_b

        groups.append((key_name, group))

    results = {}
    for key, group in groups:
        results[key] = group

    return results


def batch_all(brand, output_dir, layout="stack"):
    """Generate composites for all products that have multiple angles."""
    products = find_product_images(brand)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    count = 0
    for product_key, image_list in products.items():
        if len(image_list) < 2:
            continue
        images = [Image.open(path) for path, _ in image_list]
        labels = [label for _, label in image_list]
        safe_name = product_key.replace(" ", "-").replace("/", "-")[:50]
        out_path = output_dir / f"{safe_name}_composite.jpg"

        stitch_fn = {"stack": stitch_stack, "grid": stitch_grid, "side": stitch_side}.get(layout, stitch_stack)
        stitch_fn(images, labels, str(out_path))
        print(f"  {safe_name}: {len(images)} angles -> {out_path}")
        count += 1
        for img in images:
            img.close()

    print(f"\nGenerated {count} composites in {output_dir}")
    return count


def main():
    parser = argparse.ArgumentParser(description="Multi-angle product reference compositor")
    parser.add_argument("--images", nargs="+", help="Image files to composite")
    parser.add_argument("--labels", nargs="+", help="Labels for each image (auto-detected if omitted)")
    parser.add_argument("--output", "-o", help="Output file path")
    parser.add_argument("--layout", choices=["stack", "grid", "side"], default="stack",
                        help="Layout style (default: stack)")
    parser.add_argument("--brand", help="Brand name for auto-discovery")
    parser.add_argument("--product", help="Product name to search for")
    parser.add_argument("--all", action="store_true", help="Batch all products with multiple angles")
    parser.add_argument("--output-dir", help="Output directory for batch mode")
    args = parser.parse_args()

    # Batch mode
    if args.all and args.brand:
        out_dir = args.output_dir or str(BRANDS_DIR / args.brand / "references" / "products-composite")
        batch_all(args.brand, out_dir, args.layout)
        return

    # Auto-discovery by product name
    if args.brand and args.product:
        products = find_product_images(args.brand, args.product)
        if not products:
            print(f"No images found for product '{args.product}' in brand '{args.brand}'", file=sys.stderr)
            sys.exit(1)
        # Use first matching product
        key = list(products.keys())[0]
        image_list = products[key]
        image_paths = [p for p, _ in image_list]
        labels = [l for _, l in image_list]
        print(f"Found {len(image_paths)} angles for '{key}':")
        for p, l in image_list:
            print(f"  {l}: {os.path.basename(p)}")
    elif args.images:
        image_paths = args.images
        labels = args.labels or [auto_label(p) for p in image_paths]
    else:
        parser.print_help()
        sys.exit(1)

    if not image_paths:
        print("No images to composite", file=sys.stderr)
        sys.exit(1)

    # Load images
    images = []
    for p in image_paths:
        if not os.path.isfile(p):
            print(f"File not found: {p}", file=sys.stderr)
            sys.exit(1)
        images.append(Image.open(p))

    # Determine output path
    output = args.output
    if not output:
        if args.brand:
            out_dir = BRANDS_DIR / args.brand / "references" / "products-composite"
            out_dir.mkdir(parents=True, exist_ok=True)
            name = args.product.replace(" ", "-") if args.product else "composite"
            output = str(out_dir / f"{name}_composite.jpg")
        else:
            output = "composite.jpg"

    # Stitch
    stitch_fn = {"stack": stitch_stack, "grid": stitch_grid, "side": stitch_side}.get(args.layout, stitch_stack)
    result = stitch_fn(images, labels, output)
    print(f"Composite saved: {result}")
    print(f"Size: {OUTPUT_SIZE[0]}x{OUTPUT_SIZE[1]} (portrait)")

    for img in images:
        img.close()


if __name__ == "__main__":
    main()
