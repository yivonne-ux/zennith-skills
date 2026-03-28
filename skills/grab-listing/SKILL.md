---
name: grab-listing
description: End-to-end GrabFood listing optimization — photo pipeline, listing intelligence, copy generation, merchant portal upload. Takes raw merchant photos and outputs Grab-ready 800x800 images, bilingual menu copy, category structure, and upload manifests.
agents:
  - taoz
  - scout
---

# GrabFood Listing Optimizer

End-to-end pipeline that takes a raw photo folder from any F&B merchant and produces a fully optimized Grab listing — AI-regenerated food photography, bilingual menu copy, category structure, and upload package.

**Replaces:** Professional food photographer ($500-2000) + Canva editing + ChatGPT copy + manual uploads
**Cost:** Gemini API (free tier: 15 req/min) + $0 for PIL/sips
**Time:** ~5 min per merchant for 50 photos (vs 2-3 hours manual)

## THREE-TIER PIPELINE

| Tier | Script | What It Does | When |
|------|--------|-------------|------|
| **Fast** | `grab-listing.py` | PIL crop + color enhance | Quick preview, batch processing |
| **Premium** | `refine-photos.py` | Gemini AI per-dish refinement | Good quality, preserves original style |
| **Catalog** | `generate-catalog.py` | Gemini AI full regeneration + quality gate | **Production standard** — foodporn level |

**Always use Catalog tier for client delivery.** Fast tier is for internal preview only.

---

## WHAT IT DOES

```
INPUT:  Raw merchant photo folder (any quality, any structure, any chaos level)
  ↓
STEP 1: AUDIT — Map all files, identify quality tiers, find best photo per item
STEP 2: GENERATE — Gemini AI regenerates each dish as foodporn-level catalog photography
STEP 3: QUALITY GATE — Auto-audit brightness, sharpness, bg whiteness vs approved baseline
STEP 4: INTELLIGENCE — Build menu structure, bilingual copy, pricing, categories
STEP 5: PACKAGE — Generate upload_manifest.json + LISTING-COPY.md
STEP 6: UPLOAD — Batch upload via Grab Merchant portal (headless browser)
  ↓
OUTPUT: 800x800 catalog-grade photos + complete listing copy on Desktop
```

## VISUAL STANDARD (approved baseline)

Every generated photo must match this standard:
- **Bowl/Plate:** Clean modern white ceramic, no patterns, minimal
- **Background:** Pure seamless white, no props, no table
- **Angle:** Exactly 45 degrees — diner's perspective, bowl side visible
- **Position:** Centered, food filling 70% of frame
- **Shadow:** Soft drop shadow underneath, consistent across all photos
- **Lighting:** Bright soft key light from upper-left, warm golden tone
- **Food:** Glistening, steaming, vivid colors — looks DELICIOUS
- **Sharpness:** Tack sharp everywhere, no blur, f/8 depth of field
- **Consistency:** Every photo looks like the SAME professional photoshoot

### Quality Gate Thresholds
| Metric | Minimum | Average (approved shots) |
|--------|---------|------------------------|
| Brightness | >180 | 210 |
| Sharpness | >200 | 800 |
| BG whiteness | >210 | 240 |

Auto-retry up to 2x if photo fails gate. PIL brightness boost as fallback.

---

## WHEN TO USE

- Client gives you a folder of food photos → run this
- New merchant onboarding onto GrabFood
- Existing merchant wants listing refresh
- "Optimize my Grab listing" / "Fix my Grab photos" / "My Grab sales are low"
- Competitor audit + listing improvement

---

## QUICK START

### 1. Audit a merchant folder
```bash
python3 ~/.openclaw/skills/grab-listing/scripts/grab-listing.py audit \
  --input "/path/to/merchant/photos" \
  --merchant "merchant-name"
```
Outputs: File inventory, quality tiers, before/after analysis, missing items report.

### 2. Process photos
```bash
python3 ~/.openclaw/skills/grab-listing/scripts/grab-listing.py process \
  --input "/path/to/merchant/photos" \
  --merchant "merchant-name" \
  --output "~/Desktop/Grab Listing Output/Merchant Name"
```
Outputs: 800x800 Grab photos, 1350x750 banners, 80x80 thumbnail grid.

