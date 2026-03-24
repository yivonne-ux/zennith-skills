# Mirra Video Production DNA — Master System

> The system that produces infinite golden content. Not one video — a FACTORY.
> Every station at mastery. Every step has a why. The output is always Mirra.

---

## THE PRODUCTION FLOW

```
1. BRIEF
   What are we saying? To whom? Why now? What should they FEEL?
   ↓
2. SCRIPT
   Exact words. Exact timing. Exact emotion per beat.
   The script IS the content. Visuals serve it.
   ↓
3. ART DIRECTION
   NANO generates reference images from the script.
   The reference image IS the visual blueprint.
   ↓
4. PROMPT ENGINEERING
   Decompose reference → cinematic Sora/Kling/Veo prompt
   (@ohneis method: image → decompose → structured prompt)
   ↓
5. GENERATION
   Right model for right shot. Raw material = 12s canvas.
   Multiple generations per shot. Pick the BEST 2-3 seconds.
   ↓
6. EDITORIAL (The Kitchen)
   6a. EDITOR — Cut, pace, rhythm, structure
   6b. COLORIST — Unified Mirra grade, brand warmth
   6c. TYPOGRAPHER — World-class text design, not just drawtext
   6d. SOUND DESIGNER — BGM, SFX, silence, ducking
   6e. VFX — Grain, vignette, transitions, overlays
   ↓
7. QC / AUDIT
   Does it stop the scroll? Does it MEAN something?
   Would you share it? Does it feel Mirra with logo hidden?
   ↓
8. FEEDBACK LOOP
   What worked → save. What failed → save. System gets smarter.
```

---

## STATION 1: BRIEF

### Skills needed: Brand strategist, audience psychologist

### What mastery looks like:
- ONE sentence that defines the entire video
- Clear audience: who is this FOR?
- Clear emotion: what should they FEEL?
- Clear action: what should they DO after watching?
- Clear format: is this content, ad, story, vibe, meme, education?

### Brief template:
```
AUDIENCE: [who specifically]
FORMAT: [content / ad / story / vibe / educational / meme / format-hijack]
HOOK: [the first thing that stops the scroll — in words]
MESSAGE: [the ONE thing the viewer takes away]
FEELING: [the emotion at second 1, second 8, and the last second]
SHARE TRIGGER: [why would someone send this to a friend?]
TONE: [Mirra voice — bold, warm, smart, unapologetic, Malaysian]
DURATION: [target seconds]
REFERENCES: [specific videos/brands that have the right energy]
```

### Mastery gap: ACTIVE — need to practice writing briefs that produce great content, not generic ones

---

## STATION 2: SCRIPT

### Skills needed: Copywriter, storyteller, typographic thinker

### What mastery looks like:
- Every word is intentional — no filler
- The text works on MUTE (80% of viewers watch silent)
- The copy has Mirra VOICE — bold, warm, smart, unapologetic
- Bilingual (EN/CN) with natural code-switching
- The script defines TIMING — when each word appears and disappears
- The script thinks TYPOGRAPHICALLY — which words are big, which are small, which are emphasis

### Script template:
```
BEAT 1 (0-Xs):
  TEXT: "exact words on screen"
  TYPOGRAPHY: [font, size, weight, color, position, animation]
  VISUAL: [what the viewer SEES behind the text]
  EMOTION: [what they FEEL]

BEAT 2 (X-Ys):
  TEXT: ...
  ...

BEAT 3 (Y-Zs):
  TEXT: ...
  ...
```

### Copy voice guide (Mirra x Nasty Gal x Spiritual Gangster):
- DECLARES, doesn't explain: "your lunch just got smarter." NOT "try our healthy meal."
- SPECIFIC, not vague: "RM19 a meal" NOT "affordable pricing"
- ATTITUDE, not humble: "she doesn't meal prep. she orders smarter."
- WARM, not cold: always feels like a confident friend, never corporate
- NO exclamation marks. Period energy. Confidence is quiet.
- Bilingual: CN for emotional/cultural moments, EN for aspirational/universal moments

