# Production Specifications — Every Output Type

---

## SOCIAL MEDIA

| Platform | Format | Dimensions | Ratio | DPI | Notes |
|----------|--------|-----------|-------|-----|-------|
| IG Feed | Post | 1080×1350 | 4:5 | 72 | Primary content format |
| IG Feed | Square | 1080×1080 | 1:1 | 72 | Alternate |
| IG Feed | Landscape | 1080×566 | 1.91:1 | 72 | Rare |
| IG Story/Reel | Vertical | 1080×1920 | 9:16 | 72 | Full screen |
| IG Profile | Avatar | 320×320 | 1:1 | 72 | Circular crop |
| IG Highlight | Cover | 1080×1920 | 9:16 | 72 | Circular center crop |
| TikTok | Video | 1080×1920 | 9:16 | 72 | |
| Telegram | Sticker | 512×512 | 1:1 | 72 | PNG, transparent bg |
| Telegram | Profile | 640×640 | 1:1 | 72 | |
| Facebook | Post | 1200×630 | 1.91:1 | 72 | |
| Twitter/X | Post | 1600×900 | 16:9 | 72 | |
| YouTube | Thumbnail | 1280×720 | 16:9 | 72 | |
| LinkedIn | Post | 1200×627 | 1.91:1 | 72 | |
| Pinterest | Pin | 1000×1500 | 2:3 | 72 | |

## PRINT

| Item | Dimensions | DPI | Bleed | Color | Stock |
|------|-----------|-----|-------|-------|-------|
| Business Card | 3.5×2 in (89×51mm) | 300 | 3mm | CMYK/Pantone | 400-600gsm |
| Letterhead | A4 (210×297mm) | 300 | 3mm | CMYK | 120gsm cotton |
| Envelope C5 | 229×162mm | 300 | — | CMYK | 120gsm |
| Compliment Slip | DL (210×99mm) | 300 | 3mm | CMYK | 120gsm |
| Oracle Card | 70×120mm | 300 | 3mm | CMYK + gold foil | 400gsm+ |
| Oracle Card (US) | 2.75×4.75 in | 300 | 3mm | CMYK + foil | 400gsm+ |
| Postcard | A6 (148×105mm) | 300 | 3mm | CMYK | 350gsm |
| Poster A3 | 297×420mm | 300 | 5mm | CMYK | 170gsm+ |
| Gift Box | Custom | 300 | — | CMYK + foil | 1500gsm board |
| Dust Jacket | Custom | 300 | 10mm | CMYK | 150gsm |

## DIGITAL

| Item | Dimensions | Format | Notes |
|------|-----------|--------|-------|
| Favicon | 32×32 | ICO/PNG | Must be recognizable |
| Apple Touch | 180×180 | PNG | iOS home screen |
| App Icon | 512×512 | PNG | App stores |
| App Icon (Android) | 512×512 | PNG | Adaptive icon |
| OG Image | 1200×630 | JPG | Social sharing preview |
| Email Header | 600×200 | JPG/PNG | Max 600px wide |
| Website Logo | SVG | SVG | Vector, any size |
| Watermark | 200×200 | PNG | Transparent, 10-20% opacity |

## ORACLE CARD SPECIFICATIONS

| Spec | Standard | Premium |
|------|----------|---------|
| Size | 70×120mm | 70×130mm (Cocorrina size) |
| Stock | 350gsm coated | 400gsm+ uncoated cotton |
| Finish | Matte lamination | Soft-touch + spot UV |
| Edges | Standard cut | Gilded gold/jade |
| Corners | 3mm radius | 3mm radius |
| Back | Full color print | Deboss + foil |
| Packaging | Tuck box | Rigid box, magnetic close |
| Insert | Folded guide | Perfect-bound booklet |

## FILE FORMAT REQUIREMENTS

| Use | Format | Notes |
|-----|--------|-------|
| Logo (vector) | SVG + AI + EPS | All three for partners/printers |
| Logo (raster) | PNG (transparent) | Multiple sizes: 512, 256, 128, 64, 32 |
| Print artwork | PDF/X-4 | CMYK, embedded fonts, 300dpi images |
| Photography | TIFF (archive) + JPEG (delivery) | sRGB for digital, AdobeRGB for print |
| Social content | PNG (graphics) / JPEG (photos) | sRGB, max 20MB for IG |
| Video | MP4 H.264/H.265 | 1080p minimum, 4K preferred |

## COLOR SPACE

| Context | Color Space | Profile |
|---------|------------|---------|
| Digital / Web / Social | sRGB | IEC 61966-2-1 |
| Print (general) | CMYK | FOGRA39 (ISO Coated v2) |
| Print (premium/Asia) | CMYK | Japan Color 2011 Coated |
| Photography archive | AdobeRGB | Adobe RGB (1998) |
| Wide gamut displays | Display P3 | Apple P3 |
| Spot colors | Pantone | Pantone Matching System |

## SAFE ZONES

### Instagram Feed (1080×1350)
- Top/bottom: 100px safe from IG UI elements
- Profile pic overlap: top 80px in grid view
- Caption preview: bottom 200px may be cropped in grid

### Meta Ad (9:16 for Stories/Reels)
- Top: 250px safe (status bar + ad label)
- Bottom: 340px safe (CTA button + swipe up)
- Sides: 64px safe
- Active area: 952×1280 centered

### App Icon
- iOS: content within 80% center (20% corner rounding)
- Android: adaptive icon foreground within 66% center circle
