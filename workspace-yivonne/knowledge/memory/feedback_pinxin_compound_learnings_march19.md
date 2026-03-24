---
name: Pinxin Compound Learnings — All production mistakes consolidated
description: Every production mistake from Week 2 batch consolidated. NEVER repeat. Check BEFORE every production run. Compound learning — stop needing reminders.
type: feedback
---

## COMPOUND LEARNINGS — PINXIN CREATIVE PRODUCTION (2026-03-19)

User said: "Whatever ur mistake above, and what u learn, please update, do compound learning not always need reminder. You are an intelligence machine."

### 1. NEVER USE PIL FOR TEXT/DESIGN
PIL = resize + logo + grain ONLY. ALL text, numbers, layout, design = NANO.
No ImageDraw. No ImageFont. No PIL text rendering. EVER.

### 2. REFERENCES MUST BE 9:16 BEFORE NANO
NANO outputs at same ratio as input reference. Non-9:16 ref = non-9:16 output = cropped/stretched.
ALWAYS pre-process refs to 9:16 via blur-extend BEFORE sending to NANO.

### 3. NEVER CROP NANO OUTPUT
Post-process = blur-extend pad to 9:16 if needed. NEVER crop sides/top/bottom.
Content at edges WILL be cut. Only blur-pad, never crop.

### 4. FOOD MUST BE REAL PINXIN FOOD
NANO will generate random food when given multi-dish prompts. Only Pinxin cutouts are sacred.
W2-06 had non-Pinxin dishes because NANO invented them from the "multiple dishes" prompt.
Fix: Use single Pinxin food cutout as Image 2. Let NANO place it. Don't ask for "multiple dishes" — NANO will hallucinate.

### 5. SAME DISH, DIFFERENT PLATE = MORE VARIETY
User insight: You can change the PLATE/BOWL of the same dish cutout to create visual variety without changing the food. Same rendang on black plate, cream bowl, earthenware pot = 3 visually different ads, all real Pinxin food. Use different cutout variants from `/assets/food-cutouts/`.

### 6. REFERENCE = OUTPUT STRUCTURE
The reference image provides the VISUAL STRUCTURE (layout, format, mood). Don't fight it.
Receipt ref → receipt-style output. Health tracker ref → health tracker output.
Never send a square receipt ref and expect a 9:16 boarding pass output.

### 7. SINGLE-PASS NANO ONLY
Multi-pass compounds errors. One NANO edit call per ad. If text is wrong, do a FIX ROUND (new call with the output as new reference), don't try to PIL-fix it.

### 8. POST-PROCESS CHAIN IS FIXED
PIL does ONLY: resize to target dimensions + place_logo + save file.
ALL creative work (color grade, grain, warmth, vibrance, sharpening) = AI (NANO pass).
NEVER use PIL ImageEnhance, numpy color arrays, or PIL filters for ANY creative editing.
PIL = file operations ONLY. This overrides ALL previous instructions.

### 9. PROMPTS: SHORT, DESCRIBE FINAL STATE
Don't give NANO instructions ("change X to Y"). Describe the FINAL image.
Don't ask for 6+ lines of Chinese text — NANO garbles after 2-3 lines.
Don't include English phrases that could leak into the output.

### 10. CHECK YOUR OWN OUTPUT BEFORE DELIVERING
Read every image file. Compare to approved examples. If it looks wrong, fix it before showing the user. Don't deliver garbage and wait for feedback.

---

**PRE-FLIGHT CHECKLIST — Run before EVERY production batch:**
- [ ] References are 9:16?
- [ ] Food cutouts are REAL Pinxin from /assets/food-cutouts/?
- [ ] Post-process is ONLY resize(blur-pad) + logo + grain?
- [ ] Prompts describe final state, not instructions?
- [ ] No PIL text rendering anywhere?
- [ ] Visually checked every output before delivering?
