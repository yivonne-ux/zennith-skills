---
name: motionkit
description: GAIA MotionKit — Programmatic video compositions with Remotion
metadata:
  tags: remotion, video, react, animation, composition, motionkit, programmatic
---

## What This Is

MotionKit is a working Remotion v4 project for generating programmatic videos in the GAIA CORP-OS pipeline. It provides 5 composition templates that render brand-aware videos from structured data — no manual video editing needed.

## When to Use

- Podcast audiograms with waveform visualization and captions
- TikTok/Reels-style animated caption overlays on video
- Product showcase videos for e-commerce listings
- Brand intro/outro animations
- Animated data charts for reports and social posts

## Compositions

| ID | Format | Default Duration | Use Case |
|----|--------|-----------------|----------|
| PodcastClip | 1080x1080 | 30s | Square audiogram with waveform bars + word highlighting |
| AnimatedCaptions | 1080x1920 | variable | Video background + animated captions (tiktok/karaoke/bounce) |
| ProductShowcase | 1080x1920 | 15s | Product image + features + CTA |
| BrandIntro | 1080x1920 | 5s | Logo animation + tagline |
| DataChart | 1920x1080 | 10s | Animated bar or line chart |

## Quick Start

```bash
# 1. Setup (one time)
bash ~/.openclaw/skills/remotion/scripts/setup.sh

# 2. Open Remotion Studio (visual editor)
cd ~/.openclaw/skills/remotion/project && npm start

# 3. Render via CLI
bash ~/.openclaw/skills/remotion/scripts/render.sh brand-intro \
  --tagline "Plant-powered, Malaysian-hearted" \
  --brand gaia-eats
```

## CLI Render Examples

```bash
# Podcast clip
render.sh podcast-clip --audio podcast.mp3 --captions captions.json \
  --speaker "Jenn" --episode "Ep 1: Plant-Powered Living"

# Animated captions over video
render.sh animated-captions --video input.mp4 --captions captions.json \
  --style tiktok --position bottom

# Product showcase
render.sh product-showcase --image rendang.png --name "Rendang Paste" \
  --price "RM15.90" --features "100% Plant-Based,No MSG,Ready in 30 min"

# Brand intro
render.sh brand-intro --tagline "Plant-powered, Malaysian-hearted" --brand gaia-eats

# Data chart
render.sh data-chart --data sales.json --type bar --title "Monthly Sales" \
  --subtitle "Units sold" --y-label "Units"
```

## Brand Integration

All compositions read brand colors from `~/.openclaw/brands/<slug>/DNA.json` via the `--brand` flag. Colors are injected as the `brandColors` prop:

```json
{ "primary": "#8FBC8F", "secondary": "#DAA520", "background": "#FFFDD0", "accent": "#2E8B57" }
```

Fonts: Nunito (headings) + Open Sans (body) — matching GAIA brand DNA typography.

## Project Structure

```
~/.openclaw/skills/remotion/
├── SKILL.md                        ← This file
├── rules/                          ← 38 Remotion reference docs (unchanged)
├── scripts/
│   ├── setup.sh                    ← Install dependencies, verify Remotion
│   └── render.sh                   ← CLI render wrapper (auto-installs if needed)
└── project/
    ├── package.json
    ├── tsconfig.json
    ├── remotion.config.ts
    └── src/
        ├── index.ts                ← Entry point (registerRoot)
        ├── Root.tsx                ← Composition registry
        ├── components/
        │   ├── GradientBackground.tsx
        │   └── BrandLogo.tsx
        ├── compositions/
        │   ├── PodcastClip.tsx
        │   ├── AnimatedCaptions.tsx
        │   ├── ProductShowcase.tsx
        │   ├── BrandIntro.tsx
        │   └── DataChart.tsx
        └── utils/
            ├── types.ts
            ├── fonts.ts
            └── animations.ts
```

## Key Rules (from reference docs)

1. **All animations MUST use `useCurrentFrame()`** — no CSS transitions, no CSS keyframes, no Tailwind animation classes.
2. **Use `<Img>` from remotion** — never native `<img>`, never CSS background-image.
3. **Use `<Video>` from `@remotion/media`** — never native `<video>`.
4. **Spring animations** — `spring({ frame, fps, config: { damping: 200 } })` for smooth, `{ damping: 12 }` for bouncy.
5. **Captions** — use `@remotion/captions` with `createTikTokStyleCaptions()` for word-level highlighting.
6. **Audio visualization** — use `useWindowedAudioData()` + `visualizeAudio()` from `@remotion/media-utils`.
7. **Always clamp interpolations** — `{ extrapolateLeft: 'clamp', extrapolateRight: 'clamp' }`.
8. **Sequences reset frame** — inside `<Sequence>`, `useCurrentFrame()` returns 0-based local frames.

## Captions Format

Captions JSON follows the `@remotion/captions` `Caption` type:

```json
[
  { "text": " Hello", "startMs": 0, "endMs": 500, "timestampMs": 0, "confidence": 1 },
  { "text": " world", "startMs": 500, "endMs": 1000, "timestampMs": 500, "confidence": 1 }
]
```

Note: text includes leading space for whitespace-sensitive rendering.

## Data Chart Format

Data JSON is an array of `DataPoint` objects:

```json
[
  { "label": "Jan", "value": 120 },
  { "label": "Feb", "value": 180, "color": "#FF6B6B" }
]
```

## For Detailed API Reference

Read individual rule files in `./rules/` for deep Remotion API documentation:
- [rules/audio-visualization.md](rules/audio-visualization.md) — Spectrum bars, waveforms, bass-reactive effects
- [rules/display-captions.md](rules/display-captions.md) — TikTok-style captions with word highlighting
- [rules/charts.md](rules/charts.md) — Bar, pie, line charts with spring animations
- [rules/animations.md](rules/animations.md) — Fundamental animation patterns
- [rules/timing.md](rules/timing.md) — Interpolation, easing, spring configs
- [rules/compositions.md](rules/compositions.md) — Composition definitions, folders, metadata
- [rules/sequencing.md](rules/sequencing.md) — Sequence timing, series, nesting
- [rules/fonts.md](rules/fonts.md) — Google Fonts and local font loading
- [rules/images.md](rules/images.md) — Image embedding with `<Img>`
- [rules/videos.md](rules/videos.md) — Video embedding, trimming, volume
- [rules/text-animations.md](rules/text-animations.md) — Typewriter, word highlight effects
- [rules/transitions.md](rules/transitions.md) — Scene transition patterns
