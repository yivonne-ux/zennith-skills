---
name: content-repurpose
description: Auto-reformat one content asset into platform-optimized variants for IG Feed, Stories, Reels, FB, TikTok, Shopee, WhatsApp, EDM, LinkedIn, X, and Pinterest. One input → 10+ outputs.
agents: [dreami, iris, taoz]
version: 1.0.0
---

# Content Repurpose Engine

One hero asset (image, video, or copy) automatically reformatted into every platform variant. No manual resizing. No copy-paste. One input, full distribution.

Serves ALL 14 brands: dr-stan, gaia-eats, gaia-learn, gaia-os, gaia-print, gaia-recipes, gaia-supplements, iris, jade-oracle, mirra, pinxin-vegan, rasaya, serein, wholey-wonder.

**Agents:** Dreami (copy adaptation), Iris (visual production), Taoz (pipeline automation)
**Cost:** $0 for resize/crop operations (ffmpeg/ImageMagick local). API cost only when NanoBanana AI recomposition is needed.

---

## 1. Overview

The content bottleneck is never creation — it is distribution. A single hero image shot for Instagram Feed sits unused on TikTok, Shopee, WhatsApp, and EDM because each platform demands different dimensions, aspect ratios, caption lengths, hashtag strategies, and CTA formats.

This skill eliminates that bottleneck:

```
ONE HERO ASSET → content-repurpose → 10-15 PLATFORM-READY VARIANTS + manifest.json
```

All processing is local (ffmpeg, ImageMagick) unless the crop would destroy critical content, in which case NanoBanana handles AI-powered recomposition.

---

## 2. Platform Spec Matrix

### 2.1 Image Platforms

| Platform | Format | Dimensions (px) | Aspect Ratio | File Type | Max File Size | Caption Limit | Hashtag Limit | CTA Style |
|----------|--------|-----------------|-------------|-----------|---------------|---------------|---------------|-----------|
| IG Feed (Square) | Image | 1080 x 1080 | 1:1 | JPG/PNG | 30 MB | 2,200 chars | 30 | Link in bio |
| IG Feed (Portrait) | Image | 1080 x 1350 | 4:5 | JPG/PNG | 30 MB | 2,200 chars | 30 | Link in bio |
| IG Stories | Image | 1080 x 1920 | 9:16 | JPG/PNG | 30 MB | ~125 visible | 10 | Swipe up / Link sticker |
| IG Carousel | Image set | 1080 x 1080 or 1080 x 1350 | 1:1 or 4:5 | JPG/PNG | 30 MB/slide | 2,200 chars | 30 | Link in bio |
| FB Feed | Image | 1200 x 630 | ~1.91:1 | JPG/PNG | 30 MB | 63,206 chars | 30 | Shop Now / Learn More |
| FB Stories | Image | 1080 x 1920 | 9:16 | JPG/PNG | 30 MB | ~125 visible | 10 | Swipe up |
| FB Cover | Image | 820 x 312 | ~2.63:1 | JPG/PNG | 10 MB | N/A | N/A | N/A |
| Shopee Product Banner | Image | 1200 x 628 | ~1.91:1 | JPG/PNG | 2 MB | 120 chars | 0 | Buy Now / Add to Cart |
| Shopee Feed | Image | 1080 x 1080 | 1:1 | JPG/PNG | 2 MB | 500 chars | 5 | Shop Now |
| WhatsApp Status | Image | 1080 x 1920 | 9:16 | JPG/PNG | 16 MB | ~190 chars | 0 | Tap to order |
| WhatsApp Catalog | Image | 600 x 600 | 1:1 | JPG/PNG | 5 MB | 100 chars | 0 | Order now |
| EDM (Email) | Image | 600 x auto | 600px wide | JPG/PNG | 200 KB ideal | N/A (HTML) | 0 | Button CTA |
| LinkedIn Post | Image | 1200 x 627 | ~1.91:1 | JPG/PNG | 10 MB | 3,000 chars | 3-5 | Learn More / Visit |
| LinkedIn Article Header | Image | 1200 x 644 | ~1.86:1 | JPG/PNG | 10 MB | N/A | N/A | N/A |
| X/Twitter Post | Image | 1600 x 900 | 16:9 | JPG/PNG | 5 MB | 280 chars | 2-3 | Link |
| X Header | Image | 1500 x 500 | 3:1 | JPG/PNG | 5 MB | N/A | N/A | N/A |
| Pinterest Pin | Image | 1000 x 1500 | 2:3 | JPG/PNG | 20 MB | 500 chars | 20 | Shop / Learn More |
| YouTube Thumbnail | Image | 1280 x 720 | 16:9 | JPG/PNG | 2 MB | N/A | N/A | N/A |

