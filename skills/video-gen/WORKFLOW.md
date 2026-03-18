# Dreami Workflow — Vision-Aware Video Generation

## Overview

Dreami's new workflow uses visual analysis to create smarter, more viral video prompts. She now:
1. Analyzes main image + reference images 1/2/3/++
2. Extracts visual DNA, hooks, trending formats, and PAS lenses
3. Generates contextualized prompts for different goals (intent/output/campaign/brand/brief/test)
4. Enhances with brand DNA and viral trend awareness
5. Outputs high-quality Sora 2 videos

## Workflow Components

### 1. Vision Analysis (`vision-analyze.sh`)

**Purpose:** Extract visual DNA from images using Gemini Vision

**Usage:**
```bash
bash vision-analyze.sh <main_image> [ref1_image] [ref2_image] ...
```

**Outputs:**
- `visual_dna.json` with:
  - `scene_description` — What's in the image
  - `color_palette` — Dominant hex colors
  - `lighting`, `camera_angle`, `style`, `mood`, `vibe`
  - `hooks` — Viral hooks that grab attention
  - `trending_formats` — Best social media formats
  - `trending_tones` — Current viral tone trends
  - `passing_lenses` — PAS formula (Problem, Amplify, Solution)
  - `suggested_prompts` — Context-aware prompts for different goals

### 2. Prompt Enhancement (`prompt-enhance.sh`)

**Purpose:** Enhance base prompt with PAS + trending formats + brand DNA

**Usage:**
```bash
bash prompt-enhance.sh <visual_dna.json> [base_prompt] [--brand <brand_slug>]
```

**Enhancements:**
- PAS formula integration (Problem, Amplify, Solution)
- Viral hooks and trending formats
- Trending tone styles
- Visual DNA details (lighting, camera angle, etc.)
- Brand DNA (motion language, colors, voice)

### 3. Dreami Workflow Orchestrator (`dreami-workflow.sh`)

**Purpose:** Full automated workflow from vision → prompt → video

**Usage:**
```bash
bash dreami-workflow.sh <main_image> [ref1_image] [ref2_image] ... [--brand <brand_slug>] [--prompt "concept"]
```

**Steps:**
1. Vision analysis of all images
2. Context extraction (intent, output type, campaign, brief)
3. Prompt enhancement with PAS + trends + brand DNA
4. Sora 2 UGC video generation
5. Learnings storage for Zenni's routing

## Example Flow

### Input
- Main image: `wine-bottle.jpg`
- Reference images: `bento-topview.png`, `recipe-card.jpg`
- Brand: `pinxin-vegan`
- Concept: "Wine and cheese pairing for dinner parties"

### Step 1: Vision Analysis
```bash
bash vision-analyze.sh \
  wine-bottle.jpg \
  bento-topview.png \
  recipe-card.jpg
```

**Output:** `wine-bottle_vision_dna.json` with:
- Visual DNA: Top-down bento style, warm lighting, romantic mood
- Hooks: "Wine pairing mistakes" "Hosting like a pro"
- Formats: "Vertical bento topview for TikTok/IG Reels"
- PAS: Problem (hosting anxiety) → Amplify (memories last forever) → Solution (simple wine pairing)
- Prompts: Intent, output, campaign, brand, brief, test variants

### Step 2: Prompt Enhancement
```bash
bash prompt-enhance.sh \
  wine-bottle_vision_dna.json \
  "Wine and cheese pairing for dinner parties" \
  --brand pinxin-vegan
```

**Output:** Enhanced prompt with:
- PAS lenses integrated
- Trending vertical bento format
- Brand motion language: "Authentic handheld, warm lighting, steam visible"
- Color palette: #F7AB9F primary, #252525 secondary

### Step 3: Dreami Workflow (Full Pipeline)
```bash
bash dreami-workflow.sh \
  wine-bottle.jpg \
  bento-topview.png \
  recipe-card.jpg \
  --brand pinxin-vegan \
  --prompt "Wine and cheese pairing for dinner parties"
```

**Output:**
- Enhanced prompt: `dreami-20260301_123456/enhanced-prompt.txt`
- Video: `dreami-20260301_123456/video.mp4`
- Learnings: `data/videos/dreami-learnings.md`

## PAS Formula in Prompts

Dreami automatically structures prompts using PAS (Problem, Amplify, Solution):

**Problem:** What pain point this addresses
**Amplify:** The bigger truth this reveals
**Solution:** What you're offering that solves it

Example:
```
Problem: Hosting dinner parties can be stressful when you're not sure about wine pairings.
Amplify: Great memories with friends and family are made over good food and drinks—not complicated menus.
Solution: Here's a simple wine and cheese pairing that makes you look like a pro host, every time.
```

## Trending Formats Detection

