---
name: Reference Classification System — 4 Purpose Types
description: CRITICAL. Every reference must be classified by PURPOSE before use. Format, Aesthetic, Content, Food — each serves a different role in the pipeline. ALL brands.
type: feedback
---

## REFERENCE CLASSIFICATION — 4 PURPOSES

Every reference image used in production must be classified by its PURPOSE. Different purposes = different roles in the pipeline.

### 1. FORMAT REF (layout/structure)
- **What it provides:** Panel count, composition, split layout, comparison structure
- **Sources:** Pinterest, IG, TikTok screenshots, viral posts
- **How to use:** Describe the layout in PROMPT TEXT only. NEVER pass as Image 1 (NANO copies the style of Image 1, not just the layout)
- **Example:** A 3-panel comic ref → describe "3 panels, top-middle-bottom, each 33% height" in text

### 2. AESTHETIC REF (mood/style/texture)
- **What it provides:** Color treatment, texture, atmosphere, "vibe", design aesthetic
- **Sources:** User's Pinterest mood boards, design inspiration sites
- **How to use:** Pass as Image 1 (NANO's style anchor). The output will LOOK like this ref.
- **Example:** Mirra's pink glitter sushi pin → Image 1 → output gets the pink sparkle food photography treatment
- **Key rule:** AESTHETIC ref controls HOW it looks. PROMPT controls WHAT it shows.

### 3. CONTENT REF (viral quote/copy)
- **What it provides:** The actual text/quote that goes on the post
- **Sources:** IG viral accounts (@mytherapistsays, @betches, etc.), tweets, Pinterest viral text posts
- **How to use:** Extract the TEXT from the ref. Place it in the prompt as quoted copy. Never pass the image itself.
- **Example:** @mytherapistsays post "your boss will be the stress in the times" → extract text → put in prompt
- **Key rule:** COPY not imagine. Every quote must come from a proven viral post.

### 4. FOOD REF (sacred product photos)
- **What it provides:** Real Mirra bento photos
- **Sources:** ONLY from `01_assets/photos/food-library/`
- **How to use:** Pass as Image 2+ (after aesthetic ref). SACRED — never AI-generate.
- **Key rule:** Enhance with PIL before upload (brightness +12%, color +8%, contrast +5%, sharpness +15%)

### DUAL-REFERENCE ARCHITECTURE
```
Image 1 = AESTHETIC REF (Pinterest mood board pin)
    ↓ controls HOW it looks (background, styling, mood)
Prompt = FORMAT DESCRIPTION (from format ref) + CONTENT TEXT (from viral ref)
    ↓ controls WHAT it shows
Image 2+ = FOOD REFS (sacred enhanced bento photos)
    ↓ placed exactly as provided — NEVER modified
```

### CRITICAL: AESTHETIC REF vs FOOD POST SEPARATION
- For FOOD POSTS: the aesthetic ref must influence BACKGROUND/LABELS/TYPOGRAPHY ONLY
- **NEVER use a "luxe food" ref (jewel toast, pearl pizza, glitter sushi) as Image 1 for food posts**
  — NANO will apply the bling/gems/pearls TO the Mirra bento, destroying the sacred photo
- For food posts: use a BACKGROUND/MOOD ref as Image 1 (pink gradient, warm bokeh, etc.)
- The prompt must explicitly say: "Image 2 is the SACRED food photo — place it EXACTLY as provided, do NOT modify the food"
- Good food aesthetic refs: B2-27 pink-lavender gradient, B2-12 elegant serif + sparkle bg
- Bad food aesthetic refs: jewel toast, pearl pizza, glitter sushi (adds bling ON food)

**v4 lesson:** Luxe food pins from user's board are INSPIRATION for the brand world, NOT literal Image 1 refs for food posts. They show the ATTITUDE (food = luxe = queen energy) but the EXECUTION must keep real Mirra bentos untouched.

### PINTEREST AS MULTI-PURPOSE SOURCE
Pinterest pins can serve as FORMAT, AESTHETIC, or CONTENT refs depending on the pin:
- A cinema marquee pin with sparkle overlay → AESTHETIC ref (style anchor)
- A 3-panel comic on Pinterest → FORMAT ref (describe layout in text)
- A viral quote card on Pinterest → CONTENT ref (extract the text)
- Some pins serve DUAL purpose (format + aesthetic) — classify the PRIMARY purpose

**Why:** User feedback March 29: "we have diff purpose for each reference." The old pipeline used refs without classifying purpose, leading to wrong style transfer.
**How to apply:** Before using any reference, classify its purpose. Use in the correct pipeline position based on classification.
