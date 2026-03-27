# Brand Rules, Integration & Quality

## Brand-Aware Processing

### DNA Loading

Every repurpose operation starts by loading the brand's DNA:

```bash
BRAND_DNA="~/.openclaw/brands/${BRAND}/DNA.json"
BRAND_COLORS=$(jq -r '.colors' "$BRAND_DNA")
BRAND_FONT=$(jq -r '.font' "$BRAND_DNA")
BRAND_LOGO=$(jq -r '.logo' "$BRAND_DNA")
BRAND_MOOD=$(jq -r '.mood' "$BRAND_DNA")
BRAND_VOICE=$(jq -r '.voice' "$BRAND_DNA")
```

### Brand Overlay Rules

| Element | Rule |
|---------|------|
| Logo | Always placed in platform-safe zone. Size: 12-18% of image width. |
| Watermark | Semi-transparent (30% opacity) centered watermark for draft/preview variants only. Removed for final. |
| Brand colors | Used for text overlays, borders, gradient backgrounds on padded formats. |
| Font | Brand font for all text overlays. Fall back to system sans-serif if custom font unavailable. |
| Mood/tone | Informs copy adaptation tone. Loaded from DNA, passed to Dreami for copy repurposing. |

### Brand-Specific Overrides

| Brand | Special Rules |
|-------|--------------|
| mirra | Weight management meal subscription (bento format). Always warm tones. Logo top-left on Shopee (brand requirement). |
| pinxin-vegan | Dark forest green #1C372A backgrounds with gold #d0aa7f accents. Always include "100% Plant-Based" badge on Shopee. GrabFood banner: 1200x628 with bold food hero shot, dark green gradient left edge for text, gold CTA button. WhatsApp catalog: nasi lemak/rendang close-up, no text overlay (product speaks). Shopee feed: high-contrast food on dark green, steam/smoke visible. Light beige #F2EEE7 for EDM backgrounds. AVOID: washed-out colors, bland clinical aesthetic, Western plating. |
| wholey-wonder | Playful copy tone everywhere. Extra emoji allowed on IG/TikTok. |
| rasaya | Premium/elegant aesthetic. Minimal text overlay. No emoji on LinkedIn/EDM. |
| dr-stan | Clinical/trustworthy tone. Blue accent. Include credentials on LinkedIn. |
| serein | Calm/mindful aesthetic. Muted tones. Shorter copy across all platforms. |
| jade-oracle | Mystical/spiritual aesthetic. Deep purples/golds. Poetic copy style. |
| gaia-eats | Earthy, rustic food photography. Warm overlays. Recipe-style captions. |

## Smart Crop Logic

**Food photography (F&B brands: pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein):**
- Center-weighted crop: food subject is almost always centered
- Protect the center 60% of the frame
- Allow edge trimming only

**Lifestyle / brand imagery (gaia-learn, gaia-os, iris, jade-oracle, gaia-print, gaia-supplements):**
- Rule-of-thirds crop: subject typically at intersection points
- Face detection priority: never crop faces
- Protect top-right and bottom-left thirds

**Crop safety check:** If more than 30% of the hero content would be lost in a crop, flag for NanoBanana AI recomposition instead.

## Output Structure

```
~/.openclaw/workspace/data/images/{brand}/repurposed/
├── {YYYY-MM-DD}_{product}/
│   ├── ig-feed-1080x1080.jpg
│   ├── ig-feed-1080x1350.jpg
│   ├── ig-stories-1080x1920.jpg
│   ├── ig-reels-1080x1920.mp4          (video only)
│   ├── ig-carousel/
│   ├── fb-feed-1200x630.jpg
│   ├── fb-stories-1080x1920.jpg
│   ├── fb-cover-820x312.jpg
│   ├── tiktok-1080x1920.mp4            (video only)
│   ├── shopee-banner-1200x628.jpg
│   ├── shopee-feed-1080x1080.jpg
│   ├── whatsapp-status-1080x1920.jpg
│   ├── whatsapp-catalog-600x600.jpg
│   ├── edm-600xauto.jpg
│   ├── linkedin-1200x627.jpg
│   ├── linkedin-article-1200x644.jpg
│   ├── linkedin-carousel.pdf           (carousel only)
│   ├── x-post-1600x900.jpg
│   ├── x-header-1500x500.jpg
│   ├── pinterest-1000x1500.jpg
│   ├── yt-thumb-1280x720.jpg
│   ├── yt-shorts-1080x1920.mp4         (video only)
│   ├── copy/
│   │   ├── ig-feed.txt, ig-stories.txt, ig-reels.txt
│   │   ├── fb-feed.txt, tiktok.txt, shopee.txt
│   │   ├── whatsapp-status.txt, whatsapp-catalog.txt
│   │   ├── edm.html, linkedin.txt, x-post.txt
│   │   ├── pinterest.txt, youtube.txt
│   ├── manifest.json
│   └── quality_report.txt
```

