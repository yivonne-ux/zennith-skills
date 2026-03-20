---
name: Video art direction mastery — world-class production system
description: Complete video art direction knowledge system. Ohneis foundations + cinematography mastery + audio design + color science + prompt engineering for AI video. Apply to ALL video production. READ FIRST before any video work.
type: feedback
---

## CRITICAL: Read this BEFORE any video production session

This document contains battle-tested knowledge from the mirra_cook v1-FINAL session (March 17-18, 2026). Every rule here was learned through failure. Do not repeat these failures.

---

## 1. OHNEIS FOUNDATIONS (always apply)

### What ohneis ACTUALLY is (not what I kept getting wrong):
- **Art direction, not description.** You're briefing a cinematographer, not describing a photo.
- **Subject first, camera second, ONE effect, 3-word mood.** That's it.
- **Specific > poetic.** "Bright pink durag tied tight" beats "colorful headwear in warm tones."
- **Each shot gets a DIFFERENT technique.** Fisheye for one, macro for another, top-down for a third. Never the same formula repeated.
- **Analog imperfections are SELECTIVE.** Pick ONE per shot — not all of them stacked.

### The ohneis prompt structure:
```
[Subject + specific character details]
[Camera/lens — specific mm, f-stop, and WHY]
[ONE light source — described by its EFFECT not just its name]
[ONE analog imperfection — dust OR grain OR halation, not all three]
[3-word mood]
```

### What to NEVER do:
- ❌ Keyword spam: "halation + dust + grain + bokeh + Portra 800 + chocolate blacks" = AI renders ALL of it = surreal mess
- ❌ Poetry in prompts: "this cup is the first decision she makes every morning" = AI ignores narrative
- ❌ Same formula repeated: "warm sidelight + shallow DOF + cream sweater + dusty rose" × 6 = stock footage
- ❌ Generic subjects: "a woman holding a cup" = Shutterstock

### What TO do:
- ✅ Describe it as if the photo ALREADY EXISTS: "Low-angle fisheye from table surface, barrel distortion stretching the cup rim"
- ✅ Different technique per shot — the VARIETY is what hooks
- ✅ Specific objects that tell you WHOSE space this is
- ✅ Material descriptions that are ACHIEVABLE: "matte cream stoneware" not "kintsugi-repaired gold-filled crack ceramic"

---

## 2. VIDEO ART DIRECTION MASTERY

### Camera Movement = THE Most Critical Element
Camera movement separates boring AI video from cinematic. Without it, AI produces static lifeless footage. Always specify in Veo/Kling/Sora prompts:

**Movement vocabulary:**
- **Slow dolly in** — camera physically moves forward toward subject (intimacy)
- **Dolly zoom (Zolly)** — camera moves backward while lens zooms in (tension)
- **Side tracking** — parallel movement following subject (journey)
- **360 orbit** — circles subject completely (hero reveal)
- **Crane up reveal** — soars upward and backward (context)
- **Handheld documentary** — organic jitters, breathing motion (authenticity)
- **Locked tripod** — zero movement (stillness, control)

**CRITICAL:** Separate camera from subject in prompts:
```
[CAMERA: SLOW DOLLY IN] [SUBJECT: Woman turns, steam rises from cup]
```

### Shot Variety as Rhythm (stolen from Ana's Home Cafe forensic)
Never use the same framing twice in sequence:
```
Through-object → Abstract/bokeh → Medium action (hero) → Wide establishing → Extreme macro → Intimate detail
```
This creates visual RHYTHM. Same framing repeated = monotone.

### Composition Rules
- **Planimetric** (camera perpendicular to scene) = Wes Anderson control
- **Dutch angle** = psychological unease
- **Rule of thirds** = dynamic, natural
- **Dead center** = intentional, confrontational — use only for hero moments
- **Frame within frame** — doorways, windows, mirrors, laptop gaps, sunglasses lenses

### Color as Storytelling (not decoration)
- Each project gets ONE palette — enforce across all shots
- Mirra = dusty rose shadows, cream highlights, warm amber midtones
- Grade baked into REFS (via NANO prompt), reinforced in post (FFmpeg colorbalance)
- NOT CSS blend modes in Remotion — that's a filter, not a grade
- FFmpeg colorbalance + eq for real color science

---

## 3. AUDIO DESIGN (the 50% everyone forgets)

### Music-First Architecture
Choose BGM FIRST → detect BPM via librosa → calculate beat timestamps → CUT VIDEO TO BEATS → add SFX → add silence beats

### Per-Shot Foley
Every shot needs its own sound:
- Coffee: ceramic clink, liquid pour, steam hiss
- Shades: acetate click, fabric rustle
- Lipstick: cap twist, soft application sound
- Keyboard: typing rhythm, trackpad click
- Golden hour: ambient warmth, distant birds
- Food: chopstick on ceramic, gentle chewing

### Silence as Weapon
0.3-0.5s of complete silence before a key text moment = IMPACT. Duck BGM -12dB.

