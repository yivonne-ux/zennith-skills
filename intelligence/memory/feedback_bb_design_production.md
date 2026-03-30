---
name: BB Design Production Rules
description: Bloom & Bare COMPLETE design production rules — all compounded learnings from week batch v1-v6. Art style, photos, stickers, typography, layout, photo selection. MUST READ before any BB production.
type: feedback
---

# BB Design Production Rules (Compounded v1-v6)

User feedback across 6 fix rounds (2026-03-21):

## 1. Photo Posts = DESIGNED Layout, Not Just Photo+Text
"Cannot just post the photo with logo. Needs to be curated and designed."
- Photo posts need: solid color bg + photo in FRAME (rounded rect, arch, circle) + mascot accent + typography
- NEVER full-bleed photo with text overlay — that's lazy, not designed
- Each photo post uses a DIFFERENT frame shape for variety (rounded rect, arch, circle)
- Photo must include a mascot icon/accent to feel complete and branded
- Add design layers: doodles, sparkles, small accents on the bg — not just photo + text
- The approved reference = 05_PHOTO_convert (yellow bg, rounded frame, stamp, "OPEN PLAY")

## 2. Photo Enhancement: UV vs Non-UV
- **Non-UV photos**: `prep_photo()` with daylight pre-grade + NANO Banana Pro warm enhancement (Kinfolk magazine, Canon 5D, golden hour)
- **UV photos**: `prep_photo_uv()` — NO daylight grade, NO warming. Use UV-specific NANO prompt that PRESERVES neon purple/pink glow. The UV lighting IS the magic.
- "photo edit should not edit too much of the neon light effect, else it would be a diff play already"

## 3. Photo Selection — Must Read in Crop
- When photo goes in a CIRCLE or FRAME crop, the content must be INSTANTLY READABLE
- Abstract paint splatter = unreadable when cropped. Reject.
- Choose photos where the SUBJECT (activity, objects, hands) is clearly visible after crop
- "ur vision need to understand when its cropped, whether it shows the right motive anot"
- No customer kids' faces unless confirmed permission. Use no-face photos: hands, objects, desserts, painted surfaces.

## 4. Art Style = v16 Quality, NOT Generic Cartoon
- User approved: V16-08 (Tangy/CHAOS), V16-13 (Sunny/WE DON'T DO BORING), V16-12, V16-15 (BINGO)
- Characters: WARM, ROUND, DIMENSIONAL — like soft clay/plush, rosy cheeks, personality
- NOT flat vector, NOT outlined clipart, NOT generic AI cartoon
- Use V16-08 + V16-13 as STYLE REFERENCES when generating art posts
- Pushing "flat/risograph" = MORE generic, not less. "even more default" = too flat
- Headspace / LINE Friends quality target

## 5. Sticker/Stamp Element
- Rubber stamp feel — like ink pressed on paper. Tactile, handmade.
- **NO shadow** at all
- **Thin/light outlines** if any, or no outlines
- Can be character face OR text (like "come play") — but **NEVER "Bloom & Bare"** (that's the logo)
- NOT on every post — only where design naturally calls for it. Design variety.
- NOT a circular seal with brand text wrapping around
- NOT die-cut with thick white border
- NOT crayon/rough texture style
- About 6-12% canvas height, slightly tilted, corner placement

## 6. Typography — Body Copy Must Be DESIGNED
- Body copy (labels, CTAs, subtitles) must NEVER look like Arial/default
- Use THIN/LIGHT weight geometric sans with WIDE letter-spacing (generous tracking)
- Like Mabry Pro Light with extra tracking — airy, elegant, whisper-thin
- ALL CAPS body text = EXTRA wide tracking
- DRAMATIC contrast: chunky bold headlines vs whisper-thin tracked body
- "font looks too far from Mabry Pro... bodycopy font is abit too arial. Can be abit more thin, more tracking, like its designed not default"

## 7. Logo Zone
- Top 12% (160px) must be CLEAR — no photo, no text, no illustration
- Photo frames must start BELOW this zone
- "the image overlap on the logo" = photo pushed too high

## 8. Every Post Needs PURPOSE
Each post must have a specific intent — no mechanical batch production:
RELATE (emotional→saves), WONDER (stop-scroll→profile visits), ENGAGE (comments), ENTERTAIN (shares), CONVERT (CTA→DMs), VIRAL (shares), AUTHORITY (saves), EDUCATE, HYPE, POLL, COMMUNITY, NOSTALGIA, FOMO

## 9. Design Variety
- Every post must use a DIFFERENT design approach
- Different bg colors (yellow, blue, green, cream, lavender, coral)
- Different frame shapes (rounded rect, arch, circle)
- Different mascots per post
- Different layout structures
- "All image one is using same reference. No variety in design."

## 10. Character Rendering
- Mascot-hero posts: character must be CLEAN, UNDISTORTED
- NO sketch lines, NO rough edges on characters
- Flat color fill, rosy cheek marks, simple big eyes
- Use approved v16 outputs as STYLE REFERENCES for quality matching

## 11. Post-Processing Chain (PIL only)
force_size(1080x1350) → editorial_grade(desat=0.10, contrast=1.08) → paper_texture(0.025) → logo → grain(4.0) → sharpen
- Smart logo detection: auto-switch to B/W logo on dark photo tops
- PIL = resize + logo + grain + sharpen ONLY. ALL design = NANO.

## 12. Grid Rhythm
BOLD → PHOTO → CLEAN repeating rows of 3 in IG feed.
Week = 14 posts (2/day), alternating BOLD/PHOTO/CLEAN with variety.
