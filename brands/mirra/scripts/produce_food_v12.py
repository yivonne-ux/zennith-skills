"""
MIRRA FOOD POSTS v12 — TYPE-DRIVEN DESIGN MASTERY + VERIFIED VIRAL
March 30, 2026

VERIFIED through full pipeline:
  1. Scraped 75 refs → multi-perspective audit (5 personas) → 7 curated
  2. Autonomous research verified all viral claims → 4 replaced with sourced quotes
  3. gstack review passed all Gate 3 pre-flight checks
  4. Zero lifestyle compositing (proven failure mode)
  5. Zero "plant-based" in copy
  6. Zero unverified calorie numbers
  7. All type-driven: massive typography + food on simple bg
"""
import os, fal_client, requests, numpy as np, time, sys, traceback
from pathlib import Path
from PIL import Image, ImageEnhance
from io import BytesIO

os.environ["FAL_KEY"] = "[REDACTED — see .env]"

BASE = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra")
OUT = BASE / "06_exports/social/batch2-v4"
FOOD = BASE / "01_assets/photos/food-library"
STOCK = BASE / "01_assets/photos/stock-comparison"
LOGO_B = BASE / "01_assets/logos/Mirra logo-black.png"
LOGO_W = BASE / "01_assets/logos/Mirra logo-white.png"
TYPO = BASE / "04_references/AESTHETIC/typography-posts"

ANTI_BRAND = """You are an image editor. Do NOT write ANY brand name, logo, handle, watermark, signature ANYWHERE in the image. No words in corners. No small text at edges. Leave all corners and edges completely clean and empty."""
ANTI_RENDER = """Do NOT render hex codes, font names, pixel values as visible text. Only render actual COPY in quotes."""
MR = "Keep ALL text at least 10% from all edges."

def enhance_food_editorial(path):
    img = Image.open(str(path)).convert("RGB")
    img = ImageEnhance.Color(img).enhance(1.06)
    img = ImageEnhance.Brightness(img).enhance(1.08)
    img = ImageEnhance.Contrast(img).enhance(1.10)
    img = ImageEnhance.Sharpness(img).enhance(1.20)
    img = ImageEnhance.Color(img).enhance(0.95)
    r, g, b = img.split()
    r = r.point(lambda p: min(255, int(p * 1.04)))
    b = b.point(lambda p: int(p * 0.97))
    img = Image.merge("RGB", (r, g, b))
    p = Path(f"/tmp/film_{Path(path).stem}.png")
    img.save(str(p), "PNG"); return p

def crop45(img):
    w, h = img.size; t = 4 / 5
    if w / h > t:
        nw = int(h * t); l = (w - nw) // 2; img = img.crop((l, 0, l + nw, h))
    else:
        nh = int(w / t); top = max(0, h - nh - int(nh * 0.05)); img = img.crop((0, top, w, top + nh))
    return img.resize((1080, 1350), Image.LANCZOS)

def add_grain(img, s=0.022):
    a = np.array(img, dtype=np.float32)
    return Image.fromarray(np.clip(a + np.random.normal(0, s * 255, a.shape), 0, 255).astype(np.uint8))

