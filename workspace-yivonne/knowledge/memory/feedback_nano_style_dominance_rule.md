---
name: NANO Style Dominance Rule
description: Image 1 dominates art style in NANO edit. Format refs as images bleed their style. Describe layout in text only. Brand-agnostic.
type: feedback
---

## NANO STYLE DOMINANCE — CRITICAL RULE

**Image 1 controls the art style.** Whatever image you pass as Image 1, NANO will copy its rendering style — regardless of what the prompt says.

### THE MISTAKE (v1-v5 iterations proved this)
- Passing **scraped viral post** as Image 1 (format ref) + **brand artwork** as Image 2 (style ref)
- Result: NANO copies the SCRAPED POST's style (ink wash, sketchy, etc.) and ignores the brand artwork
- Every batch had wrong art style because Image 1 dominated

### THE FIX (proven on F02-test-style-fix)
- **Image 1 = brand's OWN artwork** (the richest, most polished illustration)
- **Image 2 = NOT USED** (or second brand artwork if needed)
- **Viral format/layout = described in PROMPT TEXT only** (not as image input)
- Result: NANO renders in the brand's art style, with the layout controlled by text description

### WHY IT WORKS
NANO edit uses Image 1 as the primary style anchor. The prompt controls CONTENT (what to draw). So:
- Image 1 → HOW it looks (rendering, color, texture, brushwork)
- Prompt → WHAT it shows (layout, poses, text, composition)

### RULE
**NEVER pass a non-brand image as Image 1 if you want brand-consistent art style.**
Format/layout references are for YOUR understanding only — describe them in text, don't feed them to NANO.

### ADDITIONAL FINDINGS (v5 regression)
- Using `"resolution": "2K"` in NANO call CHANGES the output style — don't add unless the original formula used it
- Using pinterest poster art as Image 1 → output became too painterly/realistic
- Using approved brand OUTPUT (not asset) as Image 1 → most consistent results
- The approved charV output (PX-W1-03-charV.png) worked better than the raw vector character sheet alone
- TWO refs (approved output + character sheet) = best combo. One ref alone = less consistent.

### EYES ARE THE CANARY
- If eyes come out realistic/detailed/large → the entire art style has drifted
- Correct PX eyes: soft curves, often closed, simplified
- Add explicit eye instructions to prompt: "eyes are stylized soft curves, often closed or half-closed"
- If character looks 20 instead of 40 → eyes are too large/detailed

**How to apply:** Before any NANO generation, check: Is Image 1 the brand's own artwork? If not, the output will look wrong. ALL brands.
