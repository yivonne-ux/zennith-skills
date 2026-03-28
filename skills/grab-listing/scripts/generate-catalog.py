#!/usr/bin/env python3
"""Full catalog generation — foodporn quality + visual audit gate.

Generates all 50 photos (34 Uncle Chua + 16 Choon) with:
- Foodporn-level Gemini regeneration
- Per-photo quality audit against approved baseline
- Auto-flag failures for re-generation
"""
import base64, io, time, os, json
from pathlib import Path
import httpx
from PIL import Image, ImageEnhance, ImageStat, ImageFilter, ImageDraw

# ── GEMINI ──
GEMINI_KEY = ""
for f in [Path.home() / ".openclaw" / "secrets" / "gemini.env"]:
    if f.exists():
        for line in f.read_text().splitlines():
            if line.startswith("GEMINI_API_KEY="): GEMINI_KEY = line.split("=",1)[1].strip()

URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={GEMINI_KEY}"

# ── QUALITY THRESHOLDS (from approved reference shots) ──
QA = {
    "brightness_min": 180,
    "sharpness_min": 200,
    "bg_brightness_min": 210,
}

# ── THE PROMPT (approved foodporn standard) ──
FOODPORN_PROMPT = """You are a world-class food photographer creating images for a premium food delivery app.

Look at this reference dish. Now REGENERATE it as the most MOUTH-WATERING, DELICIOUS-LOOKING food photography you can create.

MAKE THE FOOD LOOK INCREDIBLE:
- Sauce should be THICK, GLOSSY, and GLISTENING — catching the light with an oil sheen
- Prawns should be PLUMP, JUICY, bright coral-pink with a wet glistening sheen
- Noodles should look PERFECTLY COOKED — silky, glossy, each strand visible
- Vegetables should be CRISP and DEWY — like just picked, with tiny water droplets
- Fried items should be GOLDEN CRISPY with visible oil sheen — you can almost hear the crunch
- Egg yolk should be RICH GOLDEN — creamy and inviting
- Steam should be rising gently — the food is HOT and FRESH
- Every surface should have a subtle WET SHEEN — the food looks JUICY and MOIST

PHOTOGRAPHY SETUP:
- Clean modern white ceramic bowl/plate (no patterns, minimal, elegant)
- Pure white seamless background
- 45-degree angle, centered, filling 70% of frame
- Bright soft key light from upper-left with fill light
- Beautiful soft shadow underneath
- SHARP FOCUS everywhere — f/8, everything crisp, no blur
- Warm color temperature — slightly golden

FOR DRINKS: Use clean clear glass on white background, same 45-degree angle, condensation visible if cold.

THE FOOD MUST LOOK SO DELICIOUS THAT ANYONE WHO SEES THIS PHOTO WILL IMMEDIATELY WANT TO ORDER IT.

Think: Michelin restaurant menu photography meets GrabFood hero banner."""


def smart_crop(img, size=(800,800)):
    tw, th = size; tr = tw/th; iw, ih = img.size; ir = iw/ih
    if ir > tr: nw = int(ih*tr); l = (iw-nw)//2; img = img.crop((l,0,l+nw,ih))
    elif ir < tr: nh = int(iw/tr); t = (ih-nh)//2; img = img.crop((0,t,iw,t+nh))
    return img.resize(size, Image.LANCZOS)


def quality_audit(img_path):
    """Check if generated photo meets quality baseline. Returns (pass, details)."""
    img = Image.open(img_path).convert("RGB")
    stat = ImageStat.Stat(img)
    avg_r, avg_g, avg_b = [int(x) for x in stat.mean]
    brightness = 0.299 * avg_r + 0.587 * avg_g + 0.114 * avg_b

    gray = img.convert("L")
    edges = gray.filter(ImageFilter.FIND_EDGES)
    sharpness = ImageStat.Stat(edges).var[0]

    w, h = img.size
    corners = [img.getpixel((10,10)), img.getpixel((w-10,10)), img.getpixel((10,h-10)), img.getpixel((w-10,h-10))]
    bg_brightness = sum(sum(c) for c in corners) / (4 * 3)

    issues = []
    if brightness < QA["brightness_min"]:
        issues.append(f"TOO DARK (bright={brightness:.0f}, need>{QA['brightness_min']})")
    if sharpness < QA["sharpness_min"]:
        issues.append(f"TOO BLURRY (sharp={sharpness:.0f}, need>{QA['sharpness_min']})")
    if bg_brightness < QA["bg_brightness_min"]:
        issues.append(f"BG NOT WHITE (bg={bg_brightness:.0f}, need>{QA['bg_brightness_min']})")

    passed = len(issues) == 0
    detail = f"bright={brightness:.0f} sharp={sharpness:.0f} bg={bg_brightness:.0f}"
    return passed, detail, issues


