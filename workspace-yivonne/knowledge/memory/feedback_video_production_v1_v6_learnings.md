---
name: Video Production V1-V6 Learnings — Complete Journey
description: Every lesson from 6 iterations of Mirra north star video. AI video generation, prompting, model routing, assembly, typography, forensic reference adaptation. CRITICAL for all future video production.
type: feedback
---

## Model Routing (proven March 2026)

1. **Sora 2 text-to-video** = best for diverse lifestyle scenes (different outfits, locations, actions). $0.50/4s clip. iPhone-raw aesthetic when prompted correctly.
2. **Kling v2.1 Pro image-to-video** = best for face consistency (element binding locks identity). But LOCKS the scene/outfit to the reference image — cannot change outfits or locations within one generation.
3. **Kling text-to-video** = fal.ai endpoint broken (submits but 404 on poll). Don't use.
4. **For same-character multi-outfit montage**: Sora with ultra-detailed character sheet is the best current approach. Describe EXACT face features, body type, skin tone, hair length/texture/color in every prompt. Not perfect but 80% consistent across shots.
5. **Library food clips** = always use for food. Never AI-generate food. 740 real clips available.

## Prompting (what works)

1. **Ultra-precise cinematography language**: specify lens (26mm, 12mm ultrawide), aperture (f/1.8, f/2.4), camera height in cm, angle in degrees, color temperature in Kelvin.
2. **iPhone artifacts make it real**: "computational bokeh with imperfect edge detection on hair flyaways", "slight barrel distortion from 12mm ultrawide front camera", "iPhone front-camera skin smoothing".
3. **Character sheet**: face shape, jaw width, eye shape/size/color, eyebrow thickness, nose shape, lip fullness, skin tone with warmth description, hair length + texture + color + parting + layers. Include in EVERY prompt.
4. **Hair length is the hardest to maintain**: Sora frequently shortens "shoulder-length" to bob. Must use ALL CAPS emphasis: "SHOULDER-LENGTH FALLING JUST PAST HER COLLARBONES — NOT SHORT NOT BOB".
5. **Camera height determines feel**: counter height (80cm) = looking up at person = UGC energy. Face height = neutral. Floor level (10cm) = dramatic exercise/action shots.

## What NOT to do (failures)

1. **Don't use library clips when they don't match the creative direction** (V1 failure)
2. **Don't use FFmpeg ASS subtitles for CJK** — font rendering breaks. Use drawtext with explicit fontfile= path.
3. **Don't try to be creative with the structure** — steal the reference 1:1, change only the content
4. **Don't skip scenes from the reference** — count EVERY cut, match EVERY scene
5. **Don't use Kling i2v for outfit changes** — it locks to the reference image's outfit
6. **Don't use flat BGM** — shape the volume with fade in/out minimum
7. **Don't skip CTA end card** — always close with branded Mirra WhatsApp CTA

## Assembly (what works)

1. **FFmpeg concat + drawtext** = functional but typography is basic (no animation, no spring physics, no effects)
2. **Remotion** = needed for world-class typography (kinetic text, word-by-word reveal, spring animations, emphasis scaling). Not yet implemented for this video.
3. **Film grain**: noise=alls=3:allf=t (subtle). Applied LAST.
4. **Vignette**: vignette=PI/7 (gentle). Applied with grain.
5. **Color grade**: eq brightness+0.02, contrast 1.05, saturation 1.08, colorbalance rs=0.02 gs=-0.005 bs=-0.03 (warm, not orange)
6. **Cut timing for montage**: first shot 3.5s (talking), rapid cuts 1.0s each, CTA 2.5s
7. **Two text cards only** for this format: resigned confession + empowered shift. Text stays same through montage while visuals rapid-fire.

## Still needs improvement

1. **Typography** = still plain drawtext, no animation/effects/aesthetic. Need Remotion KineticTextBlock.
2. **Hair consistency** across Sora shots = 80% not 100%. Some shots shorter than others.
3. **Face consistency** = "every woman" montage approach works but not same-girl. True same-girl needs real footage or better models.
4. **Audio design** = only BGM, no SFX, no ducking, no silence beat, no ASMR. Full audio design still needed.
5. **Color grade** = unified but basic. Could be more Mirra-specific (blush warmth).

## Cost tracking

- V1: $0 (library only) — garbage
- V2: ~$5 (2 Kling + 3 Sora + 1 ElevenLabs VO) — better footage, bad assembly
- V3: ~$5 (4 Sora + 1 ElevenLabs VO) — better footage, still wrong structure
- V4: ~$4 (8 Sora) — good footage, different girls. Then $9 (8 Kling face-locked) — same girl but all same outfit
- V5: ~$4 (8 Sora with character sheet) — better consistency, some keepers
- V6: ~$7 (8 Sora + 6 regen/new) — best batch, forensic 1:1 reference match, 14 scenes
- **Total spent learning: ~$34 in API costs across 6 versions**
