---
name: Video Craft Rules — PERMANENT Operating Rules
description: MUST READ before ANY video work. Hard rules from March 16-17 marathon. Image gen = NANO only. Prompts = ultra-detail. Script FIRST. Typography = designed not drawtext. Every craft gap identified and documented.
type: feedback
---

## ABSOLUTE RULES (violating any = reject the entire output)

### Typography Must Be ALIVE
- Not just styled text sitting on screen. Typography = PERFORMANCE.
- Variable effects: some words BOOM full-frame, some slide with beat, some cover entire screen
- Beat-synced: text movement ties to music rhythm. BOOM BOOM energy.
- NOT limited to Mabry Pro + Source Han Serif. Download Nasty Gal fonts (Moderat, Apercu, etc.) as needed per concept.
- "mirra" = ACTUAL LOGO image, not typed text. Use the logo assets from Google Drive (Mirra Branding/Logo/).
- Nasty Gal reference: ALL CAPS, wide tracking (+80-150), snap/pop on beat, fills 60-80% of frame
- Spiritual Gangster reference: lowercase, light weight, airy tracking, gentle fade, calm
- The intersection shifts per beat — BOLD declarations (Nasty Gal) → warm closers (Spiritual Gangster)

### No Corners Cut
- **ZERO fallbacks.** If Remotion kinetic text is the standard, FFmpeg drawtext is FORBIDDEN. Don't use it and say "oh I fell back." Build the Remotion component or don't ship.
- **Every station at mastery.** If sound design is needed, implement REAL ducking + SFX + beat sync. Not flat BGM with fade.
- **Every model chosen by OBJECTIVE.** Fashion/party = different model than UGC. Vlog = different than mood piece. Ads = different than content. Map the objective FIRST, then choose the weapon.

### Model Selection by Video Objective
| Objective | Best Model | Why |
|---|---|---|
| UGC / lifestyle / authentic | Sora 2 | Most natural iPhone-like motion |
| Cinematic / mood / premium brand | Veo 3 i2v | Film-grade 8s, best fabric/light |
| Fashion / editorial / sharp detail | Kling v2.1 Pro i2v | Sharpest quality, best prompt adherence |
| Illustration / animation | Sora 2 or Hailuo | Style-dependent, test both |
| Quick concept test | MiniMax ($0.50) | Cheapest, fast iteration |
| Character consistency across shots | Kling element binding | Face lock across generations |
| Atmospheric / minimal mood | Veo 3 or Sora 2 | Both excel, Veo more cinematic |
| Comedy / parody / bodycam | Sora 2 | Best at absurdist/format mimicry |
| Longest single take | Sora 2 Pro (20s) or Veo 3 (8s) | Duration needs |
| Loop / seamless | Luma Ray 2 | Native loop support |

## HARD RULES (never break)

### Image Generation
- **NANO ONLY for reference images.** Never FLUX, never raw prompts. NANO has brand DNA.
- Reference image IS the art direction. Quality in = quality out.
- Edit reference images to editorial level BEFORE feeding to video models.

### Video Prompting
- **Ultra-precise, ultra-detailed** — MORE comprehensive than static prompts.
- Specify: lens mm, f-stop, camera height in cm, color temperature in Kelvin, film stock, motion direction, action in beats.
- Use @ohneis method: NANO reference image → decompose into cinematic prompt → generate.
- OpenAI 5-part structure: Subject/Setting → Camera/Framing → Action (2-3 beats) → Lighting/Style → Sound.
- Single action rule: ONE camera move + ONE subject action per shot.
- Sensory verbs, not adjectives: "stumbling" not "moving", "Kodak Vision3 250D" not "cinematic".
- NO food or packaging in AI generation — use real library footage.

### Production Flow
- **BRIEF → SCRIPT → NANO reference → Prompt → Generate → Kitchen assembly → QC**
- Script BEFORE any generation. The script IS the content.
- Music FIRST (choose BGM before editing — it drives the rhythm).
- Typography = designed, not drawtext. Must be world-class, not functional.
- Each kitchen station (editor, colorist, typographer, sound, VFX) operates at mastery.

### Model Routing (March 2026)
- **Veo 3 (Google native)**: Best cinematic quality, 8s, t2v + i2v. Use `types.Image(image_bytes=bytes, mime_type="image/jpeg")` for i2v.
- **Sora 2 (fal.ai)**: Best UGC/lifestyle, natural motion, 4s standard / 20s Pro.
- **Kling v2.1 Pro (fal.ai)**: Sharpest detail, face lock via element binding, i2v only.
- **Hunyuan (fal.ai)**: Premium editorial look.
- **MiniMax (fal.ai)**: Cheapest concept test ($0.50).
- **Luma Ray 2 (fal.ai)**: Natural motion, seamless loops.

### Content Not Ads
- Every video is CONTENT first. Brand lives in vibes, not mentions.
- Must pass 7 QC questions: scroll-stop, meaning, feeling, Mirra DNA, share trigger, mute-friendly, rewatch.
- Three content moods: high-hook creative / girlboss story / food vibes.
- Brand constant (palette, warmth, voice), format variable (every video different).

## CRAFT GAPS TO CLOSE (priority order)

1. **SCRIPTWRITING** — steal proven structures (Nike doubt stack, Lululemon manifesto, AG1 identity quit). Copy voice from Mirra's best statics. NANO should help with brand voice.
2. **TYPOGRAPHY** — build Remotion kinetic text system. Multiple fonts, spring animations, word-by-word reveal, emphasis scaling. Not FFmpeg drawtext.
3. **SOUND DESIGN** — music-first editing. Use librosa for BPM/beat detection. Implement ducking (attack 5ms, release 300ms). SFX on cuts. Silence beats before key text.
4. **EDITORIAL RHYTHM** — cut on action not time. Energy curve: hook→build→dip→peak→resolve. Musical pacing.
5. **THE EYE** — practice + feedback loops. Watch the output, feel what works, iterate.
6. **BULK SYSTEM** — build the pipeline that takes brief → finished content at scale.

## API Keys & Endpoints
- fal.ai: FAL_KEY in .env (Sora, Kling, MiniMax, Luma, Hunyuan)
- Google Veo: GOOGLE_VEO_API_KEY_2 in .env (via google-genai SDK)
- ElevenLabs: ELEVENLABS_API_KEY in .env
- Video blocks library: 740 clips on Google Drive (love@huemankind.world)
- Ohneis prompt packs: Master Prompt Tutorial folder on Drive (8 PDFs digested)

## All Research Documents
14 docs at ~/Desktop/video-compiler/docs/ and root:
VIDEO-PRODUCTION-DNA.md, VIDEO-PRODUCTION-FUNDAMENTALS.md, PROVEN-VIDEO-PROMPTS-COLLECTION.md, PROMPT-LIBRARY-SYSTEM.md, HYBRID-AI-VIDEO-PRODUCTION-RESEARCH.md, VIDEO-MASTERY-PRODUCTION-SPECS.md, AI-VIDEO-MODEL-GUIDE.md, typography-vfx-production-specs.md, LUXURY-VIDEO-AESTHETICS-RESEARCH.md, VIRAL-VIDEO-EDITING-INTELLIGENCE.md, VIRAL-VIDEO-SCIENCE-RESEARCH.md, ANIMATION-PRODUCTION-INTELLIGENCE.md, MASTERY-GAP-ACTION-PLAN.md + CRACKING_NOTES.md