def generate_one(src_path, out_path, dish_desc, max_retries=2):
    """Generate one photo with quality gate + retry."""
    for attempt in range(1, max_retries + 1):
        img = Image.open(src_path).convert("RGB")
        if max(img.size) > 1024:
            r = 1024/max(img.size); img = img.resize((int(img.size[0]*r), int(img.size[1]*r)), Image.LANCZOS)
        buf = io.BytesIO(); img.save(buf, "JPEG", quality=90)
        b64 = base64.b64encode(buf.getvalue()).decode()

        prompt = f"Reference dish: {dish_desc}\n\n{FOODPORN_PROMPT}"

        try:
            resp = httpx.post(URL, json={
                "contents": [{"parts": [
                    {"text": prompt},
                    {"inline_data": {"mime_type": "image/jpeg", "data": b64}}
                ]}],
                "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]},
            }, timeout=120)

            if resp.status_code == 429:
                print(f"    RATE LIMITED — waiting 30s...")
                time.sleep(30)
                continue

            if resp.status_code == 200:
                for part in resp.json().get("candidates",[{}])[0].get("content",{}).get("parts",[]):
                    if "inlineData" in part:
                        raw = base64.b64decode(part["inlineData"]["data"])
                        tmp = Path(out_path).parent / "tmp_raw.jpg"
                        tmp.write_bytes(raw)
                        final = smart_crop(Image.open(tmp).convert("RGB"))
                        final = ImageEnhance.Sharpness(final).enhance(1.15)
                        final = ImageEnhance.Color(final).enhance(1.05)
                        final.save(out_path, "JPEG", quality=95)
                        tmp.unlink(missing_ok=True)

                        # Quality audit
                        passed, detail, issues = quality_audit(out_path)
                        kb = Path(out_path).stat().st_size / 1024
                        if passed:
                            print(f"    PASS: {Path(out_path).name} ({kb:.0f}KB) [{detail}]")
                            return True
                        else:
                            print(f"    FAIL (attempt {attempt}): {', '.join(issues)} [{detail}]")
                            if attempt < max_retries:
                                time.sleep(5)
                            continue
                print(f"    WARN: No image in Gemini response")
            else:
                print(f"    ERROR: HTTP {resp.status_code}")
        except Exception as e:
            print(f"    ERROR: {e}")

        if attempt < max_retries:
            time.sleep(5)

    return False


# ══════════════════════════════════════════════════════════
# FULL ITEM LIST — 34 Uncle Chua + 16 Choon
# ══════════════════════════════════════════════════════════

UC = Path("/Users/jennwoeiloh/Downloads/Uncle Chua Prawn Noodle")
CH = Path("/Users/jennwoeiloh/Downloads/Choon Prawn House Noodle")

