# Dreami Routing Protocol — Zenni's Enhanced Router

## Overview

Zenni now has a learned routing system that automatically recognizes when Dreami's vision-aware workflow should be used. This happens through:

1. **Visual Input Detection:** Main image + reference images
2. **Context Recognition:** Output type, brand, campaign concept
3. **Pattern Learning:** Successful workflows stored in memory
4. **Automatic Dispatch:** Dreami invoked without explicit instructions

## Routing Triggers

Dreami workflow triggers when ALL of these conditions are met:

```json
{
  "has_visual_input": true,  // Main image + 2+ reference images
  "has_brand_context": false, // Optional but improves quality
  "has_concept": true,        // Concept/prompt provided
  "task_type": "video_ugc",   // Not specific ads or tutorials
  "visual_confidence": "high" // References match style
}
```

### High Confidence Triggers (Auto-Dispatch)

1. **Main image + 2+ reference images** → Vision analysis guaranteed to improve results
2. **Brand DNA available** → Automatic enhancement with brand motion language
3. **Concept provided** → PAS + hooks automatically integrated
4. **Output type unclear** → Vision analysis detects best format

### Medium Confidence Triggers (Ask Jenn)

1. **Single image only** → Try without refs, but offer option
2. **No brand specified** → Use general trending formats
3. **Vague concept** → Ask for clarification or keywords

### Low Confidence Triggers (Fallback)

1. **Text-only request** → Use regular Sora workflow
2. **Specific tutorial** → User likely wants educational content
3. **Hardcoded formats** → User knows what they want (16:9 only)

## Routing Decision Flow

```
Receive Message
    ↓
Does message contain images?
    ├─ No → Check for text-only video request
    │        ↓
    │   Has specific format requirements?
    │        ├─ Yes → Direct to Sora or other provider
    │        └─ No → Dispatch to Dreami for Sora UGC
    │
    └─ Yes → Count images
             ↓
        ≥3 images → Dreami workflow (high confidence)
             ↓
        =1 image → Ask Jenn: "Add 2+ references for better quality?"
             ↓
        =2 images → Dreami workflow (medium confidence)
```

## Pattern Learning

Dreami stores learnings in `data/videos/dreami-learnings.md`:

```markdown
## [2026-03-01 12:34] Dreami Workflow — Visual-Aware Video Generation

### Visual DNA Extracted
- Scene: Wine and cheese pairing
- Format: reels
- Campaign: "Hosting like a pro"
- Vibe: Romantic, warm lighting
- Trending: Vertical bento topview for TikTok/IG Reels

### Learnings
- Reference images improved visual consistency
- PAS formula helped structure viral hooks
- Brand DNA enhances authenticity
- Output type determines aspect ratio: 9:16

### Tags: video, dreami-workflow, vision-aware, sora-ugc, viral-prompts
```

**Zenni's Learning Process:**
- Reads `dreami-learnings.md` periodically
- Extracts patterns: "pinxin-vegan + wine + 3 refs → use 9:16 format"
- Updates routing cache with successful patterns
- Avoids repeating failed configurations

## Dispatch Brief for Dreami

When Zenni dispatches to Dreami, the brief includes:

```
Dreami: Create video for "wine and cheese pairing for dinner parties"
- MAIN IMAGE: /Users/jennwoeiloh/.openclaw/media/inbound/wine-bottle.jpg
- REFERENCES: /path/to/bento-topview.png, /path/to/recipe-card.jpg
- BRAND: pinxin-vegan
- CONCEPT: Wine and cheese pairing for dinner parties
- OUTPUT TYPE: reels (auto-detected)
- ASPECT RATIO: 9:16 (auto-detected)
- USE PAS: Yes (auto-detected)
- USE HOOKS: Yes (auto-detected)
- USE TRENDS: Yes (auto-detected)
```

## Output Context Routing

Dreami's output is routed to the correct channel based on context:

| Output Type | Channel | Room |
|-------------|---------|------|
| reels | WhatsApp | creative |
| story | WhatsApp | creative |
| shorts | WhatsApp | creative |
| ads/promos | WhatsApp | creative |
| tutorial | WhatsApp | build |
| general UGC | WhatsApp | creative |

**Context Detection:**
- `--campaign` keyword → creative room
- `--tutorial` keyword → build room
- Default → creative room
- `--debug` flag → also post to execution room

## Brand-Specific Routing

Dreami respects brand-specific workflows:

- **pinxin-vegan:** Vibrant, bold, health-forward (use warm lighting, steam visible)
- **wholey-wonder:** Fresh, wholesome, cozy (use natural light, textures visible)
- **mirra:** Elegant, sophisticated (use soft lighting, clean lines)
- **gaia-eats:** Fresh, appetizing (use close-up food photography, steam visible)
- **dr-stan:** Professional, trustworthy (use clinical lighting, organized layout)
- **serein:** Calm, luxurious (use soft tones, minimalist composition)

