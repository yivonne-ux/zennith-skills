# VIDEO PRODUCTION PIPELINE — Complete End-to-End Flow
> Every single detail: brief → script → VO → SFX → timestamps → lipsync → images → scenes → character → BG → attire → lighting
> Engineered from: Tricia 60 tools + Yivonne 132 memories + Joey FAL.ai costs + timkoda LoRA + Kling [cut] + 7 YouTube analyses + all scraped intelligence

---

## THE 12-STEP PIPELINE

```
┌─────────────────────────────────────────────────────────────┐
│  STEP 1: CREATIVE INTELLIGENCE (Brief)                       │
│  ├── creative-reasoning-engine → concept + hook               │
│  ├── daily-intel digest → market context                      │
│  ├── brand DNA.json → voice, colors, never-list              │
│  └── Output: Structured Brief JSON                            │
├─────────────────────────────────────────────────────────────┤
│  STEP 2: FLOW SELECTION + PLANNING                            │
│  ├── Select flow A-M from flow-alphabet.json                  │
│  ├── Map to AIDA block pattern (e.g., A3→I6→D1→D2→Act6)     │
│  ├── Select sequence template from sequence-templates.json    │
│  ├── Determine: funnel position, strategy, voice (1st/2nd/3rd)│
│  └── Output: Production Plan JSON                             │
├─────────────────────────────────────────────────────────────┤
│  STEP 3: SCRIPT GENERATION                                    │
│  ├── video-script-gen.sh → structured AIDA script             │
│  ├── 7 Visual Craft Rules enforced:                           │
│  │   1. Tension hook (number/question, no brand in first 2)   │
│  │   2. Emotional arc (curiosity→frustration→surprise→...)    │
│  │   3. Emphasis budget (5-7 *key phrases*)                   │
│  │   4. Text-image counterpoint (caption ≠ visual)            │
│  │   5. No silent gaps (VO on every block)                    │
│  │   6. Variety pacing (mix 1.2s-4.0s durations)              │
│  │   7. Callback structure (CTA echoes hook)                  │
│  ├── Per-block output:                                         │
│  │   - spoken_dialogue (with *emphasis* markers)               │
│  │   - text_overlay (caption text + emphasis segments)         │
│  │   - visual_description (scene, camera, lighting)            │
│  │   - emotion tag (for emotional arc)                         │
│  │   - block_code (AIDA phase)                                │
│  │   - duration_s (with variety)                               │
│  └── Output: Script Variants JSON                              │
├─────────────────────────────────────────────────────────────┤
│  STEP 4: SCRIPT QA (creative-qa Stage 1)                      │
│  ├── 7 Craft Rules validation (40 points)                     │
│  ├── brand-voice-check.sh (never-list, tone, AI slop)         │
│  ├── Language check (dialect, code-switching rules)            │
│  └── PASS (≥30/40) → continue | FAIL → rewrite               │
├─────────────────────────────────────────────────────────────┤
│  STEP 5: CHARACTER + SCENE PLANNING                           │
│  ├── CHARACTER CONSISTENCY:                                    │
│  │   ├── Generate character reference image (NanoBanana)      │
│  │   ├── Face-lock: pick best → use as anchor for ALL scenes  │
│  │   ├── LoRA training (if brand character):                  │
│  │   │   80-120 images → Replicate Flux → $2 in 20min        │
│  │   │   trigger_word=BRANDSTYLE, steps=1000, rank=32(face)   │
│  │   ├── Define: ethnicity, age, hair (ALL CAPS), clothing    │
│  │   ├── Hair rule: "SHOULDER-LENGTH FALLING JUST PAST        │
│  │   │   HER COLLARBONES — NOT SHORT NOT BOB"                 │
│  │   └── iPhone artifacts: "computational bokeh with           │
│  │       imperfect edge detection on hair flyaways"            │
│  ├── SCENE PLANNING (per block):                               │
│  │   ├── Environment: kitchen, office, café, gym, etc.        │
│  │   ├── Lighting: warm 3200K, cool 5600K, golden hour        │
│  │   ├── Camera height: 80cm=UGC, face=neutral, 10cm=dramatic │
│  │   ├── Lens: 26mm wide, 50mm portrait, 85mm beauty          │
│  │   ├── Aperture: f/1.8 shallow, f/4 medium, f/8 deep       │
│  │   ├── Attire: match scene (gym=activewear, office=smart)   │
│  │   ├── Props: product placement, food (REAL, never AI)      │
│  │   └── Background: consistent across scene group             │
│  └── Output: Scene Plan JSON (per-block visual specs)          │
├─────────────────────────────────────────────────────────────┤
│  STEP 6: REFERENCE IMAGE GENERATION                            │
│  ├── NanoBanana (Gemini Image API / Nano Banana 2):            │
│  │   ├── Hero image from brief (face-locked if character)     │
│  │   ├── 3-5 scene reference images                           │
│  │   ├── Edit-first technique: "Edit this image, swap X"      │
│  │   │   PRESERVE: face, hair, body proportions               │
│  │   │   CHANGE: background, attire, lighting, props          │
│  │   ├── 5-dimension scoring (≥3.0 avg):                      │
│  │   │   Angle, Authenticity, Adaptability, Mood, Platform    │
│  │   └── Reject < 3.0, regenerate                             │
│  ├── For multi-outfit montage:                                 │
│  │   ├── Character sheet in every prompt (Sora 2 method)      │
│  │   ├── 80% face consistency across shots                     │
│  │   └── Costume changes only between scene groups             │
│  └── Output: Locked Reference Set (scored, face-locked)        │
├─────────────────────────────────────────────────────────────┤
│  STEP 7: VOICEOVER GENERATION                                  │
│  ├── ElevenLabs v3 (11-voice pool):                            │
│  │   ├── Clone voice if brand character:                       │
│  │   │   Wei Lin EN=7Pct5JNpyzIzXFvnjC28                      │
│  │   │   Wei Lin CN=T4sgU6880ectKy02hYjL                      │
│  │   ├── Read spoken_dialogue from script                      │
│  │   ├── char_timestamps for word-level sync                   │
│  │   └── Output: VO MP3 + timestamps JSON                     │
│  ├── AUDIO SPECS:                                              │
│  │   ├── Normalize to -14 LUFS (broadcast standard)            │
│  │   ├── Sample rate: 44.1kHz                                  │
│  │   └── VO duration must match block durations (±0.5s)        │
│  ├── BGM SELECTION:                                            │
│  │   ├── Mood-match from bgm-library.json (15 tracks)         │
│  │   ├── Volume: 0.2-0.25 (duck on speech)                    │
│  │   └── Fade out last 2s                                      │
│  ├── SFX MAPPING (from sfx-mapping.json):                      │
│  │   ├── whoosh: transitions (-0.1s offset)                    │
│  │   ├── pop_ding: emphasis words (0.0s)                       │
│  │   ├── chime_cta: CTA blocks (0.0s)                          │
│  │   ├── page_flip: image transitions                          │
│  │   ├── magic_reveal: reveal moments                          │
│  │   ├── variety_boom: stat emphasis                           │
│  │   └── reaction: emotional moments                           │
│  └── Output: VO MP3 + char_timestamps + BGM + SFX mapped       │
├─────────────────────────────────────────────────────────────┤
│  STEP 8: VIDEO CLIP GENERATION                                  │
│  ├── MODEL ROUTING (auto-select):                               │
│  │   ├── Food content → NEVER AI (use real clips from library) │
│  │   ├── Multi-outfit montage → Sora 2 ($0.50/4s)             │
│  │   ├── Face-locked single scene → Kling 3.0 Pro i2v ($0.33) │
│  │   ├── Beat-synced music → Seedance 2.0 ($0.05/s via PiAPI) │
│  │   ├── Quick test → Kling Standard ($0.03/s)                 │
│  │   ├── Cinematic hero → Sora 2 Pro ($1.00/5s)                │
│  │   ├── Multi-scene → Kling [cut] technique                   │
│  │   │   "Scene 1 description [cut] Scene 2 [cut] Scene 3"    │
│  │   ├── Talking head → Seedance 1.5 Pro ($0.05/s via FAL)    │
│  │   └── Add motion → Veo 3.1 ($0.15/s via FAL)               │
│  ├── GENERATION (per block):                                    │
│  │   ├── Upload reference image as input                        │
│  │   ├── Ultra-precise prompt:                                  │
│  │   │   - Lens (26mm), aperture (f/1.8), color temp (3200K)  │
│  │   │   - Camera height in cm (80cm for UGC)                  │
│  │   │   - Hair ALL CAPS                                        │
│  │   │   - iPhone artifacts for authenticity                    │
│  │   │   - "Edit this image" > "Create new"                    │
│  │   ├── Generate 5-8s clips per block                          │
│  │   └── Retry failed clips only                                │
│  ├── LIPSYNC (for talking-head blocks):                         │
│  │   ├── InfiniteTalk/Wavespeed ($0.06/s) for lip-sync         │
│  │   ├── Input: character image + VO audio                      │
│  │   ├── char_timestamps lock mouth movements to words          │
│  │   └── Or: Seedance with audio input (native sync)            │
│  ├── VISION QA (per clip):                                      │
│  │   ├── Face match check (consistent with reference)           │
│  │   ├── No drift / morphing / extra limbs                      │
│  │   ├── Lighting consistency across clips                      │
│  │   ├── Attire consistency within scene group                  │
│  │   └── Regenerate failures only (save $$)                     │
│  └── Output: Raw clips (5-8 × 5-8s each)                       │
├─────────────────────────────────────────────────────────────┤
│  STEP 9: ASSEMBLY (Remotion or FFmpeg)                          │
│  ├── TIER 1 — REMOTION ($0/render, premium):                    │
│  │   ├── Load UGCComposition with blocks JSON                   │
│  │   ├── 15 components: VideoBlock, TextOverlay, KineticText,  │
│  │   │   EndCard, BrandReveal, FilmGrain, LightLeak, etc.      │
│  │   ├── Transitions: fade, slide_up, push_close, blur_zoom    │
│  │   ├── Captions: 4 presets (cn_black_outline, cn_polished,   │
│  │   │   en_black_outline, en_polished)                         │
│  │   ├── char_timestamps → word-level highlight                 │
│  │   ├── Emphasis rendering: salmon color, 1.25x scale          │
│  │   ├── Fixed lower_third position (540px from bottom)         │
│  │   └── remotion-render.sh render --props plan.json            │
│  ├── TIER 2 — FFMPEG (video-forge, $0, fallback):               │
│  │   ├── video-forge.sh assemble (concatenate + transitions)   │
│  │   ├── video-forge.sh caption (Whisper → SRT → overlay)      │
│  │   ├── video-forge.sh music (BGM + speech ducking)           │
│  │   └── video-forge.sh effects (grade + grain + vignette)     │
│  └── Output: Assembled video with captions + audio              │
├─────────────────────────────────────────────────────────────┤
│  STEP 10: POST-PRODUCTION (video-forge)                         │
│  ├── Color grade: warm (food), cool (tech), cinematic           │
│  ├── Film grain: ALWAYS LAST (noise=alls=3:allf=t)             │
│  ├── Vignette: subtle darkening at edges                        │
│  ├── Brand overlay: logo PNG (not drawtext)                     │
│  ├── Platform export: TikTok, Reels, Shorts safe zones          │
│  │   ├── TikTok: top 15% and bottom 25% safe                   │
│  │   ├── Reels: top 10% and bottom 20% safe                    │
│  │   └── Shorts: similar to TikTok                              │
│  └── Output: Platform-ready videos                              │
├─────────────────────────────────────────────────────────────┤
│  STEP 11: QUALITY GATE (creative-qa)                            │
│  ├── Script audit: 40pts (7 Craft Rules + brand voice)          │
│  ├── Audio audit: 30pts (pacing, LUFS, silence, pronunciation) │
│  ├── Video audit: 30pts (face, artifacts, captions, brand)      │
│  ├── ≥80 PASS → ship                                           │
│  ├── 60-79 WARN → review                                       │
│  ├── <60 FAIL → back to Step 3/6/8                              │
│  └── brand-voice-check.sh mandatory before publish              │
├─────────────────────────────────────────────────────────────┤
│  STEP 12: DISTRIBUTION + LEARNING                               │
│  ├── social-publish → Instagram (feed/reel/story)               │
│  ├── tiktok-posting → TikTok                                    │
│  ├── Register blocks in video-block-library                     │
│  ├── Track: cost per video, generation times, model used        │
│  ├── Meta Ads performance → learnings injection                 │
│  └── knowledge-compound → system gets smarter                   │
└─────────────────────────────────────────────────────────────┘
```

