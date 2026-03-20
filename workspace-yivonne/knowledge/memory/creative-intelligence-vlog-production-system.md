---
name: Vlog production system — proven end-to-end from mirra_cook session
description: Complete vlog production system. Proven March 17-18 2026. Reference-first workflow, NANO edit with mood/character anchoring, Kling PRO pipeline, FFmpeg post-production. Apply to ANY brand. READ alongside video-art-direction-mastery.md.
type: feedback
---

## THE BREAKTHROUGH: Reference-First, Not Imagination-First

**The #1 lesson from 15+ iterations:** NEVER generate from imagination. ALWAYS start from a real reference image that already has the art direction, mood, and angle you want. Then NANO edit it into the brand world.

**Why:** AI image generators (NANO, Imagen, FLUX) interpret text prompts unpredictably. "Warm cream-blush apartment" means something different every generation. But feeding a REAL Pinterest photo as reference + saying "keep exact same mood, change the scene to X" = consistent output.

**The workflow that works:**
```
1. SCRAPE real references (Pinterest, XHS, vlog screenshots)
2. PICK the ones with the right vibe
3. NANO EDIT each reference into the brand world
4. Use ONE generated image as CHARACTER + MOOD ANCHOR for all others
5. Kling PRO i2v for motion
6. FFmpeg post-production pipeline
```

---

## VLOG-SPECIFIC RULES (proven)

### What makes it feel like a REAL vlog (not a commercial):

1. **MIX camera types** — tripod + mirror selfie + handheld + phone POV. Never all one type.
2. **Phone-placement angles** — phone on shoe rack looking up, phone on coffee table, phone on bed, mirror selfie, POV top-down on food. These are vlog angles. NOT cinema angles.
3. **Face CLOSE to camera** for selfie/eating shots — arm's length, front camera energy
4. **Lived-in apartment** — books, remote, lip balm, phone charger, tossed blanket. NOT showroom.
5. **Speed variation** — mundane parts (arriving, changing) at 1.3x, key moments (sofa, eating) at 1.0x
6. **Same character across ALL shots** — use one generated image as anchor, reference it in every NANO edit
7. **Same apartment/props** — white coffee table, cream sofa, same mug, same remote recurring
8. **Text minimal** — one timestamp is enough. Real vlogs don't have manifesto text overlays.
9. **No transitions** — hard cuts between scenes. No zoom punch, no spring animation. Just cut.
10. **BGM from start** — clean background music, no SFX unless organic. No dramatic pauses.

### What kills the vlog feel (mistakes I made):

- ❌ "Cinematic" doorframe/through-glass/overhead compositions = FILM, not vlog
- ❌ Dark moody lighting with dramatic shadows = HORROR, not vlog
- ❌ Same camera distance for every shot = BORING
- ❌ Perfectly staged showroom apartment = FAKE
- ❌ European/Western apartment aesthetics for Asian audience = DISCONNECT
- ❌ AI-generated lifestyle photos without reference = STOCK FOOTAGE
- ❌ Spring-animated text, scale-bounce labels = OVERPRODUCED
- ❌ Multiple text overlays per scene = COMMERCIAL, not vlog
- ❌ Top-down editorial food shot = FOOD BLOG, not vlog (vlog = face + food toward camera)

---

## CHARACTER CONSISTENCY METHOD

1. Generate first batch of shots
2. Pick the BEST one where the character is clearest (face, hair, body visible)
3. Use THAT image as the anchor reference for ALL subsequent NANO edits
4. In every prompt: "Same woman as reference — same face, same dark brown shoulder-length hair, same skin tone"
5. Use 2 reference images: CHARACTER anchor + ANGLE reference

---

## MOOD CONSISTENCY METHOD

1. Find ONE Pinterest photo with the exact mood/lighting/white balance you want
2. Every NANO edit starts with: "Keep exact same mood, lighting, white balance as reference"
3. Let the reference image carry the mood — don't describe it in words
4. SHORT prompts — only describe what CHANGES, not the mood

---

## PRODUCTION PIPELINE (proven, use for ANY brand)

