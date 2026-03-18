#!/usr/bin/env python3
"""
MIRRA Ad Compositor — Composes real brand assets into ad layouts.

Unlike AI image generators that hallucinate everything, this tool:
1. Picks REAL product photos (SKU images)
2. Places the REAL brand logo
3. Renders badge icons (Nutritionist Designed, No MSG, Plant-Based)
4. Uses brand fonts and colors
5. Composites all layers via HTML→Playwright screenshot

Usage:
    ad-compose.py comparison --sku fusilli --headline "This or That" --competitor-label "Fried Rice" --competitor-cal 900 --mirra-cal 423 --tagline "Same delicious local flavours, no compromises."
    ad-compose.py hero --sku pad-thai --headline "Eat Clean, Feel Amazing"
    ad-compose.py grid --skus fusilli,pad-thai,katsu,burrito --headline "Pick Your Power Lunch"
    ad-compose.py list-skus
    ad-compose.py list-templates
"""

import argparse
import json
import os
import sys
import base64
import random
from pathlib import Path
from datetime import datetime

# ── Paths ────────────────────────────────────────────────────────
BRAND_DIR = Path(os.path.expanduser("~/.openclaw/brands/mirra"))
ASSETS_DIR = BRAND_DIR / "assets"
LOGO_PATH = ASSETS_DIR / "logo-black.png"
SKU_DIR = Path(os.path.expanduser(
    "~/.openclaw/workspace/brands/mirra/march-campaign/drive-assets/My product bento"
))
OUTPUT_DIR = Path(os.path.expanduser(
    "~/.openclaw/workspace/data/images/mirra"
))
COMPETITOR_REF_DIR = Path(os.path.expanduser(
    "~/.openclaw/workspace/brands/mirra/march-campaign/drive-assets/Food Photography reference"
))

# ── Brand Colors ─────────────────────────────────────────────────
COLORS = {
    "primary": "#F7AB9F",      # Salmon pink
    "secondary": "#252525",     # Near black
    "background": "#FFF9EB",    # Warm cream
    "accent": "#F7AB9F",
    "badge_bg": "#252525",
    "badge_text": "#FFFFFF",
    "cal_good": "#F7AB9F",      # Pink for MIRRA cal
    "cal_bad": "#252525",       # Black for competitor cal
}

# ── SKU Catalog ──────────────────────────────────────────────────
SKU_CATALOG = {
    "bbq-pita": {
        "name": "BBQ Pita Mushroom Wrap Bento Box",
        "file": "BBQ-Pita-Mushroom-Wrap-Bento-Box.png",
        "file_top": "BBQ-Pita-Mushroom-Wrap-Bento-Box-Top-View.png",
        "calories": 450,
        "price": 18,
    },
    "curry-konjac": {
        "name": "Dry Classic Curry Konjac Noodle",
        "file": "Dry-Classic-Curry-Konjac-Noodle.png",
        "file_top": "Dry-Classic-Curry-Konjac-Noodle-Top-View.png",
        "calories": 380,
        "price": 16,
    },
    "burrito": {
        "name": "Fierry Burrito Bowl",
        "file": "Fierry-Buritto-Bowl.png",
        "file_top": "Fierry-Buritto-Bowl-Top-View.png",
        "calories": 420,
        "price": 18,
    },
    "fusilli": {
        "name": "Fusilli Bolognese Bento Box",
        "file": "Fusilli-Bolognese-Bento-Box.png",
        "file_top": "Fusilli-Bolognese-Bento-Box-Top-View.png",
        "calories": 460,
        "price": 18,
    },
    "eryngii": {
        "name": "Golden Eryngii Fragrant Rice Bento Box",
        "file": "Golden-Eryngii-Fragrant-Rice-Bento-Box.png",
        "file_top": "Golden-Eryngii-Fragrant-Rice-Bento-Box-Top-View.png",
        "calories": 430,
        "price": 17,
    },
    "katsu": {
        "name": "Japanese Curry Katsu Bento Box",
        "file": "Japanese Curry Katsu Bento Box.png",
        "file_top": "Japanese Curry Katsu Bento Box-Top View.png",
        "calories": 480,
        "price": 19,
    },
    "pad-thai": {
        "name": "Konjac Pad Thai Bento Box",
        "file": "Konjac-Pad-Thai-Bento-Box.png",
        "file_top": "Konjac-Pad-Thai-Bento-Box-Top-View.png",
        "calories": 390,
        "price": 17,
    },
}

