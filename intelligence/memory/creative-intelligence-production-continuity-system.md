---
name: Production continuity system — multi-agent pre-generation workflow
description: Multi-check system for video production. Director/Art Director/Wardrobe/QC agents. Scene spec sheets. Continuity verification BEFORE generation. Prevents outfit mismatches, setting errors, story breaks. Apply to ALL video production.
type: feedback
---

## THE SYSTEM: 4 Agents Working Simultaneously

Every scene goes through 4 checks BEFORE any image is generated. Not after. BEFORE.

### Agent 1: DIRECTOR (Story & Continuity)
**Owns:** Script, scene order, story logic, timeline

Before generating, DIRECTOR checks:
- [ ] What scene comes BEFORE this one? Does this scene connect?
- [ ] What scene comes AFTER? Does it lead into it?
- [ ] What TIME OF DAY is this? (morning/commute/work/lunch/evening)
- [ ] Is this the SAME DAY as adjacent scenes? Or a different day?
- [ ] Does the ACTION make sense? (she can't be eating at her desk if previous scene shows her in the car)
- [ ] What's the STORY PURPOSE of this shot? (hook/transition/payoff/montage)

**DIRECTOR outputs:** A scene context card:
```
SCENE: 05_work
BEFORE: 04_enter (she just walked into co-working)
AFTER: 06_bento1 (lunch montage starts)
TIME: 10:00 AM (mid-morning)
DAY: Same day as scenes 03-11
PURPOSE: Show her working — establish routine before lunch payoff
CONTINUITY: Same black outfit as driving/entering. Same co-working space.
```

### Agent 2: ART DIRECTOR (Mood & Reference)
**Owns:** Visual consistency, reference matching, what to copy vs what to change

Before generating, ART DIRECTOR checks:
- [ ] Which reference image defines the ANGLE for this shot?
- [ ] What from the reference do we KEEP? (angle, composition, camera distance)
- [ ] What from the reference do we CHANGE? (person, outfit, background, props)
- [ ] Does the MOOD match the overall video? (warm cream-blush throughout)
- [ ] Is this shot visually DIFFERENT enough from the previous shot? (variety)
- [ ] iPhone camera quality? Or tripod? Or POV?

**ART DIRECTOR outputs:** A reference adaptation spec:
```
SCENE: 05_work
REFERENCE: IMG_2841
KEEP: Angle (3/4 view at desk), composition (laptop centered), natural window light
CHANGE: Person → our character (v3), outfit → black top + dark trousers, background → co-working (not home office)
MOOD: Warm cream-blush (pin_07_02 baseline)
CAMERA: Tripod side angle (not selfie)
```

### Agent 3: WARDROBE (Outfit Continuity)
**Owns:** What she wears in EVERY scene, consistency across scene blocks

The wardrobe map:
```
SCENE BLOCK 1 (HOME MORNING): cropped white tee + high waist denim shorts
  - 01_scale (feet only — socks)
  - 02_morning (getting ready — home outfit)
  - 02b_outfit (changed to work outfit — TRANSITION SCENE)
  - 02c_coffee (work outfit ON — about to leave)

SCENE BLOCK 2 (COMMUTE + WORK): black square-neck top + dark grey wide trousers + bag
  - 03_drive (black outfit + bag on passenger seat)
  - 04_enter (black outfit + bag in hand)
  - 05_work (black outfit, sleeves may be pushed up)
  - 06-10_bento (NO PERSON VISIBLE — just food on table, no hands)
  - 11_eating (black outfit — eating at co-working dining area)

SCENE BLOCK 3 (HOME RESULT): cropped white tee + denim shorts (same as morning)
  - 12_mirror_result (home outfit — the weight loss payoff)
```

Before generating, WARDROBE checks:
- [ ] What outfit should she wear in THIS scene?
- [ ] Is it the SAME as the previous scene in this block?
- [ ] If outfit changes, is there a TRANSITION SCENE showing the change?
- [ ] Are accessories consistent? (same bag, same jewelry)

### Agent 4: QC (Post-Generation Audit)
**Owns:** Checking every generated image against ALL specs before approving

After generation, QC checks:
- [ ] Does the PERSON match the character lock? (face, hair, build)
- [ ] Does the OUTFIT match the wardrobe spec for this scene?
- [ ] Does the SETTING match the location spec?
- [ ] Does the ANGLE match the reference?
- [ ] Does the MOOD match (warm cream-blush)?
- [ ] Are there AI artifacts? (phone UI, timestamps, extra limbs, wrong props)
- [ ] Does it look like an iPhone shot? (not DSLR, not stock)
- [ ] Is it CONSISTENT with the previous scene?
- [ ] Would this pass as a frame from a real vlog?

**QC outputs:** PASS or FAIL with specific reason
```
SCENE: 05_work — FAIL
REASON: Wearing beige blazer, should be black top per wardrobe spec
ACTION: Regenerate with "black square-neck top" explicitly in prompt
```

---

## STORYBOARD-FIRST WORKFLOW

### Why storyboard before generating?
Every token spent on a wrong generation is wasted. A storyboard catches issues BEFORE generation. Professional productions storyboard before shooting. We should too.

### Step 0: BUILD STORYBOARD (before ANY generation)

For each scene, create a STORYBOARD CARD:
```markdown
SCENE: 05_work
┌─────────────────────────────────────────┐
│ REFERENCE IMAGE: IMG_2841              │
│ (shows: angle, composition, framing)    │
│                                         │
│ WHAT WE KEEP: desk angle, laptop,       │
│ typing pose, natural window light       │
│                                         │
│ WHAT WE CHANGE:                         │
│ ✗ Person → our character (v3)           │
│ ✗ Outfit → BLACK square-neck top +      │
│   dark grey wide trousers               │
│ ✗ Background → co-working space         │
│   (Common Ground style — long tables,   │
│   plants, glass walls)                  │
│ ✗ Props → her laptop, coffee cup        │
│                                         │
│ ELEMENT CHECKLIST:                      │
│ □ Character face matches v3?            │
│ □ Hair: light brown, chest-length?      │
│ □ Outfit: BLACK top + dark trousers?    │
│ □ Background: co-working, not home?     │
│ □ Props: laptop, coffee — nothing else? │
│ □ Camera: vlog/phone feel, not DSLR?    │
│ □ Mood: warm cream-blush?              │
│ □ No phone UI / timestamps?            │
│ □ Connects to previous scene (04)?      │
│ □ Connects to next scene (06)?          │
└─────────────────────────────────────────┘
```

### Storyboard can be:
1. **TEXT STORYBOARD** — the scene spec sheet with element checklists (fast, we have this)
2. **VISUAL STORYBOARD** — reference images annotated with arrows/notes showing what changes (better for approval)
3. **HYBRID** — text spec + reference image side by side (best)

### The approval flow:
```
Script → Scene Spec Sheet → Storyboard Cards → USER APPROVES → Generate → QC Audit
```

User approves the STORYBOARD before any generation happens. This catches:
- Wrong outfits
- Wrong locations
- Missing props
- Story breaks
- Wrong angle choices

### Element Verification Rule
For EVERY visible element in a scene, ask:
1. Is this element IN the script? (If not, should it be? Or remove it?)
2. Is this element CONSISTENT with the previous scene?
3. Would this element exist in REAL LIFE for this character?

Elements to verify per scene:
- **Subject:** face, hair, expression, pose, body language
- **Outfit:** top, bottom, shoes, bag, jewelry, accessories
- **Background:** room/location, furniture, walls, windows, lighting source
- **Props:** what's ON the desk/table/counter — every object must be justified
- **Hands:** visible? holding what? (bento = no hands)
- **Camera:** phone/tripod/selfie — consistent with vlog style
- **Mood:** warm cream-blush — EVERY scene

---

## THE WORKFLOW: Pre-Generation Checklist

### Step 1: Build the SCENE SPEC SHEET
Before generating ANYTHING, create a complete spec sheet for EVERY scene:

```markdown
| # | Scene | Time | Location | Outfit | Ref angle | What to keep | What to change | Camera | Connected to |
```

### Step 2: Run 4-Agent Check
For each scene, run all 4 agents mentally BEFORE writing the prompt:
1. DIRECTOR: Does this scene make story sense?
2. ART DIRECTOR: What from the reference to keep vs change?
3. WARDROBE: Is the outfit correct for this scene block?
4. Write the prompt incorporating ALL checks

### Step 3: Generate
Only NOW generate the image.

### Step 4: QC Audit
Check the generated image against the spec sheet. PASS or FAIL.

### Step 5: Fix or Proceed
If FAIL → identify the specific issue → adjust prompt → regenerate
If PASS → move to next scene

---

## BENTO-SPECIFIC RULES

The 5 bento shots are a MONTAGE — different days, different lunches. Rules:
1. **NO HANDS** in frame — just the food on a table/desk
2. **Different table/surface each time** — slight variety (wood desk, white desk, counter, etc.)
3. **Slight different angle each time** — not identical composition. As if she quickly filmed her lunch before eating on different days
4. **Same warm cream-blush tone** across all 5
5. **Quick cuts in final video** — 1-1.5s each with dish name + calorie overlay
6. **Natural phone panning** — when animated via Kling, slight lateral drift (not locked)

---

## REFERENCE INTELLIGENCE RULES

When copying 1:1 from a reference:
1. **KEEP from reference:** ONLY the angle, composition, camera distance, framing, pose/action type
2. **ALWAYS OVERRIDE in prompt (NANO copies these literally if you don't):**
   - Person → our character (face, hair COLOR, hair LENGTH from character lock)
   - Outfit → EXACT wardrobe spec ("black square-neck top and dark grey wide trousers")
   - Background → our specific location ("warm cream-blush condo" or "modern co-working space")
   - Hands → "no hands visible" for bento/food-only shots
   - Phone UI → "no phone UI, no timestamps, no camera interface"
   - Mood/tone → "warm cream-blush tone"
3. **NEVER keep from reference:** the reference person's face, their clothes, their room/background, their hands, any UI elements
4. **THE PROMPT TEMPLATE:**
```
Same angle and composition as the first reference. But:
- Person: same woman as second reference — [face, hair color, hair length]
- Outfit: [EXACT wardrobe spec for this scene block]
- Background: [OUR location — condo bedroom/co-working desk/car interior]
- [No hands visible (bento only)]
- No phone UI, no timestamps
- Warm cream-blush tone. 9:16.
```

### QC REGRESSION FINDINGS (March 18-19, 2026)
- 79% failure rate on first generation batch
- ROOT CAUSES: outfit copied from reference (4 failures), hands copied from reference (5 failures), phone UI copied (2 failures), wrong home outfit (1 failure), background copied from reference (systemic)
- LESSON: NANO copies EVERYTHING from the reference literally. The prompt must EXPLICITLY override every element that should differ. "Change person" only changes the face — not outfit, not background, not hands, not UI.

---

## IMPLEMENTATION

Before EVERY generation session:
1. Print the full scene spec sheet
2. For each scene: state what DIRECTOR, ART DIRECTOR, and WARDROBE say
3. Write the prompt
4. Generate
5. QC audit against spec
6. Log PASS/FAIL

This takes 30 seconds per scene but saves hours of regeneration.
