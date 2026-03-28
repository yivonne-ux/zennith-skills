# Uncle Chua Prawn Noodle -- Grab Listing Optimization Audit
> Generated 2026-03-27 | Use Case #1 for GrabFood Enhancement Pipeline
> Store: Uncle Chua's Prawn Noodle - Medan Pu... | 4.7 (100) | Non-Halal

---

## 1. BEFORE STATE (Current Grab Listing)

### What's on Grab now (from screenshots a-g):

**Visual Treatment (EVERY photo):**
- Yellow/gold background frame on all thumbnails
- Uncle Chua cartoon chef logo (red circle) overlaid top-right corner
- "MUST TRY" / "BEST SELL" badges overlaid on photos
- Cluttered -- 3 layers of branding on a tiny 80px thumbnail
- Food is hard to see at thumbnail size because overlays eat ~30% of the image

**Current Categories on Grab:**
| Category | Items | Price Range |
|----------|-------|-------------|
| Prawn Noodle | 100-105 | RM21.90-49.90 |
| Lam Mee | 200-201 | RM21.90 |
| Soup Noodle | 300-301 | RM21.90 |
| Snacks | 500-502 | RM7.90 |
| Beverages | 600-652 | RM3.40-9.50 |

**Pricing on Grab:** RM0.40 with 50% off deal (from RM3.40). 35 min delivery.

---

## 2. PRODUCT PHOTOS INVENTORY (55 files in folder)

### Photo Tiers Detected:

#### TIER A: Professional Studio Shots (food items)
**Setup:** White backdrop, controlled lighting, 45-degree angle
**Gear:** DSLR/mirrorless, 4752x3168 (15MP), 3:2 aspect ratio
**Bowl:** Traditional Chinese ceramic with red peony/rooster design (brand signature)

| Code | Item | File(s) | Variants | Quality |
|------|------|---------|----------|---------|
| 100 | Prawn Noodle (Large) | 100.JPG, 100 (2).JPG, 100 (3).JPG | 3 angles | A - clean white bg |
| 101 | Dry Prawn Noodle (Large) | 101.JPG | 1 | A - great contrast |
| 102 | Tiger Prawn Noodle | 102.JPG, 102 (2).JPG | 2 angles | A - hero prawn visible |
| 103 | Udang Galah Prawn Noodle | 103.JPG | 1 | A - large prawn dominant |
| 105 | Prawn Noodle + Pork Ribs | 105.jpg | 1 | B+ - slightly purple cast |
| 107 | MALA Dry Prawn Noodle | 107.jpg | 1 | B+ - on cutting board, not white bg |
| 200 | Lam Mee | 200.JPG | 1 | A- - rooster spoon in shot |
| 201 | Lam Mee Suah | 201.JPG | 1 | DUPLICATE of 200.JPG (identical!) |
| 307 | MALA Dry Pork Paste (small) | 307 small bowl.jpg | 1 | B - has text overlay, wood surface |
| 500 | Fried Beancurd w/ Fugus | 500.JPG | 1 | A - clean black plate on white |
| 502 | Fried Beancurd | 502.JPG, 502 (2).JPG | 2 angles | A- |
| 800 | Red Bean Soup | 800.jpg | 1 | A- styled shot, wooden table |

#### TIER B: In-Store Drink Photos (amateur)
**Setup:** Restaurant table, available light, phone camera
**Gear:** Phone, 4608x3456 (16MP), 4:3 ratio
**Background:** Dark wooden table + tile wall + visible table numbers

| Code | Item | Quality Issue |
|------|------|---------------|
| 600 | White Coffee | Dark bg, timestamp "2020 7 20 13:00" visible |
| 601 | Kopi O | Dark bg, poor lighting |
| 602-605 | Nescafe/Neslo/Teh O/Milo | Traditional kopitiam cups, dark bg |
| 606-607 | Coca-Cola/100 Plus | Can + empty glass, cluttered |
| 608-609 | Sour Plum/Ambra Juice | Tall glass, dark bg |
| 610-612 | Herbal Tea/Barley/Barley Lime | Mixed glass types |
| 613-619 | Kopi/Teh variants | Traditional cups on saucers |
| 650-652 | Fresh juices/Glass Jelly | Portrait orientation (wrong for Grab!) |

