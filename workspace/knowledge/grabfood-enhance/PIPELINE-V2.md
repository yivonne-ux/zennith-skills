# GrabFood Enhancement Pipeline V2 — Reference-Driven
> The correct flow. Pinterest reference IN → world-class output OUT.

---

## THE CORRECT FLOW

```
STEP 1: MATCH REFERENCE
  Input photo → identify dish type → select Pinterest reference that matches
  Reference = the VISUAL STANDARD that NANO aims for

STEP 2: ENHANCE TO REFERENCE LEVEL (NANO)
  Image 1 = Pinterest reference (the target quality)
  Image 2 = original food photo (the content to preserve)
  Prompt: "Enhance Image 2 to match the quality, lighting, and sophistication
           of Image 1. Keep the FOOD from Image 2 exactly. Adopt the lighting,
           color warmth, plate styling, and overall mood from Image 1."
  → Output: food photo at Pinterest quality level, original background still present

STEP 3: BACKGROUND TO WHITE (NANO second pass)
  Image 1 = enhanced photo from Step 2
  Prompt: "Change background to clean warm white. Keep food and plate EXACTLY.
           Add soft natural drop shadow. Warm off-white (248,246,240)."
  → Output: same enhanced food, now on white background

STEP 4: POST-PROCESS (PIL)
  - Adaptive color grade (based on analysis)
  - Subtle film grain (luminosity-dependent)
  - Export to GrabFood sizes (800x800 + 1350x750)

STEP 5: STORE CONSISTENCY CHECK
  - Compare color temperature across all store photos
  - Ensure same lighting angle, warmth, shadow direction
  - Ensure same background white (no yellow/blue drift)
```

---

## WHY REFERENCE-DRIVEN

Without reference: NANO does generic "make it nicer" → mediocre, inconsistent
With reference: NANO has a VISUAL TARGET → copies the lighting, mood, sophistication

Same principle as Pinxin ads: reference = output structure.
The reference IS the quality standard. Without it, there is no standard.

---

## STORE CONSISTENCY

All photos in one store must look like they were shot in the SAME session:
- Same lighting direction (upper-left, soft diffused)
- Same color temperature (warm, 5500-6000K feel)
- Same background (warm white 248,246,240)
- Same plate style aesthetic (if NANO upgrades plates)
- Same shadow direction and softness
- Same grain amount and warmth

This is achieved by:
1. Using the SAME set of references for all photos in one store
2. Using the SAME NANO prompt template (only dish-type varies)
3. Using the SAME PIL post-processing settings
4. Running a consistency check at the end that compares color histograms

---

## REFERENCE CATEGORIES

```
references/
├── noodle/          ← wonton mee, pan mee, char kuey teow, laksa
├── rice/            ← nasi lemak, chicken rice, economy rice
├── soup/            ← BKT, wonton soup, tom yum
├── fried/           ← fried chicken, spring rolls, goreng
├── curry/           ← rendang, curry chicken, dal
├── dimsum/          ← siu mai, har gow, bao
├── dessert/         ← cendol, ais kacang, kuih
└── drink/           ← teh tarik, coffee, juice
```

Each category has 2-3 Pinterest-level references. When processing a photo,
the pipeline selects the reference that best matches the dish type.