### Beat-Sync
librosa detects BPM → beat timestamps → cuts align to nearest beat hit → text appears ON the beat → transitions feel musical, not mechanical.

---

## 4. AI VIDEO PROMPT ENGINEERING (2026 best practices)

### 8-Point Shot Grammar
Every video prompt:
1. **Subject** — what/who
2. **Emotion** — what they feel/express
3. **Optics** — lens mm, f-stop, depth
4. **Motion** — camera movement (CRITICAL)
5. **Lighting** — source, quality, direction
6. **Style** — film stock, grade, aesthetic
7. **Audio** — ambient cues (for models that support it)
8. **Continuity** — connection to previous/next shot

### Model Selection
| Need | Model | Why |
|------|-------|-----|
| Environmental realism | Veo 3.1 | Best physics, water, fabrics, light |
| Character consistency | Sora 2 Pro | 20s narrative, face lock |
| Native 4K + audio | Kling 3.0 Pro | Highest resolution |
| Fast iteration | Kling Turbo | Test before premium |

### Aspect Ratio FIRST
Set 9:16 BEFORE generating. Changing post-production loses 60%+ of the frame.
Kling standard outputs SQUARE — must use Kling Pro for 9:16 native.

### Duration Sweet Spot
5-8 seconds optimal. Beyond 10s = motion degradation. Generate 8s, trim to best 2-3s.

### Negative Prompts
Always include: "jittery motion, morphing, flickering, frame inconsistency, distorted faces, unnatural movement, blur, watermark"

---

## 5. PRODUCTION PIPELINE (proven)

```
Stage 1: REFS — NANO Banana Pro (fal-ai/nano-banana-pro or /edit)
         ├── Ohneis prompt structure
         ├── Brand palette in prompt (subtle, not flat wash)
         ├── Different technique per shot
         └── Human approval before proceeding

Stage 2: MOTION — Kling 3.0 Pro or Veo 3.0 i2v
         ├── 8-point shot grammar prompts
         ├── Camera movement specified
         ├── 9:16 native (NOT square → crop)
         └── 5-8s generation, trim best 2-3s

Stage 3: SCALE — FFmpeg scale to 1080x1920
         └── lanczos interpolation

Stage 4: GRADE — FFmpeg colorbalance
         ├── Brand-specific color shift
         ├── NOT CSS blend modes
         └── Applied per-video before assembly

Stage 5: AUDIO — librosa + pydub
         ├── BGM BPM detection → beat timestamps
         ├── Video cuts aligned to beats
         ├── Per-shot foley SFX
         ├── Silence beats before key moments
         └── Ducking: BGM -12dB during SFX

Stage 6: TYPOGRAPHY — Remotion
         ├── Brand fonts (Mabry Pro for Mirra)
         ├── MASSIVE — 80-100pt minimum for labels
         ├── Font loaded via CSS @font-face in component
         ├── Spring animation on entry
         └── Mixed fonts for header vs labels

Stage 7: GRAIN — FFmpeg noise filter
         ├── noise=alls=10-15:allf=t
         ├── Applied in video space, not CSS SVG
         └── CRF 22-23 to control file size

Stage 8: ASSEMBLY — FFmpeg merge
         └── Video (graded+grained) + Audio (mixed) → final MP4
```

---

## 6. SESSION LEARNINGS (mistakes to never repeat)

1. **Imagen ≠ NANO.** User's tool is `fal-ai/nano-banana-pro`. Always use this, never Google Imagen.
2. **"Warm" ≠ Mirra.** Mirra is PINK-warm (dusty rose). AI defaults to ORANGE-warm. Must specify "pink undertone in shadows, not orange/amber."
3. **Kling standard = SQUARE.** Must use Kling Pro for native 9:16. Standard outputs 960x960.
4. **FFmpeg curves filter** with quotes breaks in shell scripts. Use colorbalance instead.
5. **Film grain inflates file size.** noise=18 at CRF 17 = 400MB. Use noise=12 at CRF 23 = ~100MB.
6. **Font loading in Remotion SSR** — `new FontFace()` in `ensureBrandFonts()` crashes SSR for new fonts. Use CSS `@font-face` injection via `<style dangerouslySetInnerHTML>` instead.
7. **drawtext is UGLY.** Never use FFmpeg drawtext for typography. Always Remotion.
8. **Veo 3 rate limits** — quota exhausts after ~10-15 generations. Plan accordingly.
9. **Veo download needs API key** appended to URI: `url + "?key=" + API_KEY`
10. **npx serve dies** between Remotion renders. Start fresh server for each render.

---

## 7. REFERENCE ARTISTS (study their work)

- **Andreas Wannerstedt** — oddly satisfying 3D loops, low-saturated palette, meditative motion
- **Studio Brasch** — hyper-real colors, abstract ceramic forms, products staged among impossible sculptural shapes
- **Haruko Hayakawa** — 3D product visualization in surreal environments, between photography and illustration
- **Shusaku Takaoka** — classical art + contemporary mashups, unexpected humor
- **Ana's Home Cafe** — one continuous world, shot variety, persistent typography frame, signature color grade