### 2.2 Video Platforms

| Platform | Format | Dimensions (px) | Aspect Ratio | Max Duration | Min Duration | File Type | Max File Size | Caption Limit | Hashtag Limit |
|----------|--------|-----------------|-------------|-------------|-------------|-----------|---------------|---------------|---------------|
| IG Reels | Video | 1080 x 1920 | 9:16 | 90s | 3s | MP4 | 4 GB | 2,200 chars | 30 |
| IG Stories (Video) | Video | 1080 x 1920 | 9:16 | 15s/segment | 1s | MP4 | 4 GB | ~125 visible | 10 |
| FB Stories (Video) | Video | 1080 x 1920 | 9:16 | 20s | 1s | MP4 | 4 GB | ~125 visible | 10 |
| TikTok | Video | 1080 x 1920 | 9:16 | 10min | 3s | MP4 | 4 GB | 2,200 chars | 5 |
| YouTube Shorts | Video | 1080 x 1920 | 9:16 | 60s | 3s | MP4 | 4 GB | 100 chars | 15 |
| YouTube (standard) | Video | 1920 x 1080 | 16:9 | 12h | 3s | MP4 | 256 GB | 5,000 chars | 15 |

---

## 3. Content Type Workflows

### A. Image Repurposing

**SOP:** One hero image in, platform-optimized variants out.

#### Step 1: Analyze Hero Image

```bash
# Get image dimensions and detect content regions
identify -verbose hero.png | grep -E "Geometry|Resolution"
# Output: e.g., 2400x2400 (1:1 source)
```

Determine source aspect ratio. Map which target platforms need cropping vs. padding vs. AI recomposition.

#### Step 2: Smart Crop Logic

**Food photography (F&B brands: pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein):**
- Center-weighted crop: food subject is almost always centered
- Protect the center 60% of the frame
- Allow edge trimming only

**Lifestyle / brand imagery (gaia-learn, gaia-os, iris, jade-oracle, gaia-print, gaia-supplements):**
- Rule-of-thirds crop: subject typically at intersection points
- Face detection priority: never crop faces
- Protect top-right and bottom-left thirds

**Crop safety check:** If more than 30% of the hero content would be lost in a crop, flag for NanoBanana AI recomposition instead.

#### Step 3: Resize/Crop Commands (ffmpeg)

