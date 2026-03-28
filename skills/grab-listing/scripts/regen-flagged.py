#!/usr/bin/env python3
"""Re-generate 32 flagged photos with category-specific prompts.
3 prompt types: FOOD (bowls), DRINKS (glasses), RICE SETS (plated meals)
"""
import base64, io, time, os
from pathlib import Path
import httpx
from PIL import Image, ImageEnhance

GEMINI_KEY = ""
for f in [Path.home() / ".openclaw" / "secrets" / "gemini.env"]:
    if f.exists():
        for line in f.read_text().splitlines():
            if line.startswith("GEMINI_API_KEY="): GEMINI_KEY = line.split("=",1)[1].strip()

URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key={GEMINI_KEY}"

# ── 3 CATEGORY PROMPTS ──

FOOD_PROMPT = """You are a world-class food photographer. REGENERATE this dish for a premium food delivery catalog.

COMPOSITION — CRITICAL:
- Food must be CENTERED in the frame — exactly in the middle
- Food must fill 65-75% of the image — the bowl/plate should be LARGE and dominant
- 45-degree angle — see the front rim clearly, back rim higher
- PURE WHITE background everywhere — no grey, no gradient, no shadow on bg
- Only shadow: tiny soft one directly under the bowl/plate base

FOOD STYLING:
- Every ingredient VIVID and SATURATED — rich reds, bright greens, golden yellows
- Sauce/broth GLOSSY and GLISTENING with light reflection
- Steam rising from hot dishes
- Textures sharp and visible — crispy, juicy, dewy
- Clean white ceramic bowl/plate, no patterns

LIGHTING: Very bright, luminous, soft key light from upper-left. Warm golden tone.
FOCUS: Tack sharp everywhere, f/8, no blur.

Make it look SO DELICIOUS you want to order immediately."""

DRINK_PROMPT = """You are a world-class beverage photographer. REGENERATE this drink for a premium food delivery catalog.

COMPOSITION — CRITICAL:
- Glass must be LARGE — filling 60-70% of the image height
- Glass must be perfectly CENTERED horizontally AND vertically
- The glass should be the dominant element, not floating in empty white space
- 45-degree angle looking slightly down at the glass
- PURE WHITE background — no grey anywhere

DRINK STYLING:
- Glass should look CRYSTAL CLEAR with visible condensation droplets if cold
- Liquid COLORS must be VIVID and SATURATED — make them POP against white
- Ice cubes glistening and crystal clear
- If it's coffee/tea — the brown should be RICH and WARM, not dull grey-brown
- If it's juice — the color should be VIBRANT (bright orange, vivid green, etc)
- Straws and garnishes clearly visible
- The drink should look REFRESHING and THIRST-QUENCHING

LIGHTING: Very bright, luminous. Light should pass THROUGH the glass showing the beautiful liquid color.
FOCUS: Sharp everywhere.
BACKGROUND: Pure white, absolutely nothing else."""

RICE_PROMPT = """You are a world-class food photographer. REGENERATE this rice set for a premium food delivery catalog.

COMPOSITION — CRITICAL:
- ALL components plated together on ONE plate/bowl — rice, curry/meat, cucumber, egg
- Plate must be LARGE — filling 65-75% of the image
- Perfectly CENTERED in the frame
- 45-degree angle — see the front rim, depth visible
- PURE WHITE background — no grey anywhere

FOOD STYLING:
- Rice grains clearly visible (blue butterfly pea rice should be vivid blue-purple)
- Curry/meat sauce THICK, GLOSSY, GLISTENING
- Cucumber slices CRISP, bright green
- Egg with RICH GOLDEN yolk
- Steam rising
- Every color SATURATED and VIVID — not dull or washed out

Clean white round ceramic plate, no patterns. Bright luminous lighting."""

UC = Path("/Users/jennwoeiloh/Downloads/Uncle Chua Prawn Noodle")
CH = Path("/Users/jennwoeiloh/Downloads/Choon Prawn House Noodle")
BASE = Path(os.path.expanduser("~/Desktop/Grab Listing Output"))