ALL_ITEMS = [
    # === UNCLE CHUA FOOD ===
    ("uc", "100", UC/"100.JPG", "Penang Prawn Noodle Soup — yellow egg noodles in rich orange-red prawn broth, 4 plump fresh prawns, halved soft-boiled egg with golden yolk, sliced pork belly, bean sprouts, pandan leaf, crispy fried shallots"),
    ("uc", "101", UC/"101.JPG", "Dry Prawn Noodle — dark noodles tossed in rich prawn paste, fresh prawns, halved egg, pork slices, bean sprouts, pandan leaf, crispy shallots"),
    ("uc", "102", UC/"102.JPG", "Tiger Prawn Noodle — whole large tiger prawn in orange-red prawn broth, noodles, egg, pork, bean sprouts, pandan leaf"),
    ("uc", "103", UC/"103.JPG", "Udang Galah Prawn Noodle — large freshwater prawn (udang galah) in broth with noodles, egg, pork, bean sprouts"),
    ("uc", "105", UC/"105.jpg", "Prawn Noodle with Pork Ribs — prawn noodle soup with tender pork ribs, prawns, egg, kangkung, fried shallots"),
    ("uc", "107", UC/"107.jpg", "MALA Dry Prawn Noodle — numbing spicy mala sauce tossed noodles with prawns, egg, pork, vegetables on wooden board"),
    ("uc", "200", UC/"200.JPG", "Penang Lam Mee — prawn-egg drop soup with fresh shrimps, pork, spring onions, bean sprouts, fried shallots"),
    ("uc", "205", UC/"205_converted.jpg", "Nyonya Curry Laksa — creamy coconut curry noodle with prawns, tofu puffs, fish balls, bean sprouts, keropok"),
    ("uc", "305", UC/"305_converted.jpg", "Chicken Shrimp Wanton Hor Fun — silky flat rice noodles in clear soup with shredded chicken, plump shrimp wantons"),
    ("uc", "307", UC/"307 small bowl.jpg", "MALA Dry Pork Paste Noodle — dark noodles tossed in mala sauce with pork paste balls, fried beancurd, vegetables"),
    ("uc", "500", UC/"500.JPG", "Fried Beancurd with Fungus — crispy deep-fried beancurd skin rolls stuffed with fungus, fresh cucumber slices, parsley garnish"),
    ("uc", "501", UC/"501_converted.jpg", "Fried Chicken Popcorn — bite-sized golden crispy chicken popcorn pieces with fresh cucumber"),
    ("uc", "502", UC/"502.JPG", "Crispy Fried Beancurd — stack of thin crispy golden beancurd skin chips with cucumber slices"),
    ("uc", "503", UC/"503_converted.jpg", "Golden Beancurd Prawn — golden fried prawn paste wrapped in beancurd skin with cucumber"),
    ("uc", "506", UC/"506_converted.jpg", "Fried Fish Ball — bouncy golden deep fried fish balls"),
    ("uc", "800", UC/"800.jpg", "Red Bean Soup — warm Chinese red bean dessert soup in traditional bowl with spoon"),
    # === UNCLE CHUA DRINKS ===
    ("uc", "600", UC/"600_White Coffee.jpg", "White Coffee — traditional kopitiam white coffee in classic cup with saucer, creamy and frothy"),
    ("uc", "601", UC/"601_Kopi O.jpg", "Kopi O — traditional black coffee in kopitiam cup, rich dark brown color"),
    ("uc", "602", UC/"602_Nescafe.jpg", "Nescafe — instant coffee with condensed milk in kopitiam cup"),
    ("uc", "604", UC/"604_Teh O.jpg", "Teh O — local black tea in clear glass, amber golden color"),
    ("uc", "605", UC/"605_Milo.jpg", "Hot Milo — rich chocolate malt drink in traditional kopitiam cup"),
    ("uc", "606", UC/"606_CocaCola.jpg", "Coca-Cola — red can with ice-filled glass"),
    ("uc", "607", UC/"607_100 Plus.jpg", "100 Plus — isotonic drink can with ice glass"),
    ("uc", "608", UC/"608_Sour Plum Juice.jpg", "Iced Sour Plum Juice — lime-green sour plum drink in tall sundae glass with ice and blue straw"),
    ("uc", "609", UC/"609_Ambra Juice.jpg", "Ambra Juice — kedondong juice in tall glass, golden-green color"),
    ("uc", "610", UC/"610_Herbal Tea.jpg", "Herbal Tea — Chinese herbal tea in clear glass, dark amber"),
    ("uc", "611", UC/"611_Barley.jpg", "Barley Water — white creamy barley drink in glass"),
    ("uc", "612", UC/"612_Barley Lime.jpg", "Barley Lime — barley water with lime in colorful mug"),
    ("uc", "613", UC/"613_Kopi.jpg", "Nanyang Kopi — Nanyang coffee in traditional cup with saucer"),
    ("uc", "615", UC/"615_Teh.jpg", "Nanyang Teh — Nanyang tea in traditional cup"),
    ("uc", "618", UC/"618_Cham.jpg", "Cham — coffee-tea blend with milk in traditional cup"),
    ("uc", "650", UC/"650_Fresh Orange Juice.jpg", "Fresh Orange Juice — freshly squeezed orange juice in tall glass, bright orange"),
    ("uc", "651", UC/"651_Fresh Apple Juice.jpg", "Fresh Apple Juice — fresh apple juice in tall glass, pale yellow-green"),
    ("uc", "652", UC/"652_Glass Jelly.jpg", "Glass Jelly — grass jelly dessert drink, dark jelly in sweet syrup"),
    # === CHOON PRAWN HOUSE ===
    ("ch", "DR01", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Curry Asam Seafood (Share)_232354293.jpg",
     "Curry Asam Seafood — prawns, squid, octopus in tangy spicy asam curry sauce, served in a bowl. Rich red-orange curry with kaffir lime leaf"),
    ("ch", "DR02", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Lor Chicken Feet & Taofu Spice Rice_1726226539742.jpg",
     "Lor Chicken Feet & Taufu Rice — braised chicken feet and golden fried taufu in dark soy sauce, with butterfly pea blue rice, cucumber slices, halved egg"),
    ("ch", "DR03", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Lor Pork Tail & lntestine Spice Rice _1726226627021.jpg",
     "Lor Pork Tail & Intestine Rice — braised pork tail and intestine in dark soy, with blue butterfly pea rice, cucumber, egg"),
    ("ch", "DR04", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Rendang Chicken Spice Rice _1726226598847.jpg",
     "Nyonya Rendang Chicken Rice — slow-cooked rendang chicken pieces in rich spice paste, with butterfly pea blue rice, cucumber slices, egg, lemongrass stalk"),
    ("ch", "DR05", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Rendang Pork Rib Spice Rice_205810283.jpg",
     "Rendang Pork Rib Rice — rendang pork ribs in dark spice paste, with blue butterfly pea rice, cucumber, egg"),
    ("ch", "DR06", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/LOR CHICKEN FEET(Share) _231826415.jpg",
     "Lor Chicken Feet — bowl of braised chicken feet in rich dark soy sauce, glistening and tender"),
    ("ch", "DR07", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Lor Tail & Instestine(share) _152500158.jpg",
     "Lor Pork Tail & Intestine — braised pork tail and intestine pieces in dark soy sauce bowl"),
    ("ch", "N01", CH/"Everything Choon Prawn Mee/Prawn Mee Ramen/20240614_125235.jpg",
     "Prawn Mee Ramen — dark prawn broth ramen with fresh prawns, shredded chicken, halved egg, kangkung, noodles in black bowl"),
    ("ch", "S01", CH/"Photo for standby use(2024 MENU) (2)/Copy of 406  Stew Chicken Feet     五香卤鸡脚  RM9.90 (1).jpg",
     "Five-Spice Stew Chicken Feet — braised chicken feet in aromatic five-spice dark sauce on plate"),
    ("ch", "S02", CH/"Photo for standby use(2024 MENU) (2)/Copy of 908  Nyonya Acar            Toufu            娘惹腌菜炸豆腐   RM9.90 (1).jpg",
     "Nyonya Acar Toufu — crispy fried taufu blocks with pickled vegetable acar, sesame seeds on top"),
    ("ch", "S03", CH/"Photo for standby use(2024 MENU) (2)/Copy of 911  Nyonya Taugeh Kerabu    娘惹豆芽沙拉  RM10.90.jpg",
     "Nyonya Taugeh Kerabu — crunchy bean sprout salad with dried shrimp, lime, chilli, herbs"),
    ("ch", "S04", CH/"Photo for standby use(2024 MENU) (2)/Copy of 914 Fried Seafood  Taufu  炸海鲜豆腐  RM9.90.jpg",
     "Fried Seafood Taufu — golden fried seafood taufu pieces with chilli sauce and cucumber"),
    ("ch", "S05", CH/"Photo for standby use(2024 MENU) (2)/Copy of 915 Pandan                Chicken            香兰叶鸡 RM10.90.jpg",
     "Pandan Chicken — marinated chicken wrapped in green pandan leaves, deep fried, with chilli sauce and cucumber"),
    ("ch", "S06", CH/"Photo for standby use(2024 MENU) (2)/Copy of 916 Fried Prawn             Ball                炸虾球  RM9.90 (1).jpg",
     "Fried Prawn Balls — 6 golden crispy deep-fried prawn balls with oil sheen, sweet chilli dipping sauce, fresh cucumber"),
    ("ch", "D01", CH/"Photo for standby use(2024 MENU) (2)/MTXX_MH20240220_100721071.jpg",
     "Pat Bo Milk Tea Cincau — herbal eight-treasure milk tea with dark grass jelly, ice, in tall glass"),
    ("ch", "B01", CH/"Photo for standby use(2024 MENU) (2)/Copy of Breakfast & Tea Break (1).jpg",
     "Malaysian Breakfast Set — toast with butter and kaya, two half-boiled eggs in yellow bowl, hot coffee in blue mug, butter and jam dishes"),
]