```bash
# === SQUARE (1:1) — IG Feed, WhatsApp Catalog, Shopee Feed ===
# Center crop from any source to 1080x1080
ffmpeg -i hero.png -vf "crop=min(iw\,ih):min(iw\,ih):(iw-min(iw\,ih))/2:(ih-min(iw\,ih))/2,scale=1080:1080" \
  -q:v 2 ig-feed-1080x1080.jpg

# === PORTRAIT (4:5) — IG Feed Portrait, IG Carousel ===
# Center crop to 4:5, then scale
ffmpeg -i hero.png -vf "crop=if(gt(iw*5\,ih*4)\,ih*4/5\,iw):if(gt(iw*5\,ih*4)\,ih\,iw*5/4):(iw-if(gt(iw*5\,ih*4)\,ih*4/5\,iw))/2:(ih-if(gt(iw*5\,ih*4)\,ih\,iw*5/4))/2,scale=1080:1350" \
  -q:v 2 ig-feed-1080x1350.jpg

# === TALL (9:16) — IG Stories, WhatsApp Status, Reels thumb, TikTok thumb ===
# If source is wider than 9:16, center-crop width. If taller, center-crop height.
ffmpeg -i hero.png -vf "crop=if(gt(iw*16\,ih*9)\,ih*9/16\,iw):if(gt(iw*16\,ih*9)\,ih\,iw*16/9):(iw-if(gt(iw*16\,ih*9)\,ih*9/16\,iw))/2:(ih-if(gt(iw*16\,ih*9)\,ih\,iw*16/9))/2,scale=1080:1920" \
  -q:v 2 ig-stories-1080x1920.jpg

# === LANDSCAPE (1.91:1) — FB Feed, LinkedIn, Shopee Banner ===
ffmpeg -i hero.png -vf "crop=if(gt(iw*100\,ih*191)\,ih*191/100\,iw):if(gt(iw*100\,ih*191)\,ih\,iw*100/191):(iw-if(gt(iw*100\,ih*191)\,ih*191/100\,iw))/2:(ih-if(gt(iw*100\,ih*191)\,ih\,iw*100/191))/2,scale=1200:628" \
  -q:v 2 fb-feed-1200x628.jpg

# === WIDE (16:9) — X Post, YouTube Thumbnail ===
ffmpeg -i hero.png -vf "crop=if(gt(iw*9\,ih*16)\,ih*16/9\,iw):if(gt(iw*9\,ih*16)\,ih\,iw*9/16):(iw-if(gt(iw*9\,ih*16)\,ih*16/9\,iw))/2:(ih-if(gt(iw*9\,ih*16)\,ih\,iw*9/16))/2,scale=1600:900" \
  -q:v 2 x-post-1600x900.jpg

# Scale variant for YouTube thumbnail
ffmpeg -i x-post-1600x900.jpg -vf "scale=1280:720" -q:v 2 yt-thumb-1280x720.jpg

# === PINTEREST (2:3) ===
ffmpeg -i hero.png -vf "crop=if(gt(iw*3\,ih*2)\,ih*2/3\,iw):if(gt(iw*3\,ih*2)\,ih\,iw*3/2):(iw-if(gt(iw*3\,ih*2)\,ih*2/3\,iw))/2:(ih-if(gt(iw*3\,ih*2)\,ih\,iw*3/2))/2,scale=1000:1500" \
  -q:v 2 pinterest-1000x1500.jpg

# === X HEADER (3:1) ===
ffmpeg -i hero.png -vf "crop=if(gt(iw\,ih*3)\,ih*3\,iw):if(gt(iw\,ih*3)\,ih\,iw/3):(iw-if(gt(iw\,ih*3)\,ih*3\,iw))/2:(ih-if(gt(iw\,ih*3)\,ih\,iw/3))/2,scale=1500:500" \
  -q:v 2 x-header-1500x500.jpg

# === FB COVER (2.63:1) ===
ffmpeg -i hero.png -vf "crop=if(gt(iw*312\,ih*820)\,ih*820/312\,iw):if(gt(iw*312\,ih*820)\,ih\,iw*312/820):(iw-if(gt(iw*312\,ih*820)\,ih*820/312\,iw))/2:(ih-if(gt(iw*312\,ih*820)\,ih\,iw*312/820))/2,scale=820:312" \
  -q:v 2 fb-cover-820x312.jpg

# === EDM (600px wide, maintain aspect ratio) ===
ffmpeg -i hero.png -vf "scale=600:-1" -q:v 4 edm-600xauto.jpg
# Optimize for email: target <200KB
convert edm-600xauto.jpg -quality 75 -strip edm-600xauto.jpg

# === WHATSAPP CATALOG (600x600) ===
ffmpeg -i hero.png -vf "crop=min(iw\,ih):min(iw\,ih):(iw-min(iw\,ih))/2:(ih-min(iw\,ih))/2,scale=600:600" \
  -q:v 2 whatsapp-catalog-600x600.jpg

# === LINKEDIN ARTICLE HEADER (1200x644) ===
ffmpeg -i hero.png -vf "crop=if(gt(iw*644\,ih*1200)\,ih*1200/644\,iw):if(gt(iw*644\,ih*1200)\,ih\,iw*644/1200):(iw-if(gt(iw*644\,ih*1200)\,ih*1200/644\,iw))/2:(ih-if(gt(iw*644\,ih*1200)\,ih\,iw*644/1200))/2,scale=1200:644" \
  -q:v 2 linkedin-article-1200x644.jpg
```

#### Step 4: Brand Overlay

```bash
# Logo placement — bottom-right with 5% padding from edges (default safe zone)
# Load logo from brand DNA path
LOGO="~/.openclaw/brands/${BRAND}/assets/logo-white.png"

# Composite logo onto image (ImageMagick)
# Size logo to 15% of image width, place in bottom-right safe zone
convert output.jpg \
  \( "$LOGO" -resize "$(( WIDTH * 15 / 100 ))x" \) \
  -gravity SouthEast -geometry +$(( WIDTH * 5 / 100 ))+$(( HEIGHT * 5 / 100 )) \
  -composite output-branded.jpg
```

**Safe Zone Map for Logo Placement:**

