---
name: NANO anti-patterns — things that ALWAYS fail
description: Comprehensive list of mistakes from cn-ads-v4 (4 fix rounds, 24 variants). Every item here was tried, failed, and cost a fix round. Never repeat these.
type: feedback
---

## NANO Anti-Patterns — NEVER DO THESE (2026-03-13)

### 1. Never generate full AI humans in lifestyle scenes
NANO humans in scenes = 100% obviously AI. User: "confirm 100% can tell its AI generated."
Fix: Remove human, let scene + copy carry emotion. Empty seat > fake face.
Partial humans (hands holding product) OK. Edit-first on existing human photos OK.

### 2. Never shrink typography to fit more food
Smaller type = looks cheap. User rejected V03 fix4 ('午后限定' at 30% canvas) but loved fix5 ('不重复' at 50%+). The massive type IS the premium feel. Food is secondary.
Fix: Type-driven concepts = characters at 50-60% canvas height MINIMUM.

### 3. Never apply blanket rules to all variants
User corrected: "this is NOT a rule for all ads, only the ones i picked, and you need to analyse the reason behind it." Blindly adding badges/CTA/price to every variant = wrong.
Fix: Analyze WHY each variant needs what it needs. TOFU = vibe-first. BOFU = commerce. Concept = story-first.

### 4. Never blank out real product sticker text
Telling NANO to render packaging sticker as a blank color block (no text) = looks fake. User: "mirra bento with sticker but no words on the sticker."
Fix: Preserve packaging photos EXACTLY. Branded sticker text is product photography, not added design text.

### 5. Never put English text in NANO prompts that could leak
"Afternoon Special" appeared in V03 fix4 output — NANO rendered it as visible text because it was in the prompt.
Fix: ONLY put Chinese copy in single quotes. Never write English phrases that could be rendered. Use description language ("small text showing the price") not literal English strings.

### 6. Never over-correct by rearranging a layout the user liked
V13 fix3 rearranged the fix2 layout to fix sticker color — user preferred the original layout.
Fix: When fixing ONE thing, keep EVERYTHING ELSE the same. Surgical fixes, not redesigns.

### 7. Never use multiple food items when NANO can't preserve them
Multi-food layouts = ALL AI food. NANO reinterprets every food photo it receives.
Fix: Single food + strong composition > multiple AI-reinterpreted foods. Let DESIGN (typography, layout) tell the variety story, not many food photos.

### 8. Never use wrong image type in code (bento vs food)
`("bento", ...)` resolves from FOOD_BENTO_DIR (drive-full/). `("food", ...)` resolves from original FOOD_DIR with fuzzy matching. Using wrong type = FileNotFoundError.
Fix: Check which directory the file lives in. Bento box top-view photos = "bento". Original dish photos (no "Bento Box" in name) = "food".

### 9. Never use diff/swap language with NANO
NANO is edit-first. "Change X to Y" and "swap X with Y" confuse it.
Fix: Describe the FINAL STATE. "The headline reads '不重复' in massive bold Chinese" — not "change the Japanese text to Chinese."

### 10. Never let NANO invent dish names or calorie numbers
NANO generates fake dish names ("经典煎饺套餐") and wrong calorie counts.
Fix: Always include "DO NOT invent dish names or calorie numbers unless in single quotes" in the FOOD safety layer.

### 11. Never use yen prices or foreign currency from reference
NANO copies "770円" or "150元" from Japanese references into the output.
Fix: Explicitly say "Remove ALL original Japanese text, brand marks, yen prices" and specify the correct price in Chinese: '从RM19起'.

### 12. Never generate food at wrong angle for the composition
Top-view bentos in a side-angle scene (or vice versa) = looks pasted-on.
Fix: Match food angle to scene — overhead/flat-lay compositions use top-view bento photos, editorial/table scenes use side-view bento photos.

### 13. Never assume NANO will follow "all unique" for repeated elements
V09 reviews: '推荐给全office了' appeared twice despite "ALL UNIQUE, no repeats" instruction. NANO doesn't reliably deduplicate.
Fix: Accept this as a NANO limitation. For critical dedup, need post-processing text detection or PIL compositing.

### 14. Never use hex codes, pixel values, or font names in prompts
NANO renders them as visible text. "#F5F0E8" or "120px" or "DX Lactos" will appear in the output.
Fix: Use natural language only. "warm cream" not "#F5F0E8". "large" not "120px". "bold editorial serif" not "DX Lactos".
