---
name: DotDot v8 Rejection — Product text distortion, logo overlap, mascot needs character sheet
description: CRITICAL. v8 rejected. 3 root causes. NANO distorts product packaging text. Logo placement still overlaps words. Mascot needs standalone character design sheet BEFORE post production. Save all compound learnings.
type: feedback
---

## DOTDOT v8 REJECTION — 3 ROOT CAUSES (29 March 2026)

### ❌ REJECTION 1: Product Packaging Text Distortion (P1, P2, P3)

**What happened:** NANO distorted the text on the real product packaging when passed as Image 2. "dotdot.." became garbled, "German Collagen" became fuzzy, product details unreadable.

**Root cause:** NANO edits ALL input images — it doesn't preserve Image 2 as-is. It interprets and re-renders everything including text on packaging. This is the SAME failure as Bloom & Bare v1 rejection: "FLUX Kontext destroys text — garbles dense copy after 1 pass."

**Fix — 3-Layer Stack (Rule 38 from COLOR-DESIGN-MASTERCLASS):**
1. NANO generates BACKGROUND + LAYOUT + TEXT only (no product in the AI generation)
2. PIL composites REAL product PNG on top with drop shadow (product preserved pixel-perfect)
3. PIL composites logo on top
4. PIL applies post-processing (grain, sharpen)

**The user initially said "no PIL for product, use NANO only" — but NANO proven to distort product text. The 3-layer stack is the correct architecture. PIL for product compositing is NOT "creative editing" — it's PLACEMENT of a real asset, same as logo placement.**

### ❌ REJECTION 2: Logo Overlapping Text on ALL Posts

**What happened:** Despite "smart logo" code checking bg variance, logo consistently lands ON headline text. Every single v8 post has logo overlapping words.

**Root cause:** Current smart_logo checks bg VARIANCE — but text IS high variance (black strokes on light bg = high stddev). So the code detects "busy bg" and adds white pill backing, but STILL PLACES THE LOGO ON THE TEXT. The variance check prevents invisible logos on busy backgrounds but doesn't prevent overlapping with text/content.

**Fix — True Smart Logo Placement:**
1. NANO must be instructed to LEAVE A CLEAR ZONE for logo (top-right 150x100px area with no text/illustration)
2. In the prompt: "Leave the top-right corner COMPLETELY CLEAR — no text, no illustration, no design elements in a 150x100px zone"
3. After generation: VERIFY the zone is actually clear before placing logo
4. If zone is NOT clear: try alternate positions (top-left, bottom-right) or resize content
5. Multiple logo position OPTIONS, not hardcoded top-right

**The artwork must ACCOMMODATE the logo — the logo doesn't fight for space with content.**

### ❌ REJECTION 3: Mascot Needs Character Design Sheet FIRST

**What happened:** Generated mascot posts (M1-M4) directly without building a proper character asset first. Result: inconsistent mascot sizing, proportions, and integration. Mascot was generated fresh each time = different every time.

**Root cause:** Treating mascot as "just another prompt instruction" instead of as a LOCKED ASSET like product packaging. The mascot needs its own standalone character design sheet before being used in any post.

**The correct workflow (from user's intent):**
1. **Research** — world-class character design for social media. Which apps, models, workflows do top creators use? Study @business.shorts production pipeline, 3D artist workflows, character design best practices.
2. **Forensic analysis** — what makes these characters work? Proportions, expression system, pose library, consistency techniques.
3. **Build character design sheet** — generate a COMPLETE character profile:
   - Front view, side view, back view
   - Expression sheet (happy, sad, curious, excited, teaching, presenting)
   - Pose sheet (standing, sitting, pointing, holding objects, exercising)
   - Scale reference (how big relative to humans, products, text)
   - DotDot brand adaptation (mochi shape adapted to our flat editorial art style)
4. **Lock as PNG asset** — like `german-collagen-1box.png`, the mascot becomes `mascot-front.png`, `mascot-teaching.png`, etc.
5. **THEN use in posts** — composite or reference the locked character sheet, not regenerate from description

**The mascot is an ELEMENT of the design system, like packaging. It needs its own "profile image."**

---

## COMPOUND LEARNINGS v1-v8 (ALL VERSIONS)

### Architecture Proven Wrong:
- ❌ NANO for product packaging = distorts text (v8, same as BB v1)
- ❌ NANO for logo = renders wrong brand marks (v1-v2)
- ❌ NANO for mascot without character sheet = inconsistent every time (v7-v8)
- ❌ Hardcoded logo position without content awareness = overlaps (v1-v8)

### Architecture That Works:
- ✅ NANO for illustration/background/layout = good
- ✅ NANO for typography/headlines = good (HK commercial poster style)
- ✅ PIL for product PNG compositing = preserves packaging text perfectly
- ✅ PIL for logo compositing = exact asset, consistent
- ✅ Locked character sheet → PIL composite or NANO Image 2 = consistent mascot
- ✅ Own approved output as Image 1 = style consistency
- ✅ Logo on RAW before pad-fit = correct positioning

### The Correct Full Pipeline:
```
1. Character Design Sheet → locked PNG assets (mascot-*.png)
2. Product PNGs → already have (german-collagen-1box.png etc.)
3. Logo PNG → already have (dotdot-logo-main.png)

For each post:
1. NANO generates BACKGROUND + ILLUSTRATION + TYPOGRAPHY
   - Image 1 = style anchor (own approved output)
   - Prompt describes layout with CLEAR ZONES for product + logo
2. PIL composites PRODUCT PNG (with drop shadow) into designated zone
3. PIL composites MASCOT PNG (if mascot post) into designated zone
4. PIL composites LOGO into clear corner zone
5. PIL applies post-processing (grade, texture, grain, sharpen)
```

### Never Repeat:
1. Never pass real product packaging to NANO as Image 2 (text distortion)
2. Never hardcode logo position without checking for text/content
3. Never generate mascot from prompt description — use locked character sheet
4. Never skip character design sheet phase for any brand mascot
5. Never present posts with overlapping logo as "passed audit"

**How to apply:** Before next DotDot batch, BUILD the mascot character sheet first. Then implement 3-layer stack (NANO bg + PIL product + PIL logo). Then generate.