| Platform | Logo Position | Avoid Zone | Reason |
|----------|--------------|------------|--------|
| IG Feed | Bottom-right | Bottom 15% center | Username/likes overlay |
| IG Stories | Top-right or bottom-right | Top 14% (camera/close), Bottom 20% (reply/CTA) | UI elements |
| IG Reels (thumb) | Bottom-right | Bottom 25% center | Caption/music overlay |
| FB Feed | Bottom-right | Bottom 10% center | Reactions bar |
| TikTok | Top-left or center | Right 20% (follow/like/share), Bottom 20% (caption) | UI buttons |
| Shopee | Top-left | Bottom 15% (price tag area) | Platform overlays |
| WhatsApp Status | Center or top | Bottom 20% (reply bar) | UI elements |
| EDM | Top-center or bottom-center | N/A | No platform overlay |
| LinkedIn | Bottom-right | N/A | Clean platform |
| X | Bottom-right | N/A | Clean platform |
| Pinterest | Bottom-center | Top 10% (save button) | Pin UI |
| YouTube Thumb | Bottom-right | Bottom-right 10% (duration badge) | Timestamp overlay |

#### Step 5: Text Overlay Adaptation

For images that include text overlays (promo banners, announcements):
- **Large formats** (1200px+ wide): Full headline + subheadline + CTA
- **Medium formats** (1080px wide, square/portrait): Headline + CTA only
- **Small/tall formats** (Stories, 9:16): Headline only, larger font size
- **Tiny formats** (WhatsApp Catalog 600px): No text overlay, product image only

#### Step 6: NanoBanana AI Recomposition (Fallback)

When smart crop would lose >30% of meaningful content:

```bash
# AI recomposition — extends canvas or repositions subject
bash ~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh \
  --ref-image hero.png \
  --prompt "Recompose this image for ${ASPECT_RATIO} aspect ratio, preserving all key elements. Brand: ${BRAND}." \
  --aspect "${TARGET_ASPECT}" \
  --style-seed original \
  --brand "${BRAND}"
```

---

### B. Video Repurposing

**SOP:** One hero video in, platform-optimized video variants out.

#### Step 1: Analyze Source Video

```bash
# Get video metadata
ffprobe -v quiet -print_format json -show_streams -show_format hero.mp4 | \
  jq '{duration: .format.duration, width: .streams[0].width, height: .streams[0].height, codec: .streams[0].codec_name}'
```

#### Step 2: Aspect Ratio Conversion

**16:9 source to 9:16 (landscape to portrait):**

```bash
# Smart reframe: center crop with slight upward bias (faces tend to be upper third)
ffmpeg -i hero.mp4 -vf "crop=ih*9/16:ih:iw/2-ih*9/32:0,scale=1080:1920" \
  -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k \
  reframed-9x16.mp4
```

**9:16 source to 16:9 (portrait to landscape):**

```bash
# Blur-padded background with sharp center
ffmpeg -i hero.mp4 \
  -filter_complex "[0:v]split[main][bg];[bg]scale=1920:1080,boxblur=20:5[blurred];[main]scale=-1:1080[scaled];[blurred][scaled]overlay=(W-w)/2:0" \
  -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k \
  landscape-16x9.mp4
```

**1:1 source to 9:16:**

```bash
# Pad top and bottom with branded color or blur
ffmpeg -i hero.mp4 \
  -filter_complex "[0:v]scale=1080:1080[main];[0:v]scale=1080:1920,boxblur=30:5[bg];[bg][main]overlay=0:(H-h)/2" \
  -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k \
  portrait-9x16.mp4
```

#### Step 3: Duration Trimming

```bash
# IG Stories: trim to 15s (best segment detection via loudness)
ffmpeg -i hero.mp4 -af loudnorm -f null - 2>&1 | grep "I:" # find loud sections

# Simple trim: first 15 seconds (with fade out)
ffmpeg -i hero.mp4 -t 15 -vf "fade=t=out:st=13.5:d=1.5" -af "afade=t=out:st=13.5:d=1.5" \
  -c:v libx264 -crf 23 -c:a aac ig-stories-15s.mp4

# IG Reels: trim to 30s (with hook preservation — keep first 3s intact)
ffmpeg -i hero.mp4 -t 30 -vf "fade=t=out:st=28.5:d=1.5" -af "afade=t=out:st=28.5:d=1.5" \
  -c:v libx264 -crf 23 -c:a aac ig-reels-30s.mp4

# YouTube Shorts: trim to 60s
ffmpeg -i hero.mp4 -t 60 -vf "fade=t=out:st=58:d=2" -af "afade=t=out:st=58:d=2" \
  -c:v libx264 -crf 23 -c:a aac yt-shorts-60s.mp4

# TikTok: keep full (up to 10min), but optimize first 3s hook
# No trimming needed unless source >10min
```

#### Step 4: Hook Optimization (First 3 Seconds)

Platform-specific hook treatment for the critical first 3 seconds:

