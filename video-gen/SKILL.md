---
name: video-gen
agents: [iris, taoz]
description: Unified video generation skill — Kling, Wan, Sora
---

# Video Generation Skill

Unified CLI for video generation across multiple providers.

## Usage
bash scripts/video-gen.sh <provider> <command> [options]

## Providers
- **kling**: Kling AI — text2video, image2video (KLING_ACCESS_KEY, KLING_SECRET_KEY)
- **wan**: Wan 2.2 via fal.ai — text2video, image2video, image2video-pro (FAL_API_KEY)
- **sora**: Sora 2 via OpenAI — generate, image2video (OPENAI_API_KEY)

## Commands
- `<provider> text2video` — Generate video from text prompt
- `<provider> image2video` — Generate video from image + prompt
- `<provider> status <task-id>` — Check generation status
- `<provider> download <task-id>` — Download completed video
- `status <task-id>` — Auto-detect provider from task ID prefix
- `pipeline` — Chain: NanoBanana images → video gen → video-forge assembly
- `reverse-prompt` — Extract frames from video → Gemini Vision analysis

## Options
- `--prompt "..."` — Generation prompt
- `--image <path>` — Input image for image2video
- `--brand <brand>` — Brand slug (loads DNA + auto-selects reference image)
- `--duration <seconds>` — Target duration
- `--aspect-ratio <ratio>` — 16:9, 9:16, 1:1
- `--output-type <type>` — Output type from output-types.json (applies style params)
- `--output <path>` — Output file path (default: auto-generated in workspace/data/videos/)
- `--auto-ref` — Explicitly enable auto-reference image selection (auto when --brand is set)
- `--no-forge` — Skip auto post-production after generation

## Auto-Reference Image (IMPORTANT)
When `--brand` is specified and NO `--image` is provided:
1. Scans `~/.openclaw/brands/{brand}/references/products-flat/` for matching product photos
2. Matches product keywords from prompt (e.g., "fusilli" → Fusilli-Bolognese-Top-View.png)
3. Falls back to first available product photo if no keyword match
4. Switches from text-to-video to IMAGE-TO-VIDEO automatically
5. This ensures videos show REAL product visuals, not AI hallucinations

**Reference library structure:**
```
brands/{brand}/references/
├── products-flat/    ← Top-view product photos (used for video refs)
├── products/         ← Nested product refs with metadata
├── styles/           ← Style reference images
├── compositions/     ← Layout templates
├── graphics/         ← Logos, badges, brand elements
└── videos/           ← Video style references (for reverse-prompting)
```

## Post-Generation Pipeline (automatic)
After EVERY video generation:
1. **Seed Store** — registers in content-seed-bank for tracking
2. **Creative Room** — posts to creative room for team visibility
3. **Auto Video-Forge** — if `--brand` is set, runs `video-forge brand` for logo/watermark
4. **Iris QA Room** — posts to iris-qa room for visual quality review

## The RIGHT Way to Generate Videos
```bash
# WRONG — text-only, no reference, no post-prod:
bash video-gen.sh sora generate --prompt "bento box" --brand mirra

# RIGHT — auto-ref finds product photo, switches to image2video, auto-forges:
bash video-gen.sh sora generate --prompt "Top-down reveal of fusilli bolognese bento" --brand mirra --duration 8 --aspect-ratio 9:16

# BEST — full pipeline (NanoBanana scene images → video → assemble):
bash video-gen.sh pipeline --prompt "Mirra weekly menu reveal" --brand mirra --provider sora --scenes 5 --duration 4
```

## Brand DNA Integration
When `--brand` is specified, loads `~/.openclaw/brands/{brand}/DNA.json` and applies:
- `motion_language` → prompt enhancement (vibe, camera, audio cues)
- `visual_identity.colors` → color guidance
- `voice.tone` → mood guidance
- `references/products-flat/` → auto-reference image selection
- MIRRA-specific: bento box instructions, UGC style, shallow DOF

## Sora 2 CRITICAL Rules
- Duration: ONLY `"4"`, `"8"`, `"12"` seconds — **STRINGS not integers!**
- Sizes: `"720x1280"` (9:16), `"1280x720"` (16:9), `"720x720"` (1:1) — **STRINGS**
- API param: `seconds` (NOT `duration`)
- **Download within 1 hour** or link expires
- Cannot: text overlays (use VideoForge post-prod), abstract concepts, multiple scenes per prompt
- Blocks: face images in `input_reference`, catsuit/tight on feminine bodies
- For face lock video: use Kling 3.0 elements mode instead

### Sora 2 Prompt Style
Sora responds well to cinematography vocabulary:
- Camera: handheld, tripod, Steadicam, gimbal, drone, dolly
- Movement: pan, tilt, push-in, pull-back, tracking, orbit, rack focus
- Shot: extreme close-up, close-up, medium, wide, POV, over-shoulder
- Lens: wide-angle, telephoto, macro, 35mm, 50mm, anamorphic
- Film: Kodak Portra 400, Fuji Velvia, CineStill 800T
- Lighting: natural daylight, golden hour, blue hour, side-lit, backlit

### Duration Guide
- 4s: Single action (pour, look up, smile)
- 8s: Action + reaction (make bowl → present)
- 12s: Mini story (enter → prepare → reveal)

## Kling 3.0 CRITICAL Rules
- Face lock: MUST use `frontal_image_url` (not `image_url`) + `reference_image_urls` array
- `elements` mode locks face identity in generated video
- Standard: ~$0.28/5s | Pro: ~$1.40/10s
- Check fal.ai balance before batch: `403 Exhausted balance` = hard stop

## PAS Format (Problem-Agitate-Solution) for Video
Maps to Tricia's Three-Beat UGC Framework:
- P = Beat 1 HOOK (0-3s): "I/You [relatable problem]..." — handheld eye-level, natural bounce
- A = Beat 2 SENSORY PROOF (3-8s): "Look at this [crispy/steaming]..." — push-in, shallow DOF
- S = Beat 3 VIBE SHIFT (8-12s): "Finally/Honestly? [result + CTA]" — medium shot, pull-back

### Script Power Words → Sora Actions
- "Look at this..." → camera pan or hold-up gesture
- "Crunchy / Fresh" → high-detail textures, sharp lighting
- "Finally" / "Wow" → relief/excitement micro-expression
- "Honestly?" → specific head tilt (looks more human)

## Cost Estimates
- Kling text2video: ~$0.30
- Kling image2video: ~$0.30
- Wan text2video: ~$0.20
- Wan image2video: ~$0.20
- Wan image2video-pro: ~$0.80
- Sora generate: ~$0.50

## OpenClaw Integration
This skill is wired into the GAIA OS pipeline:
- **classify.sh**: Video generation routes to DREAMI (scripts/concepts) or SCRIPT tier (direct gen)
- **Agents**: Dreami writes video briefs, Iris oversees visual QA, Taoz builds pipeline
- **Cron**: Scheduled batch generation via OpenClaw cron (optional)
- **Hooks**: post_generate() auto-registers, auto-forges, auto-QA
- **E2E flow**: WhatsApp → Zenni → classify → agent → video-gen.sh → video-forge → Iris QA → creative room