def smart_logo(img, pref="br"):
    arr = np.array(img); h, w = arr.shape[:2]
    zones = {"br": (int(w*.70), int(h*.88), int(w*.97), int(h*.98)),
             "bl": (int(w*.03), int(h*.88), int(w*.30), int(h*.98)),
             "bc": (int(w*.35), int(h*.93), int(w*.65), int(h*.99)),
             "tr": (int(w*.70), int(h*.02), int(w*.97), int(h*.08))}
    scores, lums = {}, {}
    for n, (x1, y1, x2, y2) in zones.items():
        r = arr[y1:y2, x1:x2]
        if r.size == 0: scores[n] = 999; lums[n] = 128; continue
        g = np.mean(r, axis=2)
        scores[n] = np.mean(np.abs(np.diff(g, axis=1))) + np.mean(np.abs(np.diff(g, axis=0))) + np.std(r) / 10
        lums[n] = np.mean(r)
    preferred = [pref] + [z for z in ["br", "bl", "bc", "tr"] if z != pref]
    best = min(preferred, key=lambda z: scores.get(z, 999)); lum = lums[best]
    logo = Image.open(str(LOGO_B if lum > 130 else LOGO_W)).convert("RGBA")
    bb = logo.getbbox()
    if bb: logo = logo.crop(bb)
    logo = logo.resize((110, int(logo.height * (110 / logo.width))), Image.LANCZOS)
    a = logo.split()[3]; a = a.point(lambda p: int(p * 0.9)); logo.putalpha(a)
    m = 35
    pos = {"br": (w - logo.width - m, h - logo.height - m), "bl": (m, h - logo.height - m),
           "bc": ((w - logo.width) // 2, h - logo.height - 25), "tr": (w - logo.width - m, m)}
    c = img.convert("RGBA"); c.paste(logo, pos.get(best, pos["br"]), logo)
    return c.convert("RGB")

def nano(prompt, refs, ar="4:5"):
    urls = [fal_client.upload_file(str(r)) for r in refs]
    r = fal_client.subscribe("fal-ai/nano-banana-pro/edit", arguments={
        "prompt": f"{ANTI_BRAND}\n{ANTI_RENDER}\n{MR}\n{prompt}",
        "image_urls": urls, "resolution": "2K", "aspect_ratio": ar})
    return Image.open(BytesIO(requests.get(r["images"][0]["url"]).content))

def save(img, name, logo_pref="br"):
    img = crop45(img); img = add_grain(img); img = smart_logo(img, logo_pref)
    p = OUT / name; img.save(str(p), "PNG"); print(f"  -> {name}"); return p

# ============================================================
# 7 FOOD POSTS — TYPE-DRIVEN, VERIFIED VIRAL
# ============================================================
POSTS = [
    # F2: "NASI." massive slab — CIAO! style
    # Viral: @DaddyJew "future plans: lunch"
    {"id": "F2", "logo": "bl",
     "refs": [TYPO / "pinterest_552183604332959629.jpg",
              enhance_food_editorial(FOOD / "Nasi-Lemak-Classic-Bento-Box-Top-View.png")],
     "prompt": """Edit this image. Match the design style from Image 1 — MASSIVE bold slab-serif typography repeated as wallpaper behind food, with food layered in front.
Create a food poster:
- Giant text "NASI." repeated 3 times vertically, filling 80% canvas, bold warm-toned slab serif
- Image 2 is the real bento — place it centered, overlapping the giant text (food IN FRONT of letters)
- Warm terracotta/coral monochrome background (NOT yellow — warm coral pink)
- Small text at bottom: "future plans? lunch." in clean sans
- The typography IS the design — bold, confident, editorial
Keep the food from Image 2 EXACTLY as provided. Do not modify the food.""",
     "out": "F2-nasi-poster.png"},

    # F4: "AIOLI." bold type — No Sugar style adapted
    # Viral: @iamstarvingaf "aioli is just mayo that studied abroad"
    {"id": "F4", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959653.jpg",
              enhance_food_editorial(FOOD / "Golden-Eryngii-Fragrant-Rice-Bento-Box-Top-View.png")],
     "prompt": """Edit this image. Match the clean bold typography + hero food style from Image 1 — massive condensed bold text with a single food item as hero.
Design:
- Giant text at top: "AIOLI IS JUST" in massive bold condensed black type
- Below: Image 2 (the real bento) as the hero, centered
- Below food: "MAYO THAT STUDIED ABROAD." in same massive bold type
- Very bottom: "eryngii fragrant rice bento" in small clean text
- Clean cream/off-white background
- The BOLD TYPE + SINGLE FOOD HERO is the entire design
Keep the bento from Image 2 EXACTLY as provided.""",
     "out": "F4-aioli-poster.png"},

    # F5: Lunch quiz — FORMAT from Toast pin, SACRED food photos only
    # Interactive engagement format
    {"id": "F5", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959651.jpg",
              enhance_food_editorial(FOOD / "BBQ-Pita-Mushroom-Wrap-Bento-Box-Top-View.png"),
              enhance_food_editorial(FOOD / "Nasi-Lemak-Classic-Bento-Box-Top-View.png"),
              enhance_food_editorial(FOOD / "Japanese Curry Katsu Bento Box-Top View.png")],
     "prompt": """Edit this image. Match the quiz/list layout from Image 1 — clean background with food items as personality types.
Create an interactive quiz post:
Title: "what kind of lunch person are you?" in bold serif with "lunch" highlighted in warm pink
Then 3 rows, each with a food photo from Images 2-4 on the left and text on the right:
Row 1 (Image 4 - katsu curry): "The Classic" in bold — "reliable. comforting. always a good choice."
Row 2 (Image 3 - nasi lemak): "The Adventurous" in bold — "today nasi lemak, tomorrow pad thai."
Row 3 (Image 2 - bbq pita wraps): "The Bold" in bold — "no explanation needed."
Clean warm cream background. Small emoji faces at bottom.
Keep ALL food photos EXACTLY as provided. Do not generate any food.""",
     "out": "F5-lunch-quiz.png"},

    # F6: "i eat a little vs i eat a lot" split — Smooth/Creamy style
    # DOUBLE VALIDATED: TikTok active + Mirra batch 1 proven
    {"id": "F6", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959633.webp",
              enhance_food_editorial(FOOD / "Fusilli-Bolognese-Bento-Box-Top-View.png")],
     "prompt": """Edit this image. Match the split editorial design from Image 1 — two panels with elegant serif typography.
LEFT panel: muted grey-blue tone. Show a small sad portion — a plain sandwich and a small drink. Text in elegant serif: "i eat a little"
RIGHT panel: warm blush pink tone. Image 2 is the real Mirra bento — generous, colorful, abundant. Text: "i eat a lot"
MASSIVE text spanning BOTH panels at bottom: "same calories." in giant elegant serif
The visual contrast IS the message: tiny portion left vs abundant bento right = same energy, different volume.
Keep the bento from Image 2 EXACTLY as provided.
The left side food can be generated — just a simple sandwich. The RIGHT side bento must be sacred.""",
     "out": "F6-eat-little-lot.png"},

    # F8: "2:00pm / 2:04pm" bento time — JOIN THE CLUB style bold type
    # Viral: @dfarella timestamp format, adapted to bento
    {"id": "F8", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959645.jpg",
              enhance_food_editorial(FOOD / "Nasi-Lemak-Classic-Bento-Box-Top-View.png"),
              enhance_food_editorial(FOOD / "Konjac-Pad-Thai-Bento-Box-Top-View.png")],
     "prompt": """Edit this image. Match the bold condensed type-over-food style from Image 1 — massive bold text layered over food imagery.
Design with two bentos side by side (Images 2 and 3):
LEFT bento: text above "2:00pm" in bold condensed, below: "saving half for later"
RIGHT bento: text above "2:04pm" in bold condensed, below: "it's later."
The bentos sit side by side on a warm blush pink background.
Title at top could say "THIS OR THAT" or simply let the timestamps tell the story.
Warm pink background. Bold condensed type in dark brown or black.
Keep BOTH food photos EXACTLY as provided.""",
     "out": "F8-two-pm.png"},

    # F9: "GIRL DINNER." massive type — No Sugar style (BEST ref 9.4/10)
    # Viral: #girldinner mega-viral format, @liviemaher origin
    {"id": "F9", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959653.jpg",
              enhance_food_editorial(FOOD / "Lemon-Mushroom-Rice-Bento-Box-Top-View.png")],
     "prompt": """Edit this image. Match the clean bold typography + hero food style from Image 1 — massive condensed bold text at top, single food item centered below.
Design:
- Giant text at top: "GIRL" in massive bold condensed black type, taking 25% of canvas
- Next line: "DINNER." in same massive bold type
- Below: Image 2 (the real bento) as the hero, centered and prominent
- Below food small text: "but make it actually nutritious"
- Very bottom: "lemon mushroom rice bento" in smallest clean text
- Clean cream/off-white background
- Minimal, bold, editorial — the type and food carry everything
Keep the bento from Image 2 EXACTLY as provided.""",
     "out": "F9-girl-dinner.png"},

    # F11: bold condensed on warm bg — Bread Peak style adapted
    # Viral: @iamstarvingaf "whatever happen calorically this weekend"
    {"id": "F11", "logo": "bl",
     "refs": [TYPO / "pinterest_552183604332959636.jpg",
              enhance_food_editorial(FOOD / "Dry-Classic-Curry-Konjac-Noodle-Top-View.png")],
     "prompt": """Edit this image. Match the bold condensed conceptual poster design from Image 1 — massive white condensed type on bold colored background with food as hero.
Design:
- Bold warm salmon/coral background (NOT blue — warm pink-coral)
- Giant bold condensed WHITE text at top-right: "WHATEVER HAPPEN CALORICALLY THIS WEEKEND"
- Image 2 (the real bento) placed center-left, the food hero
- Small text at bottom-left: "can never happen again." in small white
- Then: "dry classic curry konjac noodle bento" in smallest text
- The bold color + massive white type + food hero = the entire design
Keep the bento from Image 2 EXACTLY as provided.""",
     "out": "F11-calorically.png"},
]

def produce(post):
    pid = post["id"]
    print(f"\n{'='*60}\n{pid}: {post['out']}\n{'='*60}")
    try:
        resolved = [r if isinstance(r, Path) else Path(r) for r in post["refs"]]
        img = nano(post["prompt"], resolved)
        return pid, True, str(save(img, post["out"], post.get("logo", "br")))
    except Exception as e:
        print(f"  FAILED: {pid} — {e}"); traceback.print_exc()
        return pid, False, str(e)

if __name__ == "__main__":
    print(f"\nMIRRA FOOD v12 — {len(POSTS)} posts (type-driven + verified viral)")
    sel = [p for p in POSTS if p["id"] in set(sys.argv[1:])] if len(sys.argv) > 1 else POSTS
    print(f"Running {len(sel)}...\n")
    results = []
    for p in sel:
        r = produce(p); results.append(r); time.sleep(2)
    ok = [r for r in results if r[1]]; fail = [r for r in results if not r[1]]
    print(f"\n{'='*60}\nDONE: {len(ok)}/{len(results)}")
    if fail:
        for n, _, e in fail: print(f"  FAIL: {n}: {e}")
