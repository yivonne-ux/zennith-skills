---
name: Food Audit — Pixel-match against real cutouts, not "looks like food"
description: CRITICAL AUDIT RULE — every food in every output must be verifiable against the EXACT real cutout photo. NANO remixes food into generic dishes. Applies to ALL brands.
type: feedback
---

**CRITICAL AUDIT FAILURE (March 24, 2026 — W3 batch):**

My audit said "food looks recognizable" for W3-RT-01, RT-03, and WA-02. The user caught that the food was NOT real Pinxin — NANO had remixed the cutouts into generic-looking Asian food.

**The problem:** NANO takes food cutout images as input but often:
1. Remixes them into generic-looking dishes
2. Changes plating, proportions, and distinctive features
3. Removes signature visual markers (petai beans, purple eggplant, lemongrass)
4. Creates "close enough" food that isn't actually the real product

**How to audit food correctly — PIXEL-MATCH method:**

For EVERY dish visible in the output, verify it matches the source cutout by checking:

| Dish | Signature markers (MUST be visible) |
|------|-------------------------------------|
| Rendang | Golden-brown chunks, red chilli, scallions, white scalloped plate |
| BKT | Clay pot, tofu puffs, mushrooms, wolfberries, clear/dark broth |
| Classic Curry | Yellow-brown curry sauce, potato/mushroom chunks |
| Sambal Petai | **GREEN PETAI BEANS** (most distinctive — if no green beans, it's not sambal) |
| Spicy Asam | **Red sauce, okra, mint leaves, fish-shaped pieces** on white oval plate |
| Green Curry | **PURPLE EGGPLANT**, green peas, green curry sauce, carrot |
| Black Vinegar | **Dark black sauce**, peanuts, black fungus, cilantro |
| Namyu Tofu | Brown sauce, tofu slices, **cucumber garnish**, blue-pattern plate |

If ANY signature marker is missing → the food was AI-remixed → REJECT and regenerate.

**The correct audit question is NOT:** "Does this look like food?"
**The correct audit question IS:** "Can I identify the EXACT Pinxin dish by its signature markers?"

**How to apply — add to every production audit:**
1. Open each output image
2. For each visible dish, identify which Pinxin product it's supposed to be
3. Check for signature markers from the table above
4. If markers missing → flag as "AI-remixed food" → REGENERATE
5. Compare side-by-side with the actual cutout photo if uncertain

**This applies to ALL brands.** Every brand has sacred real food photos. AI will always try to "improve" or remix them. The audit must catch this.

**Root cause:** NANO doesn't preserve input food images faithfully — it uses them as inspiration and generates "similar" food. This is a known limitation. The fix is strict visual audit, not better prompting.