# ── Competitor presets ───────────────────────────────────────────
COMPETITOR_PRESETS = {
    "nasi-lemak": {"label": "Nasi Lemak", "calories": 850, "price": 12},
    "fried-rice": {"label": "Fried Rice", "calories": 900, "price": 10},
    "char-kway-teow": {"label": "Char Kway Teow", "calories": 750, "price": 8},
    "roti-canai": {"label": "Roti Canai Set", "calories": 680, "price": 7},
    "mcdonalds": {"label": "McDonald's Set", "calories": 1100, "price": 15},
    "grabfood": {"label": "GrabFood Average", "calories": 800, "price": 25},
    "mamak": {"label": "Mamak Dinner", "calories": 950, "price": 12},
}


def img_to_data_uri(path: Path) -> str:
    """Convert image file to data URI for embedding in HTML."""
    if not path.exists():
        print(f"WARNING: Image not found: {path}", file=sys.stderr)
        return ""
    suffix = path.suffix.lower()
    mime = {"png": "image/png", "jpg": "image/jpeg", "jpeg": "image/jpeg",
            "svg": "image/svg+xml", "gif": "image/gif", "webp": "image/webp"}
    mime_type = mime.get(suffix.lstrip("."), "image/png")
    data = base64.b64encode(path.read_bytes()).decode()
    return f"data:{mime_type};base64,{data}"


def get_sku_image(sku_id: str, top_view: bool = True) -> Path:
    """Get the product image path for a SKU."""
    sku = SKU_CATALOG.get(sku_id)
    if not sku:
        print(f"ERROR: Unknown SKU '{sku_id}'. Use 'list-skus' to see options.", file=sys.stderr)
        sys.exit(1)
    fname = sku["file_top"] if top_view else sku["file"]
    return SKU_DIR / fname