**Key principle from all:** The object is real but the WORLD around it is extraordinary. Find the extraordinary angle in ordinary things.

---

## 8. THE THINKING LAYER — WHY, not just HOW

### Emotional Beat → Camera Language (the DECISION system)
Before writing ANY prompt, ask: "What should the viewer FEEL?" Then select:

| Target emotion | Camera | Lens | Angle | Light | Movement |
|---------------|--------|------|-------|-------|----------|
| **Intimacy** | Close-up | 85mm f/1.8 | Eye level | Soft key, warm | Slow dolly in |
| **Power/confidence** | Wide static | 35mm | Eye level or slight low | Even, 5600K | Locked tripod |
| **Vulnerability** | MCU | 85mm | Slight high angle | Low key ratio, shadows | Handheld micro-jitter |
| **Revelation/joy** | Dynamic | Wide aperture | Upward gaze | Warm fill 3200K, catchlights | Arc or dolly in |
| **Tension** | Narrow DOF | Telephoto | Asymmetric frame | Rim light, cool temp | Dutch angle or handheld |
| **Calm/meditation** | Locked wide | 50mm f/4 | Level, centered | Diffused even | Zero movement |
| **Awe/scale** | Extreme wide | 24mm | Low angle | Golden hour | Crane up reveal |
| **ASMR/sensory** | Extreme macro | 100mm | Perpendicular to surface | Ring light or raking side | Slow lateral drift |

### The Story Arc in 6 Shots
Every short-form video is a MICRO-STORY with an arc:
1. **Hook** (0-2s) — pattern interrupt, curiosity, "what is this?"
2. **Setup** (2-4s) — establish the world, who/where
3. **Build** (4-6s) — rising action, the thing happening
4. **Peak** (6-8s) — the emotional climax, the MOMENT
5. **Resolve** (8-10s) — satisfaction, completion, payoff
6. **Brand** (10-12s) — tag, logo, identity. Leave them wanting more.

Each shot should have a DIFFERENT emotion. Never repeat adjacent emotions.

### Frame-by-Frame Thinking
For EVERY shot, answer these 5 questions BEFORE writing the prompt:
1. **What emotion does this frame serve?**
2. **What should the viewer's eye look at FIRST?**
3. **What's the camera doing and WHY?**
4. **What's the SOUND at this moment?**
5. **How does this connect to the shot BEFORE and AFTER?**

If you can't answer all 5, the shot isn't ready.

### The 8-Point Shot Grammar (apply to every Veo/Kling/Sora prompt)
```
"A [SUBJECT doing ACTION];
[LENS mm] with [DEPTH OF FIELD];
[CAMERA MOVEMENT] with [MOTION QUALITY];
[KEY LIGHT source] + [FILL/RIM] at [COLOR TEMP K];
[STYLE/GRADE reference];
[AUDIO elements];
[CONTINUITY tokens from previous shot]."
```

### Platform-Specific Prompt Optimization
**Veo 3:** Best for camera arcs + environmental realism. Template: [Camera Arc] + [Subject Blocking] + [Audio Cue]. Use for establishing shots, nature, light play.
**Sora 2:** Best for character consistency. Use "Shot Stacks" — break into sequential beats: enter → react → exit. Seed locking for wardrobe.
**Kling 3.0 Pro:** Native 4K + audio. Best for high-res B-roll and product. MUST use Pro tier for 9:16 (standard = square).

### Prompt Chaining for Consistency
1. Define a GLOBAL CONTINUITY LOCK: time of day, wardrobe, location, lighting, color palette
2. Reuse EXACT descriptor strings across shots: "cream cable-knit sweater, thin gold ring on right ring finger"
3. Seed lock when supported
4. Each shot output informs the next prompt

### What Separates 5/10 from 10/10
- 5/10 describes WHAT is in the frame
- 7/10 describes HOW the camera sees it
- 10/10 describes WHY the viewer should FEEL something, expressed through specific camera/light/motion choices that trigger that feeling unconsciously

The audience never thinks "nice dolly in." They think "I feel close to her." The technique is invisible. The emotion is everything.

---

## 9. TYPOGRAPHY RULES

- **Mabry Pro Bold** for Mirra headlines — 80-100pt MASSIVE
- **DM Serif Display Italic** for subheadlines/headers
- **Cormorant Garamond Light Italic** for elegant labels
- The Mirra font reference shows a bold condensed Didone — for future, find/download the exact font match
- Text should FILL 60-80% of the frame — IN YOUR FACE, not subtle
- Mixed fonts + mixed sizes = designed poster, not text overlay
- ONE hero lockup moment — not 6 equal text cards
- Spring animation on entry (scale 1.15→1.0, damping 8-10)