### Mastery gap: CRITICAL — haven't written a single proper script before generating. This is the #1 gap.

---

## STATION 3: ART DIRECTION (Reference Images)

### Skills needed: Art director, photographer, brand designer

### What mastery looks like:
- NANO generates reference images from the script brief
- Each reference image IS the first frame / visual blueprint for Sora
- The reference carries brand DNA: Mirra palette, composition, mood
- Multiple references per video (one per beat/scene)
- The reference is EDITORIAL quality — not casual, not stock

### Tools:
- NANO (primary — has brand DNA built in)
- FLUX Pro on fal.ai (backup for specific styles)
- Midjourney (for illustration/artistic styles)
- Real Mirra food photos (edited to editorial level for food beats)

### Image editing pipeline:
- bloom_core.py approach: color grade → composition → sharpening → brand overlay
- Upgrade to mastery: proper color science, crop ratios, focal point, negative space

### Mastery gap: MODERATE — FLUX produced good references, but should use NANO which already knows Mirra DNA. Image editing pipeline is basic PIL, needs upgrade.

---

## STATION 4: PROMPT ENGINEERING

### Skills needed: Cinematographer (virtual), AI model specialist

### What mastery looks like:
- @ohneis method: reference image → decompose → structured prompt
- OpenAI 5-part structure: Subject/Setting → Camera → Action → Light/Style → Sound
- Single action rule: ONE camera move, ONE subject action per shot
- Sensory verbs, not adjectives: "stumbling" not "moving", "Kodak Vision3 250D" not "cinematic"
- Model-specific optimization (Sora vs Kling vs Veo prompt patterns differ)
- 3-level motion: macro (camera) + mid (subject) + micro (environment) = cinematic
- Negative prompts: 3-5 max, targeted

### Model routing:
| Need | Best Model | Why |
|------|-----------|-----|
| Lifestyle/UGC human | Sora 2 t2v | Best natural human motion |
| From reference image | Sora 2 i2v | Frame 1 = reference, adds motion |
| Character consistency | Kling v3 Pro i2v | Element binding locks face |
| Multi-shot story | Kling multi-shot | 6 shots in 1 generation |
| Illustration/animation | Sora 2 or Hailuo 2.3 | Style-dependent |
| Longest duration | Sora 2 Pro (25s) | When one take matters |
| Liquid/fluid physics | Sora 2 | Best at pour, splash, steam |
| Cheapest concept test | MiniMax ($0.50) | Test before committing |
| Cinematic fidelity | Veo 3.1 | Most film-like, but 8s max |

### Prompt library: PROVEN-VIDEO-PROMPTS-COLLECTION.md (40+ actual tested prompts)
### Style catalogue: Qubit Flow visual filters
### Prompt system: docs/PROMPT-LIBRARY-SYSTEM.md

### Mastery gap: MODERATE — have the knowledge, proven it works with reference-first method. Need more practice and iteration to build intuition.

---

## STATION 5: GENERATION

### Skills needed: Producer, quality selector

### What mastery looks like:
- Generate 3-4 versions per shot, pick the BEST 2-3 seconds (@ohneis: "take the cleanest moments")
- Budget: cheap model for concept (MiniMax $0.50), expensive for final (Sora Pro $0.50/s)
- Know when to regenerate vs when to cut around artifacts
- Use 12-second generations as CANVAS — break apart, recombine, insert library footage
- Never use Sora for food/packaging (use real library footage)
- Real food footage: 740 library clips, edited to editorial level

### Mastery gap: LOW — proven across V1-V6 + masterpiece + creative burst. The generation skill is functional.

---

## STATION 6a: EDITOR

### Skills needed: Film editor, rhythm specialist, storyteller in cuts

