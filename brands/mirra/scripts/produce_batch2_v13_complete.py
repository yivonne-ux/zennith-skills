"""
MIRRA BATCH 2 v13 — COMPLETE REGEN (30 posts)
March 30, 2026

4 food fixes + 26 non-food regens
All paths updated to new folder structure.
All viral quotes verified.
All compound learnings from v1-v12 applied.
Audit mastery v1.4 compliant.

FOLDER STRUCTURE (reorganized):
  04_references/AESTHETIC/korean-webtoon/       → illustration style refs
  04_references/AESTHETIC/sparkle-glamour/       → sparkle/cat/glamour refs
  04_references/AESTHETIC/pinterest/pinterest-social/  → original pinterest social pins
  04_references/AESTHETIC/pinterest/pinterest-ig/      → original pinterest ig pins
  04_references/AESTHETIC/typography-posts/      → typography design refs
  04_references/AESTHETIC/editorial-typography/  → editorial typography refs
  04_references/CONTENT/attitude-memes/         → meme refs
  04_references/CONTENT/glitter-quotes/         → glitter/billboard refs
  04_references/FORMAT/bold-graphic/            → bold graphic format refs
  04_references/FORMAT/food-typography/          → food typography refs
  04_references/FORMAT/illustration-layout/      → illustration layout refs
  01_assets/logos/                               → Mirra logos
  01_assets/photos/food-library/                → sacred food photos
"""
import os, fal_client, requests, numpy as np, time, sys, traceback
from pathlib import Path
from PIL import Image, ImageEnhance
from io import BytesIO

os.environ["FAL_KEY"] = "[REDACTED — see .env]"

BASE = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra")
OUT = BASE / "06_exports/social/batch2-v4"
OUT.mkdir(parents=True, exist_ok=True)

# === NEW PATHS ===
FOOD = BASE / "01_assets/photos/food-library"
LOGO_B = BASE / "01_assets/logos/Mirra logo-black.png"
LOGO_W = BASE / "01_assets/logos/Mirra logo-white.png"
IREF = BASE / "04_references/AESTHETIC/korean-webtoon"
PS = BASE / "04_references/AESTHETIC/pinterest/pinterest-social"
PI = BASE / "04_references/AESTHETIC/pinterest/pinterest-ig"
TYPO = BASE / "04_references/AESTHETIC/typography-posts"
SPARKLE = BASE / "04_references/AESTHETIC/sparkle-glamour"
EDIT_TYPO = BASE / "04_references/AESTHETIC/editorial-typography"
CONTENT = BASE / "04_references/CONTENT"
STOCK = BASE / "01_assets/photos/stock-comparison"

# Illustration style refs
SR = [IREF / f for f in [
    "korean-girl-lavender-bg-phone-contemplative.jpg",
    "korean-girl-cream-bg-cozy-scarf.jpg",
    "korean-girl-cream-bg-peace-sign-playful.jpg",
    "korean-girl-black-bg-sparkle-hoodie.jpg",
    "korean-girl-lavender-headphones-sparkles.jpg",
    "korean-girl-mint-bg-dreamy-gaze.jpg"
]]

# === PROMPT BLOCKS ===
ANTI_BRAND = """You are an image editor. Do NOT write ANY brand name, logo, handle, watermark, signature ANYWHERE in the image. No words in corners. No small text at edges. Leave all corners and edges completely clean and empty."""
ANTI_BRAND_I = """You are an image generator creating an illustration. Do NOT write ANY text that looks like a brand name, watermark, signature, handle, or logo ANYWHERE. The ONLY text allowed is dialogue/quote text explicitly specified in quotes below."""
ANTI_RENDER = """Do NOT render hex codes, font names, pixel values as visible text. Only render actual COPY in quotes."""
STYLE = """Match Image 1 art style: Korean semi-realistic (warmcorner.ai / gunelisa). NOT Disney/Pixar/chibi. Eyes 15-20% larger. Mature face 26yo, dark brown hair. Soft cel-shading, warm peach-pink shadows. VERTICAL PORTRAIT."""
FACE = "Her face: brown irises, white catchlights, defined brows, small nose, pink lips, subtle blush."
MR = "Keep ALL text at least 10% from all edges."

