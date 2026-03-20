---
name: Vlog production v5 regression — every failure from Lost5kg session
description: 20+ failures from Lost5kg vlog production. Camera logic, food sourcing, pipeline bugs, typography, setting consistency. READ BEFORE any vlog production.
type: feedback
---

## PIPELINE BUGS (never repeat)

### 1. Stale clip propagation
When raw clips are regenerated, ALL downstream stages must be re-processed. Check timestamps.
**Why:** Regenerated 03_drive, 11_eating, 12_mirror with new Kling prompts, but `lost5kg_processed/` and `remotion/public/clips/` still had old versions. Final video showed old clips.
**How to apply:** Before final render, compare timestamps: `raw > processed > remotion`. If raw is newer, re-process everything downstream.

### 2. Double text overlay
FFmpeg drawtext + Remotion both adding text = double text.
**Why:** Typography step burned text into clips via FFmpeg, then Remotion rendered on top of those titled clips.
**How to apply:** Pick ONE text renderer. If using Remotion, feed it PROCESSED clips (no text). Never feed titled/grained clips to Remotion.

### 3. Brand logo as typed text
Used `drawtext=text='mirra'` in Helvetica instead of actual MIRRA logo PNG.
**Why:** Pillow/FFmpeg drawtext can only render system fonts. The brand wordmark is a custom serif font in a PNG.
**How to apply:** Brand logo = ALWAYS the PNG asset. Never type it. For ending cards, composite the logo PNG. For watermarks, use white version of logo PNG with opacity.

## CAMERA MOVEMENT RULES (i2v prompts)

### 4. Every i2v prompt MUST declare camera type
| Setting | Camera | Prompt pattern |
|---------|--------|----------------|
| Tripod (home/office) | STATIC | "Static tripod camera, no camera movement. Camera completely still." |
| Phone mounted (car dash) | FIXED + vibration | "Phone mounted, fixed position. Smooth ride, very slight vibration only." |
| Selfie (walking) | HANDHELD | "Handheld selfie, natural bounce and sway from walking." |
| Food filming | SLIGHT PAN | "Camera slowly drifts/pans. Subtle movement." |
| Mirror selfie | MICRO-MOVEMENT | "Phone in hand, tiny natural micro-movement." |

### 5. Modern car = specify explicitly
**Why:** Kling generated a manual car with handbrake and shaky ride.
**How to apply:** Always say "modern automatic car interior, smooth ride, no shaking, no manual handbrake, no gear stick."

### 6. No blinking/flickering on displays
**Why:** Scale scene had LED display blinking like a strobe.
**How to apply:** For static displays (scales, screens, clocks): "Display shows steady number, no blinking, no flickering."

## FOOD / BENTO RULES

### 7. NEVER generate food with AI
**Why:** AI-generated food doesn't match Mirra's actual menu. Generated "green curry" that looked nothing like Mirra's green curry.
**How to apply:** ALL food must come from `shared/brand-identity/mirra/food-library/drive-full/`. Use NANO edit to place real food photos onto the correct setting, not to generate new food.

### 8. Same-location scenes MUST share setting anchor
**Why:** 5 bento shots on 3 different table surfaces (wood, marble, walnut). Doesn't feel like same office desk.
**How to apply:** Before generating, establish ONE reference as the setting anchor. All same-location scenes use that reference for desk/table/background. Only the subject (food) changes.

### 9. Bento box style must be consistent
**Why:** Mixed round bowls, square compartment boxes, rectangular boxes across the 5 days.
**How to apply:** Mirra uses specific packaging. Use the SAME bento box style across all shots. Source from food library which has consistent packaging.

### 10. No steam on bento food
**Why:** Kling adds steam/smoke by default on food. Looks fake.
**How to apply:** Always say "No steam, no smoke, no vapor. Room temperature food." in food scene prompts.

### 11. No hands in food-only shots
**Why:** Kling generated hands holding/reaching for food.
**How to apply:** "No hands, no fingers, no arms, no person in frame at all. Only food visible."

## CHARACTER / EMOTION RULES

### 12. Face scenes need emotion direction
**Why:** Eating scene had zero reaction — just mechanical chewing.
**How to apply:** For face-to-camera scenes, always include emotion: "subtle satisfied smile," "slight nod like food is good," "natural happy expression." Keep it SUBTLE — "not exaggerated, very natural."

### 13. Mirror/body scenes need movement direction
**Why:** Mirror scene was static, no flaunt.
**How to apply:** "Subtly turns body from side to front, showing figure confidently. Very subtle, not exaggerated."

### 14. All actions must be SUBTLE
**Why:** Exaggerated AI movements look fake instantly.
**How to apply:** Always include "very subtle," "natural," "not exaggerated" in every motion prompt. Less is more.

## TYPOGRAPHY RULES

### 15. Single font per video
**Why:** Mixed DM Serif Display + Mabry Pro looked inconsistent.
**How to apply:** Pick ONE font family for the entire video. Use weight (medium vs bold) and size for hierarchy, not different fonts.

### 16. Text MUST have outline stroke, not just drop shadow
**Why:** Drop shadow alone = text fades into bright backgrounds.
**How to apply:** Always use 8-directional outline stroke (`-2px -2px 0 black, 2px -2px 0 black...`) PLUS drop shadow. This guarantees readability on any background.

## PROCESS RULES

### 17. Full script + setting logic BEFORE any generation
**Why:** Spent hours rendering clips, then realized no captions, no story, wrong settings.
**How to apply:** Before generating ANY image or video:
1. Write full script with every caption
2. Define setting logic (which scenes share which location)
3. Define wardrobe per scene
4. Define camera type per scene
5. Get user approval on the PLAN
6. THEN generate

### 18. Pre-flight QC checklist before final render
Before rendering final video, verify:
- [ ] All raw clips newer than processed clips? Re-process if not.
- [ ] Remotion using processed clips (no text burned in)?
- [ ] Brand logo is PNG, not typed text?
- [ ] Same desk/table across all same-location scenes?
- [ ] All food from real food library?
- [ ] Typography has outline stroke?
- [ ] Single font family?
- [ ] Script/captions reviewed and approved?

### 19. "Would this pass if the user saw it?" test
Before delivering, scrub through every second and ask:
- Does this look like a real vlog or AI slop?
- Would the user reject this for any reason I already know about?
- Is anything inconsistent with previous approved scenes?
