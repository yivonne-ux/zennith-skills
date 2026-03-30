---
name: Video generation hard lessons — every failure pattern from March 17-19 2026
description: Every mistake made in the mirra_cook video production session. 15+ hours of iterations distilled. Read BEFORE any video generation work.
type: feedback
---

## NANO Banana Pro — How It ACTUALLY Works

1. **NANO copies EVERYTHING from the reference literally.** Face, outfit, background, hands, phone UI, props — ALL copied unless explicitly overridden in the prompt.
2. **"Change the person" only changes the FACE.** Outfit stays. Background stays. Hands stay.
3. **You must EXPLICITLY override** every element that should differ from the reference.
4. **The reference gives ONLY the angle/composition.** Everything else comes from YOUR prompt.

## The Prompt Template That Works
```
Same angle and composition as the first reference. But:
- Person: same woman as second reference — [exact face, hair color, hair length]
- Outfit: [EXACT garment names — "black square-neck top and dark grey wide trousers"]
- Background: [YOUR specific location — "warm cream-blush condo bedroom" or "modern co-working space with glass walls and plants"]
- [No hands visible in frame (for food-only shots)]
- No phone UI, no timestamps, no camera interface
- Warm cream-blush tone. 9:16.
```

## Hard Lessons (never repeat)

### Prompt Engineering
1. **"Warm" ≠ Mirra.** AI defaults to ORANGE-warm. Mirra is PINK-warm. Specify "cream-blush" not "warm."
2. **"iPhone camera" in prompt → iPhone UI in output.** Never mention iPhone in the prompt. Say "phone camera quality" or just "natural, vlog style."
3. **Keyword spam = surreal mess.** "Halation + dust + grain + bokeh + Portra 800" all together = AI renders ALL of them. Pick ONE analog effect max.
4. **Poetry in prompts = ignored.** "This cup is the first decision she makes every morning" — AI doesn't understand narrative. Only describe what's VISIBLE.
5. **Long prompts override the reference.** The more you describe, the more NANO ignores the reference. SHORT prompts let the reference speak.
6. **"No X" works.** "No hands visible" "No phone UI" — negative instructions are respected.

### Character Consistency
7. **Each NANO generation creates a different person.** You MUST provide a character reference image with EVERY generation.
8. **Use 2 reference images:** angle ref + character ref. The prompt bridges them.
9. **Hair color drifts.** Specify "light brown" or "dyed brownish" every single time.
10. **Outfit is NOT locked by the character ref.** NANO will put the reference image's outfit on your character. Override explicitly.

### Setting / Background
11. **NANO copies the reference background.** If the reference shows a European apartment, your output shows a European apartment — even if you say "KL condo."
12. **The mood anchor (pin_07_02) sets the COLOR TONE, not the room.** It doesn't make every room look like the same apartment.
13. **"Co-working space" is too vague.** Say "modern co-working space with long wooden tables, green plants, glass partition walls, natural light from floor-to-ceiling windows."
14. **Home scenes need the SAME room across shots.** Use the CHARACTER_v3 background as the home anchor.

### Food / Bento
15. **v20_06_phonepov_v2 reference has hands.** NANO will generate hands unless you say "no hands visible."
16. **"Different table each time" requires different angle references** or explicit table description changes.
17. **Food color can shift.** The Mirra bento colors may get muted by the warm tone. Check food vibrancy in QC.

### Technical
18. **Kling standard = SQUARE.** Always use Kling PRO (`v3/pro`) for 9:16.
19. **yuv444p → playback fails.** Always encode with `-pix_fmt yuv420p`.
20. **FPS mismatch = stuttering.** ALL clips must be same fps before concat (30fps).
21. **Film grain inflates file size.** noise=18 + CRF 17 = 400MB. Use noise=8-12 + CRF 22-23.
22. **Ending card disappears at high CRF.** Mostly-white frames compress to near-zero. Use CRF 1 for ending.
23. **Non-breaking spaces in macOS filenames.** Always copy files to clean names before processing.

### Process
24. **Reference-first, not imagination-first.** NEVER generate from text description alone. Always start from a real reference image.
25. **Storyboard BEFORE generating.** Every scene spec'd with element checklist. User approves storyboard before any tokens are spent.
26. **4-agent check BEFORE generating.** Director (story) → Art Director (mood) → Wardrobe (outfit) → QC (audit).
27. **QC regression after EVERY batch.** Use Gemini Vision to audit all outputs against the spec. Find patterns. Fix systemically.
28. **One scene at a time when iterating.** Don't generate 12 shots hoping they all work. Generate 1, verify, then next.

### What Stops Scrolls
29. **Food-first hooks with specific numbers** outperform lifestyle hooks. "i lost 5kg eating these everyday / 420 cal" > "6:20 PM after work."
30. **Face-to-camera eating** is a proven vlog angle. Not top-down editorial.
31. **Vlog = mix of tripod + selfie + POV.** Not all one type.
32. **Real vlogs have lived-in spaces.** Books, remotes, chargers, tossed blankets. Not showrooms.
33. **Speed variation** — mundane parts at 1.3x, key moments at 1.0x.

### Lesson 34: "Would this angle exist if she filmed ALONE with one phone?"
If the answer is no → the angle is wrong. A vlog has ONE phone. Every shot must be achievable by one person with one device. No "photographer across the room" angles. Add this check to auto-QC.

### Lesson 35: REFERENCE FIRST — NEVER describe camera placement
When I write "phone on tripod from the side" or "self-shot angle" in the prompt, NANO ignores the reference and imagines its own angle. The prompt should ONLY say "Same exact angle as reference." STOP adding camera descriptions that override the reference.

### Lesson 36: The prompt that works
```
Same exact angle and composition as the first reference. 
Change person to second reference — [character].
Outfit: [exact outfit].
Background: [our location].
No phone UI. 9:16.
```
NOTHING ELSE. No camera descriptions. No "self-shot". No "tripod". Let the reference BE the angle.

### Lesson 37: ALWAYS LOOK AT THE ACTUAL IMAGE — NEVER read code/filenames and assume
Before describing, referencing, or making decisions about ANY image:
1. READ the actual image file with the Read tool
2. LOOK at what's actually in it — the background, the lighting, the outfit, the angle
3. NEVER assume what an image contains based on its filename, the prompt that generated it, or the code that produced it
4. If you haven't LOOKED at the image in this conversation, you don't know what's in it
5. This is FORBIDDEN: "05_work has a bright co-working with plants" ← said without looking. WRONG.
6. This is REQUIRED: Read the image → "05_work shows: white ceiling tiles, fluorescent panels, brown partition, white desk, grey chair" ← described from actually seeing it.

**Why:** I described 05_work's background as "bright co-working with plants and shared wooden tables" across 4 generations — because I read my OWN prompt text, not the actual image. The real image has ceiling tiles and fluorescent lights. Every eating shot generated the WRONG background because I never looked.

**How to apply:** Before ANY generation that references another image, READ that image first. Describe what you SEE, not what you THINK is there.