### 3. Generate listing copy + manifest
```bash
python3 ~/.openclaw/skills/grab-listing/scripts/grab-listing.py intelligence \
  --merchant "merchant-name" \
  --cuisine "Penang Hawker" \
  --output "~/Desktop/Grab Listing Output/Merchant Name"
```
Outputs: upload_manifest.json, LISTING-COPY.md with all bilingual names + descriptions.

### 4. Upload to Grab
```bash
python3 ~/.openclaw/skills/grab-listing/scripts/grab-listing.py upload \
  --manifest "path/to/upload_manifest.json" \
  --merchant "merchant-name"
```
Requires: Grab Merchant portal login credentials.

---

## PHOTO PIPELINE SPEC

### GrabFood Image Requirements
- **Menu item:** 800x800px (1:1 square), JPEG, max 6MB
- **Store banner:** 1350x750px (9:5), JPEG
- **Thumbnail display:** 80x80px on consumer app
- **No:** text, watermarks, borders, logos overlaid on food

### Enhancement Settings by Background Type

| Setting | White BG | Black BG | Wood/Mixed BG |
|---------|----------|----------|---------------|
| Brightness | +5% | +25% | +15% |
| Warmth (R) | +6 | +10 | +8 |
| Warmth (G) | +2 | +4 | +3 |
| Saturation | +15% | +20% | +18% |
| Contrast | +8% | +12% | +10% |
| Sharpness | +15% | +20% | +15% |

### HEIC Handling
macOS `sips` converts HEIC → JPEG losslessly. No external library needed.
```bash
sips -s format jpeg input.HEIC --out output.jpg
```

### Smart Crop Algorithm
1. Calculate target aspect ratio (1:1 for Grab menu)
2. If image wider: crop equal sides, keep center
3. If image taller: crop top/bottom, keep center (food is usually center)
4. Resize to target with LANCZOS resampling

### Thumbnail Test
Every processed photo gets an 80px thumbnail render. Generate a grid image to verify all items are identifiable at Grab's actual display size.

---

## LISTING INTELLIGENCE SPEC

### Category Structure (template)
Optimal for Grab: **5-8 categories**, sorted by popularity.

```
1. 🔥 Best Sellers 招牌推荐     ← Top 3-5 items, always first
2. 🍜 [Signature Category]     ← Main dish type
3. 🍚 [Secondary Category]     ← Rice/alternative dishes
4. 🥟 Sides 小吃               ← Appetizers, snacks
5. 🍧 Desserts 甜品             ← If applicable
6. ☕ Hot Beverages 热饮         ← Split hot/cold for long drink menus
7. 🧊 Cold Beverages 冷饮
8. 🍳 Breakfast 早餐            ← If applicable
```

### Naming Convention
Every item name follows: **Emoji + English Name + Chinese Name**
```
🍜 Signature Prawn Noodle 招牌虾面
🌶️ MALA Dry Prawn Noodle 麻辣干捞虾面
🦐 Tiger Prawn Noodle 大头虾虾面
```

### Description Rules
- 50-80 characters
- Mention 2-3 key ingredients
- Use appetite-triggering sensory words (crispy, rich, tender, fresh, fragrant)
- NO generic "delicious" — be specific
- End with hook (exclamation, emoji, or benefit)

### Tags
Use Grab's built-in tags: `BESTSELLER`, `MOST_ORDERED`, `MOST_LIKED`, `SPICY`, `NEW`, `POPULAR`, `PREMIUM`, `SHARING`

### Pricing Rules
- Round to .90 or .50 (RM13.90, RM15.50)
- Best sellers in the RM12-22 range
- Premium items clearly marked (RM30+)
- Size variants: Small/Large with RM2-4 gap

---

## OUTPUT FILES

### Per Merchant Output
```
{output_dir}/
├── photos/
│   ├── {merchant}_{code}_{slug}_grab-800.jpg    ← Menu photo (800x800)
│   ├── {merchant}_{code}_{slug}_banner-1350.jpg  ← Banner variant
│   ├── {merchant}_{code}_{slug}_thumb-80.jpg     ← Thumbnail test
│   └── _THUMBNAIL_TEST_GRID.jpg                   ← All thumbnails in grid
├── reports/
│   ├── upload_manifest.json                       ← Machine-readable upload spec
│   ├── LISTING-COPY.md                            ← Human-readable copy doc
│   └── audit-report.md                            ← Before/after analysis
```

