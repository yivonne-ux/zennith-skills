# Dreami Workflow Enhancement — Complete Guide

## What Changed

Dreami's video generation workflow is now **vision-aware**. She can:

1. ✅ **Analyze multiple reference images** (main + ref 1/2/3/++)
2. ✅ **Extract visual DNA** (scene, colors, lighting, camera angle, mood, vibe)
3. ✅ **Generate PAS-formatted prompts** (Problem, Amplify, Solution)
4. ✅ **Apply trending hooks & formats** (vertical bento, handheld authentic, etc.)
5. ✅ **Integrate brand DNA** automatically (motion language, colors, voice)
6. ✅ **Output context-aware prompts** (intent, output, campaign, brand, brief, test)
7. ✅ **Store learnings for Zenni's routing** (patterns, what worked, what didn't)

## New Scripts Created

### 1. `vision-analyze.sh` (9.9K) — Vision Analysis
**Purpose:** Analyze main image + reference images using Gemini Vision

**Usage:**
```bash
bash vision-analyze.sh <main_image> [ref1_image] [ref2_image] ...
```

**Outputs:** `visual_dna.json` with:
- Visual DNA (scene, lighting, camera angle, etc.)
- Viral hooks that grab attention
- Trending social media formats
- PAS lenses (Problem, Amplify, Solution)
- Context-aware prompts (intent, output, campaign, brand, brief, test)

**Example:**
```bash
bash vision-analyze.sh wine-bottle.jpg \
  bento-topview.png \
  recipe-card.jpg
```

### 2. `prompt-enhance.sh` (7.0K) — Prompt Enhancement
**Purpose:** Enhance base prompt with PAS + trending formats + brand DNA

**Usage:**
```bash
bash prompt-enhance.sh <visual_dna.json> [base_prompt] [--brand <brand_slug>]
```

**Enhancements:**
- PAS formula integration
- Viral hooks and trending formats
- Visual DNA details (lighting, camera angle, etc.)
- Brand DNA (motion language, colors, voice)

**Example:**
```bash
bash prompt-enhance.sh wine-bottle_vision_dna.json \
  "Wine and cheese pairing for dinner parties" \
  --brand pinxin-vegan
```

### 3. `dreami-workflow.sh` (6.0K) — Full Workflow Orchestrator
**Purpose:** Full automated workflow from vision → prompt → video

**Usage:**
```bash
bash dreami-workflow.sh <main_image> [ref1_image] [ref2_image] ... \
  [--brand <brand_slug>] [--prompt "concept"]
```

**Steps:**
1. Vision analysis of all images
2. Context extraction (intent, output type, campaign, brief)
3. Prompt enhancement with PAS + trends + brand DNA
4. Sora 2 UGC video generation
5. Learnings storage for Zenni's routing

**Example:**
```bash
bash dreami-workflow.sh wine-bottle.jpg \
  bento-topview.png \
  recipe-card.jpg \
  --brand pinxin-vegan \
  --prompt "Wine and cheese pairing for dinner parties"
```

**Outputs:**
- `dreami-YYYYMMDD_HHMMSS/vision-dna.json` — Visual DNA
- `dreami-YYYYMMDD_HHMMSS/enhanced-prompt.txt` — Final prompt
- `dreami-YYYYMMDD_HHMMSS/video.mp4` — Generated video
- `data/videos/dreami-learnings.md` — Learnings for Zenni

## How It Works — Step-by-Step

### Step 1: Upload Images
You upload:
- **Main image:** The primary visual (product, scene, etc.)
- **Reference images (optional):** 2-4 additional images for style/angle reference

**Why:**
- References ensure visual consistency
- Top-down bento shots, lighting angles, food styling
- Brand assets (logos, color palette references)

### Step 2: Vision Analysis
Dreami uses Gemini Vision to analyze:

**Visual DNA extracted:**
```
{
  "scene_description": "Bottle of red wine next to cheese board with grapes",
  "color_palette": ["#722F37", "#F7AB9F", "#FFF9EB", "#252525"],
  "lighting": "Warm natural light from left, dramatic shadows on right",
  "camera_angle": "Top-down flat lay, 45-degree angle",
  "style": "Clean minimalist bento composition",
  "mood": "Romantic, warm, sophisticated",
  "vibe": "Authentic, not overly polished"
}
```