---

## CONSISTENCY RULES (Character + Scene)

### Character Consistency Across Blocks:
1. **Face-lock**: Generate ONCE → use as reference for ALL subsequent generations
2. **LoRA**: For brand characters, train LoRA (80-120 images, $2, 20min)
3. **Hair ALL CAPS**: Exact description in every prompt
4. **Clothing**: Define per scene group, not per block
5. **Body proportions**: Reference image controls this
6. **Expression**: Match emotion tag from script

### Scene Consistency Within Groups:
1. **Environment**: Same location for blocks in same scene group
2. **Lighting**: Same color temperature (Kelvin) within group
3. **Camera angle**: Vary for interest but maintain spatial logic
4. **Props**: Consistent placement (product always visible)
5. **Time of day**: Consistent within group (morning light stays morning)

### When Things CHANGE (by design):
1. **Outfit**: Changes between scene groups (morning→gym→office)
2. **Location**: Changes between scene groups
3. **Lighting**: Changes to match location (warm kitchen→cool office)
4. **Mood**: Follows emotional arc from script

---

## TIMESTAMP MATCHING (VO → Captions → Lipsync)

```
VOICEOVER generates:
  Audio MP3 + char_timestamps[]

char_timestamps maps to:
  [0.0, 0.12, 0.25, 0.38, ...]  ← one per character

Remotion TextOverlay reads:
  char_timestamps → reveals characters one-by-one
  emphasis[] → highlights key phrases at larger size + brand color

Lipsync (InfiniteTalk) reads:
  VO audio → maps mouth movements to phonemes
  char_timestamps → syncs lip shapes to exact word timing

Block assignment:
  block_1: start_s=0, duration_s=3.2 → VO chars 0-48
  block_2: start_s=3.2, duration_s=4.1 → VO chars 49-110
  ...
```

