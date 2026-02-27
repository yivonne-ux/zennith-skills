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
- `--brand <brand>` — Brand slug (loads DNA for motion_language)
- `--duration <seconds>` — Target duration
- `--aspect-ratio <ratio>` — 16:9, 9:16, 1:1
- `--output-type <type>` — Output type from output-types.json (applies style params)
- `--output <path>` — Output file path (default: auto-generated in workspace/data/videos/)

## Brand DNA Integration
When `--brand` is specified, loads `~/.openclaw/brands/{brand}/DNA.json` and applies:
- `motion_language` → prompt enhancement
- `visual_identity.colors` → color guidance
- `voice.tone` → mood guidance

## Cost Estimates
- Kling text2video: ~$0.30
- Kling image2video: ~$0.30
- Wan text2video: ~$0.20
- Wan image2video: ~$0.20
- Wan image2video-pro: ~$0.80
- Sora generate: ~$0.50