**Trending hooks:**
```
- Hook 1: "Wine pairing mistakes that make hosting look cheap"
- Hook 2: "One bottle + one cheese board = hosting like a pro"
```

**Trending formats:**
```
- Format 1: Vertical bento topview for TikTok/IG Reels
- Format 2: Warm handheld camera with room tone
```

**PAS lenses:**
```
Problem: Hosting dinner parties is stressful when you're not sure about wine pairings.
Amplify: Great memories with friends are made over good food and drinks—not complicated menus.
Solution: Here's a simple wine and cheese pairing that makes you look like a pro host, every time.
```

### Step 3: Prompt Enhancement
Dreami enhances your concept with:

**Base prompt:** "Wine and cheese pairing for dinner parties"

**Enhanced prompt:**
```
Create a viral video about "wine pairing for dinner parties". 

Problem: Hosting dinner parties is stressful when you're not sure about wine pairings. 
Amplify: Great memories with friends are made over good food and drinks—not complicated menus. 
Solution: Here's a simple wine and cheese pairing that makes you look like a pro host, every time.

Viral Hooks: 
- "Wine pairing mistakes that make hosting look cheap"
- "One bottle + one cheese board = hosting like a pro"

Trending Formats: Vertical bento topview for TikTok/IG Reels

Trending Tone Trends: Raw authentic handheld camera with room tone

Visual: Bottle of red wine next to cheese board with grapes, top-down flat lay
Colors: #722F37 (red wine), #F7AB9F (cheese), #FFF9EB (background), #252525 (text)
Lighting: Warm natural light from left, dramatic shadows on right
Camera Angle: Top-down flat lay, 45-degree angle
Style: Clean minimalist bento composition
Mood: Romantic, warm, sophisticated
Vibe: Authentic, not overly polished

Brand Motion: Vibe: Authentic handheld camera, warm lighting | Audio cues: Room tone, gentle food sounds
Brand Colors: primary:#4CAF50, secondary:#8D6E63, background:#F5F0EB
Brand Voice: Bold, clean, health-forward, proudly Malaysian
```

### Step 4: Video Generation
Dreami uses Sora 2 UGC pipeline:
- Aspect ratio: 9:16 (auto-detected from reference format)
- Duration: 8 seconds (optimal for viral short-form)
- Model: sora-2

### Step 5: Learnings Storage
Dreami stores learnings to `data/videos/dreami-learnings.md`:

```markdown
## [2026-03-01 12:34] Dreami Workflow — Visual-Aware Video Generation

### What Happened
- Vision analysis of wine-bottle.jpg with 2 reference images
- PAS + trending hooks + formats integrated into prompt
- Brand DNA applied: pinxin-vegan
- Output: video.mp4

### Visual DNA Extracted
- Scene: Wine pairing for dinner parties
- Format: reels (vertical bento topview)
- Campaign: "Hosting like a pro"
- Vibe: Romantic, warm lighting
- Trending: Vertical bento topview for TikTok/IG Reels

### Learnings
- Reference images improved visual consistency by 40%
- PAS formula helped structure viral hooks
- Brand motion language enhances authenticity
- Output type determines aspect ratio: 9:16

### Tags: video, dreami-workflow, vision-aware, sora-ugc, viral-prompts
```

**Zenni uses these learnings:**
- Recognizes patterns: "pinxin-vegan + wine + 3 refs → use 9:16 format"
- Routes to Dreami automatically for vision-aware tasks
- Learns which hooks/format worked best
- Avoids repeating failed configurations

## Zenni's Routing — Auto-Detection

**How Zenni decides when to use Dreami:**

### High Confidence → Auto-Dispatch
- Main image + 2+ reference images
- Brand DNA available
- Concept provided
- Clear intent

**Example:** You upload 3 images → Zenni auto-dispatches to Dreami without asking.

### Medium Confidence → Ask Jenn
- Single image only
- No brand specified
- Vague concept

**Example:** You upload 1 image → Zenni asks: "Add 2+ references for better quality?"

### Low Confidence → Fallback
- Text-only request
- Specific tutorial
- Hardcoded format

**Example:** "Create 16:9 wine tutorial" → Zenni routes to regular Sora workflow.

## PAS Formula Explained

**Problem:** What pain point this addresses
**Amplify:** The bigger truth this reveals
**Solution:** What you're offering that solves it

**Why it works:**
- Hooks attention with relatable pain point
- Amplifies emotional connection
- Provides satisfying solution
- Creates narrative structure for viral content

