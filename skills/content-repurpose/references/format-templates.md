# Format Templates — Resize, Crop, Video & Copy Adaptation

## Image Resize/Crop Commands (ffmpeg)

### SQUARE (1:1) — IG Feed, WhatsApp Catalog, Shopee Feed

```bash
ffmpeg -i hero.png -vf "crop=min(iw\,ih):min(iw\,ih):(iw-min(iw\,ih))/2:(ih-min(iw\,ih))/2,scale=1080:1080" \
  -q:v 2 ig-feed-1080x1080.jpg
```

### PORTRAIT (4:5) — IG Feed Portrait, IG Carousel

```bash
ffmpeg -i hero.png -vf "crop=if(gt(iw*5\,ih*4)\,ih*4/5\,iw):if(gt(iw*5\,ih*4)\,ih\,iw*5/4):(iw-if(gt(iw*5\,ih*4)\,ih*4/5\,iw))/2:(ih-if(gt(iw*5\,ih*4)\,ih\,iw*5/4))/2,scale=1080:1350" \
  -q:v 2 ig-feed-1080x1350.jpg
```

### TALL (9:16) — IG Stories, WhatsApp Status, Reels thumb, TikTok thumb

```bash
ffmpeg -i hero.png -vf "crop=if(gt(iw*16\,ih*9)\,ih*9/16\,iw):if(gt(iw*16\,ih*9)\,ih\,iw*16/9):(iw-if(gt(iw*16\,ih*9)\,ih*9/16\,iw))/2:(ih-if(gt(iw*16\,ih*9)\,ih\,iw*16/9))/2,scale=1080:1920" \
  -q:v 2 ig-stories-1080x1920.jpg
```

### LANDSCAPE (1.91:1) — FB Feed, LinkedIn, Shopee Banner

```bash
ffmpeg -i hero.png -vf "crop=if(gt(iw*100\,ih*191)\,ih*191/100\,iw):if(gt(iw*100\,ih*191)\,ih\,iw*100/191):(iw-if(gt(iw*100\,ih*191)\,ih*191/100\,iw))/2:(ih-if(gt(iw*100\,ih*191)\,ih\,iw*100/191))/2,scale=1200:628" \
  -q:v 2 fb-feed-1200x628.jpg
```

### WIDE (16:9) — X Post, YouTube Thumbnail

```bash
ffmpeg -i hero.png -vf "crop=if(gt(iw*9\,ih*16)\,ih*16/9\,iw):if(gt(iw*9\,ih*16)\,ih\,iw*9/16):(iw-if(gt(iw*9\,ih*16)\,ih*16/9\,iw))/2:(ih-if(gt(iw*9\,ih*16)\,ih\,iw*9/16))/2,scale=1600:900" \
  -q:v 2 x-post-1600x900.jpg

# Scale variant for YouTube thumbnail
ffmpeg -i x-post-1600x900.jpg -vf "scale=1280:720" -q:v 2 yt-thumb-1280x720.jpg
```

### PINTEREST (2:3)

```bash
ffmpeg -i hero.png -vf "crop=if(gt(iw*3\,ih*2)\,ih*2/3\,iw):if(gt(iw*3\,ih*2)\,ih\,iw*3/2):(iw-if(gt(iw*3\,ih*2)\,ih*2/3\,iw))/2:(ih-if(gt(iw*3\,ih*2)\,ih\,iw*3/2))/2,scale=1000:1500" \
  -q:v 2 pinterest-1000x1500.jpg
```

### X HEADER (3:1)

```bash
ffmpeg -i hero.png -vf "crop=if(gt(iw\,ih*3)\,ih*3\,iw):if(gt(iw\,ih*3)\,ih\,iw/3):(iw-if(gt(iw\,ih*3)\,ih*3\,iw))/2:(ih-if(gt(iw\,ih*3)\,ih\,iw/3))/2,scale=1500:500" \
  -q:v 2 x-header-1500x500.jpg
```

### FB COVER (2.63:1)

```bash
ffmpeg -i hero.png -vf "crop=if(gt(iw*312\,ih*820)\,ih*820/312\,iw):if(gt(iw*312\,ih*820)\,ih\,iw*312/820):(iw-if(gt(iw*312\,ih*820)\,ih*820/312\,iw))/2:(ih-if(gt(iw*312\,ih*820)\,ih\,iw*312/820))/2,scale=820:312" \
  -q:v 2 fb-cover-820x312.jpg
```

### EDM (600px wide, maintain aspect ratio)

```bash
ffmpeg -i hero.png -vf "scale=600:-1" -q:v 4 edm-600xauto.jpg
convert edm-600xauto.jpg -quality 75 -strip edm-600xauto.jpg
```

### WHATSAPP CATALOG (600x600)

```bash
ffmpeg -i hero.png -vf "crop=min(iw\,ih):min(iw\,ih):(iw-min(iw\,ih))/2:(ih-min(iw\,ih))/2,scale=600:600" \
  -q:v 2 whatsapp-catalog-600x600.jpg
```

### LINKEDIN ARTICLE HEADER (1200x644)

```bash
ffmpeg -i hero.png -vf "crop=if(gt(iw*644\,ih*1200)\,ih*1200/644\,iw):if(gt(iw*644\,ih*1200)\,ih\,iw*644/1200):(iw-if(gt(iw*644\,ih*1200)\,ih*1200/644\,iw))/2:(ih-if(gt(iw*644\,ih*1200)\,ih\,iw*644/1200))/2,scale=1200:644" \
  -q:v 2 linkedin-article-1200x644.jpg
```

## Brand Overlay

