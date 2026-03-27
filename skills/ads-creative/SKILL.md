---
name: ads-creative
description: Cross-platform creative quality audit covering ad copy, video, image, and landing pages. Creative scoring framework.
agents:
  - dreami
  - hermes
---

# Ads Creative — Cross-Platform Creative Quality Audit

Deep evaluation of advertising creative assets across all platforms. Covers ad copy, images, video, carousel, and landing page creative alignment. Dreami's domain.

## When to Use

- Creative performance is declining (rising CPM, dropping CTR)
- Preparing for a creative refresh
- Auditing existing ad library for quality
- Evaluating A/B test results on creative elements
- New brand launch needs creative quality baseline

## Procedure

### Step 1 — Inventory Creative Assets

Catalog all active ad creatives across platforms:

| Asset | Platform | Format | Status | Age | CTR | Notes |
|-------|----------|--------|--------|-----|-----|-------|
| ... | Meta | Video 15s | Active | 14d | 2.1% | ... |

Check image assets at: `~/.openclaw/workspace/data/images/{brand}/`

### Step 2 — Copy Audit

For each ad, evaluate the copy:

| Element | Score (1-10) | Criteria |
|---------|-------------|----------|
| Hook | | First line grabs attention? Pattern interrupt? |
| Value Prop | | Clear benefit stated? Specific and believable? |
| Social Proof | | Numbers, testimonials, authority signals? |
| Urgency | | Time limit, scarcity, FOMO? |
| CTA | | Clear, single action? Matches funnel stage? |
| Brand Voice | | Matches DNA.json tone? Consistent across ads? |
| Platform Fit | | Copy length/style matches platform norms? |

### Step 3 — Visual Audit

For images and video:

| Element | Score (1-10) | Criteria |
|---------|-------------|----------|
| Thumb-Stop Power | | Would you stop scrolling? First frame quality? |
| Brand Consistency | | Colors, fonts, style match DNA.json? |
| Text Overlay | | Readable on mobile? Under 20% of image area? |
| Faces/People | | Human faces increase engagement. Present? |
| Product Visibility | | Is the product/service clearly shown? |
| Platform Specs | | Correct aspect ratio? Resolution? File size? |

For video specifically:

| Element | Score (1-10) | Criteria |
|---------|-------------|----------|
| First 3 Seconds | | Hook strong enough to prevent skip? |
| Pacing | | Cuts every 2-3s for short-form? Keeps attention? |
| Sound Design | | Works with sound off (captions)? Sound on adds value? |
| CTA Placement | | End card? Mid-roll? Verbal + visual? |
| Length | | Appropriate for platform and placement? |

### Step 4 — Brand Voice Check

Load the brand DNA:
```
~/.openclaw/brands/{brand}/DNA.json
```

Verify all creative elements align with:
- Brand colors and visual identity
- Tone of voice (formal, casual, spiritual, etc.)
- Target audience messaging
- Prohibited terms or themes

### Step 5 — A/B Testing Assessment

Evaluate testing practices:
- Are creatives being A/B tested?
- Is only ONE variable changed per test?
- Is sample size sufficient before declaring winners?
- Are winning elements being applied to new creatives?
- Testing cadence — how often are new creatives introduced?

### Step 6 — Creative Fatigue Detection

Check for signs of creative fatigue:
- Frequency > 3 on any ad set
- CTR declining week-over-week for 2+ weeks
- CPM rising with stable targeting
- Negative comments increasing
- Same creative running > 30 days without refresh

### Step 7 — Output Report

```markdown
# Creative Audit — {Brand}
## Overall Creative Score: {score}/10

### Strongest Creatives
1. {ad name} — Why it works: ...

### Weakest Creatives
1. {ad name} — Issues: ...

### Creative Gaps
- Missing formats: {e.g., no UGC video, no carousel}
- Missing angles: {e.g., no testimonial ads, no comparison ads}

### Recommendations
1. {Priority action with expected impact}
...

### New Creative Briefs
{2-3 creative concepts to test next}
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-creative-{brand}-{date}.md`

## Agent Role

- **Dreami**: Primary owner. Evaluates all creative elements, writes copy recommendations, generates new creative concepts, ensures brand voice alignment. Dreami should load the brand DNA.json before any creative assessment.

## Creative Generation

If new creatives are needed, Dreami can use:
- `ad-composer` skill for image generation (NanoBanana, Recraft, Flux)
- `nanobanana-gen.sh` for quick image generation
- Brand DNA for voice and visual guidelines

## Example

```
Audit all active Meta ad creatives for jade-oracle.
Check brand voice alignment with spiritual/QMDJ positioning.
Identify creative fatigue and recommend 3 new concepts.
```