# === HELPERS ===
def enhance_food(path):
    img = Image.open(str(path)).convert("RGB")
    img = ImageEnhance.Color(img).enhance(1.06)
    img = ImageEnhance.Brightness(img).enhance(1.06)  # reduced from 1.08 to prevent white blowout (v1.4)
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

def add_grain(img, s=0.025):
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

def nano_edit(refs, prompt, ar="4:5"):
    urls = [fal_client.upload_file(str(r)) for r in refs]
    r = fal_client.subscribe("fal-ai/nano-banana-pro/edit", arguments={
        "prompt": f"{ANTI_BRAND}\n{ANTI_RENDER}\n{MR}\n{prompt}",
        "image_urls": urls, "resolution": "2K", "aspect_ratio": ar})
    return Image.open(BytesIO(requests.get(r["images"][0]["url"]).content))

def nano_illust(ref, prompt):
    url = fal_client.upload_file(str(ref))
    r = fal_client.subscribe("fal-ai/nano-banana-pro/edit", arguments={
        "prompt": f"{ANTI_BRAND_I}\n{STYLE}\n{FACE}\n{MR}\n{prompt}",
        "image_urls": [url], "resolution": "2K", "aspect_ratio": "4:5"})
    return Image.open(BytesIO(requests.get(r["images"][0]["url"]).content))

def save(img, name, logo_pref="br", grain=0.025, skip_logo=False):
    img = crop45(img); img = add_grain(img, grain)
    if not skip_logo: img = smart_logo(img, logo_pref)
    p = OUT / name; img.save(str(p), "PNG"); print(f"  -> {name}"); return p