### What mastery looks like:
- Music-first editing (Nicolas Neubert method): choose BGM FIRST, cut to the beat
- Pacing is MUSICAL, not mechanical — hold, breathe, rapid-fire, hold
- The edit tells the story — you can shuffle shots and the effect CHANGES (narrative, not montage)
- Energy curve: HOOK → build → dip → peak → resolve
- Cut on ACTION not on time (cut when something changes, not every 1.5s)
- Know when to use library footage vs Sora footage vs pure typography cards
- The 12s Sora output is raw material — break it apart, use the best 2-3 seconds per segment, intercut with other sources

### Tools: FFmpeg (functional), Remotion (powerful but unused), CapCut (for reference)

### Mastery gap: CRITICAL — currently doing mechanical concat. Need musical pacing, beat-synced cutting, energy curves. This is the biggest editorial gap.

---

## STATION 6b: COLORIST

### Skills needed: Color scientist, brand visual guardian

### What mastery looks like:
- Mirra-specific LUT/grade that works across ALL sources (Sora, library, text cards)
- Understands color SCIENCE not just filter sliders — lift/gamma/gain, color wheels, HSL qualification
- Different grades for different moods within Mirra palette (warm morning vs cool office vs golden street)
- Grain: subtle, monochrome, ALWAYS last step
- Vignette: gentle, draws eye to center of interest (not always center of frame)
- The grade makes Sora footage + library footage + text cards feel like ONE world

### Mirra grade values (current):
- Warm amber shadows (rs=0.035, bs=-0.045)
- Clean highlights (slight warmth, not orange)
- Food saturation boost (+10-15%)
- Blush midtones (rm=0.015)
- Film grain: noise=2-3, monochrome, overlay

### Mastery gap: MODERATE — functional grade works, but needs proper LUT development and per-shot adjustment. Using one-size-fits-all instead of per-shot art direction.

---

## STATION 6c: TYPOGRAPHER

### Skills needed: Type designer, motion graphics artist, brand voice designer

### What mastery looks like:
- Typography IS the content, not decoration on top of footage
- Different fonts for different moods WITHIN one video:
  - Bold condensed (Nasty Gal energy): declarations, hooks, prices
  - Warm serif (Spiritual Gangster): emotional lines, brand name, closers
  - Clean sans (Mabry Pro): information, supporting text
- Text ANIMATION: fade, slide, scale, spring physics — not just static drawtext
- Text TIMING: appears and disappears with intention, synced to audio beats
- Safe zone aware: nothing in top 15% or bottom 20%
- Bilingual: CN characters need different sizing/spacing than EN
- The typography has a SYSTEM — not ad-hoc per video but a brand typographic language

### Tools needed:
- Remotion KineticTextBlock (spring physics, word-by-word, emphasis)
- OR CapCut text templates
- OR After Effects (not available)
- FFmpeg drawtext is FUNCTIONAL but not mastery — it's the PIL equivalent for video

### Mastery gap: CRITICAL — biggest quality gap. Using basic drawtext with one font. Need Remotion kinetic text system with multiple fonts, animations, and brand typographic language. This is what separates "test" from "content."

---

## STATION 6d: SOUND DESIGNER

### Skills needed: Music supervisor, audio engineer, rhythm architect

### What mastery looks like:
- Music FIRST — choose the track before editing (it drives the rhythm)
- BGM selection matches the MOOD of the brief, not just "warm track"
- Volume shaping: fade in, silence beats at transitions, fade out
- Ducking: BGM responds to text appearance (dip when text appears, rise when visual-only)
- SFX placement: whoosh on cuts (2 frames before), pop on text reveal, ambient food sounds
- SILENCE is a tool: 300-700ms of near-silence before key text creates impact
- Master output: -14 LUFS, -1 dBFS true peak (platform normalization)

### Audio specs (from research):
| Element | Level |
|---------|-------|
| BGM under text | -18 to -24 dBFS |
| BGM visual-only | -12 to -14 dBFS |
| SFX | -12 to -18 dBFS |
| Ducking: attack 5ms, release 300ms, ratio 6:1 |

### Mastery gap: HIGH — only implemented flat BGM with fade. No ducking, no SFX, no silence beats, no music-first editing. Know the theory from research but zero execution.

---

## STATION 6e: VFX