#### TIER C: Reference / Kitchen Shots
| File | What It Is |
|------|-----------|
| 1768712751295.jpg | Kitchen counter shot -- Lam Mee reference |
| 1768712751311.jpg | Kitchen counter shot -- noodle reference |
| 1768712751325.jpg | Kitchen counter shot -- noodle reference |
| new logo.jpg | Logo file (348x340, low res) |
| white wall-hires.jpg | White wall photo for background use |

#### HEIC Files (Cannot Process -- Need Conversion)
| Code | Item |
|------|------|
| 107.HEIC | MALA Dry Prawn Noodle (alt angle?) |
| 205.HEIC | Nyonya Curry Laksa |
| 305.HEIC | Shredded Chicken Shrimp Wanton |
| 307.HEIC | MALA Dry Pork Paste Noodles |
| 501.HEIC | Snack item |
| 503.HEIC | Snack item |
| 506.HEIC, 506 (2).HEIC | Snack items |

---

## 3. PIXEL-LEVEL ANALYSIS

### Food Photos (100-500 series) -- THE GOOD ONES
```
Resolution:     4752x3168 (15 megapixels, ~5MB each)
Aspect Ratio:   3:2 (NOT square -- needs crop to 1:1 for Grab)
Color Warmth:   +17 to +47 (warm tones, good for food)
Brightness:     168-205 (good range)
Contrast:       38-62 (moderate, could boost +10-15)
Saturation:     Low-moderate (reds and oranges could be richer)
Background:     89% white (some have gray/cream edges)
Sharpness:      97-167 (acceptable, could sharpen for thumbnails)
```

### Drink Photos (600 series) -- THE BAD ONES
```
Resolution:     4608x3456 (16 megapixels, ~7MB each)
Aspect Ratio:   4:3 or 9:20 (portrait!) -- WRONG for Grab
Color Warmth:   +13 to +34 (cooler than food shots)
Brightness:     112-165 (DARK -- 40% dimmer than food photos!)
Contrast:       35-63 (wide range, inconsistent)
Background:     0% white (100% dark restaurant interior)
Sharpness:      168-823 (high variance, some oversharpened)
```

### CRITICAL GAP: Food vs Drinks
| Metric | Food (100-500) | Drinks (600) | Problem |
|--------|----------------|--------------|---------|
| Brightness | 185 avg | 122 avg | Drinks 34% darker |
| White bg | 89% | 0% | Drinks look amateur |
| Consistency | High | Low | Mixed cup types, angles |
| Grab-ready | Close (need crop) | NO (need reshoot) | 2 completely different quality levels |

---

## 4. MENU STRUCTURE (from physical menu photos)

### Full Menu Map (menu1-menu4):

**A. Prawn Noodles (虾面) -- 100 Series**
| Code | Item EN | Item CN | Price | Photo? |
|------|---------|---------|-------|--------|
| 100 | Prawn Noodles | 泉记虾面 | S RM13.90 / L RM15.90 | YES (3 variants) |
| 101 | Prawn Noodles (Dry) | 干捞虾面 | S RM13.90 / L RM15.90 | YES |
| 102 | Tiger Prawn | "大头虾" 虾面 | RM12.90-23.90 | YES (2 variants) |
| 103 | Prawn Noodles w/ U'dang | "空空虾" 虾面 | ? | YES |
| 105 | Prawn Noodles w/ Pork Ribs | 排骨虾面 | ? | YES |
| 107 | MALA Dry Prawn Noodles | 麻辣干捞虾面 | S RM11.50 / L RM13.50 | YES (HEIC + jpg) |
| 108 | Seafood Deluxe (2 Pax) | 海鲜王虾面 | RM39.90 | NO PHOTO |

**B. Lam Mee (煨面) -- 200 Series**
| Code | Item | Price | Photo? |
|------|------|-------|--------|
| 200 | Lam Mee | S/L RM? | YES |
| 201 | Lam Mee Suah | S/L RM? | DUPLICATE of 200! |
| 205 | Nyonya Curry Laksa | RM13.90 | HEIC ONLY |
| 206 | Chicken Chop Rice | RM13.90 | NO PHOTO |

