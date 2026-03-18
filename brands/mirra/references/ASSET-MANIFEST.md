# Mirra Asset Manifest
> Auto-generated 2026-03-06. Source: Tricia's Video Compiler + GAIA brand assets.

## Product Photos

### Top-View (products-flat/) — 8 images
Best for: static ads, carousels, thumbnails
- BBQ-Pita-Mushroom-Wrap-Bento-Box-Top-View.png
- Dry-Classic-Curry-Konjac-Noodle-Top-View.png
- Fierry-Buritto-Bowl-Top-View.png
- Fusilli-Bolognese-Bento-Box-Top-View.png
- Golden-Eryngii-Fragrant-Rice-Bento-Box-Top-View.png
- Japanese Curry Katsu Bento Box-Top View.png
- Konjac-Pad-Thai-Bento-Box-Top-View.png
- group image.jpg

### Portrait 720x1280 (products-portrait/) — 11 images
Best for: video ref_image (Sora image2video), Stories, Reels
- mirra_Dry Classic Curry Konjac Noodle_720x1280.jpg
- mirra_Japanese Curry Katsu Rice_720x1280.jpg
- mirra_Mapo Tofu Rice_720x1280.jpg
- mirra_Mei Cai Fried Rice_720x1280.jpg
- mirra_Taiwanese Braised Mushroom Rice_720x1280.jpg
- mirra_bowl_720x1280.jpg (generic bowl)
- mirra_bowl_Falafel Bowl rice_720x1280.jpg
- mirra_bowl_Fiery Burrito Bowl_720x1280.jpg
- mirra_bowl_Kimchi Fried Quinoa Rice_720x1280.jpg
- mirra_bowl_Sweet & Sour Hericium Rice_720x1280.jpg
- mirra_bowl_Sweet & Sour Seaweed Tofu Rice_720x1280.jpg

## Real KOL Footage (footage/mirra-kol/) — 57 clips
Source: Krissyaly V2 Portrait shoot
Symlinked from: ~/Downloads/Video Compiler/assets/footage/mirra/

### By AIDA Phase:
**Attention (A):** Hooks, reactions, social proof
- A3_Reaction_Positive_v1.mp4 — Creator smiling warmly (5s)
- A4_Reaction_SocialProof_v1.mp4 — Social proof compilation
- A5_Problem_* — 20+ problem scenario clips (BlandDiet, Bloat, Confession, NoTimeToCook, WeightGain)
- A5_Reaction_Hook_v1.mp4 — Direct-to-camera hook (3s)

**Interest (I):** Behind scenes, ingredients
- I1_Dish_KitchenPrep_v1.mp4 — Kitchen prep (5s)
- I3_Ingredient_FreshPrep_v1.mp4 — Fresh ingredients close-up

**Desire (D):** Dish showcase, reactions, unboxing
- D1_Dish_* — Dish showcase clips (BlandDiet, NoTimeToCook, WeightGain)
- D1_Reaction_* — 16 reaction clips (Bloat, Empowerment, General, NoTimeToCook, Surprise, WeightGain)
- D3_Unbox_ProductReveal_v1.mp4 — Product reveal unboxing (4s)

**Action (Act):** End cards, promos
- Act6_Promo_EndCard_v1.mp4 — CTA end card

### Clip Index
Full metadata: `footage/clip-index.json`
Each clip has: id, type, label, duration, tags, description, aida_phase, block_code, category, subtype, version

## Block Schema
- `block-schema.json` — Universal AIDA taxonomy (A1-A6, I1-I5, D1-D6, Act1-Act6)
- `mirra-block-schema.json` — Mirra-specific categories (Dish, Ingredient, Reaction, Problem, Promo, Gift, Unbox) + subtypes

## Generation Learnings
`footage/generation-learnings.json` — 22 corrections from real production runs:
- Silent audio fix: "With audio." prefix + audio priority footer
- No food descriptions when using ref_image
- Spoon for rice (not chopsticks) — Malaysian standard
- Malaysian English/华语 dialect rules
- One continuous shot for 12s — no scene cuts
- No zoom (AI tell)
- Framing progression timestamps, not camera movements