### Skills needed: Post-production artist, compositing specialist

### What mastery looks like:
- Film grain (subtle, monochrome, LAST step)
- Vignette (gentle, per-shot adjustment)
- Zoom punch on cuts (1.05x spring, 4-8 frames) — currently in Remotion VideoBlock but unused
- Speed ramping within clips (0.7x for premium moments, 1.3x for energy)
- Flash frames on scene changes (2 frames, 80% white, every 3rd-5th cut)
- Mixed media overlays (illustration elements on real footage) — NOT YET ATTEMPTED
- Doodle/annotation overlays — NOT YET ATTEMPTED

### Mastery gap: MODERATE — grain and vignette work. Everything else (zoom punch, speed ramp, flash, overlays) is researched but unimplemented.

---

## STATION 7: QC / AUDIT

### The 7 Questions (every video must pass ALL):

1. **SCROLL STOP**: Does the first frame make you pause your thumb?
2. **MEANING**: Can you describe what this video is ABOUT in one sentence?
3. **FEELING**: Do you FEEL something? (not just "that's nice" — an actual emotion)
4. **MIRRA**: With the logo hidden, can you tell this is Mirra? (palette, warmth, voice)
5. **SHARE**: Would you send this to a friend? WHY specifically?
6. **MUTE**: Does it work completely on mute? (text carries the full story)
7. **LOOP**: Does it make you want to watch again?

### Fail any one = back to the relevant station.

---

## CONTENT TYPES (Brand Constant, Format Variable)

Every video is DIFFERENT in format. Every video is UNMISTAKABLY MIRRA.

| Type | Description | Sora Use | Library Use |
|------|-------------|----------|-------------|
| **Vibe** | Pure mood, atmospheric, minimal text | Atmospheric shots | None or minimal |
| **Story** | Narrative arc with beginning/middle/end | Character/lifestyle scenes | Food as payoff |
| **Hook** | Scroll-stopping pattern interrupt | The impossible/unexpected | Real food as proof |
| **UGC** | Looks real, feels authentic | Human lifestyle shots | Food close-ups |
| **Illustration** | Animated character/story | Illustrated animation | None |
| **Format Hijack** | Calculator, WhatsApp, horoscope, etc. | UI/format generation | Food in context |
| **Comedy** | Funny, shareable, bodycam, parody | The absurd situation | None |
| **Educational** | Value-driven, "did you know" | Supporting visuals | Real food/nutrition |
| **Meme** | Cultural moment, trend participation | Trend-specific | Brand adaptation |

---

## WHAT'S READY vs WHAT NEEDS BUILDING

### READY (proven today):
- [x] Creative Intelligence Engine (concepts, hooks, share triggers)
- [x] Sora generation with reference-first method
- [x] FFmpeg assembly pipeline
- [x] Basic color grading
- [x] Library footage (740 clips)
- [x] 12 research documents (7000+ lines)
- [x] 40+ proven prompt templates

### NEEDS BUILDING (critical gaps):
- [ ] **SCRIPT SYSTEM** — brief → script → typography plan → THEN generate
- [ ] **TYPOGRAPHY MASTERY** — Remotion kinetic text with brand type system
- [ ] **SOUND DESIGN** — music-first editing, ducking, SFX, silence beats
- [ ] **NANO INTEGRATION** — NANO generates reference images from brief
- [ ] **EDITORIAL RHYTHM** — beat-synced cutting, energy curves, musical pacing
- [ ] **IMAGE EDITING PIPELINE** — upgrade bloom_core.py for universal editorial grading
- [ ] **PER-SHOT COLOR** — individual grade per shot, not one-size-fits-all

---

## THE NORTH STAR

The system produces content that:
- Stops the scroll (hook)
- Makes you feel something (emotion)
- Sounds like Mirra (voice)
- Looks like nothing else (brand)
- Makes you share it (trigger)
- Works on mute (typography)
- Gets better every cycle (feedback loop)

Not one perfect video. A FACTORY that produces infinite golden content across every format, every mood, every message — all unmistakably Mirra.
