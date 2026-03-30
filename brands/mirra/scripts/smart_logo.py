"""
Smart Logo Placement — analyzes image content to find the best clear zone.
Detects luminance, edge density, and text regions to avoid overlap.
Places logo where it's least intrusive and most integrated.
"""
from PIL import Image
import numpy as np
from pathlib import Path

LOGO_PATH = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/04_references/curated/MIRRA LOGO")
LOGO_BLACK = LOGO_PATH / "Mirra logo-black.png"
LOGO_WHITE = LOGO_PATH / "Mirra logo-white.png"

# 6 candidate zones
ZONES = {
    "bottom-right":  (0.75, 0.88, 0.95, 0.97),   # x1%, y1%, x2%, y2% of canvas
    "bottom-left":   (0.03, 0.88, 0.25, 0.97),
    "bottom-center": (0.38, 0.92, 0.62, 0.98),
    "top-right":     (0.75, 0.02, 0.97, 0.08),
    "top-left":      (0.03, 0.02, 0.25, 0.08),
    "top-center":    (0.38, 0.02, 0.62, 0.08),
}


def analyze_zone(img_arr, zone_box):
    """Score a zone: lower = cleaner = better for logo."""
    h, w = img_arr.shape[:2]
    x1, y1, x2, y2 = int(w*zone_box[0]), int(h*zone_box[1]), int(w*zone_box[2]), int(h*zone_box[3])
    region = img_arr[y1:y2, x1:x2]

    if region.size == 0:
        return 999

    # Edge density (high = text/detail = bad for logo)
    gray = np.mean(region, axis=2)
    dx = np.abs(np.diff(gray, axis=1))
    dy = np.abs(np.diff(gray, axis=0))
    edge_score = np.mean(dx) + np.mean(dy)

    # Variance (high = busy = bad)
    var_score = np.std(region) / 10

    # Combined: lower = cleaner
    return edge_score + var_score


def get_zone_luminance(img_arr, zone_box):
    """Average luminance of a zone (0=dark, 255=bright)."""
    h, w = img_arr.shape[:2]
    x1, y1, x2, y2 = int(w*zone_box[0]), int(h*zone_box[1]), int(w*zone_box[2]), int(h*zone_box[3])
    region = img_arr[y1:y2, x1:x2]
    if region.size == 0:
        return 128
    return np.mean(region)


def smart_place_logo(img, preferred_zones=None, logo_width=120):
    """
    Analyze image, find cleanest zone, place correct logo variant.
    preferred_zones: list of zone names to prefer (in order). If None, check all.
    """
    arr = np.array(img)

    # Score all zones
    zones_to_check = preferred_zones or list(ZONES.keys())
    scores = {}
    for zname in zones_to_check:
        if zname in ZONES:
            scores[zname] = analyze_zone(arr, ZONES[zname])

    # Pick cleanest zone
    best_zone = min(scores, key=scores.get)
    best_box = ZONES[best_zone]

    # Pick logo color based on zone luminance
    lum = get_zone_luminance(arr, best_box)
    logo_file = LOGO_BLACK if lum > 140 else LOGO_WHITE

    # Load and resize logo
    logo = Image.open(str(logo_file)).convert("RGBA")
    bbox = logo.getbbox()
    if bbox:
        logo = logo.crop(bbox)
    ratio = logo_width / logo.width
    logo = logo.resize((logo_width, int(logo.height * ratio)), Image.LANCZOS)

    # Calculate position
    h, w = arr.shape[:2]
    x1, y1, x2, y2 = int(w*best_box[0]), int(h*best_box[1]), int(w*best_box[2]), int(h*best_box[3])
    # Center logo within the zone
    lx = x1 + (x2 - x1 - logo.width) // 2
    ly = y1 + (y2 - y1 - logo.height) // 2

    # Composite
    canvas = img.convert("RGBA")
    canvas.paste(logo, (lx, ly), logo)

    return canvas.convert("RGB"), best_zone, lum


def reprocess_with_smart_logo(input_path, output_path, preferred_zones=None, logo_width=120):
    """Load an existing image, apply smart logo, save."""
    img = Image.open(str(input_path))
    img, zone, lum = smart_place_logo(img, preferred_zones, logo_width)
    img.save(str(output_path), "PNG")
    logo_type = "black" if lum > 140 else "white"
    print(f"  Logo: {zone} ({logo_type}, lum={lum:.0f})")
    return zone


if __name__ == "__main__":
    # Test on all 8 viral regens
    IN = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/06_exports/social/viral-regen-v1")
    OUT = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/06_exports/social/viral-regen-v1-smartlogo")
    OUT.mkdir(parents=True, exist_ok=True)

    # Per-post preferred zones based on layout audit
    PREFS = {
        "VR01": ["bottom-right", "bottom-center"],        # 3-panel: below panels
        "VR02": ["bottom-center", "bottom-right"],         # 3-panel: below last panel
        "VR03": ["bottom-right", "bottom-center"],         # 6-panel: corner of last panel
        "VR04": ["bottom-center", "bottom-right"],         # Single: below character
        "VR05": ["bottom-center", "bottom-right"],         # 4-panel: below panels
        "VR06": ["bottom-right", "top-right"],             # Single + text: beside text
        "VR07": ["bottom-right", "bottom-center"],         # Split: in "me:" panel
        "VR08": ["bottom-center", "bottom-right"],         # 3-panel: below caption
    }

    for f in sorted(IN.glob("VR*.png")):
        prefix = f.stem[:4]
        prefs = PREFS.get(prefix)
        print(f"{f.stem}:")
        reprocess_with_smart_logo(f, OUT / f.name, prefs)