**Brand Detection:**
1. Check `--brand` flag
2. Look for brand keywords in concept prompt
3. Check uploaded images for brand colors/assets
4. Default to general tone if no brand detected

## Successful Routing Examples

### Example 1: Auto-Detect

**Jenn:** "Create a wine and cheese video like this" (uploads 3 images)

**Zenni (Detects):**
- Main image: wine-bottle.jpg
- Refs: bento.png, recipe.jpg
- Output type: reels (from ref images)
- Confidence: HIGH (3+ images, clear intent)

**Zenni dispatches:**
```
Dreami: Create video for wine and cheese pairing
- 3 reference images provided
- High confidence: Use dreami-workflow
- Output: 9:16 reels for social
```

**No question asked to Jenn** — auto-decision based on high confidence.

### Example 2: Medium Confidence

**Jenn:** "Make a wine video" (uploads 1 image only)

**Zenni (Detects):**
- Main image: wine-bottle.jpg
- Refs: none
- Confidence: MEDIUM (1 image, no concept)

**Zenni asks:**
```
Jenn: I detected this wine bottle image. Should I:
1. Generate a video directly from this image (good quality, but no reference style)
2. First ask you for 2-3 reference images for better visual consistency
```

**Jenn chooses** or Zenni auto-decides based on urgency.

### Example 3: Brand-Specific

**Jenn:** "Pinxin vegan recipe video" (uploads 2 images)

**Zenni (Detects):**
- Brand: pinxin-vegan (keyword in prompt)
- Refs: dish photo, bento ref
- Output type: reels (viral format)
- Confidence: HIGH (brand + refs + concept)

**Zenni dispatches:**
```
Dreami: Create viral pinxin vegan recipe video
- BRAND: pinxin-vegan (bold, health-forward, Malaysian)
- 2 reference images for bento style
- Output: 9:16 reels for TikTok/IG
- Style: Handheld authentic, warm lighting, steam visible
```

**Automatic brand DNA injection** without asking Jenn.

## Feedback Loop

**Dreami → Zenni → Jenn**

After each workflow run, Dreami reports back to Zenni:

```json
{
  "workflow_id": "dreami-20260301_123456",
  "status": "success",
  "visual_dna": {
    "scene": "wine pairing",
    "formats": ["vertical bento topview"],
    "trends": ["warm natural lighting", "authentic handheld"]
  },
  "output": {
    "video_path": "/data/videos/dreami-20260301_123456/video.mp4",
    "cost": 0.50,
    "duration": 8
  },
  "learnings": [
    "PAS formula improved hook engagement",
    "Bento topview references worked well",
    "Brand motion language enhanced authenticity"
  ]
}
```

**Zenni aggregates learnings** and shares with Jenn:
- "✅ Video generated: vineyard-wine-bento.mp4 (8s, ~$0.50)"
- "Key insights: Bento topview worked well, PAS hooks performed best"
- "Stored learnings for future viral content"

## Error Handling

**When things go wrong:**

1. **Vision analysis fails**
   - Zenni asks Jenn: "Can't analyze images. Text-only video?"

2. **Brand DNA not found**
   - Zenni warns Jenn: "No brand DNA for 'x'. Using general style."

3. **Video generation fails**
   - Zenni asks Jenn: "Sora failed. Try Wan provider? Add more prompt details?"

4. **Low confidence but urgent**
   - Zenni auto-decides based on urgency
   - Reports back with details for review

## Configuration

**Routing thresholds:**

| Threshold | Value | Description |
|-----------|-------|-------------|
| min_refs | 2 | Minimum references for high confidence |
| max_refs | 5 | Maximum references for vision analysis |
| min_brand | true | Require brand for brand-specific routing |
| confidence_score | 70% | Minimum confidence to auto-dispatch |
| learnings_age | 7 days | How long to keep learnings before review |

## Best Practices

1. **Always specify brand** when creating brand content
2. **Add 2+ reference images** for vision-aware generation
3. **Be specific about output type** (reels vs ads)
4. **Review learnings periodically** to improve routing
5. **Share successful patterns with Jenn** for future content

## Future Enhancements

- [ ] Automatic trend detection from Instagram/TikTok API
- [ ] Style matching from reference images
- [ ] A/B testing of multiple prompt variations
- [ ] Real-time performance tracking
- [ ] Cross-brand learning (learn from pinxin-vegan, apply to wholey-wonder)
- [ ] Manual overrides with transparency (why did Zenni choose this?)