# ══════════════════════════════════════════════════════════
# RUN
# ══════════════════════════════════════════════════════════
UC_OUT = Path(os.path.expanduser("~/Desktop/Grab Listing Output/Uncle Chua/photos-final"))
CH_OUT = Path(os.path.expanduser("~/Desktop/Grab Listing Output/Choon Prawn House/photos-final"))
UC_OUT.mkdir(parents=True, exist_ok=True)
CH_OUT.mkdir(parents=True, exist_ok=True)

print(f"{'='*60}")
print(f"FULL CATALOG GENERATION — {len(ALL_ITEMS)} dishes")
print(f"Foodporn quality + Visual audit gate")
print(f"{'='*60}\n")

passed = 0
failed = 0
flagged = []

for i, (store, code, src, desc) in enumerate(ALL_ITEMS):
    out_dir = UC_OUT if store == "uc" else CH_OUT
    prefix = "uncle-chua" if store == "uc" else "choon"
    slug = desc.split("—")[0].strip().replace(" ","-").lower()[:30]
    out_path = str(out_dir / f"{prefix}_{code}_{slug}.jpg")

    # Skip if already exists and passes QA
    if Path(out_path).exists() and Path(out_path).stat().st_size > 10000:
        ok, detail, issues = quality_audit(out_path)
        if ok:
            print(f"[{i+1}/{len(ALL_ITEMS)}] SKIP (exists+pass): {code} {desc.split('—')[0].strip()}")
            passed += 1
            continue

    if not Path(src).exists():
        print(f"[{i+1}/{len(ALL_ITEMS)}] MISSING SOURCE: {code}")
        failed += 1
        continue

    print(f"[{i+1}/{len(ALL_ITEMS)}] {code} {desc.split('—')[0].strip()}")
    ok = generate_one(str(src), out_path, desc)

    if ok:
        passed += 1
    else:
        failed += 1
        flagged.append(f"{code}: {desc.split('—')[0].strip()}")

    # Rate limit: ~12 req/min
    if i < len(ALL_ITEMS) - 1:
        time.sleep(5)

# ══════════════════════════════════════════════════════════
# REPORT
# ══════════════════════════════════════════════════════════
print(f"\n{'='*60}")
print(f"RESULTS")
print(f"{'='*60}")
print(f"  Passed QA: {passed}/{len(ALL_ITEMS)}")
print(f"  Failed:    {failed}/{len(ALL_ITEMS)}")
uc_count = len(list(UC_OUT.glob("*.jpg")))
ch_count = len(list(CH_OUT.glob("*.jpg")))
print(f"  Uncle Chua: {uc_count} photos in {UC_OUT}")
print(f"  Choon:      {ch_count} photos in {CH_OUT}")

if flagged:
    print(f"\n  FLAGGED (need manual review):")
    for f in flagged:
        print(f"    - {f}")

print(f"\nDone.")