```
STAGE 1: REFERENCES
├── Pinterest scraper (playwright) — 10+ queries, 3-4 images each
├── User picks favorites
├── NANO edit into brand world (mood anchor + scene prompt)
├── Character anchor selected from best generation
└── Human approval before proceeding

STAGE 2: VIDEO — Kling 3.0 PRO (fal-ai/kling-video/v3/pro/image-to-video)
├── MUST use PRO tier for native 9:16 (standard = square!)
├── Duration: 5s per clip
├── Negative prompt: "blur, distort, watermark, text, jittery, morphing"
├── For eating: "lips closed, subtle jaw, no exaggerated movement"
├── Negative for eating: "exaggerated jaw, face distortion, warping, open mouth"
└── 3-5 min per clip on PRO

STAGE 3: SCALE — FFmpeg
└── scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920

STAGE 4: GRADE — FFmpeg colorbalance
├── Brand-specific color shift (Mirra: rs=0.02:bs=-0.015:rm=0.01)
└── NOT CSS blend modes in Remotion

STAGE 5: TRIM — FFmpeg
├── Cut first 0.5s of EVERY Kling clip (AI jitter on frame 1)
├── Speed up mundane scenes: setpts=PTS/1.3
├── Normal speed for key moments
└── Text overlay via drawtext on first clip only

STAGE 6: AUDIO — pydub
├── Clean BGM from start, consistent volume
├── Fade in 500ms, fade out 2000ms
└── Keep it simple — no SFX unless organic

STAGE 7: CONCAT + GRAIN — FFmpeg
├── Concat all clips (MUST match fps + pix_fmt)
├── ALL clips must be 30fps + yuv420p (mismatch = playback pause!)
├── Grain: noise=alls=8:allf=t (lighter = smaller file)
└── CRF 22 for reasonable file size

STAGE 8: MERGE — FFmpeg
└── -c:v copy -c:a aac -b:a 192k -shortest
```

---

## CRITICAL TECHNICAL BUGS (never repeat)

1. **yuv444p** — Kling sometimes outputs yuv444p. Most players can't play it. Always re-encode with `-pix_fmt yuv420p`.
2. **FPS mismatch** — mixing 24fps and 30fps clips in concat = playback pauses/stutters. Normalize ALL clips to 30fps before concat.
3. **Ending card disappears** — static PNG → video at high CRF compresses to nearly nothing if the image is mostly white. Use CRF 1 or ensure the ending card video is generated separately with quality settings.
4. **Non-breaking spaces in filenames** — macOS screenshots have invisible special characters. Always copy to clean filenames before processing.
5. **NANO edit inherits reference dimensions** — if reference is square, output is square. Must crop/resize reference to 9:16 first, OR specify in generation mode with image_size.
6. **Kling standard = SQUARE** — always use `v3/pro` not `v3/standard` for 9:16 content.

---

## APPLYING TO ANY BRAND

This system works for any brand by changing:

1. **Pinterest search queries** — match the brand's aesthetic + target audience lifestyle
2. **Mood anchor image** — find the ONE photo that captures the brand's visual DNA
3. **Color grade values** — adjust FFmpeg colorbalance to brand palette
4. **Character brief** — age, ethnicity, style, wardrobe for the target persona
5. **Story beats** — what does the target customer's day/evening look like?
6. **Props** — what objects define this person's life? (brand-specific items appear naturally)
7. **Text** — minimal, matches brand voice
8. **BGM** — matches brand energy

The PIPELINE stays the same. The CONTENT changes per brand.

---

## WHAT 8/10+ REQUIRES (not yet achieved)

1. **Better music selection** — need a music library matched to brand moods, not random tracks
2. **Real footage mix** — AI video + real phone footage composited together would be undetectable
3. **Character LoRA** — train a LoRA on one face for perfect consistency across unlimited generations
4. **ComfyUI/RunningHub pipelines** — chain models for higher quality (WanVideo + InfiniteTalk + LoRAs)
5. **Proper color LUT** — brand-specific 3D LUT instead of colorbalance approximation
6. **Audio-visual sync** — librosa beat detection driving cut points automatically
7. **Template system** — proven sequences stored as templates, swap footage per brand/campaign