| Platform | Hook Strategy |
|----------|--------------|
| IG Reels | Fast cut or zoom-in on product. Text overlay: question or bold claim. |
| TikTok | Pattern interrupt: unexpected visual, direct eye contact, or trending audio hook. |
| IG Stories | Immediate product reveal. Poll sticker prompt in text. |
| YouTube Shorts | "Wait for it..." text or immediate payoff. |
| FB Feed | Autoplay-optimized: compelling visual without audio dependency. |

```bash
# Add text hook overlay to first 3 seconds
ffmpeg -i hero.mp4 \
  -vf "drawtext=text='${HOOK_TEXT}':fontfile=${BRAND_FONT}:fontsize=48:fontcolor=white:borderw=2:bordercolor=black:x=(w-text_w)/2:y=h*0.15:enable='between(t,0.5,3)'" \
  -c:v libx264 -crf 23 -c:a copy hooked.mp4
```

#### Step 5: Subtitle/Caption Handling

```bash
# Extract subtitles using VideoForge (WhisperX backend)
bash ~/.openclaw/skills/video-forge/scripts/video-forge.sh transcribe --input hero.mp4 --lang auto

# Burn subtitles for platforms that don't support SRT (IG, TikTok)
ffmpeg -i hero.mp4 -vf "subtitles=hero.srt:force_style='FontName=${BRAND_FONT},FontSize=22,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,Outline=2,Alignment=2'" \
  -c:v libx264 -crf 23 -c:a copy subtitled.mp4
```

#### Step 6: Thumbnail Extraction

```bash
# Extract best thumbnail frame (highest visual complexity at rule-of-thirds points)
ffmpeg -i hero.mp4 -vf "select='gt(scene,0.3)',scale=1280:720" -frames:v 5 -vsync vfr thumb_%02d.jpg

# Or extract at specific timestamp
ffmpeg -i hero.mp4 -ss 00:00:02 -frames:v 1 -vf "scale=1280:720" yt-thumb-1280x720.jpg
```

#### Step 7: Full Video Repurpose Pipeline (VideoForge)

```bash
# Use VideoForge for complete video processing pipeline
bash ~/.openclaw/skills/video-forge/scripts/video-forge.sh repurpose \
  --input hero.mp4 \
  --brand "${BRAND}" \
  --platforms "ig-reels,ig-stories,tiktok,yt-shorts,fb-stories" \
  --add-subtitles \
  --add-hook \
  --output-dir "${OUTPUT_DIR}"
```

---

### C. Copy Repurposing

**SOP:** One hero caption in, platform-adapted copy variants out.

#### Platform Copy Rules

| Platform | Max Length | Hashtag Count | Emoji Density | Tone | CTA Format |
|----------|-----------|---------------|---------------|------|------------|
| IG Feed | 2,200 chars (125 visible before "more") | 20-30 (in first comment or end of caption) | Medium-high | Conversational, storytelling | "Link in bio" / "DM us" |
| IG Stories | ~125 chars visible | 3-5 (small, placed low) | High | Punchy, single thought | Sticker CTA / poll |
| IG Reels | 2,200 chars (short preferred) | 10-15 | Medium | Hook-driven, casual | "Follow for more" |
| FB Feed | 63,206 chars (80 visible before "See more") | 3-5 | Medium | Slightly more formal than IG | "Shop Now" button / link |
| TikTok | 2,200 chars (short preferred) | 3-5 (trending ones) | Medium | Gen Z casual, trend-aware | "Link in bio" / "Comment X" |
| Shopee | 500 chars | 0 | Low | Direct, benefit-focused | "Buy Now" / "Add to Cart" |
| WhatsApp | 190 chars (status), 100 chars (catalog) | 0 | Low-medium | Personal, direct | "Tap to order" / "Reply to order" |
| EDM | N/A (HTML layout) | 0 | Low | Professional, value-driven | Button: "Shop Now" / "Read More" |
| LinkedIn | 3,000 chars (140 visible before "see more") | 3-5 (industry-specific) | None-low | Professional, thought leadership | "Learn more at..." |
| X/Twitter | 280 chars | 1-3 | Low | Concise, witty, timely | Link |
| Pinterest | 500 chars | 10-20 (SEO keywords) | Low | Aspirational, descriptive, keyword-rich | "Shop" / "Learn More" |
| YouTube | 5,000 chars (description) | 10-15 (in description) | Low | Informative, SEO-optimized | "Subscribe" / "Check link in description" |

#### Copy Transformation Rules

**From IG Feed (2,200 char hero) to each platform:**

