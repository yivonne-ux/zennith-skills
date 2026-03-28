---
name: remotion-renderer
agents:
  - taoz
  - dreami
---

# Remotion Renderer — Zennith OS Skill

## What This Is

React-based video renderer using Remotion v4.0.435. Produces pixel-perfect, templated video at $0/render. Ported from Tricia's battle-tested 15-component system (video-compiler) and extended for multi-brand support across all 14 Zennith OS brands.

## When To Use

| Use Case | Example | Cost |
|----------|---------|------|
| Daily oracle card reveal (Jade) | Template: card image + name + meaning + animation | $0 |
| Daily meal announcement (MIRRA) | Template: food photo + price + CTA + music | $0 |
| Quote reels (Luna) | Template: text + background + word-by-word highlight | $0 |
| Brand intros/outros | Template: logo + tagline + transition | $0 |
| Captioned reels | Whisper transcribe → TikTok-style word highlighting | $0 |
| Kinetic typography | Spring-based text animations (8 modes) | $0 |
| UGC ad assembly | Multi-block AIDA video with transitions + effects | $0 |
| Data visualization reels | Charts + animations from analytics data | $0 |

## NOT For

- AI video generation (use video-gen.sh for Kling/Sora/Wan/Seedance)
- FFmpeg-only post-production (use video-forge.sh)
- Quick draft kinetic reels (use kinetic-reel.sh PIL fallback)

## Architecture

```
Tier 1: REMOTION (this skill) — $0/render, deterministic, pixel-perfect
Tier 2: AI VIDEO GEN (video-gen.sh) — per-video cost, novel content
Tier 3: POST-PROD (video-forge.sh) — FFmpeg effects, $0
```

## 15 Components

| Component | Purpose |
|-----------|---------|
| UGCComposition | Main composition — assembles blocks with transitions |
| TextOverlay | Caption rendering with char_timestamps, 4 style presets |
| KineticTextBlock | 4 animation styles: word_pop, line_slide, typewriter, scale_bounce |
| KineticOverlay | 8 animation modes: slam, blur_reveal, slide_up/down, elastic, typewriter, fade_scale, drop |
| EndCard | Branded CTA card with product images |
| BrandRevealBlock | 3 reveal styles: zoom_burst, cascade_in, orbit |
| VideoBlock | Video playback with Ken Burns + camera punch + shake |
| BrandWatermark | Logo overlay (PNG-based, full-frame) |
| FilmGrain | SVG turbulence grain (animated per-frame) |
| LightLeak | Gradient glow effect (5 positions) |
| MangaSpeedLines | Radial impact lines for emphasis |
| FoodCollageBlock | 4 layouts: grid_2x2, grid_3x2, masonry, diagonal |
| SplitScreenBlock | Before/after reveal with wipe animation |
| PersistentBadge | Always-visible CTA badge |
| ImageBlock | Static image with Ken Burns zoom |

## Usage

```bash
# Preview in browser (development)
cd skills/remotion-renderer && npm run preview

# Render UGC composition from JSON props
remotion-render.sh render --props props.json --output video.mp4

# Render with brand override
remotion-render.sh render --props props.json --brand jade-oracle --output video.mp4

# Quick kinetic text render
remotion-render.sh kinetic --text "Your daily oracle message" --style word_pop --brand jade-oracle

# Quick brand reveal render
remotion-render.sh brand-reveal --brand mirra --products "img1.png,img2.png" --style zoom_burst
```

## Props Format (JSON)

```json
{
  "variant_id": "mirra_v1",
  "fps": 30,
  "total_duration_s": 45,
  "width": 1080,
  "height": 1920,
  "blocks": [
    {
      "id": "block_1",
      "type": "kol_video",
      "file": "file:///path/to/clip.mp4",
      "duration_s": 5,
      "start_s": 0,
      "text_overlay": {
        "text": "This changed my life",
        "style": "bold",
        "position": "lower_third",
        "emphasis": [{ "text": "changed", "color": "#F7AB9F" }]
      }
    }
  ],
  "voiceover": null,
  "bgm": "file:///path/to/bgm.mp3",
  "bgm_volume": 0.25,
  "watermark": { "text": "MIRRA", "opacity": 0.85 }
}
```

## Brand Support

5 brand presets built in: mirra, jade-oracle, luna, pinxin-vegan, rasaya.
Each brand gets its own colors, fonts, and accent colors.
Add new brands by extending `src/brandConfig.ts`.

## Files

```
skills/remotion-renderer/
├── SKILL.md
├── package.json              # Remotion v4.0.435 + React 18
├── tsconfig.json
├── remotion.config.ts
├── src/
│   ├── index.ts              # Entry point
│   ├── Root.tsx               # Composition registry
│   ├── UGCComposition.tsx     # Main UGC composition (35KB)
│   ├── HelloWorld.tsx         # Test composition
│   ├── types.ts               # Block/overlay/config types
│   ├── fonts.ts               # Font loader (CN + EN)
│   ├── defaultProps.ts        # Example props (Mirra 50s UGC)
│   ├── brandConfig.ts         # Multi-brand color/font config
│   └── components/
│       ├── TextOverlay.tsx    # Caption system (34KB)
│       ├── KineticTextBlock.tsx
│       ├── KineticOverlay.tsx
│       ├── EndCard.tsx
│       ├── BrandRevealBlock.tsx
│       ├── VideoBlock.tsx
│       ├── BrandWatermark.tsx
│       ├── FilmGrain.tsx
│       ├── LightLeak.tsx
│       ├── MangaSpeedLines.tsx
│       ├── FoodCollageBlock.tsx
│       ├── SplitScreenBlock.tsx
│       ├── PersistentBadge.tsx
│       ├── ImageBlock.tsx
│       └── LogoSting.tsx
├── config/
│   ├── text-style-presets.json
│   ├── color-grades.json
│   ├── sfx-mapping.json
│   └── flow-alphabet.json
├── public/
│   ├── fonts/                 # Brand fonts (CN + EN)
│   └── *.png, *.mp4           # Brand assets
└── scripts/
    └── remotion-render.sh     # CLI wrapper
```

## Cost

$0 per render. Remotion renders locally using React + FFmpeg.
Batch 100 videos = same $0. No API calls.
