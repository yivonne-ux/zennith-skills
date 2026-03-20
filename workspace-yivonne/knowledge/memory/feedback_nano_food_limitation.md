---
name: NANO does not preserve food photos exactly
description: NANO Banana Pro Edit treats input food photos as references, not pixel-perfect elements. It always regenerates its own version. For pixel-perfect real food, need PIL compositing architecture (generate scene without food, paste real photos in).
type: feedback
---

## NANO Food Photo Preservation Limitation (2026-03-13)

NANO Banana Pro Edit does NOT preserve input food photos exactly. Even with strong prompts like "SACRED PHOTOGRAPH", "EXACT photo", "UNTOUCHABLE" — NANO reinterprets the food and generates its own version. The food LOOKS like bentos with similar colors/compartments, but is never the exact input photo.

**Why:** NANO is an image EDITOR that treats all inputs as references for generation. It doesn't have a "paste this image exactly here" capability — it uses the input to understand what food should look like, then generates its own version.

**How to apply:**
- For ads where food is VISUAL CONTEXT (not hero): AI food is acceptable — design/copy/layout carries the ad
- For ads where food is the HERO: Need PIL compositing architecture — generate scene WITHOUT food zones, then paste real food photos programmatically
- Pipeline B from mirra workflow already has this concept: `_treat_food_photo()` → NANO multi-image with treated food anchored first
- Best results so far: single food item in simple scene (V10, V11, V22) where NANO creates a plausible bento. Worst: multi-food flat-lays (V03, V14) where NANO invents all food.
- The user specifically wants to SEE their real Mirra food photos recognizable in the ads
- **Key cn-ads-v4 learning:** When a concept requires "variety," let DESIGN tell the variety story (massive '不重复' typography + 50+ 料理 badge) rather than cramming multiple food photos that NANO will all reinterpret. Single food + strong type > multiple AI food.
- **Food angle must match scene:** Top-view bentos for overhead/flat-lay, side-view for table/editorial scenes. Mismatch = looks pasted-on.