1. **IG Stories:** Extract the single most compelling line. Add emoji. Frame as question or bold statement.
2. **FB Feed:** Keep first 80 chars as hook. Slightly more formal tone. Replace "link in bio" with actual link.
3. **TikTok:** Rewrite as 1-2 punchy sentences. Use trending language. Keep hashtags to 3-5 trending ones.
4. **Shopee:** Strip to pure product benefit. Price/promo upfront. "Buy Now" CTA.
5. **WhatsApp Status:** One sentence + emoji + "Tap to order." Must fit 190 chars.
6. **WhatsApp Catalog:** Product name + key benefit. Under 100 chars.
7. **EDM:** Structure as: headline > subheadline > 2-3 benefit bullets > CTA button.
8. **LinkedIn:** Reframe as industry insight or founder story. Professional tone. No emoji spam.
9. **X/Twitter:** Distill to core insight. Under 200 chars (leave room for link). Max 2 hashtags.
10. **Pinterest:** Keyword-rich description. Aspirational language. Include product details for search.
11. **YouTube:** SEO-optimized description with timestamps, keywords, links.

#### Pinxin Vegan Copy Repurpose Example

Hero (IG Feed):
```
Bold flavours. Zero compromise. Our Nasi Lemak Set is BACK — coconut rice, crispy tempeh rendang, house sambal, and all the fixings. 100% plant-based, 100% Malaysian.

Order now on Shopee or GrabFood. Free delivery KL/PJ!
#PinxinVegan #BoldFlavours #VeganMalaysia #NasiLemak #PlantBased
```

Repurposed:
- **Shopee listing:** `Pinxin Vegan Nasi Lemak Set — Plant-Based, Bold Malaysian Flavours. Coconut rice + tempeh rendang + house sambal. Free delivery KL/PJ. Order now!`
- **WhatsApp Status:** `Nasi Lemak Set is BACK! 100% plant-based, 100% sedap. Order now on Shopee!`
- **GrabFood description:** `Bold vegan nasi lemak — coconut rice, crispy tempeh rendang, fiery house sambal. Plant-based, Malaysian-made.`
- **X/Twitter:** `Our Nasi Lemak Set is BACK. Bold. Plant-based. Malaysian. #PinxinVegan #VeganMalaysia`

#### Language Rule

Maintain the original language of the hero copy. Do NOT translate. Translation is handled by `campaign-translate` skill. If the hero copy is bilingual (e.g., EN + CN), preserve both in platforms that support it, and pick the dominant language for character-limited platforms.

---

### D. Carousel Repurposing

**SOP:** One carousel set in, multi-platform carousel variants out.

#### Source Carousel Detection

Carousel inputs arrive as numbered files: `slide-01.png`, `slide-02.png`, ... `slide-10.png`.

#### Platform Carousel Specs

| Platform | Max Slides | Aspect Ratio | Notes |
|----------|-----------|-------------|-------|
| IG Carousel | 20 | 1:1 or 4:5 (consistent across slides) | First slide is hook, last is CTA |
| LinkedIn Carousel (PDF) | 300 pages | 4:5 recommended | Upload as PDF document |
| Pinterest Idea Pins | 20 | 2:3 | Each pin is standalone-valuable |
| FB Carousel | 10 | 1:1 | Each card can have own link |
| TikTok Photo Mode | 35 | 9:16 | Swipe-through format |

#### Carousel Transformation

```bash
# IG Carousel (1:1) → LinkedIn Carousel (4:5 PDF)
for slide in slide-*.png; do
  ffmpeg -i "$slide" -vf "crop=if(gt(iw*5\,ih*4)\,ih*4/5\,iw):if(gt(iw*5\,ih*4)\,ih\,iw*5/4),scale=1080:1350" \
    -q:v 2 "linkedin-${slide}"
done
# Convert to PDF for LinkedIn
convert linkedin-slide-*.png linkedin-carousel.pdf

# IG Carousel (1:1) → Pinterest Idea Pins (2:3)
for slide in slide-*.png; do
  ffmpeg -i "$slide" -vf "crop=if(gt(iw*3\,ih*2)\,ih*2/3\,iw):if(gt(iw*3\,ih*2)\,ih\,iw*3/2),scale=1000:1500" \
    -q:v 2 "pinterest-${slide}"
done

# IG Carousel → TikTok Photo Mode (9:16)
for slide in slide-*.png; do
  ffmpeg -i "$slide" -vf "crop=if(gt(iw*16\,ih*9)\,ih*9/16\,iw):if(gt(iw*16\,ih*9)\,ih\,iw*16/9),scale=1080:1920" \
    -q:v 2 "tiktok-${slide}"
done
```