**C. Pork Paste Soup Noodles (肉骨茶面) -- 300 Series**
| Code | Item | Price | Photo? |
|------|------|-------|--------|
| 300 | Pork Paste Soup Noodle | S/L RM? | NO PHOTO |
| 301 | Dry Pork Paste Soup Noodle | S/L RM? | 307 small bowl (wrong code?) |
| 305 | Shredded Chicken Wanton | S RM10.90 / L RM12.90 | HEIC ONLY |
| 307 | MALA Dry Pork Paste Noodles | S RM11.50 / L RM13.50 | YES (has text overlay) |

**D. Snacks (小吃) -- 500 Series**
| Code | Item | Price | Photo? |
|------|------|-------|--------|
| 500 | Fried Beancurd w/ Fungus | RM4.90/plate | YES |
| 501 | ? | ? | HEIC ONLY |
| 502 | Fried Beancurd | ? | YES (2 variants) |
| 503 | ? (Golden Beancurd Prawn?) | ? | HEIC ONLY |
| 506 | ? | ? | HEIC ONLY (2 variants) |

**E. Desserts (甜品) -- 800 Series**
| Code | Item | Price | Photo? |
|------|------|-------|--------|
| 800 | Red Bean Soup (?) | ? | YES (styled shot) |

**F. Beverages (饮料) -- 600 Series**
All 23 drink photos exist but are AMATEUR QUALITY.

**G. Add-Ons (加料另计)**
From menu: Egg RM1.00, Pork RM4.00, Veg RM2.00, etc.
No individual photos needed for add-ons.

---

## 5. PROBLEMS FOUND (Priority Order)

### CRITICAL
1. **All photos are 3:2 or 4:3 -- NONE are 1:1 (800x800) for Grab**
   - Every photo needs center-crop + resize to 800x800
   - Also need 1350x750 (9:5) banner variant

2. **Drinks are amateur phone shots** (brightness 122 vs food 185)
   - 0% white background, dark restaurant interior visible
   - Table numbers, wall tiles, random objects in frame
   - NEED: Either reshoot OR heavy AI enhancement (rembg + NANO)

3. **HEIC files can't be processed** (6 items)
   - 205, 305, 307, 501, 503, 506 -- all important menu items
   - Must convert HEIC to JPG first

### HIGH
4. **Duplicate/identical photos**
   - 200.JPG = 201.JPG (exact same file, different name)
   - 615_Teh.jpg = 616_Teh C.jpg (identical)
   - 601_Kopi O = 617_Cham O (identical)
   - 618_Cham = 619_Cham C (identical)
   - Need unique photos for each menu item

5. **Missing photos for key items**
   - 108 Seafood Deluxe (RM39.90 -- highest priced item!)
   - 206 Chicken Chop Rice
   - 300 Pork Paste Soup Noodle
   - Multiple snack items (501, 503, 504, 505, 506)

6. **No consistent naming convention**
   - Mix of: "100.JPG", "105.jpg", "307 small bowl.jpg", "600_White Coffee.jpg"
   - Some have spaces, some underscores, mixed case

### MEDIUM
7. **Logo overlay on current Grab listing** kills thumbnail readability
   - At 80px display size, logo + badge eat 30% of visible area
   - Clean photos without overlay will outperform

8. **Inconsistent plating across categories**
   - Noodles: white peony bowl (good, consistent)
   - Snacks: black square plate with doily (good, consistent)
   - Drinks: random kopitiam cups, glasses, cans (inconsistent)

9. **No GrabFood-specific assets**
   - No store banner (1350x750)
   - No category headers
   - No promotional images

---

## 6. STANDARDIZED MENU PACKAGE DESIGN

### Naming Convention
```
{brand}_{code}_{item-slug}_{variant}.{ext}

Examples:
uncle-chua_100_prawn-noodle_hero.jpg
uncle-chua_100_prawn-noodle_grab-800.jpg
uncle-chua_100_prawn-noodle_banner-1350.jpg
uncle-chua_600_white-coffee_hero.jpg
```

