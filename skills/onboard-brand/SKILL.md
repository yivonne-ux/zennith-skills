---
name: onboard-brand
description: Create a new GAIA brand with AI-assisted identity design — colors, voice, tone, audience, DNA.json generation, brand directory setup.
agents:
  - main
  - dreami
---

# Onboard Brand — New Brand Creation Pipeline

End-to-end pipeline for creating a new GAIA brand. Generates brand identity, DNA.json configuration, directory structure, and initial creative assets. From concept to operational brand.

## When to Use

- Adding a new brand to the GAIA/Zennith ecosystem
- Rebranding an existing brand
- Creating a sub-brand or variant
- Cloning a competitor's brand positioning (copy business strategy)

## Current Brands (14)

dr-stan, gaia-eats, gaia-learn, gaia-os, gaia-print, gaia-recipes, gaia-supplements, iris, jade-oracle, mirra, pinxin-vegan, rasaya, serein, wholey-wonder

## Procedure

### Step 1 — Brand Discovery

Gather the following inputs:

| Field | Description | Example |
|-------|-------------|---------|
| Name | Brand name (lowercase, hyphenated) | jade-oracle |
| Full Name | Display name | The Jade Oracle |
| Tagline | One-line positioning | "Ancient wisdom, modern clarity" |
| Category | Business category | Spiritual services |
| Target Audience | Primary demographic | Women 25-45, spiritual seekers |
| Competitors | Who we compete with | Psychic Samira, CoStar |
| Unique Angle | What makes us different | Real QMDJ vs generic AI readings |
| Revenue Model | How it makes money | $1 intro reading, $47 deep reading, $497 mentorship |
| Tone | Communication style | Mystical, warm, authoritative |

### Step 2 — Brand Identity Design

Generate the following with Dreami:

#### Colors
- **Primary**: Main brand color (HEX)
- **Secondary**: Accent color (HEX)
- **Background**: Light/dark base (HEX)
- **Text**: Primary text color (HEX)
- **Accent**: Highlight/CTA color (HEX)

#### Voice & Tone
- **Personality**: 3-5 adjectives
- **Voice**: How the brand speaks (formal, casual, mystical, etc.)
- **Tone**: Emotional quality (warm, authoritative, playful, etc.)
- **Language**: Key phrases, vocabulary, prohibited words
- **POV**: First person, third person, brand as entity?

#### Visual Identity
- **Style**: Photography, illustration, AI-generated, mixed?
- **Mood**: Energetic, calm, luxurious, grounded?
- **Typography Direction**: Serif, sans-serif, handwritten?
- **Imagery Themes**: What appears in brand visuals?

### Step 3 — Generate DNA.json

Create the brand DNA file:

```json
{
  "name": "{brand-name}",
  "fullName": "{Full Brand Name}",
  "tagline": "{tagline}",
  "category": "{category}",
  "colors": {
    "primary": "#XXXXXX",
    "secondary": "#XXXXXX",
    "background": "#XXXXXX",
    "text": "#XXXXXX",
    "accent": "#XXXXXX"
  },
  "voice": {
    "personality": ["{adj1}", "{adj2}", "{adj3}"],
    "tone": "{tone description}",
    "language": {
      "use": ["{preferred phrases}"],
      "avoid": ["{prohibited terms}"]
    }
  },
  "audience": {
    "primary": "{demographic}",
    "psychographic": "{interests, values, lifestyle}",
    "painPoints": ["{pain1}", "{pain2}"],
    "desires": ["{desire1}", "{desire2}"]
  },
  "products": [
    {
      "name": "{product}",
      "price": "{price}",
      "description": "{brief}"
    }
  ],
  "competitors": ["{competitor1}", "{competitor2}"],
  "uniqueAngle": "{differentiation}",
  "visualStyle": {
    "mood": "{mood}",
    "imagery": ["{theme1}", "{theme2}"],
    "style": "{photography/illustration/ai}"
  }
}
```

Save to: `~/.openclaw/brands/{brand-name}/DNA.json`

### Step 4 — Directory Setup

Create the standard brand directory structure:

```
~/.openclaw/brands/{brand-name}/
  DNA.json              (brand identity, created in step 3)
  assets/               (brand assets folder)

~/.openclaw/workspace/data/images/{brand-name}/
  (empty, ready for content)
```

### Step 5 — Register in System

After creating the brand:

1. Update `openclaw.json` to include the brand in relevant agent configs (if needed)
2. Run `python3 workspace/scripts/sync-claude-md.py` to update CLAUDE.md
3. Verify DNA.json loads correctly: check JSON is valid
4. Post to ops room: brand created, ready for content

### Step 6 — Initial Creative Test

Generate 2-3 test images using the new brand DNA:

```bash
nanobanana-gen.sh generate \
  --brand {brand-name} \
  --prompt "{test prompt aligned with brand}" \
  --output ~/.openclaw/workspace/data/images/{brand-name}/test-001.png
```

Verify:
- Colors match DNA.json
- Visual style matches brand mood
- No brand bleed from other GAIA brands
- Text rendering (if any) is clean

### Step 7 — Output

```markdown
# Brand Onboarding Complete — {Brand Name}
## Status: Active

### Brand Identity
- Colors: {swatches}
- Voice: {personality adjectives}
- Audience: {primary target}

### Files Created
- DNA.json: ~/.openclaw/brands/{brand}/DNA.json
- Image directory: ~/.openclaw/workspace/data/images/{brand}/

### Test Images
- {paths to test images}

### Next Steps
- [ ] Create character (if applicable)
- [ ] Design initial ad creatives
- [ ] Set up social media profiles
- [ ] Create landing page
```

## Agent Roles

- **Zenni (main)**: Orchestrates the onboarding, gathers inputs, coordinates steps, registers in system
- **Dreami**: Designs brand identity (colors, voice, visual style), generates DNA.json content, creates test images, ensures no brand bleed

## Brand Bleed Prevention

Learned from NanoBanana brand injection bugs (2026-03-12):
- Each brand DNA must have unique, non-overlapping visual elements
- Test with `--brand {name}` to verify NanoBanana uses correct DNA
- If brand names or logos appear in generated images, use `--raw` flag
- Check that no "sacred futurism" or other GAIA-OS themes bleed into new brands

## Example

```
Onboard a new brand: "serene-kitchen"
Category: Meal prep delivery for busy professionals
Audience: Working professionals 28-40, health-conscious, no time to cook
Tone: Clean, efficient, trustworthy, slightly premium
Competitors: Factor, HelloFresh, Trifecta
Unique angle: AI-personalized weekly menus based on health goals
```