Vision analysis detects and incorporates trending social media formats:

- **Vertical bento topview** — Best for TikTok/IG Reels product demos
- **Handheld authentic** — Current viral trend for UGC feel
- **12-second vertical** — Ideal for TikTok Shorts format
- **Warm natural lighting** — Current trend for authentic food content

## Brand DNA Integration

When `--brand` is specified, Dreami loads:
- **Motion language:** Vibe, motion style, audio cues
- **Colors:** Primary, secondary, background, accent
- **Voice:** Tone, language mix, personality

Example brand DNA injection:
```
Brand Motion: Vibe: Authentic handheld camera, warm lighting | Audio cues: Room tone, gentle food sounds
Brand Colors: primary:#4CAF50, secondary:#8D6E63, background:#F5F0EB
Brand Voice: Bold, clean, health-forward, proudly Malaysian
```

## Output Types and Aspect Ratios

Dreami automatically determines aspect ratio based on output type:

| Output Type    | Aspect Ratio | Best For             |
|----------------|--------------|----------------------|
| reels          | 9:16         | TikTok, IG Reels     |
| story          | 9:16         | IG Stories           |
| shorts         | 9:16         | YouTube Shorts       |
| ads/promos     | 16:9         | Facebook/Instagram Ads, Pre-roll |
| tutorial       | 16:9         | YouTube Tutorials   |

## Zenni's Routing Learning

Dreami stores learnings after each workflow:

**File:** `data/videos/dreami-learnings.md`

**What's stored:**
- Visual DNA extracted
- Trending formats used
- PAS lenses applied
- Brand DNA integrated
- Output type and aspect ratio
- Prompt enhancements that worked

**How Zenni uses this:**
- Recognizes patterns: "If user uploads main+2 refs → use dreami-workflow"
- Routes to Dreami automatically for vision-aware tasks
- Learns which brands/contexts work best with PAS/hooks
- Stores successful prompt structures for future use

## Command Reference

### Individual Components

```bash
# Vision analysis only
bash vision-analyze.sh main.jpg ref1.png ref2.png

# Prompt enhancement only
bash prompt-enhance.sh vision-dna.json "base prompt" --brand pinxin-vegan

# Full dreami workflow
bash dreami-workflow.sh main.jpg ref1.png ref2.png --brand pinxin-vegan --prompt "wine pairing"
```

### Integration with video-gen.sh

```bash
# Use dreami-workflow instead of manual steps
video-gen.sh sora-ugc --prompt "$(bash prompt-enhance.sh vision-dna.json)" --brand pinxin-vegan

# Or use dreami-workflow for full automation
bash dreami-workflow.sh main.jpg ref1.png ref2.png --brand pinxin-vegan
```

## Best Practices

### 1. Reference Images Matter

- Add 2-4 reference images for better visual consistency
- Use top-quality images with good lighting
- Include diverse angles (top-view, side, action shot)
- Reference brand assets when available

### 2. Concept Prompt Clarity

- Be specific about intent (educate, sell, entertain, inspire)
- Include campaign angle or key message
- Mention target audience if relevant
- Reference brand voice if applicable

### 3. Brand DNA Integration

- Always specify `--brand` when working with brand content
- Check brand DNA before enhancements
- Use brand motion language for authenticity
- Match brand colors in prompt descriptions

### 4. Output Type Selection

- reels/story/shorts → vertical 9:16
- ads/promos → landscape 16:9
- tutorial → landscape 16:9
- Don't force aspect ratio unless necessary

### 5. Learn from Results

- Review `dreami-learnings.md` for patterns
- Note which hooks/format worked best
- Adjust concept prompts for future runs
- Share learnings with Jenn

## Troubleshooting

**Vision analysis fails:**
- Check GEMINI_API_KEY is set
- Verify images are valid JPG/PNG/WebP
- Try reducing number of reference images

**Prompt enhancement empty:**
- Check visual_dna.json is valid JSON
- Verify BASE_PROMPT is provided
- Check brand DNA file exists

**Video generation fails:**
- Check Sora 2 API key is available
- Verify output directory has write permissions
- Check enhanced prompt is not too long

**Aspect ratio wrong:**
- Explicitly set `--aspect-ratio 9:16` or `16:9`
- Verify output type is correctly classified

## Future Enhancements

- [ ] Automatic format selection based on upload platform
- [ ] A/B testing multiple prompt variations
- [ ] Style transfer from reference images to generated video
- [ ] Real-time trend detection (Instagram/TikTok API)
- [ ] Automatic caption generation with style matching
- [ ] Performance tracking (views, engagement, saves)

## Contact

For questions about Dreami workflow:
- Jenn Woei (jennwoeiloh)
- GAIA CORP-OS
- Check memory/working/ for past workflow experiments