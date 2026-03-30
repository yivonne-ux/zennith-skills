---
name: Reference mastery system — curation, scoring, forensic, matching
description: How to master references for video production. Rating system, taxonomy, curation process, forensic analysis framework. References = 50% of output quality. READ BEFORE sourcing or selecting references.
type: feedback
---

## PRINCIPLE: Master the reference, master 50% of the output.

A bad reference = a bad output, no matter how good the prompt. A perfect reference = the prompt barely matters — just "copy this, change the person."

---

## 1. REFERENCE RATING SYSTEM (score 1-5 on each)

Every reference image gets scored on 5 dimensions:

| Dimension | 1 (reject) | 3 (usable) | 5 (perfect) |
|-----------|-----------|------------|-------------|
| **ANGLE** | Generic/boring straight-on | Interesting but common | Unique POV that hooks — you've never seen this angle before |
| **AUTHENTICITY** | Obvious stock photo, studio lighting | Looks real but slightly staged | Indistinguishable from a real vlog frame — iPhone quality, imperfect framing, natural light |
| **ADAPTABILITY** | Too specific to copy (branded items, recognizable location) | Can be adapted with effort | Easy to swap person/outfit/background while keeping the angle |
| **MOOD** | Cold/corporate/harsh | Neutral | Warm, natural, matches brand world (cream-blush for Mirra) |
| **PLATFORM** | Horizontal/wrong ratio | Works but not native | Native 9:16, feels like it belongs on IG reels/TikTok/XHS |

**Minimum score to keep: 3.0 average across all 5.**
**Target for hero references: 4.0+ average.**

### Quick filter (instant reject):
- Horizontal format → REJECT (unless angle is so unique it's worth cropping)
- Obvious watermark → REJECT
- Low resolution / blurry → REJECT
- Staged studio lighting → REJECT
- Western lifestyle that doesn't translate to Asian audience → REJECT

---

## 2. REFERENCE TAXONOMY (how to organize)

### By SHOT TYPE (primary organization):
```
references/
├── scale/           — feet on weighing scale POV
├── morning/         — getting ready, bathroom, bedroom
├── outfit/          — full body outfit check, mirror, doorway
├── coffee/          — making/holding coffee, kitchen counter
├── commute/         — car interior, walking to car, transit
├── office_enter/    — walking into building, elevator, hallway
├── working/         — at desk, laptop, typing, focused
├── food_topdown/    — food on table, no person, phone POV angle
├── eating_face/     — face-to-camera eating, mukbang style
├── selfie/          — mirror selfie, front camera selfie
├── mirror_result/   — body check, weight loss result, confident
├── walking/         — street, hallway, moving
└── misc/            — anything that doesn't fit above
```

### By METADATA (secondary tags):
- Platform source: pinterest / tiktok / ig / xhs / youtube
- Person visible: yes / no / hands only
- Angle type: pov / tripod / selfie / overhead / side
- Setting: home / office / car / outdoor / restaurant
- Mood: warm / cool / neutral / dramatic

---

## 3. CURATION PROCESS

### Initial scrape: cast wide (50-100 per query)
### First pass: quick filter (remove instant rejects)
### Second pass: rate each 1-5 on all dimensions
### Third pass: keep only 3.0+ average
### Final library: 3-5 HERO references per shot type

**The target: for every shot type, have 3-5 options that score 4.0+.**

When you have 5 perfect "eating face" references, you KNOW what that shot looks like. You're not guessing. You're not imagining. You're copying proven frames.

---

## 4. FORENSIC ANALYSIS PER REFERENCE

For every HERO reference (4.0+), document:

```markdown
## REF: eating_face_01.jpg
**Source:** TikTok @xo_re.t.ii
**Score:** 4.6 (angle:5, auth:5, adapt:4, mood:4, platform:5)

### What makes this work:
- Camera at EXACT face level — not above, not below
- Food bowl visible at bottom of frame (chin to bowl = the composition)
- Natural expression — mid-chew, not posing
- Background is blurred but recognizable as a real room
- Warm natural light from the left
- Phone propped on table (you can tell from the slight upward angle)

### Technical specs to copy:
- Distance: ~60cm from face (arm's length phone placement)
- Angle: straight-on, very slight upward tilt
- DOF: face sharp, background soft (phone portrait mode)
- Framing: head cropped at forehead, bowl cropped at bottom
- Light: window left, overhead ambient

### What to KEEP when adapting:
- Exact face-to-bowl framing ratio
- Camera height (table level)
- The slight upward tilt
- Background blur level

### What to CHANGE when adapting:
- Person → our character
- Outfit → per wardrobe spec
- Food → Mirra bento
- Background → our setting
```

---

## 5. REFERENCE MATCHING ENGINE

Given a scene spec, find the best reference:

```
INPUT: Scene type = "working at desk"
       Character = "28yo Chinese woman"
       Setting = "co-working space"
       Mood = "warm cream-blush"

SEARCH: references/working/*.jpg
FILTER: score >= 4.0
RANK BY: adaptability (how easy to swap person + setting)
OUTPUT: Top 3 references with forensic analysis
```

This can be automated:
1. Gemini Vision scores new references automatically
2. Metadata tags applied
3. Stored in a JSON index
4. Query by scene type → get ranked results

---

## 6. CONTINUOUS SOURCING

### Where to find references:
1. **Pinterest** — best for static angles, mood boards, aesthetic
2. **TikTok** — best for vlog angles, real human movement, hooks
3. **IG Reels** — best for trending formats, editing styles
4. **XHS** — best for Asian lifestyle, food, aesthetic daily life
5. **YouTube** — best for long-form vlog scenes, detailed shots

### Sourcing cadence:
- Before EVERY new video concept: scrape 50-100 references
- After curation: keep 20-30
- After forensic: 3-5 heroes per shot type
- After generation: save successful outputs as FUTURE references

### The flywheel:
Good reference → good output → output becomes reference for next video → quality compounds

### Auto-scraper tool:
`~/Desktop/video-compiler/tools/reference_scraper.py`
- Unified scraper: Pinterest + TikTok + IG + YouTube
- Auto-download videos (yt-dlp)
- Auto-extract scenes (FFmpeg every 2s)
- Auto-score (Gemini Vision, 5 dimensions)
- Auto-organize into categorized library (13 shot types)
- Usage: `python3 tools/reference_scraper.py --queries "..." --platforms pinterest youtube --score --library path/`

---

## 7. WHAT I LACK RIGHT NOW

### Skills to develop:
1. **VISUAL TASTE** — I can analyze technically but I can't FEEL what stops a scroll. This comes from studying thousands of viral frames, not from reading about them.
2. **ASIAN VLOG AESTHETIC FLUENCY** — I default to Western stock photography aesthetics. Need to internalize Korean/Taiwanese/XHS visual language through exposure.
3. **ANGLE VOCABULARY** — I describe angles in cinema terms (85mm f/1.8) when I should describe them in vlog terms (phone propped on coffee table).
4. **SPEED OF JUDGMENT** — I should know in 1 second if a reference is 3/5 or 5/5. Right now I need Gemini Vision to tell me.
5. **CULTURAL SPECIFICITY** — what does a REAL KL condo look like? A REAL Common Ground co-working space? I imagine generic versions instead of specific ones.

### How to develop:
- Study 100+ viral Asian vlogs frame-by-frame (not thumbnails — actual scenes)
- Build a reference library of 200+ scored, forensic-analyzed hero references
- Practice: given a scene spec, pick the reference in under 10 seconds
- Feedback loop: every user rejection teaches what I misjudged