**Example:** "Wine pairing mistakes" (Problem) → "Hosting like a pro" (Amplify) → "Simple wine pairing" (Solution)

## Trending Formats Detected

Vision analysis detects current viral trends:

| Trend | Best For | Why It Works |
|-------|----------|--------------|
| Vertical bento topview | Product demos, recipes | Shows everything at once, highly shareable |
| Handheld authentic | UGC feel, testimonials | Feels real, not scripted |
| Warm natural lighting | Food, lifestyle | Inviting, appetizing |
| 12-second vertical | TikTok Shorts | Perfect attention span |
| Close-up textures | Premium products | Shows quality, detail |

## Brand DNA Integration

**When brand is specified:**
```bash
--brand pinxin-vegan
```

**Dreami loads:**
- **Motion language:** Vibe: Authentic handheld camera, warm lighting
- **Colors:** primary:#4CAF50, secondary:#8D6E63, background:#F5F0EB
- **Voice:** Bold, clean, health-forward, proudly Malaysian

**Result:** Brand authenticity in every video.

## Best Practices

### 1. Use Multiple Reference Images
- **2-4 images** recommended
- Include top-down, side, and action shots
- Use brand assets (bento templates, logos)
- Reference successful viral videos

### 2. Be Specific About Intent
- Say "educate" not just "show wine"
- Mention "viral hooks" if you want attention
- Specify "authentic" vs "polished" style

### 3. Always Specify Brand
```bash
--brand pinxin-vegan
```

Prevents generic style injection.

### 4. Review Learnings
Check `data/videos/dreami-learnings.md` after runs:
- What formats worked best?
- Which hooks performed well?
- Brand DNA integration points

### 5. Let Zenni Route
Zenni auto-detects when to use Dreami workflow:
- High confidence = no questions
- Medium confidence = brief confirmation
- Low confidence = alternative workflow

## Output Types & Aspect Ratios

| Output Type | Aspect Ratio | Best For |
|-------------|--------------|----------|
| reels | 9:16 | TikTok, IG Reels |
| story | 9:16 | IG Stories |
| shorts | 9:16 | YouTube Shorts |
| ads/promos | 16:9 | Facebook/Instagram Ads |
| tutorial | 16:9 | YouTube Tutorials |

**Auto-detected from reference images** unless you specify:

```bash
--aspect-ratio 16:9  # Force landscape for ads
```

## Cost & Performance

**Per video generation:**
- Vision analysis (Gemini Vision): ~$0.02
- Prompt enhancement: ~$0.01 (Gemini 2.5 flash)
- Sora 2 generation: ~$0.50
- **Total:** ~$0.53 per video

**Time to complete:**
- Vision analysis: 15-30 seconds
- Prompt generation: 5-10 seconds
- Sora generation: 2-5 minutes (polling)
- **Total:** ~3-6 minutes

## Troubleshooting

**Vision analysis fails:**
- Check GEMINI_API_KEY is set
- Verify images are valid JPG/PNG/WebP
- Reduce number of reference images

**Enhanced prompt too long:**
- Shorten base concept
- Remove unnecessary references
- Let Dreami auto-truncate

**Video quality poor:**
- Use higher quality main image
- Add more reference images
- Be more specific with concept

**Brand DNA not applied:**
- Check brand slug spelling: `--brand pinxin-vegan`
- Verify DNA.json exists: `~/.openclaw/brands/pinxin-vegan/DNA.json`
- Check brand names: pinxin-vegan, wholey-wonder, mirra, rasaya, gaia-eats, dr-stan, serein

## Documentation

- **WORKFLOW.md:** Complete workflow documentation with examples
- **DREAMI-ROUTING.md:** Zenni's routing protocol and pattern learning
- **SKILL.md:** Original video-gen skill (still works, now enhanced)

## Next Steps

1. **Try Dreami Workflow:** Upload images + concept, let Dreami enhance
2. **Review Learnings:** Check `data/videos/dreami-learnings.md` for patterns
3. **Provide Feedback:** Tell Jenn what worked, what didn't
4. **Refine References:** Adjust reference images for better results
5. **Expand Brand DNA:** Add more brand-specific motion styles

---

**Created:** 2026-03-02
**Version:** 2.0
**Author:** Dreami + Zenni (GAIA CORP-OS)
**Status:** ✅ Production Ready