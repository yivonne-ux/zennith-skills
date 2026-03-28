---
name: kinetic-text-reel
description: Generate kinetic typography reels (word-by-word, slide-reveal, style-showcase, quote-reel) using FFmpeg. Vertical 9:16 for TikTok/IG Reels.
agents:
  - dreami
  - taoz
---

# Kinetic Text Reel — Animated Typography Video Generator

Create short-form vertical video reels with animated text overlays using FFmpeg. No external API costs. Inspired by @ohneis652 "25 Design Styles in 40 Seconds" format.

## When to Use

- Creating TikTok/IG Reels with animated text
- Building style showcase reels (rapid-fire image + label)
- Generating quote reels for Jade Oracle / Luna
- Making word-by-word caption-style videos
- Building educational content with phrase transitions

## 4 Reel Types

| Type | What | Best For |
|------|------|----------|
| word-by-word | Words appear one at a time, TikTok caption style | Hook text, short messages |
| slide-reveal | Phrases fade in/out with transitions | Multi-point explanations |
| style-showcase | Rapid-fire images with text labels | Portfolio, design styles, product lineup |
| quote-reel | Single quote with Ken Burns zoom on background | Oracle cards, daily quotes, spiritual content |

## Quick Start

```bash
# Word-by-word (TikTok caption style)
bash ~/.openclaw/skills/kinetic-text-reel/scripts/kinetic-reel.sh word-by-word \
  --text "The universe is always listening to your energy" \
  --duration 8 --brand jade-oracle

# Slide reveal (multi-phrase)
bash ~/.openclaw/skills/kinetic-text-reel/scripts/kinetic-reel.sh slide-reveal \
  --text "Stop scrolling|This is your sign|The oracle speaks|Save this post" \
  --duration 12 --brand jade-oracle

# Style showcase (rapid images)
bash ~/.openclaw/skills/kinetic-text-reel/scripts/kinetic-reel.sh style-showcase \
  --images "card1.png,card2.png,card3.png" \
  --labels "The Phoenix,The Healer,The Sage" \
  --duration 15 --brand jade-oracle

# Quote reel (Ken Burns + text)
bash ~/.openclaw/skills/kinetic-text-reel/scripts/kinetic-reel.sh quote-reel \
  --text "Sometimes the universe whispers before it speaks" \
  --bg oracle-bg.png --duration 10 --brand jade-oracle
```

## Brand Presets

| Brand | BG | Accent | Font Color |
|-------|----|--------|------------|
| jade-oracle | Dark charcoal | Jade green #00A86B | White |
| luna | Ivory #FAF8F5 | Dusty rose #D4A5A5 | Charcoal |
| mirra | White | Green #2E7D32 | Dark |
| pinxin-vegan | Cream #F5F0E8 | Green #4CAF50 | Dark gray |

## Technical

- FFmpeg 8.0+ required (drawtext filter)
- Font: Impact (macOS system font) — bold condensed, reads well at small sizes
- Output: 1080x1920 (9:16 vertical), H.264, 30fps
- No external API costs — runs entirely local

## Key Constraints

- Keep text SHORT — max 8 words per frame for readability
- Use | delimiter for slide-reveal phrases
- Style-showcase needs pre-generated images (use NanoBanana first)
- Quote-reel wraps text at 25 chars per line (max 6 lines)