**Slide Count Optimization:**
- IG: Keep all slides (up to 20). Strong hook on slide 1, CTA on last.
- LinkedIn: Keep 5-10 slides. More text-heavy, insight-driven.
- Pinterest: Keep 3-7 slides. Each must be visually standalone.
- FB: Max 10. Each card needs independent value + own link.
- TikTok: 5-10 slides. Fast-paced, trend-styled.

**Cover Slide Adaptation:**
- IG: Bold visual + text hook ("5 ways to..." or "Swipe for...")
- LinkedIn: Professional, text-forward, insight-driven headline
- Pinterest: Aspirational, keyword-rich title overlay
- TikTok: Pattern-interrupt visual, trend-styled text

---

## 4. Brand-Aware Processing

### DNA Loading

Every repurpose operation starts by loading the brand's DNA:

```bash
BRAND_DNA="~/.openclaw/brands/${BRAND}/DNA.json"
# Extract key brand parameters
BRAND_COLORS=$(jq -r '.colors' "$BRAND_DNA")
BRAND_FONT=$(jq -r '.font' "$BRAND_DNA")
BRAND_LOGO=$(jq -r '.logo' "$BRAND_DNA")
BRAND_MOOD=$(jq -r '.mood' "$BRAND_DNA")
BRAND_VOICE=$(jq -r '.voice' "$BRAND_DNA")
```

### Brand Overlay Rules

| Element | Rule |
|---------|------|
| Logo | Always placed in platform-safe zone (see safe zone map in Section 3A). Size: 12-18% of image width. |
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

---

## 5. Workflow SOP

```
INPUT:
  - Hero asset: image (.png/.jpg), video (.mp4), copy (.txt), or carousel (slide-*.png)
  - Brand name (required)
  - Target platforms (optional — defaults to ALL)

STEP 1: DETECT ASSET TYPE
  ├── Image? → Image Repurposing Pipeline (Section 3A)
  ├── Video? → Video Repurposing Pipeline (Section 3B)
  ├── Text?  → Copy Repurposing Pipeline (Section 3C)
  └── Carousel (multiple images)? → Carousel Repurposing Pipeline (Section 3D)

STEP 2: LOAD BRAND DNA
  └── Read ~/.openclaw/brands/{brand}/DNA.json
  └── Extract: colors, font, logo path, mood, voice, special rules

STEP 3: LOAD PLATFORM SPECS
  └── Reference Section 2 matrix for all target platforms

STEP 4: FOR EACH TARGET PLATFORM
  a. Resize/reframe asset to platform dimensions (ffmpeg/ImageMagick)
     - Check crop loss percentage
     - If >30% loss → NanoBanana AI recomposition
  b. Apply brand overlay
     - Logo in platform-safe zone
     - Brand colors for padding/borders if needed
  c. Adapt copy
     - Enforce character limits
     - Adjust hashtag count and selection
     - Adapt CTA format
     - Shift tone per platform rules
  d. Generate platform-specific thumbnail (if video)
  e. Export with naming convention:
     {platform}-{WxH}.{ext}
     Example: ig-feed-1080x1080.jpg, tiktok-1080x1920.mp4

STEP 5: QUALITY CHECK
  ├── Verify all output dimensions match spec
  ├── Verify file sizes within platform limits
  ├── Verify logo placement in safe zones
  ├── Verify copy length within limits
  └── Flag any files that need manual review

STEP 6: EXPORT MANIFEST
  └── Generate manifest.json listing all generated assets with metadata:
      - filename, platform, dimensions, file_size, copy_length, hashtag_count, status

OUTPUT:
  - 10-20 platform-ready assets in output directory
  - manifest.json with full asset inventory
  - quality_report.txt with any flagged issues
```

---

## 6. CLI Usage