### manifest.json Schema

```json
{
  "brand": "mirra",
  "product": "matcha-bento-set",
  "date": "2026-03-23",
  "source": {
    "file": "hero.png",
    "type": "image",
    "dimensions": "2400x2400",
    "size_bytes": 4521984
  },
  "outputs": [
    {
      "platform": "ig-feed",
      "filename": "ig-feed-1080x1080.jpg",
      "dimensions": "1080x1080",
      "aspect_ratio": "1:1",
      "size_bytes": 245760,
      "method": "center-crop",
      "crop_loss_pct": 0,
      "has_overlay": true,
      "copy_file": "copy/ig-feed.txt",
      "copy_length": 1847,
      "hashtag_count": 25,
      "status": "ok"
    }
  ],
  "quality_flags": [],
  "generated_at": "2026-03-23T14:30:00+08:00"
}
```

## Integration

### Feeds FROM (upstream)

| Skill | What it provides |
|-------|-----------------|
| `product-studio` | Hero product photography (images) |
| `creative-studio` | Campaign visuals, mood boards |
| `content-supply-chain` | Hero content from CREATE stage |
| `video-gen` / `video-forge` | Hero video assets |
| `nanobanana` | AI-generated hero images |
| `ad-composer` | Ad creatives needing multi-platform distribution |

### Feeds INTO (downstream)

| Skill | What it receives |
|-------|-----------------|
| Social publishing | Platform-ready images + copy |
| `ad-composer` | Reformatted creatives for ad sets |
| EDM tools | Email-optimized images + HTML copy |
| `campaign-translate` | Copy variants for translation to other languages |
| `content-supply-chain` | Completes the PRODUCE stage distribution prep |

### Tool Dependencies

| Tool | Used for |
|------|----------|
| `ffmpeg` | Image/video resize, crop, reframe, subtitle burn, thumbnail extraction |
| `ImageMagick` (`convert`, `identify`) | Logo compositing, image optimization, PDF generation |
| `video-forge` | Video transcription (WhisperX), video post-production pipeline |
| `nanobanana` | AI-powered image recomposition when crop would lose content |
| `style-control` | Brand consistency validation on outputs |
| `brand-voice-check` | Copy tone validation against brand DNA |
| `jq` | JSON parsing for brand DNA and manifest generation |

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Crop loss >30% | Source aspect ratio too different from target | Auto-fallback to NanoBanana AI recomposition |
| File size exceeds limit | Output too large for platform (e.g., Shopee 2MB) | Auto-recompress with lower quality. If still over: flag for manual review. |
| Missing brand DNA | Brand not found in `~/.openclaw/brands/` | Abort with error. Do not generate unbranded outputs. |
| Copy exceeds limit | Adapted copy still too long after trimming | Truncate at last complete sentence before limit. Flag in quality report. |
| ffmpeg fails | Corrupt source file or unsupported codec | Log error, skip platform, continue with remaining. Flag in manifest. |
| Missing font | Brand font file not found on system | Fall back to system default (Helvetica on macOS). Log warning. |

## Quality Checklist

- [ ] All output dimensions match platform spec exactly
- [ ] All file sizes within platform limits
- [ ] Logo visible and within safe zone on every image
- [ ] No text/logo clipped by platform UI overlays
- [ ] Copy length within platform limits for every variant
- [ ] Hashtag count within platform limits
- [ ] CTA present and appropriate for platform
- [ ] Video duration within platform limits
- [ ] Video has audio (unless source was silent)
- [ ] manifest.json generated and valid
- [ ] No empty/corrupt output files