---

## COST PER VIDEO

| Component | Cost |
|-----------|------|
| Script generation (Gemini Flash) | ~$0.01 |
| VO (ElevenLabs, 40s) | ~$0.15 |
| Reference images (NanoBanana, 5 images) | $0 (Gemini free) |
| Video clips (Kling 3.0, 6 blocks × 5s) | ~$1.00 |
| Video clips (Seedance, 6 blocks × 5s) | ~$1.50 |
| Lipsync (InfiniteTalk, 30s) | ~$1.80 |
| Assembly (Remotion) | $0 |
| Post-production (FFmpeg) | $0 |
| **TOTAL typical 40s UGC ad** | **$1.50-3.50** |

vs. Agency: $500-2000/ad. vs. Manual: 4-8 hours.

---

## TOOLS MATRIX

| Step | Tool | Skill |
|------|------|-------|
| 1. Brief | creative-reasoning-engine | cre-to-brief.sh |
| 2. Plan | flow-alphabet.json | video-script-gen.sh flows |
| 3. Script | video-script-gen.sh | generate |
| 4. Script QA | creative-qa.sh | script |
| 5. Characters | nanobanana-gen.sh + LoRA | train-lora.sh (new) |
| 6. References | nanobanana-gen.sh | --ref-image |
| 7. Voiceover | ElevenLabs API | (needs skill) |
| 8. Clips | video-gen.sh | kling/sora/wan/seedance |
| 9. Assembly | remotion-render.sh | render --props |
| 10. Post-prod | video-forge.sh | effects/brand/export |
| 11. QA | creative-qa.sh | audit |
| 12. Publish | social-publish / tiktok-posting | jade-ig-poster |