```bash
# === FULL REPURPOSE (all platforms, auto-detect asset type) ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra \
  --input /path/to/hero.png

# === SPECIFIC PLATFORMS ONLY ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra \
  --input /path/to/hero.mp4 \
  --platforms "ig-feed,ig-stories,tiktok,fb"

# === IMAGE ONLY ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh image \
  --brand pinxin-vegan \
  --input /path/to/hero.png

# === PINXIN VEGAN — Nasi Lemak hero to all delivery platforms ===
# Generates: GrabFood banner (1200x628), Shopee listing (1080x1080),
# WhatsApp catalog (600x600), IG Feed (1080x1350), IG Stories (1080x1920)
# All with dark green #1C372A overlays and gold #d0aa7f accents
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh image \
  --brand pinxin-vegan \
  --input ~/.openclaw/workspace/data/images/pinxin-vegan/nasi-lemak-hero.png \
  --platforms "shopee-banner,shopee-feed,grabfood,whatsapp-catalog,ig-feed,ig-stories"

# === VIDEO ONLY ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh video \
  --brand pinxin-vegan \
  --input /path/to/hero-video.mp4

# === COPY ONLY (no visuals) ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh copy \
  --brand mirra \
  --input /path/to/caption.txt

# === CAROUSEL ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh carousel \
  --brand mirra \
  --input /path/to/slides/

# === BATCH (all recent hero assets for a brand) ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh batch \
  --brand mirra \
  --since 7d

# === DRY RUN (preview what would be generated) ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra \
  --input /path/to/hero.png \
  --dry-run

# === WITH PRODUCT TAG (for organized output) ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra \
  --input /path/to/hero.png \
  --product "matcha-bento-set"

# === SKIP BRAND OVERLAY ===
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh all \
  --brand mirra \
  --input /path/to/hero.png \
  --no-overlay
```

### CLI Flags Reference

| Flag | Required | Description |
|------|----------|-------------|
| `--brand` | Yes | Brand name (must match a dir in `~/.openclaw/brands/`) |
| `--input` | Yes | Path to hero asset (image, video, text file, or directory of carousel slides) |
| `--platforms` | No | Comma-separated list of target platforms. Default: all. |
| `--product` | No | Product name for output directory naming. Default: derived from filename. |
| `--dry-run` | No | Preview output plan without generating files. |
| `--no-overlay` | No | Skip brand logo/watermark overlay. |
| `--since` | No | For batch mode: process assets newer than this (e.g., "7d", "24h"). |
| `--output-dir` | No | Custom output directory. Default: canonical path (see Section 7). |
| `--quality` | No | Output quality: "draft" (fast, lower quality) or "final" (slow, max quality). Default: final. |

---

## 7. Output Structure

```
~/.openclaw/workspace/data/images/{brand}/repurposed/
├── {YYYY-MM-DD}_{product}/
│   ├── ig-feed-1080x1080.jpg
│   ├── ig-feed-1080x1350.jpg
│   ├── ig-stories-1080x1920.jpg
│   ├── ig-reels-1080x1920.mp4          (video only)
│   ├── ig-carousel/
│   │   ├── slide-01-1080x1080.jpg      (carousel only)
│   │   ├── slide-02-1080x1080.jpg
│   │   └── ...
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
│   │   ├── ig-feed.txt
│   │   ├── ig-stories.txt
│   │   ├── ig-reels.txt
│   │   ├── fb-feed.txt
│   │   ├── tiktok.txt
│   │   ├── shopee.txt
│   │   ├── whatsapp-status.txt
│   │   ├── whatsapp-catalog.txt
│   │   ├── edm.html
│   │   ├── linkedin.txt
│   │   ├── x-post.txt
│   │   ├── pinterest.txt
│   │   └── youtube.txt
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
    },
    {
      "platform": "ig-stories",
      "filename": "ig-stories-1080x1920.jpg",
      "dimensions": "1080x1920",
      "aspect_ratio": "9:16",
      "size_bytes": 312400,
      "method": "ai-recomposition",
      "crop_loss_pct": 42,
      "has_overlay": true,
      "copy_file": "copy/ig-stories.txt",
      "copy_length": 118,
      "hashtag_count": 5,
      "status": "ok"
    }
  ],
  "quality_flags": [],
  "generated_at": "2026-03-23T14:30:00+08:00"
}
```

---

## 8. Integration

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

---

## 9. Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Crop loss >30% | Source aspect ratio too different from target | Auto-fallback to NanoBanana AI recomposition |
| File size exceeds limit | Output too large for platform (e.g., Shopee 2MB) | Auto-recompress with lower quality. If still over: flag for manual review. |
| Missing brand DNA | Brand not found in `~/.openclaw/brands/` | Abort with error. Do not generate unbranded outputs. |
| Copy exceeds limit | Adapted copy still too long after trimming | Truncate at last complete sentence before limit. Flag in quality report. |
| ffmpeg fails | Corrupt source file or unsupported codec | Log error, skip platform, continue with remaining. Flag in manifest. |
| Missing font | Brand font file not found on system | Fall back to system default (Helvetica on macOS). Log warning. |

---

## 10. Quality Checklist

Run automatically at Step 5 of the workflow. Also available manually:

```bash
bash ~/.openclaw/skills/content-repurpose/scripts/content-repurpose.sh quality-check \
  --dir ~/.openclaw/workspace/data/images/mirra/repurposed/2026-03-23_matcha-bento-set/
```

Checks performed:

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
