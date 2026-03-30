---
name: Pinxin Social Post Production — W1 Learnings (YES and NO)
description: CRITICAL. Social posts vs ads pipeline differences. Egg/non-vegan violations. Illustration reference rules. Apply to ALL future social media production.
type: feedback
---

## SOCIAL POST PRODUCTION — W1 COMPOUND LEARNINGS (27 March 2026)

### ✅ YES — What Worked

1. **PX-W1-01 (Hari Raya)** — PASS. Dark PX Green bg, gold frame with ketupat corners, crescent moon, rendang hero centered, bilingual CN+Malay text. Mood ref `mood-nanhotpot-green-gold.jpg` as Image 1 = correct color anchor.

2. **PX-W1-04 (Carousel S1)** — PASS. Bold CN typography on PX Green bg, lion's mane mushroom illustrations. On brand.

3. **PX-W1-06 (Frozen to Fab)** — PASS. Before/after split. Real BKT packaging on left, plated BKT on right. Good concept execution.

4. **Single hero dish + mood ref = reliable** — Same proven pattern from W3 ads batch works for social posts too.

5. **4:5 (1080x1350) is correct for social feed posts** — IG/FB feed standard in 2026. No 9:16 extension needed.

### ❌ NO — What Failed

1. **NEVER generate social posts at 9:16** — Social feed posts = 4:5 (1080x1350). The 9:16 extension (1080x1920) is ONLY for ads with Stories/Reels placements. First PX-W1-01 was wrongly generated at 9:16 with blur-pad extension.

2. **NANO generates EGGS by default** — PX-W1-03 (comic panel 4), PX-W1-05 (quote illustration), PX-W1-07 (Qingming family table) ALL had fried eggs. NANO's training data defaults to generic Chinese food which includes eggs. Pinxin is 100% VEGAN — ZERO eggs, ZERO non-vegan food. Must explicitly state "ZERO EGGS. This is a 100% vegan/plant-based brand. No eggs, no dairy, no animal products visible anywhere." in EVERY prompt.

3. **PX-W1-02 (Green Curry) = reference bleed-through** — Ghost CN text bleeding through behind the title. Looked like words slapped on the mood reference photo, not a designed post. Need stronger layout transformation, not just text overlay.

4. **PX-W1-03 (Comic) panel 2 = random handshake** — Doesn't match the script. NANO hallucinated an irrelevant gesture.

5. **PX-W1-05 (Quote) = no PX food reference used** — Illustrated generic non-vegan food (with egg!) instead of Pinxin dishes. Must use PX food cutout as Image 2 even for illustration posts to anchor NANO to real PX food.

6. **PX-W1-07 (Qingming) = all wrong food** — Dumplings, egg, generic meat dishes. None are PX products. Family illustration was warm but food on table must be recognizable PX dishes.

7. **Illustration posts need style reference** — Without explicit illustration reference as Image 1, NANO defaults to generic styles. Must use locked illustration refs from `04_references/social-media-refs/comics-illustration/_LOCKED/`.

### 🔧 PRODUCTION RULES — Social Posts (Enforced)

| Rule | Detail |
|------|--------|
| **Format** | 4:5 (1080×1350) for IG/FB feed. NO 9:16 extension. |
| **Pipeline** | Single NANO pass at 4:5 → PIL resize → logo → grain. No two-pass. |
| **Vegan gate** | EVERY prompt: "ZERO EGGS. 100% vegan. No eggs, dairy, meat, animal products." |
| **Food anchor** | Even illustration posts MUST use PX food cutout as reference image. |
| **Illustration ref** | Use locked refs from `_LOCKED/` dir as Image 1 for illustration posts. |
| **Text overlay** | NANO must DESIGN the layout, not just overlay text on a reference photo. |
| **Logo** | Ginkgo emblem top-right, y=30 (not y=300 which was for 9:16 offset). |

### 📋 SOCIAL vs ADS — Key Differences

| Aspect | Social Posts | Ads |
|--------|------------|-----|
| **Dimensions** | 1080×1350 (4:5) | 1080×1920 (9:16) for Stories/Reels |
| **Pipeline** | Single NANO pass → logo → grain | Two-pass: 4:5 → extend → 9:16 → logo → grain |
| **Safe zone** | Full 4:5 = visible | Top 14% + bottom 20% = overlays |
| **Logo Y** | y=30 (top-right) | y=300 (below 9:16 top padding) |
| **Promo text** | Optional, organic feel | Required (买8送8, pricing, CTA) |

### 📁 ILLUSTRATION REFERENCES (Survived cleanup)
Located: `~/Desktop/_WORK/pinxin/04_references/social-media-refs/comics-illustration/_LOCKED/`
Style: Semi-realistic, warm tones, clean flat illustration with soft gradients. NOT anime. NOT cartoon. Warm, editorial, lifestyle illustration.
Key ref: `pinterest_641763015692323361_1536045964.jpg` — warm tones, clean illustration, lifestyle feel.