---

## WHAT'S WIRED vs WHAT NEEDS BUILDING

### ✅ WIRED (working now):
- Step 1: creative-reasoning-engine + cre-to-brief.sh
- Step 2: flow-alphabet.json + sequence-templates
- Step 3: video-script-gen.sh generate
- Step 4: creative-qa.sh script + brand-voice-check.sh
- Step 6: nanobanana-gen.sh (images work)
- Step 8: video-gen.sh (kling/sora/wan work)
- Step 9: remotion-render.sh (kinetic/endcard/transitions work)
- Step 10: video-forge.sh effects/brand/export work
- Step 11: creative-qa.sh video
- Step 12: social-publish + tiktok-posting

### ⚠️ PARTIALLY WIRED:
- Step 5: Character planning (manual, no automation)
- Step 8: Seedance exists (seedance-gen.sh) but not in video-gen.sh CLI
- Step 9: video-forge.sh assemble (audio-less clips issue)
- Step 10: video-forge.sh caption (Whisper KMP workaround)

### ❌ NEEDS BUILDING:
- Step 5: LoRA trainer skill (timkoda method: $2, 20min, Replicate)
- Step 7: Voiceover skill (ElevenLabs API integration)
- Step 8: Lipsync skill (InfiniteTalk/Wavespeed integration)
- Step 8: Kling [cut] multi-scene in video-gen.sh
- Step 9: Full Remotion render with real video blocks (not just kinetic)
- Orchestrator: Single command that chains Steps 1-12