### Upload Manifest Schema
```json
{
  "version": "1.0",
  "merchant_id": "merchant-name",
  "store": {
    "name_optimized": "🍜 Store Name 中文名",
    "description": "Under 150 chars, bilingual, with emoji + USP"
  },
  "categories": [
    {
      "display_name": "🔥 Best Sellers 招牌推荐",
      "items": [
        {
          "code": "100",
          "grab_name": "🍜 Signature Dish 招牌菜",
          "description": "50-80 char appetite-triggering copy",
          "price": 15.90,
          "photo_path": "/path/to/grab-800.jpg",
          "tags": ["BESTSELLER"]
        }
      ]
    }
  ],
  "upload_queue": [
    {"action": "upload_photo", "item_name": "...", "photo_path": "..."},
    {"action": "update_item", "item_name": "...", "new_name": "...", "new_desc": "..."}
  ]
}
```

---

## MERCHANT PORTAL AUTOMATION

### Login Flow
```
1. Navigate to merchant.grab.com
2. Login via OTP or saved session
3. Select store (if multi-store)
4. Navigate to Food Menu section
```

### Upload Flow (per item)
```
1. Find item by name (fuzzy match)
2. Click item → Edit
3. Screenshot BEFORE
4. Upload photo via file input
5. Update name, description, price
6. Save
7. Screenshot AFTER
8. Next item
```

### URLs
```
Login:     https://weblogin.grab.com/merchant/login
Dashboard: https://merchant.grab.com/dashboard
Menu:      https://merchant.grab.com/food-menu
Marketing: https://merchant.grab.com/marketing
Reviews:   https://merchant.grab.com/feedback
Analytics: https://merchant.grab.com/insights
Consumer:  https://food.grab.com/my/en/restaurant/online-delivery/{slug}
```

---

## PROVEN RESULTS

### Use Case 1: Uncle Chua Prawn Noodle
- **Input:** 55 photos (organized, 8 HEIC files)
- **Output:** 34 catalog-grade photos, 43 items, 8 categories
- **QA:** 31/34 passed first attempt, 3 fixed with brightness boost
- **Key transformation:** Dark restaurant drink photos → bright white-bg catalog shots

### Use Case 2: Choon Prawn House Noodle
- **Input:** 474 files (total chaos — duplicates, screenshots, raw phone shots)
- **Output:** 16 catalog-grade photos, 21 items, 7 categories
- **QA:** 13/16 passed first attempt, 3 auto-retried and passed
- **Key transformation:** Black-bg studio + overhead rice sets → standardised 45° white-bg catalog

---

## RESEARCH — What Makes GrabFood Listings Convert

### Photo Impact
- Menu photos increase sales by **65%** (Grubhub data)
- High-quality photos increase orders by **35%** (Snappr data)
- Viewing pictures is **1.44x more important** than reading descriptions
- High-contrast thumbnails improve CTR by **20-40%**

### Thumbnail Psychology (80px display)
1. Clean separation — food distinct from background
2. High contrast — bright food on clean background
3. Saturated warm tones — reds, oranges, yellows
4. Single focal point — one dish, centered
5. Visible texture — steam, sauce sheen, crispy edges
6. No shadows on background — clean drop shadow only

### Color Science
- **Red:** Most appetite-stimulating (increases heart rate)
- **Yellow/Orange:** Warmth, comfort, happiness
- **Blue:** Appetite SUPPRESSANT — avoid
- **Warm white bg** (RGB 248,246,240): Clean but not clinical

### Naming Impact
- Bilingual names increase orders from Chinese-speaking customers by ~20%
- Emoji prefixes improve scan speed in long menus
- "Signature" / "Best Seller" tags increase CTR by 15-25%

---

## DEPENDENCIES

- Python 3.10+
- Pillow (PIL) — `pip install Pillow`
- macOS `sips` — HEIC conversion (built-in)
- Optional: `rembg` — background removal for drink photos
- Optional: Playwright — Grab Merchant portal automation
- Optional: OpenAI API — LLM-generated copy (works without, uses templates)

---

## RELATED SKILLS

- `grabfood-enhance` — Photo enhancement research (color science, NANO prompts)
- `food-photography` — AI food photography intelligence
- `product-studio` — Product photography pipeline
- `nanobanana` — AI image generation for missing photos