### Output Spec per Item
```
1. hero.jpg         -- Full resolution master (original or enhanced)
2. grab-800.jpg     -- 800x800 1:1 square crop, JPEG < 2MB
3. grab-1350.jpg    -- 1350x750 9:5 banner crop (optional, for promos)
4. thumb-80.jpg     -- 80x80 thumbnail test render
```

### Category Structure for Grab
```
CATEGORY 1: Prawn Noodle (虾面)
├── 100  Prawn Noodle (Large)          RM21.90  [3 photo options]
├── 101  Dry Prawn Noodle (Large)      RM21.90  [1 photo]
├── 102  Tiger Prawn Noodle            RM29.90  [2 photo options]
├── 103  Udang Galah Prawn Noodle      RM49.90  [1 photo]
├── 105  Prawn Noodle + Pork Ribs      RM29.90  [1 photo, needs color fix]
├── 107  MALA Dry Prawn Noodle         RM13.50  [needs HEIC convert]
└── 108  Seafood Deluxe (2 Pax)        RM39.90  [NO PHOTO - needs shoot]

CATEGORY 2: Lam Mee (煨面)
├── 200  Lam Mee                       RM21.90  [1 photo]
├── 201  Lam Mee Suah                  RM21.90  [NEEDS UNIQUE PHOTO]
├── 205  Nyonya Curry Laksa            RM13.90  [HEIC only]
└── 206  Chicken Chop Rice             RM13.90  [NO PHOTO]

CATEGORY 3: Soup Noodle (肉骨茶面)
├── 300  Pork Paste Soup Noodle        RM21.90  [NO PHOTO]
├── 301  Dry Pork Paste Soup Noodle    RM21.90  [307 small bowl?]
├── 305  Chicken Shrimp Wanton         RM12.90  [HEIC only]
└── 307  MALA Dry Pork Paste           RM13.50  [text overlay, needs clean]

CATEGORY 4: Snacks (小吃)
├── 500  Fried Beancurd w/ Fungus      RM7.90   [1 photo, good]
├── 502  Fried Beancurd                RM7.90   [2 photo options]
└── 501/503/506 -- need HEIC convert + possible reshoot

CATEGORY 5: Desserts (甜品)
└── 800  Red Bean Soup                 RM?      [1 styled photo]

CATEGORY 6: Beverages (饮料)
├── 600-619 Hot/Cold Drinks            RM3.40-9.50  [ALL need enhancement]
└── 650-652 Fresh Juices               RM?          [portrait, need crop]
```

### Variation Handling
For items with size options (Small/Large), use SAME photo with different listing.
For items with noodle choice (Yellow/Beehoon/Lam Mee/etc), use SAME photo.

---

## 7. ENHANCEMENT PIPELINE (What To Do)

### Phase 1: Quick Wins (can do NOW)
1. Convert all HEIC to JPG (6 files)
2. Center-crop all food photos to 1:1 (800x800)
3. Boost contrast +10, vibrance +15, warmth +5 on all
4. Generate 80px thumbnails for review
5. Fix naming convention
6. Remove the yellow overlay + logo treatment from Grab listing

### Phase 2: Drink Photos (AI Enhancement)
1. Run rembg to remove dark restaurant backgrounds
2. Place on warm white background (RGB 248,246,240)
3. Color correct to match food photo warmth (+30 brightness, +15 saturation)
4. Crop to 800x800
5. Thumbnail test at 80px

### Phase 3: Missing Items
1. Request reshoot or AI-generate: 108, 206, 300, missing snacks
2. Create unique photo for 201 (currently duplicate of 200)
3. Create store banner (1350x750)

### Phase 4: Upload to Grab
1. Replace all menu photos via Grab Merchant portal
2. Remove logo/badge overlays
3. Update item descriptions (bilingual EN/CN)
4. Verify at consumer view

---

## 8. BEFORE → AFTER TRANSFORMATION SUMMARY

| Aspect | BEFORE | AFTER (Target) |
|--------|--------|----------------|
| Background | Yellow frame + logo | Clean warm white |
| Overlays | Logo + MUST TRY badge | NONE |
| Dimensions | Mixed, non-square | 800x800 (1:1) |
| File size | 5-8MB | < 2MB |
| Drinks | Dark restaurant shots | White bg, matched |
| Naming | Random | {brand}_{code}_{slug} |
| Thumbnail test | Logo covers food | Food fills frame |
| Consistency | 2 quality tiers | 1 unified standard |
| Missing items | 8+ items no photo | All items covered |
| Banner | None | 1350x750 store banner |

