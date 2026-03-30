---
name: DotDot Mascot v3 Audit — Only exercise pose passed. Skin tone + face feature forensic.
description: CRITICAL. v3-exercise is the ONLY correct pose. Use it as anchor for all future mascot generation. Skin must be LIGHT PEACH, no eyebrows, no missing limbs.
type: feedback
---

## MASCOT v3 AUDIT (30 March 2026)

### Only 1/8 passed: v3-exercise

**v3-exercise (CORRECT — use as reference for all future):**
- Face skin: LIGHT PEACH (not dark brown) ✅
- Eyes: two dots, correct position ✅
- Nose: two tiny dots center ✅
- Mouth: small open, bottom center ✅
- No eyebrows ✅
- Hood effect (white body wrapping peach face) ✅
- Body posture: sitting, leg extended ✅

### What failed and WHY:

| Pose | Issue | Root Cause |
|------|-------|------------|
| v3-hero | Skin too DARK brown | NANO overcorrected from "peach/brown" in prompt — should say "LIGHT peach" |
| v3-thinking | Has eyebrow, missing hand+legs | Strength too low (0.50) lost limb detail, NANO added eyebrow from training data |
| v3-thumbsup | Eyes/mouth wrong position | NANO drifted face features when changing pose |
| v3-teaching | Eyes/mouth wrong, dark skin | Same skin tone issue + face feature drift |
| v3-happy | Eyes/mouth wrong, dark skin | Same issues |
| v3-sympathy | Not checked but likely same issues | — |
| v3-presenting | Not checked | — |

### Fix for v4:
1. Use v3-exercise.png as Image 1 anchor (it's the ONLY correct one)
2. Change prompt to specify "LIGHT peach" not "peach/brown"
3. Add: "NO eyebrows. Character has NO eyebrows."
4. Add: "ALL four limbs visible (two arms, two legs/feet)"
5. Keep strength at 0.50 to preserve face but watch for limb loss

### The v3-exercise face spec (EXACT):
- Face zone: LIGHT peach, warm but NOT dark brown
- Hood: white body wrapping around face, clean separation
- Eyes: two small black dots, slightly above center, moderate spacing
- Nose: two TINY dots, center, below eyes
- Mouth: small rounded open shape, bottom of face zone
- Blush: soft pink circles on cheeks
- NO eyebrows, NO eyelashes, NO extra facial features
- Limbs: both arms visible (nub style), both feet visible

**How to apply:** ALWAYS use v3-exercise.png as the Image 1 anchor. It is the proven correct reference. Describe pose changes only. Specify "LIGHT peach face, NO eyebrows, all four limbs visible."