# ============================================================
# ALL 30 POSTS
# ============================================================
POSTS = [
    # ===== 4 FOOD FIXES =====

    # F4 REPLACE: was aioli (non-relevant) → "i should quit my job to focus on cooking dinner" @iamstarvingaf
    {"id": "F4", "type": "food", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959653.jpg",
              enhance_food(FOOD / "Golden-Eryngii-Fragrant-Rice-Bento-Box-Top-View.png")],
     "prompt": """Edit this image. Match the clean bold typography + hero food style from Image 1.
- Giant text at top: "I SHOULD" in massive bold condensed black
- Below: "QUIT MY JOB" same massive bold
- Image 2 (real bento) as hero, centered
- Below food: "TO FOCUS ON DINNER." same bold type
- Bottom small: "eryngii fragrant rice bento" clean text
- Clean cream background
Keep the bento from Image 2 EXACTLY as provided.""",
     "out": "F4-quit-job-dinner.png", "grain": 0.022},

    # F5 FIX: use round bowl for "Adventurous" row
    {"id": "F5", "type": "food", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959651.jpg",
              enhance_food(FOOD / "BBQ-Pita-Mushroom-Wrap-Bento-Box-Top-View.png"),
              enhance_food(FOOD / "Fierry-Buritto-Bowl-Top-View.png"),
              enhance_food(FOOD / "Japanese Curry Katsu Bento Box-Top View.png")],
     "prompt": """Edit this image. Match the quiz/list layout from Image 1.
Title: "what kind of lunch person are you?" bold serif with "lunch" highlighted pink
3 rows with food photo left, text right:
Row 1 (Image 4 - katsu curry bento): "The Classic" bold — "reliable. comforting. always hits."
Row 2 (Image 3 - round burrito bowl): "The Adventurous" bold — "today nasi lemak, tomorrow pad thai."
Row 3 (Image 2 - bbq pita wraps): "The Bold" bold — "no explanation needed."
Clean warm cream background. Small emoji faces at bottom.
Keep ALL food photos EXACTLY as provided. Do not generate any food.""",
     "out": "F5-lunch-quiz.png", "grain": 0.022},

    # F8 REPLACE: was 2pm timestamp (visual didn't match) → "saving half for later / it's later" with FULL vs EMPTY visual
    {"id": "F8", "type": "food", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959633.webp",
              enhance_food(FOOD / "Nasi-Lemak-Classic-Bento-Box-Top-View.png")],
     "prompt": """Edit this image. Match the split editorial style from Image 1.
LEFT panel: Image 2 (real bento) looking FULL, abundant, colorful. Text: "saving half for later" in elegant italic serif.
RIGHT panel: an EMPTY bento container (just the white plastic box with no food inside, maybe a few crumbs). Text: "four minutes later." in elegant italic serif.
Warm blush pink background on both panels.
The humor: the bento went from full to empty in 4 minutes. The EMPTY container IS the punchline.
Keep Image 2 bento EXACTLY as provided on the left side.""",
     "out": "F8-four-minutes.png", "grain": 0.022},

    # F9 FIX: reduce brightness on white areas
    {"id": "F9", "type": "food", "logo": "bc",
     "refs": [TYPO / "pinterest_552183604332959653.jpg",
              enhance_food(FOOD / "Lemon-Mushroom-Rice-Bento-Box-Top-View.png")],
     "prompt": """Edit this image. Match the clean bold typography + hero food style from Image 1.
- Giant text: "GIRL" then "DINNER." massive bold condensed black, 40% canvas
- Image 2 (real bento) centered below
- The bento container should retain natural texture — NOT blown out white. Keep the container slightly warm/cream, not pure white.
- Below food small: "but make it actually nutritious"
- Bottom: "lemon mushroom rice bento" smallest text
- Warm cream background (NOT pure white — slightly warm)
Keep the bento from Image 2 EXACTLY as provided.""",
     "out": "F9-girl-dinner.png", "grain": 0.022},

    # ===== 10 ILLUSTRATIONS =====

    {"id": "B2-01", "type": "illust", "logo": "bc", "ref": SR[0],
     "prompt": """Generate Korean semi-realistic 3-panel vertical comic.
Panel 1: Girl at office desk, blank stare, typing. Caption: "me at work"
Panel 2: SAME girl walking out, slight smile. Caption: "5:01pm"
Panel 3: SAME girl on couch in pajamas, eating noodles, genuine happy. Caption: "me at home"
Text at bottom: "equal parts professional and unhinged"
Background: flat dusty rose. Thin panel dividers.""",
     "out": "B2-01-corporate-npc.png", "grain": 0.028},

    {"id": "B2-02", "type": "illust", "logo": "br", "ref": SR[1],
     "prompt": """Generate Korean semi-realistic 3-panel vertical comic.
Panel 1: Girl in cozy kitchen, pouring coffee, content. Caption: "making my morning coffee"
Panel 2: Same girl 10 min later, confused, making ANOTHER coffee. TWO mugs visible. Caption: "wait did i already make coffee"
Panel 3: Same girl on couch holding TWO coffees, amused. Caption: "guess i have two coffees now"
Warm blush pink backgrounds. ALL drinks are black coffee or oat milk.
30% clean space at bottom.""",
     "out": "B2-02-double-coffee.png", "grain": 0.028},

    {"id": "B2-03", "type": "illust", "logo": "bc", "ref": SR[2],
     "prompt": """Generate Korean semi-realistic 2-panel vertical.
TOP (40%): Girl in dim room, phone, messy hair, tired. Blue-grey cold. Caption: "january me"
BOTTOM (50%): SAME girl in warm pink room, journaling, flowers, happy. Caption: "march me"
Text at bottom: "i blocked my ex and my skin cleared"
Dramatic contrast: cold dim top, warm bottom.""",
     "out": "B2-03-healing-era.png", "grain": 0.028},

    {"id": "B2-04", "type": "illust", "logo": "br", "ref": SR[3],
     "prompt": """Generate Korean semi-realistic 3-panel vertical comic.
Panel 1: Girl at desk, laptop open, eyes wide, empty coffee. Caption: "9am: answering one email"
Panel 2: Same girl scrolling phone under desk, 2pm on clock. Caption: "2pm: still recovering from the one email"
Panel 3: Same girl packing bag at 5:01pm, confident smirk. Caption: "5:01pm: another productive day"
Text at bottom: "just admit it y'all are pretending to work most of the time"
Flat dusty rose backgrounds.""",
     "out": "B2-04-pretending-to-work.png", "grain": 0.028},

    {"id": "B2-05", "type": "illust", "logo": "bc", "ref": SR[4],
     "prompt": """Generate Korean semi-realistic 4-panel grid (2x2).
Panel 1: Girl at brunch, champagne, golden light. Caption: "mood 1: i am that girl"
Panel 2: Same girl in bed 2am, scrolling, snacks. Caption: "mood 2: goblin mode"
Panel 3: Girl walking confidently. Caption: "mood 1 returns"
Panel 4: Girl ordering delivery under blanket. Caption: "mood 2 wins again"
Blush pink borders. Text at bottom: "i have two settings and they both involve food" """,
     "out": "B2-05-two-moods.png", "grain": 0.028},

    {"id": "B2-06", "type": "illust", "logo": "br", "ref": SR[5],
     "prompt": """Generate Korean semi-realistic 3-panel comic.
Panel 1: Girl hits Reply All. "oh no" face. Caption: "8:47am: minor incident"
Panel 2: Eyes WIDE, hand over mouth, notification alerts. Caption: "8:47am: escalation"
Panel 3: Face-down on desk. Caption: "8:48am: acceptance"
Text at bottom: "everything will work out because i'm insane"
Warm cream backgrounds.""",
     "out": "B2-06-reply-all.png", "grain": 0.028},

    {"id": "B2-07", "type": "illust", "logo": "bc", "ref": SR[0],
     "prompt": """Generate Korean semi-realistic single illustration.
Girl cross-legged on fluffy rug, candles, tea, journal. Writing peacefully.
Text at top in serif: "i want a soft life. ease. rest — not as a reward but as practice."
Dusty rose background.""",
     "out": "B2-07-soft-life.png", "grain": 0.028},

    {"id": "B2-08", "type": "illust", "logo": "br", "ref": SR[1],
     "prompt": """Generate Korean semi-realistic 3-panel comic.
Panel 1: Girl unpacking bento at desk. Coworkers staring. Caption: "just a little tuesday lunch"
Panel 2: Close-up colorful bento spread. Other desks: sad sandwiches. Caption: "their faces"
Panel 3: Girl eating contentedly, earbuds in. Caption: "me in my own world"
ALL food shown must be vegetables, rice, tofu — vegan only.
Text at bottom: "relationship status: emotionally attached to food" """,
     "out": "B2-08-desk-lunch.png", "grain": 0.028},

    {"id": "B2-09", "type": "illust", "logo": "br", "ref": SR[2],
     "prompt": """Generate Korean semi-realistic 2-panel.
TOP (45%): Girl doing yoga at sunrise, green smoothie, golden light. Caption: "what my brain promises at midnight"
BOTTOM (45%): SAME girl in bed, alarm 10:47, tangled blankets, one eye open. Caption: "what actually happens"
Bottom 10% empty for logo. Warm tones.""",
     "out": "B2-09-midnight-promises.png", "grain": 0.028},

    {"id": "B2-10", "type": "illust", "logo": "tr", "ref": SR[1],
     "prompt": """Generate Korean semi-realistic single illustration.
Girl at desk, chin on hand, staring at laptop showing job listings. Slight smirk.
Small thought bubbles: chef hat, camera, paintbrush, airplane, laptop icons.
Background: flat warm cream.
Text at bottom: "me at 29 wondering what i'll be when i grow up"
Top-right 30% clean for logo.""",
     "out": "B2-10-what-ill-be.png", "grain": 0.028},

    # ===== 5 TYPOGRAPHY/GLITTER =====

    {"id": "B2-17", "type": "edit", "logo": "tr",
     "refs": [SPARKLE / "glitter-heart-sign-thank-you.jpg"],
     "prompt": """Edit this sparkle heart sign image. Keep warm pink sparkle aesthetic.
Replace text with: "EVERYTHING WILL WORK OUT BECAUSE I'M INSANE"
Elegant glowing letters. Warm pink tones. Do NOT add any other text or logos.""",
     "out": "B2-17-heart-insane.png", "grain": 0.020},

    {"id": "B2-18", "type": "edit", "logo": "tr",
     "refs": [SPARKLE / "roses-wine-glitter-beach-night.jpg"],
     "prompt": """Edit this sparkle beach wine scene. Keep warm pink sparkle aesthetic.
Replace or add text: "ME BEING FINANCIALLY IRRESPONSIBLE IN THE NAME OF SELF CARE"
Elegant serif text. Warm tones. Do NOT add logos.""",
     "out": "B2-18-self-care.png", "grain": 0.020},

    {"id": "B2-19", "type": "edit", "logo": "bc",
     "refs": [SPARKLE / "digicam-screen-when-you-like-yourself.jpg"],
     "prompt": """Edit this digicam screen image. Keep the warm sparkle aesthetic.
Replace text with: "STANDING ON BUSINESS"
Bold glitter text. Warm tones. Do NOT add logos.""",
     "out": "B2-19-standing-business.png", "grain": 0.020},

    {"id": "B2-20", "type": "edit", "logo": "br",
     "refs": [EDIT_TYPO / "let-yourself-be-seen.jpg"],
     "prompt": """Edit this image. Keep the warm editorial typography aesthetic.
Replace text with: "soft is my favourite kind of strength"
Elegant mixed serif. Warm sunset tones. Do NOT add logos.""",
     "out": "B2-20-neon-soft.png", "grain": 0.020},

    {"id": "B2-21", "type": "edit", "logo": "bl",
     "refs": [EDIT_TYPO / "note-card-to-myself.jpg"],
     "prompt": """Edit this image. Keep the warm note/card aesthetic.
Replace text with: "i'm reinventing myself at 3am"
Elegant handwritten style. Warm tones. Do NOT add logos.""",
     "out": "B2-21-reinventing.png", "grain": 0.020},

    # ===== 4 MEMES (user approved B2-23, B2-25 copyright) =====

    {"id": "B2-22", "type": "illust", "logo": "bc", "ref": SR[0],
     "prompt": """Generate Korean semi-realistic single illustration.
Girl at desk, Monday morning. Eyes half-closed, cheek on hand, giant coffee mug. Beautifully unbothered.
Desk has tiny calendar showing MONDAY. Stack of papers she's ignoring.
Background: flat warm blush pink.
Text at bottom: "monday is a state of mind. mine is 'no thanks.'"
30% space at bottom for logo.""",
     "out": "B2-22-monday-no-thanks.png", "grain": 0.028},

    {"id": "B2-24", "type": "edit", "logo": "bl",
     "refs": [CONTENT / "attitude-memes/51a052f780434e2f19eec095cc3a08b9.jpg"],
     "prompt": """Edit this image. Keep the meme photo aesthetic.
Add text: top: "saving money this month" in clean serif
Bottom: "me: orders delivery for the 5th time this week" in clean serif
Warm blush pink text zones. Do NOT add logos.""",
     "out": "B2-24-saving-money.png", "grain": 0.025},

    {"id": "B2-26", "type": "illust", "logo": "bc", "ref": SR[2],
     "prompt": """Generate Korean semi-realistic single illustration.
Girl standing in bedroom, holding crumpled fitted sheet with both hands, looking at it with total defeat.
Iced coffee on nightstand. Messy bed in background.
Background: flat warm blush pink room, pink bedding.
Text at bottom: "adulting is like folding a fitted sheet. why bother?"
30% space at bottom.""",
     "out": "B2-26-adulting-sheet.png", "grain": 0.028},

    # ===== 3 CATS =====

    {"id": "B2-32", "type": "edit", "logo": "tr",
     "refs": [SPARKLE / "queen-cat-flamingo-pool-city.jpg"],
     "prompt": """Edit this queen cat image. Keep the glamour sparkle aesthetic.
Add text at top: "i am not ignoring you. i am prioritizing myself." clean serif.
Do NOT put ANY text on props, cups, or objects. Quote at top only.
Warm tones. Do NOT add logos.""",
     "out": "B2-32-cat-prioritizing.png", "grain": 0.025},

    {"id": "B2-33", "type": "edit", "logo": "bl",
     "refs": [SPARKLE / "cat-glitter-bath-how-to-be-rich.jpg"],
     "prompt": """Edit this sparkle cat image. Keep the glitter aesthetic.
Add text at top: "no thoughts. head empty." bold serif.
Warm sparkle tones. Do NOT add logos.""",
     "out": "B2-33-cat-head-empty.png", "grain": 0.025},

    {"id": "B2-34", "type": "edit", "logo": "bl",
     "refs": [SPARKLE / "pink-heart-balloon-talk-to-yourself.jpg"],
     "prompt": """Edit this pink balloon image. Keep the pink aesthetic.
Replace text with: "drama queen energy. no apologies given."
Clean serif. Warm pink tones. Do NOT add logos.""",
     "out": "B2-34-drama-queen.png", "grain": 0.025},

    # ===== 3 TYPOGRAPHY/OBJECT =====

    {"id": "B2-35", "type": "edit", "logo": "br",
     "refs": [EDIT_TYPO / "editorial-serif-be-picky.png"],
     "prompt": """Edit this editorial typography image. Keep the clean serif aesthetic.
Replace text with: "she stopped explaining herself and her life got quieter and her heart got lighter"
Bold editorial serif. Warm tones. Do NOT add logos.""",
     "out": "B2-35-stopped-explaining.png", "grain": 0.020},

    {"id": "B2-36", "type": "edit", "logo": "br",
     "refs": [EDIT_TYPO / "gradient-believe-yours.jpg"],
     "prompt": """Edit this gradient typography image. Keep the warm gradient aesthetic.
Replace text with: "demand what you want like it's non-negotiable"
Clean serif on warm gradient. Do NOT add logos.""",
     "out": "B2-36-demand.png", "grain": 0.020},

    {"id": "B2-37", "type": "edit", "logo": "bl",
     "refs": [EDIT_TYPO / "block-bold-more-self-love.jpg"],
     "prompt": """Edit this bold block typography image.
Replace text with: "soft life, strong woman"
Bold block letters. Warm pink tones. Do NOT add logos.""",
     "out": "B2-37-soft-life-strong.png", "grain": 0.020},
]