# All 32 flagged items with their source, description, output path, and prompt type
FLAGGED = [
    # UC FOOD
    ("food", UC/"105.jpg", "Prawn Noodle with Pork Ribs — prawn broth with tender pork ribs, prawns, egg, bean sprouts, pandan leaf in white bowl", "Uncle Chua/photos-final/uncle-chua_105_prawn-noodle-with-pork-ribs.jpg"),
    ("food", UC/"305_converted.jpg", "Chicken Shrimp Wanton Hor Fun — silky flat noodles in clear soup with shredded chicken, shrimp wantons in white bowl", "Uncle Chua/photos-final/uncle-chua_305_chicken-shrimp-wanton-hor-fun.jpg"),
    ("food", UC/"500.JPG", "Fried Beancurd with Fungus — crispy beancurd skin rolls with fungus, cucumber slices on LARGE white round plate filling most of the frame", "Uncle Chua/photos-final/uncle-chua_500_fried-beancurd-with-fungus.jpg"),
    ("food", UC/"502.JPG", "Crispy Fried Beancurd — stack of golden crispy beancurd chips with cucumber on LARGE white round plate, centered", "Uncle Chua/photos-final/uncle-chua_502_crispy-fried-beancurd.jpg"),
    ("food", UC/"503_converted.jpg", "Golden Beancurd Prawn — golden fried prawn paste in beancurd skin with cucumber on LARGE white round plate, vivid golden color", "Uncle Chua/photos-final/uncle-chua_503_golden-beancurd-prawn.jpg"),
    ("food", UC/"800.jpg", "Red Bean Soup — warm thick red bean soup in LARGE white bowl, rich dark red color, visible bean texture, white ceramic spoon", "Uncle Chua/photos-final/uncle-chua_800_red-bean-soup.jpg"),
    # UC DRINKS — all need bigger glass, centered, vivid color
    ("drink", UC/"600_White Coffee.jpg", "White Coffee — creamy frothy white coffee in a LARGE traditional kopitiam cup on saucer, rich warm brown color, steam rising", "Uncle Chua/photos-final/uncle-chua_600_white-coffee.jpg"),
    ("drink", UC/"601_Kopi O.jpg", "Kopi O — strong black coffee in LARGE traditional kopitiam cup on saucer, rich deep dark brown, steam rising", "Uncle Chua/photos-final/uncle-chua_601_kopi-o.jpg"),
    ("drink", UC/"602_Nescafe.jpg", "Nescafe — instant coffee with condensed milk in LARGE traditional kopitiam cup, caramel brown color", "Uncle Chua/photos-final/uncle-chua_602_nescafe.jpg"),
    ("drink", UC/"604_Teh O.jpg", "Teh O — local black tea in LARGE clear glass, beautiful amber golden color, ice cubes visible", "Uncle Chua/photos-final/uncle-chua_604_teh-o.jpg"),
    ("drink", UC/"605_Milo.jpg", "Hot Milo — LARGE cup of rich chocolate malt Milo in traditional kopitiam cup, thick dark chocolate brown color", "Uncle Chua/photos-final/uncle-chua_605_hot-milo.jpg"),
    ("drink", UC/"606_CocaCola.jpg", "Coca-Cola — bright red Coca-Cola can next to LARGE ice-filled glass with dark cola, condensation droplets, centered", "Uncle Chua/photos-final/uncle-chua_606_coca-cola.jpg"),
    ("drink", UC/"607_100 Plus.jpg", "100 Plus — blue 100 Plus can next to LARGE ice-filled glass with clear fizzy drink, condensation, centered", "Uncle Chua/photos-final/uncle-chua_607_100-plus.jpg"),
    ("drink", UC/"608_Sour Plum Juice.jpg", "Iced Sour Plum Juice — LARGE tall sundae glass filled with VIVID lime-green sour plum drink, ice, sour plum visible, blue straw", "Uncle Chua/photos-final/uncle-chua_608_iced-sour-plum-juice.jpg"),
    ("drink", UC/"609_Ambra Juice.jpg", "Ambra Juice — LARGE tall glass of VIVID golden-green kedondong juice with ice, straw", "Uncle Chua/photos-final/uncle-chua_609_ambra-juice.jpg"),
    ("drink", UC/"610_Herbal Tea.jpg", "Herbal Tea — LARGE clear glass of dark amber Chinese herbal tea with ice, centered in frame", "Uncle Chua/photos-final/uncle-chua_610_herbal-tea.jpg"),
    ("drink", UC/"611_Barley.jpg", "Barley Water — LARGE glass of creamy white-beige barley drink with ice, centered", "Uncle Chua/photos-final/uncle-chua_611_barley-water.jpg"),
    ("drink", UC/"612_Barley Lime.jpg", "Barley Lime — LARGE glass of barley water with lime slice, slightly green tint, ice, centered", "Uncle Chua/photos-final/uncle-chua_612_barley-lime.jpg"),
    ("drink", UC/"613_Kopi.jpg", "Nanyang Kopi — LARGE traditional kopitiam cup of rich Nanyang coffee on saucer, deep warm brown, centered", "Uncle Chua/photos-final/uncle-chua_613_nanyang-kopi.jpg"),
    ("drink", UC/"615_Teh.jpg", "Nanyang Teh — LARGE traditional kopitiam cup of Nanyang tea on saucer, warm amber-brown, centered", "Uncle Chua/photos-final/uncle-chua_615_nanyang-teh.jpg"),
    ("drink", UC/"618_Cham.jpg", "Cham — LARGE traditional kopitiam cup of coffee-tea blend with milk on saucer, rich warm brown, centered", "Uncle Chua/photos-final/uncle-chua_618_cham.jpg"),
    ("drink", UC/"650_Fresh Orange Juice.jpg", "Fresh Orange Juice — LARGE tall glass of VIVID bright orange freshly squeezed juice, ice, centered, vibrant color", "Uncle Chua/photos-final/uncle-chua_650_fresh-orange-juice.jpg"),
    ("drink", UC/"651_Fresh Apple Juice.jpg", "Fresh Apple Juice — LARGE tall glass of pale golden-green apple juice, ice, straw, centered", "Uncle Chua/photos-final/uncle-chua_651_fresh-apple-juice.jpg"),
    # CHOON
    ("food", CH/"Photo for standby use(2024 MENU) (2)/Copy of Breakfast & Tea Break (1).jpg", "Malaysian Breakfast Set — toast, half-boiled eggs, coffee, butter & kaya, all arranged on LARGE white plate, vivid colors, centered", "Choon Prawn House/photos-final/choon_B01_malaysian-breakfast-set.jpg"),
    ("drink", CH/"Photo for standby use(2024 MENU) (2)/MTXX_MH20240220_100721071.jpg", "Pat Bo Milk Tea Cincau — LARGE tall glass of iced milk tea with dark grass jelly at bottom, creamy top, ice, straws, VIVID two-tone color", "Choon Prawn House/photos-final/choon_D01_pat-bo-milk-tea-cincau.jpg"),
    ("food", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Curry Asam Seafood (Share)_232354293.jpg", "Curry Asam Seafood — prawns, squid in VIVID red-orange tangy asam curry in LARGE white bowl, glistening", "Choon Prawn House/photos-final/choon_DR01_curry-asam-seafood.jpg"),
    ("rice", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Lor Chicken Feet & Taofu Spice Rice_1726226539742.jpg", "Lor Chicken Feet & Taufu Rice — braised chicken feet + golden taufu + VIVID blue butterfly pea rice + cucumber + egg, ALL on one LARGE white plate, centered", "Choon Prawn House/photos-final/choon_DR02_lor-chicken-feet-&-taufu-rice.jpg"),
    ("rice", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Lor Pork Tail & lntestine Spice Rice _1726226627021.jpg", "Lor Pork Tail & Intestine Rice — braised pork + VIVID blue butterfly pea rice + cucumber + egg, ALL on one LARGE white plate", "Choon Prawn House/photos-final/choon_DR03_lor-pork-tail-&-intestine-rice.jpg"),
    ("rice", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Rendang Chicken Spice Rice _1726226598847.jpg", "Rendang Chicken Rice — rendang chicken in thick spice paste + VIVID blue butterfly pea rice + cucumber + egg, ALL on one LARGE white plate, centered", "Choon Prawn House/photos-final/choon_DR04_nyonya-rendang-chicken-rice.jpg"),
    ("rice", CH/"Everything Choon Prawn Mee (1)/Dinner Rice Sets (1)/Quality Edited (Confirm) (1)/Rendang Pork Rib Spice Rice_205810283.jpg", "Rendang Pork Rib Rice — rendang pork ribs + VIVID blue butterfly pea rice + cucumber + egg, ALL on one LARGE white plate", "Choon Prawn House/photos-final/choon_DR05_rendang-pork-rib-rice.jpg"),
    ("food", CH/"Everything Choon Prawn Mee/Prawn Mee Ramen/20240614_125235.jpg", "Prawn Mee Ramen — rich dark prawn broth with prawns, chicken, egg, kangkung, noodles in LARGE white bowl filling 70% of frame", "Choon Prawn House/photos-final/choon_N01_prawn-mee-ramen.jpg"),
    ("food", None, "Pandan Chicken — 5 pieces of chicken wrapped in bright green pandan leaves, deep fried golden crispy, on LARGE white round plate with red chilli sauce dish and cucumber slices, filling 65% of frame, centered, VIVID green and golden colors", "Choon Prawn House/photos-final/choon_S05_pandan-chicken.jpg"),
]

PROMPTS = {"food": FOOD_PROMPT, "drink": DRINK_PROMPT, "rice": RICE_PROMPT}

def smart_crop(img, size=(800,800)):
    tw, th = size; tr = tw/th; iw, ih = img.size; ir = iw/ih
    if ir > tr: nw = int(ih*tr); l = (iw-nw)//2; img = img.crop((l,0,l+nw,ih))
    elif ir < tr: nh = int(iw/tr); t = (ih-nh)//2; img = img.crop((0,t,iw,t+nh))
    return img.resize(size, Image.LANCZOS)

print(f"{'='*60}")
print(f"RE-GENERATING {len(FLAGGED)} FLAGGED PHOTOS")
print(f"3 category prompts: food / drink / rice")
print(f"{'='*60}\n")

ok = fail = 0
for i, (ptype, src, desc, out_rel) in enumerate(FLAGGED):
    out = BASE / out_rel
    name = desc.split("—")[0].strip()
    print(f"[{i+1}/{len(FLAGGED)}] [{ptype}] {name}")

    prompt = PROMPTS[ptype]

    # Build request
    parts = [{"text": f"Reference: {desc}\n\n{prompt}"}]

    # Add image if source exists (text-only for pandan chicken)
    if src and Path(src).exists():
        img = Image.open(str(src)).convert("RGB")
        if max(img.size) > 1024:
            r = 1024/max(img.size); img = img.resize((int(img.size[0]*r), int(img.size[1]*r)), Image.LANCZOS)
        buf = io.BytesIO(); img.save(buf, "JPEG", quality=90)
        b64 = base64.b64encode(buf.getvalue()).decode()
        parts.append({"inline_data": {"mime_type": "image/jpeg", "data": b64}})

    try:
        resp = httpx.post(URL, json={
            "contents": [{"parts": parts}],
            "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]},
        }, timeout=120)

        if resp.status_code == 429:
            print(f"  RATE LIMITED — waiting 30s...")
            time.sleep(30)
            resp = httpx.post(URL, json={
                "contents": [{"parts": parts}],
                "generationConfig": {"responseModalities": ["TEXT", "IMAGE"]},
            }, timeout=120)

        if resp.status_code == 200:
            found = False
            for part in resp.json().get("candidates",[{}])[0].get("content",{}).get("parts",[]):
                if "inlineData" in part:
                    raw = base64.b64decode(part["inlineData"]["data"])
                    tmp = out.parent / "tmp.jpg"; tmp.write_bytes(raw)
                    final = smart_crop(Image.open(tmp).convert("RGB"))
                    final = ImageEnhance.Sharpness(final).enhance(1.12)
                    final = ImageEnhance.Color(final).enhance(1.08)
                    final = ImageEnhance.Brightness(final).enhance(1.03)
                    final.save(str(out), "JPEG", quality=95)
                    tmp.unlink(missing_ok=True)
                    kb = out.stat().st_size / 1024
                    print(f"  DONE: {out.name} ({kb:.0f}KB)")
                    ok += 1
                    found = True
                    break
            if not found:
                print(f"  WARN: No image returned")
                fail += 1
        else:
            print(f"  ERROR: {resp.status_code}")
            fail += 1
    except Exception as e:
        print(f"  ERROR: {e}")
        fail += 1

    if i < len(FLAGGED) - 1:
        time.sleep(5)

print(f"\n{'='*60}")
print(f"DONE: {ok} regenerated, {fail} failed")
print(f"{'='*60}")