```bash
LOGO="~/.openclaw/brands/${BRAND}/assets/logo-white.png"
convert output.jpg \
  \( "$LOGO" -resize "$(( WIDTH * 15 / 100 ))x" \) \
  -gravity SouthEast -geometry +$(( WIDTH * 5 / 100 ))+$(( HEIGHT * 5 / 100 )) \
  -composite output-branded.jpg
```

## Text Overlay Adaptation

- **Large formats** (1200px+ wide): Full headline + subheadline + CTA
- **Medium formats** (1080px wide, square/portrait): Headline + CTA only
- **Small/tall formats** (Stories, 9:16): Headline only, larger font size
- **Tiny formats** (WhatsApp Catalog 600px): No text overlay, product image only

## NanoBanana AI Recomposition (Fallback)

When smart crop would lose >30% of meaningful content:

```bash
bash ~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh \
  --ref-image hero.png \
  --prompt "Recompose this image for ${ASPECT_RATIO} aspect ratio, preserving all key elements. Brand: ${BRAND}." \
  --aspect "${TARGET_ASPECT}" \
  --style-seed original \
  --brand "${BRAND}"
```

## Video Repurposing

### Aspect Ratio Conversion

**16:9 source to 9:16 (landscape to portrait):**

```bash
ffmpeg -i hero.mp4 -vf "crop=ih*9/16:ih:iw/2-ih*9/32:0,scale=1080:1920" \
  -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k \
  reframed-9x16.mp4
```

**9:16 source to 16:9 (portrait to landscape):**

```bash
ffmpeg -i hero.mp4 \
  -filter_complex "[0:v]split[main][bg];[bg]scale=1920:1080,boxblur=20:5[blurred];[main]scale=-1:1080[scaled];[blurred][scaled]overlay=(W-w)/2:0" \
  -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k \
  landscape-16x9.mp4
```

**1:1 source to 9:16:**

```bash
ffmpeg -i hero.mp4 \
  -filter_complex "[0:v]scale=1080:1080[main];[0:v]scale=1080:1920,boxblur=30:5[bg];[bg][main]overlay=0:(H-h)/2" \
  -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k \
  portrait-9x16.mp4
```

### Duration Trimming

```bash
# IG Stories: 15s with fade
ffmpeg -i hero.mp4 -t 15 -vf "fade=t=out:st=13.5:d=1.5" -af "afade=t=out:st=13.5:d=1.5" \
  -c:v libx264 -crf 23 -c:a aac ig-stories-15s.mp4

# IG Reels: 30s with hook preservation
ffmpeg -i hero.mp4 -t 30 -vf "fade=t=out:st=28.5:d=1.5" -af "afade=t=out:st=28.5:d=1.5" \
  -c:v libx264 -crf 23 -c:a aac ig-reels-30s.mp4

# YouTube Shorts: 60s
ffmpeg -i hero.mp4 -t 60 -vf "fade=t=out:st=58:d=2" -af "afade=t=out:st=58:d=2" \
  -c:v libx264 -crf 23 -c:a aac yt-shorts-60s.mp4
```

### Hook Optimization (First 3 Seconds)

| Platform | Hook Strategy |
|----------|--------------|
| IG Reels | Fast cut or zoom-in on product. Text overlay: question or bold claim. |
| TikTok | Pattern interrupt: unexpected visual, direct eye contact, or trending audio hook. |
| IG Stories | Immediate product reveal. Poll sticker prompt in text. |
| YouTube Shorts | "Wait for it..." text or immediate payoff. |
| FB Feed | Autoplay-optimized: compelling visual without audio dependency. |

```bash
ffmpeg -i hero.mp4 \
  -vf "drawtext=text='${HOOK_TEXT}':fontfile=${BRAND_FONT}:fontsize=48:fontcolor=white:borderw=2:bordercolor=black:x=(w-text_w)/2:y=h*0.15:enable='between(t,0.5,3)'" \
  -c:v libx264 -crf 23 -c:a copy hooked.mp4
```

### Subtitle/Caption Handling

```bash
bash ~/.openclaw/skills/video-forge/scripts/video-forge.sh transcribe --input hero.mp4 --lang auto

ffmpeg -i hero.mp4 -vf "subtitles=hero.srt:force_style='FontName=${BRAND_FONT},FontSize=22,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,Outline=2,Alignment=2'" \
  -c:v libx264 -crf 23 -c:a copy subtitled.mp4
```

### Thumbnail Extraction

```bash
ffmpeg -i hero.mp4 -vf "select='gt(scene,0.3)',scale=1280:720" -frames:v 5 -vsync vfr thumb_%02d.jpg
ffmpeg -i hero.mp4 -ss 00:00:02 -frames:v 1 -vf "scale=1280:720" yt-thumb-1280x720.jpg
```

### Full Video Repurpose Pipeline (VideoForge)

```bash
bash ~/.openclaw/skills/video-forge/scripts/video-forge.sh repurpose \
  --input hero.mp4 \
  --brand "${BRAND}" \
  --platforms "ig-reels,ig-stories,tiktok,yt-shorts,fb-stories" \
  --add-subtitles \
  --add-hook \
  --output-dir "${OUTPUT_DIR}"
```

## Carousel Transformation

```bash
# IG Carousel (1:1) → LinkedIn Carousel (4:5 PDF)
for slide in slide-*.png; do
  ffmpeg -i "$slide" -vf "crop=if(gt(iw*5\,ih*4)\,ih*4/5\,iw):if(gt(iw*5\,ih*4)\,ih\,iw*5/4),scale=1080:1350" \
    -q:v 2 "linkedin-${slide}"
done
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

## Copy Transformation Rules

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

### Pinxin Vegan Copy Repurpose Example

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

### Language Rule

Maintain the original language of the hero copy. Do NOT translate. Translation is handled by `campaign-translate` skill.