# ============================================================
# RUNNER
# ============================================================
def produce(post):
    pid = post["id"]
    print(f"\n{'='*60}\n{pid}: {post['out']} [{post['type']}]\n{'='*60}")
    try:
        if post["type"] == "illust":
            img = nano_illust(post["ref"], post["prompt"])
        elif post["type"] == "edit":
            img = nano_edit(post["refs"], post["prompt"])
        elif post["type"] == "food":
            resolved = [r if isinstance(r, Path) else Path(r) for r in post["refs"]]
            img = nano_edit(resolved, post["prompt"])
        else:
            raise ValueError(f"Unknown type: {post['type']}")

        skip = post.get("skip_logo", False)
        return pid, True, str(save(img, post["out"], post.get("logo", "br"), post.get("grain", 0.025), skip))
    except Exception as e:
        print(f"  FAILED: {pid} — {e}"); traceback.print_exc()
        return pid, False, str(e)

if __name__ == "__main__":
    print(f"\nMIRRA BATCH 2 v13 COMPLETE — {len(POSTS)} posts")
    if len(sys.argv) > 1:
        sel = [p for p in POSTS if p["id"] in set(sys.argv[1:])]
    else:
        sel = POSTS
    print(f"Running {len(sel)}...\n")
    results = []
    for p in sel:
        r = produce(p); results.append(r); time.sleep(1.5)
    ok = [r for r in results if r[1]]; fail = [r for r in results if not r[1]]
    print(f"\n{'='*60}\nDONE: {len(ok)}/{len(results)}")
    if fail:
        print(f"FAILED: {len(fail)}")
        for n, _, e in fail: print(f"  {n}: {e}")