def pick_random_competitor_image() -> Path:
    """Pick a random food photo from the competitor reference folder."""
    if not COMPETITOR_REF_DIR.exists():
        return None
    images = [f for f in COMPETITOR_REF_DIR.iterdir()
              if f.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp")]
    if not images:
        return None
    return random.choice(images)


# ── Badge SVGs (inline) ─────────────────────────────────────────
BADGE_NUTRITIONIST = '''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <circle cx="40" cy="40" r="38" fill="#252525" stroke="#F7AB9F" stroke-width="2"/>
  <text x="40" y="32" text-anchor="middle" fill="white" font-size="9" font-weight="bold" font-family="Georgia,serif">NUTRITIONIST</text>
  <text x="40" y="44" text-anchor="middle" fill="white" font-size="9" font-weight="bold" font-family="Georgia,serif">APPROVED</text>
  <path d="M30 54 L35 50 L40 56 L50 46 L55 50 L40 62Z" fill="#F7AB9F"/>
</svg>'''

BADGE_NO_MSG = '''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <circle cx="40" cy="40" r="38" fill="#252525" stroke="#F7AB9F" stroke-width="2"/>
  <text x="40" y="36" text-anchor="middle" fill="white" font-size="14" font-weight="bold" font-family="Georgia,serif">NO</text>
  <text x="40" y="52" text-anchor="middle" fill="white" font-size="14" font-weight="bold" font-family="Georgia,serif">MSG</text>
  <line x1="15" y1="15" x2="65" y2="65" stroke="#F7AB9F" stroke-width="3"/>
</svg>'''

BADGE_PLANT = '''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <circle cx="40" cy="40" r="38" fill="#252525" stroke="#F7AB9F" stroke-width="2"/>
  <text x="40" y="30" text-anchor="middle" fill="white" font-size="8" font-weight="bold" font-family="Georgia,serif">PLANT-BASED</text>
  <text x="40" y="42" text-anchor="middle" fill="white" font-size="8" font-weight="bold" font-family="Georgia,serif">PERFECTION</text>
  <path d="M35 48 C35 48 30 58 40 62 C50 58 45 48 45 48 L40 44Z" fill="#4CAF50"/>
  <line x1="40" y1="50" x2="40" y2="60" stroke="#2E7D32" stroke-width="1.5"/>
</svg>'''

BADGE_HALAL = '''<svg width="80" height="80" viewBox="0 0 80 80" xmlns="http://www.w3.org/2000/svg">
  <circle cx="40" cy="40" r="38" fill="#1B5E20" stroke="#4CAF50" stroke-width="2"/>
  <text x="40" y="36" text-anchor="middle" fill="white" font-size="11" font-weight="bold" font-family="Georgia,serif">HALAL</text>
  <text x="40" y="52" text-anchor="middle" fill="white" font-size="8" font-family="Georgia,serif">CERTIFIED</text>
</svg>'''


def badge_data_uri(svg_str: str) -> str:
    b64 = base64.b64encode(svg_str.encode()).decode()
    return f"data:image/svg+xml;base64,{b64}"


# ── HTML Templates ───────────────────────────────────────────────

def comparison_html(args) -> str:
    """Generate comparison ad HTML (This vs That layout)."""
    sku = SKU_CATALOG[args.sku]
    sku_img = img_to_data_uri(get_sku_image(args.sku, top_view=True))
    logo = img_to_data_uri(LOGO_PATH)

    # Competitor image — use reference photo if available
    competitor_img_tag = ""
    comp_img = pick_random_competitor_image()
    if comp_img:
        competitor_img_tag = f'<img src="{img_to_data_uri(comp_img)}" class="food-img competitor-img">'
    else:
        competitor_img_tag = '<div class="food-img placeholder-food">🍛</div>'

    headline = args.headline or "This or That"
    competitor_label = args.competitor_label or "Regular Takeout"
    competitor_cal = args.competitor_cal or 900
    mirra_cal = sku["calories"]
    tagline = args.tagline or "Same delicious local flavours, no compromises."
    mirra_price = f"RM{sku['price']}"

    badges_html = f'''
    <div class="badges">
        <img src="{badge_data_uri(BADGE_NUTRITIONIST)}" class="badge-icon">
        <img src="{badge_data_uri(BADGE_NO_MSG)}" class="badge-icon">
        <img src="{badge_data_uri(BADGE_PLANT)}" class="badge-icon">
    </div>
    '''

    return f'''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;900&family=DM+Sans:wght@400;500;700&display=swap');

  * {{ margin: 0; padding: 0; box-sizing: border-box; }}

  body {{
    width: 1080px;
    height: 1080px;
    overflow: hidden;
    font-family: 'DM Sans', sans-serif;
  }}

  .container {{
    width: 1080px;
    height: 1080px;
    display: flex;
    flex-direction: column;
    position: relative;
  }}

  /* ── Top: Logo ── */
  .logo-bar {{
    position: absolute;
    top: 30px;
    right: 40px;
    z-index: 10;
  }}
  .logo-bar img {{
    height: 40px;
  }}

  /* ── Headline ── */
  .headline {{
    text-align: center;
    padding: 40px 40px 20px;
    background: {COLORS["primary"]};
    font-family: 'Playfair Display', serif;
    font-size: 56px;
    font-weight: 900;
    color: {COLORS["secondary"]};
    letter-spacing: -1px;
  }}

  /* ── Split panels ── */
  .split {{
    display: flex;
    flex: 1;
    min-height: 0;
  }}

  .panel {{
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 30px;
    position: relative;
  }}

  .panel-left {{
    background: {COLORS["primary"]};
  }}

  .panel-right {{
    background: {COLORS["background"]};
  }}

  /* ── Divider ── */
  .split::after {{
    content: '';
    position: absolute;
    left: 50%;
    top: 120px;
    bottom: 180px;
    width: 2px;
    background: rgba(0,0,0,0.15);
    border-style: dashed;
    z-index: 5;
  }}

  /* ── Food images ── */
  .food-img {{
    max-width: 380px;
    max-height: 380px;
    object-fit: contain;
    border-radius: 12px;
    filter: drop-shadow(0 8px 24px rgba(0,0,0,0.15));
  }}

  .competitor-img {{
    filter: drop-shadow(0 8px 24px rgba(0,0,0,0.15));
  }}

  .placeholder-food {{
    font-size: 200px;
    opacity: 0.6;
  }}

  /* ── Labels ── */
  .food-label {{
    font-family: 'DM Sans', sans-serif;
    font-size: 22px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1px;
    margin-top: 16px;
    color: {COLORS["secondary"]};
  }}

  /* ── Calorie badges ── */
  .cal-badge {{
    display: inline-block;
    padding: 8px 24px;
    border-radius: 6px;
    font-family: 'DM Sans', sans-serif;
    font-size: 28px;
    font-weight: 700;
    margin-top: 12px;
  }}

  .cal-bad {{
    background: {COLORS["cal_bad"]};
    color: white;
  }}

  .cal-good {{
    background: {COLORS["cal_good"]};
    color: {COLORS["secondary"]};
  }}

  /* ── Price ── */
  .price-tag {{
    font-family: 'DM Sans', sans-serif;
    font-size: 20px;
    font-weight: 500;
    margin-top: 8px;
    color: {COLORS["secondary"]};
    opacity: 0.7;
  }}

  /* ── Badges row ── */
  .badges {{
    display: flex;
    gap: 10px;
    margin-top: 14px;
  }}
  .badge-icon {{
    width: 55px;
    height: 55px;
  }}

  /* ── Nutritionist callout ── */
  .nutritionist-callout {{
    position: absolute;
    top: 20px;
    right: 20px;
    background: white;
    border-radius: 20px;
    padding: 8px 16px;
    font-family: 'Playfair Display', serif;
    font-style: italic;
    font-size: 16px;
    color: {COLORS["secondary"]};
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    display: flex;
    align-items: center;
    gap: 6px;
  }}
  .nutritionist-callout svg {{
    width: 24px;
    height: 24px;
  }}

  /* ── Bottom bar ── */
  .tagline-bar {{
    background: {COLORS["background"]};
    text-align: center;
    padding: 24px 40px;
    font-family: 'Playfair Display', serif;
    font-size: 30px;
    font-weight: 700;
    color: {COLORS["secondary"]};
    border-top: 2px solid rgba(0,0,0,0.08);
  }}
</style>
</head>
<body>
<div class="container">
  <!-- Logo -->
  <div class="logo-bar">
    <img src="{logo}" alt="MIRRA">
  </div>

  <!-- Headline -->
  <div class="headline">{headline}</div>

  <!-- Split comparison -->
  <div class="split" style="position:relative;">
    <!-- Left: Competitor -->
    <div class="panel panel-left">
      {competitor_img_tag}
      <div class="food-label">{competitor_label}</div>
      <div class="cal-badge cal-bad">{competitor_cal} kcal</div>
    </div>

    <!-- Right: MIRRA -->
    <div class="panel panel-right">
      <div class="nutritionist-callout">
        <svg viewBox="0 0 24 24" fill="none"><path d="M9 12l2 2 4-4" stroke="{COLORS['primary']}" stroke-width="2.5" stroke-linecap="round"/><circle cx="12" cy="12" r="10" stroke="{COLORS['primary']}" stroke-width="2"/></svg>
        Nutritionist Designed
      </div>
      <img src="{sku_img}" class="food-img">
      <div class="food-label">MIRRA {sku["name"].split(" Bento")[0]}</div>
      <div class="cal-badge cal-good">{mirra_cal} kcal</div>
      <div class="price-tag">{mirra_price} only</div>
      {badges_html}
    </div>
  </div>

  <!-- Tagline -->
  <div class="tagline-bar">{tagline}</div>
</div>
</body>
</html>'''


def hero_html(args) -> str:
    """Generate hero ad HTML (single product showcase)."""
    sku = SKU_CATALOG[args.sku]
    sku_img = img_to_data_uri(get_sku_image(args.sku, top_view=False))
    logo = img_to_data_uri(LOGO_PATH)
    headline = args.headline or "Eat Clean. Feel Amazing."
    tagline = args.tagline or f"Only RM{sku['price']} · {sku['calories']} kcal · Nutritionist Designed"

    return f'''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;900&family=DM+Sans:wght@400;500;700&display=swap');
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ width: 1080px; height: 1080px; overflow: hidden; }}

  .container {{
    width: 1080px;
    height: 1080px;
    background: linear-gradient(160deg, {COLORS["primary"]} 0%, {COLORS["background"]} 100%);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    position: relative;
  }}

  .logo {{ position: absolute; top: 40px; right: 50px; height: 40px; }}

  .headline {{
    font-family: 'Playfair Display', serif;
    font-size: 64px;
    font-weight: 900;
    color: {COLORS["secondary"]};
    text-align: center;
    margin-bottom: 30px;
    padding: 0 60px;
    line-height: 1.1;
  }}

  .product-img {{
    max-width: 550px;
    max-height: 550px;
    object-fit: contain;
    filter: drop-shadow(0 16px 40px rgba(0,0,0,0.2));
    margin-bottom: 30px;
  }}

  .info-bar {{
    display: flex;
    gap: 20px;
    align-items: center;
  }}

  .info-chip {{
    background: {COLORS["secondary"]};
    color: white;
    padding: 10px 24px;
    border-radius: 30px;
    font-family: 'DM Sans', sans-serif;
    font-size: 18px;
    font-weight: 700;
  }}

  .info-chip.accent {{
    background: white;
    color: {COLORS["secondary"]};
    border: 2px solid {COLORS["secondary"]};
  }}

  .tagline {{
    position: absolute;
    bottom: 40px;
    font-family: 'DM Sans', sans-serif;
    font-size: 22px;
    color: {COLORS["secondary"]};
    opacity: 0.7;
  }}

  .badges {{
    display: flex;
    gap: 12px;
    margin-top: 20px;
  }}
  .badge-icon {{ width: 50px; height: 50px; }}
</style>
</head>
<body>
<div class="container">
  <img src="{logo}" class="logo" alt="MIRRA">
  <div class="headline">{headline}</div>
  <img src="{sku_img}" class="product-img">
  <div class="info-bar">
    <div class="info-chip">{sku['calories']} kcal</div>
    <div class="info-chip accent">RM{sku['price']}</div>
    <div class="info-chip">Nutritionist Designed</div>
  </div>
  <div class="badges">
    <img src="{badge_data_uri(BADGE_NUTRITIONIST)}" class="badge-icon">
    <img src="{badge_data_uri(BADGE_NO_MSG)}" class="badge-icon">
    <img src="{badge_data_uri(BADGE_PLANT)}" class="badge-icon">
  </div>
  <div class="tagline">{sku['name']}</div>
</div>
</body>
</html>'''


def grid_html(args) -> str:
    """Generate grid ad HTML (multiple products)."""
    skus = args.skus.split(",") if args.skus else list(SKU_CATALOG.keys())[:4]
    logo = img_to_data_uri(LOGO_PATH)
    headline = args.headline or "Pick Your Power Lunch"
    tagline = args.tagline or "Nutritionist-designed bentos from RM16"

    items_html = ""
    for sku_id in skus[:6]:
        sku_id = sku_id.strip()
        if sku_id not in SKU_CATALOG:
            continue
        sku = SKU_CATALOG[sku_id]
        img = img_to_data_uri(get_sku_image(sku_id, top_view=True))
        items_html += f'''
        <div class="grid-item">
            <img src="{img}" class="grid-img">
            <div class="grid-name">{sku["name"].split(" Bento")[0].split(" Konjac")[0]}</div>
            <div class="grid-info">{sku["calories"]} kcal · RM{sku["price"]}</div>
        </div>'''

    cols = min(len(skus), 3)
    return f'''<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  @import url('https://fonts.googleapis.com/css2?family=Playfair+Display:wght@400;700;900&family=DM+Sans:wght@400;500;700&display=swap');
  * {{ margin: 0; padding: 0; box-sizing: border-box; }}
  body {{ width: 1080px; height: 1080px; overflow: hidden; }}

  .container {{
    width: 1080px;
    height: 1080px;
    background: {COLORS["background"]};
    display: flex;
    flex-direction: column;
    position: relative;
  }}

  .logo {{ position: absolute; top: 30px; right: 40px; height: 36px; }}

  .headline {{
    font-family: 'Playfair Display', serif;
    font-size: 52px;
    font-weight: 900;
    color: {COLORS["secondary"]};
    text-align: center;
    padding: 50px 40px 20px;
  }}

  .grid {{
    display: grid;
    grid-template-columns: repeat({cols}, 1fr);
    gap: 20px;
    padding: 20px 40px;
    flex: 1;
    align-content: center;
  }}

  .grid-item {{
    background: white;
    border-radius: 16px;
    padding: 20px;
    text-align: center;
    box-shadow: 0 4px 16px rgba(0,0,0,0.06);
  }}

  .grid-img {{
    width: 100%;
    max-height: 240px;
    object-fit: contain;
    border-radius: 8px;
  }}

  .grid-name {{
    font-family: 'DM Sans', sans-serif;
    font-size: 18px;
    font-weight: 700;
    margin-top: 10px;
    color: {COLORS["secondary"]};
  }}

  .grid-info {{
    font-family: 'DM Sans', sans-serif;
    font-size: 15px;
    color: {COLORS["secondary"]};
    opacity: 0.6;
    margin-top: 4px;
  }}

  .tagline-bar {{
    text-align: center;
    padding: 24px;
    font-family: 'DM Sans', sans-serif;
    font-size: 22px;
    font-weight: 500;
    color: {COLORS["secondary"]};
    background: {COLORS["primary"]};
  }}

  .badges {{
    display: flex;
    justify-content: center;
    gap: 12px;
    padding: 10px 0;
    background: {COLORS["primary"]};
  }}
  .badge-icon {{ width: 45px; height: 45px; }}
</style>
</head>
<body>
<div class="container">
  <img src="{logo}" class="logo" alt="MIRRA">
  <div class="headline">{headline}</div>
  <div class="grid">{items_html}</div>
  <div class="badges">
    <img src="{badge_data_uri(BADGE_NUTRITIONIST)}" class="badge-icon">
    <img src="{badge_data_uri(BADGE_NO_MSG)}" class="badge-icon">
    <img src="{badge_data_uri(BADGE_PLANT)}" class="badge-icon">
  </div>
  <div class="tagline-bar">{tagline}</div>
</div>
</body>
</html>'''


def render_html_to_png(html: str, output_path: Path, width: int = 1080, height: int = 1080):
    """Render HTML to PNG using Playwright."""
    from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={"width": width, "height": height})
        page.set_content(html, wait_until="networkidle")
        # Wait for Google Fonts to load
        page.wait_for_timeout(2000)
        page.screenshot(path=str(output_path), full_page=False)
        browser.close()

    size_mb = output_path.stat().st_size / (1024 * 1024)
    print(f"Generated: {output_path} ({size_mb:.1f}MB)")
    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="MIRRA Ad Compositor — compose real brand assets into ad layouts"
    )
    sub = parser.add_subparsers(dest="command")

    # ── comparison ──
    p_comp = sub.add_parser("comparison", help="Split comparison ad (This vs That)")
    p_comp.add_argument("--sku", required=True, help="MIRRA product SKU ID")
    p_comp.add_argument("--headline", default=None)
    p_comp.add_argument("--competitor-label", default=None)
    p_comp.add_argument("--competitor-cal", type=int, default=None)
    p_comp.add_argument("--competitor-preset", default=None,
                        help="Preset: nasi-lemak, fried-rice, char-kway-teow, etc.")
    p_comp.add_argument("--tagline", default=None)
    p_comp.add_argument("--output", default=None)

    # ── hero ──
    p_hero = sub.add_parser("hero", help="Single product hero ad")
    p_hero.add_argument("--sku", required=True)
    p_hero.add_argument("--headline", default=None)
    p_hero.add_argument("--tagline", default=None)
    p_hero.add_argument("--output", default=None)

    # ── grid ──
    p_grid = sub.add_parser("grid", help="Multi-product grid ad")
    p_grid.add_argument("--skus", default=None, help="Comma-separated SKU IDs")
    p_grid.add_argument("--headline", default=None)
    p_grid.add_argument("--tagline", default=None)
    p_grid.add_argument("--output", default=None)

    # ── list-skus ──
    sub.add_parser("list-skus", help="List available product SKUs")

    # ── list-templates ──
    sub.add_parser("list-templates", help="List available ad templates")

    args = parser.parse_args()

    if args.command == "list-skus":
        print("Available MIRRA SKUs:")
        for k, v in SKU_CATALOG.items():
            status = "OK" if (SKU_DIR / v["file"]).exists() else "MISSING"
            print(f"  {k:20s} {v['name']:45s} {v['calories']}kcal  RM{v['price']}  [{status}]")
        return

    if args.command == "list-templates":
        print("Available templates:")
        print("  comparison   — Split 'This vs That' layout (competitor vs MIRRA)")
        print("  hero         — Single product showcase")
        print("  grid         — Multi-product grid (2-6 products)")
        return

    if not args.command:
        parser.print_help()
        return

    # Apply competitor preset if given
    if args.command == "comparison" and args.competitor_preset:
        preset = COMPETITOR_PRESETS.get(args.competitor_preset)
        if preset:
            if not args.competitor_label:
                args.competitor_label = preset["label"]
            if not args.competitor_cal:
                args.competitor_cal = preset["calories"]

    # Generate HTML
    if args.command == "comparison":
        html = comparison_html(args)
    elif args.command == "hero":
        html = hero_html(args)
    elif args.command == "grid":
        html = grid_html(args)
    else:
        parser.print_help()
        return

    # Output path
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    if args.output:
        out_path = Path(args.output)
    else:
        OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
        # Include SKU in filename to avoid collisions
        sku_tag = getattr(args, 'sku', '') or ''
        comp_tag = getattr(args, 'competitor_preset', '') or getattr(args, 'competitor_label', '') or ''
        if comp_tag:
            comp_tag = f"_vs_{comp_tag}"
        out_path = OUTPUT_DIR / f"{ts}_composed_{args.command}_{sku_tag}{comp_tag}.png"

    render_html_to_png(html, out_path)

    # Also save HTML for debugging
    html_path = out_path.with_suffix(".html")
    html_path.write_text(html)
    print(f"HTML source: {html_path}")


if __name__ == "__main__":
    main()