---

## APPENDIX: Choon Prawn House Noodle -- Folder Chaos Map

**Total files: 474** across 5 top-level folders (heavily duplicated)

### Folder Structure (with duplication analysis):
```
Choon Prawn House Noodle/
├── Everything Choon Prawn Mee/          <-- MAIN ORGANIZED
│   ├── Best Seller Trio/                 (2 customer screenshots)
│   ├── Dinner Rice Sets/                 (79 phone photos, 2024-09-06)
│   ├── Lobak/                            (2 customer screenshots)
│   ├── Lor Cham Thng/                    (1 customer screenshot)
│   ├── Prawn Mee/                        (6 customer screenshots)
│   ├── Prawn Mee Ramen/                  (13 phone photos, 2024-06-14)
│   └── XHS Marketing/Raw Photos/        (18 photos for XHS content)
│
├── Everything Choon Prawn Mee (1)/      <-- DUPLICATE WITH SUB-EDITS
│   ├── Dinner Rice Sets (1)/
│   │   ├── Asam Curry Seafood/          (3 raw photos)
│   │   ├── Chicken Feet n Taufo/        (3 raw + 1 edited)
│   │   ├── Rendang Chicken/             (2 raw + 1 edited)
│   │   ├── Rendang Rib/                 (2 raw + 1 edited)
│   │   ├── Tail n lntestine/            (1 raw + 1 edited)
│   │   ├── Quality Edited (Confirm)/    (6 FINAL edited photos!)
│   │   └── From phone Angela/           (2 phone photos)
│   └── Lobak (1)/                        (2 customer screenshots)
│
├── Photo for standby use(2024 MENU) (2)/ <-- BIGGEST DUMP (138 loose + subfolders)
│   ├── 901 KT TENG/                     (24 photos of one dish)
│   ├── Blue pea flower tea/             (8 photos)
│   ├── Lobak/                           (29 photos)
│   ├── NY ASAM CURRY/                   (24 photos)
│   ├── Pat Bo Milk Tea Cincau Ais/      (7 photos)
│   ├── Rice/                            (19 photos)
│   ├── Prawn Mee/                       (in subfolder)
│   ├── Photos Standby/                  (subfolder)
│   └── 138 loose files (menu items with Chinese names in filenames)
│
├── Photo for standby use(2024 MENU) (1)/ <-- SMALL
│   └── Prawn Mee/10 (PORK SLICE)/      (9 photos of prawn mee with pork)
│
└── Product Photos (Use in menu 2024)/    <-- SUPPOSED TO BE FINALS
    └── DRAFT/                            (only 4 files!)
```

### Choon Key Products Identified:
- Prawn Mee (multiple variants)
- Dinner Rice Sets: Asam Curry Seafood, Chicken Feet + Taufo, Rendang Chicken, Rendang Pork Rib, Lor Pork Tail + Intestine
- Lobak
- Lor Cham Thng (Braised Mixed Soup)
- Prawn Mee Ramen
- KT Teng (901 series)
- Snacks: Stew Chicken Feet (406), Nyonya Acar (908), Taugeh Kerabu (911), Fried Seafood Taufu (914), Pandan Chicken (915), Fried Prawn Ball (916)
- Drinks: Blue Pea Flower Tea, Pat Bo Milk Tea Cincau
- Breakfast items (from menu photo)

### Choon Priority Actions:
1. **"Quality Edited (Confirm)"** folder = the 6 confirmed final dinner rice set photos
2. The 138 files in "standby" folder need sorting into: KEEP (1 best per item) vs ARCHIVE
3. Customer screenshots = social proof, not for Grab listing
4. XHS Marketing photos = separate use case
5. Need to apply same pipeline as Uncle Chua: crop, white bg, standardize

---

*Report generated by Grab Listing Optimizer audit pipeline*
*Next step: Run enhancement pipeline on Uncle Chua Phase 1 (quick wins)*
