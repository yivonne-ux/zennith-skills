---
name: ads-landing
description: Landing page quality assessment for paid advertising campaigns. Evaluate message match, load speed, conversion elements, mobile UX.
agents:
  - dreami
  - hermes
---

# Ads Landing — Landing Page Quality Assessment

Evaluates landing pages used in paid advertising campaigns. Checks message match with ads, conversion rate optimization elements, page speed, mobile UX, and trust signals.

## When to Use

- Ad CTR is good but conversion rate is low
- Launching new landing pages for ad campaigns
- Quality Score "Landing Page Experience" is below average
- A/B testing landing page variations
- New brand store setup (Shopify, etc.)

## Procedure

### Step 1 — Page Inventory

List all landing pages used in active ad campaigns:

| URL | Platform | Campaign | Monthly Traffic | Conv Rate | Notes |
|-----|----------|----------|----------------|-----------|-------|
| ... | Meta | ... | ... | ... | ... |

### Step 2 — Message Match Audit

For each ad-to-landing-page combination:

| Check | Score (1-10) | Notes |
|-------|-------------|-------|
| Headline matches ad promise | | Visitor sees what they clicked for? |
| Visual continuity | | Same imagery/style as ad? |
| Offer matches | | Same price/discount/freebie as ad? |
| CTA alignment | | Action on page matches ad CTA? |
| Audience match | | Page speaks to the targeted audience? |

### Step 3 — Conversion Elements

| Element | Present? | Quality (1-10) |
|---------|----------|----------------|
| Clear headline above fold | | |
| Subheadline with value prop | | |
| Hero image/video | | |
| Primary CTA button (contrasting color) | | |
| Social proof (testimonials, reviews, numbers) | | |
| Trust signals (badges, guarantees, SSL) | | |
| Benefit bullets (not feature bullets) | | |
| Urgency/scarcity element | | |
| FAQ section | | |
| Minimal navigation (no distracting links) | | |
| Secondary CTA for non-converters | | |
| Exit intent capture | | |

### Step 4 — Technical Assessment

| Check | Status | Target |
|-------|--------|--------|
| Page load time | | < 3 seconds |
| Mobile responsive | | Tested on iPhone/Android |
| Core Web Vitals (LCP, FID, CLS) | | All green |
| SSL certificate | | Active |
| Tracking pixels firing | | Meta Pixel, Google Tag, etc. |
| Form functionality | | Submits correctly, confirmation shown |
| Cross-browser | | Chrome, Safari, Firefox at minimum |
| Image optimization | | WebP, compressed, lazy loaded |

### Step 5 — Mobile UX Deep Dive

Over 70% of ad traffic is mobile. Check:

- Thumb-friendly CTA buttons (min 44x44px)
- No horizontal scrolling
- Text readable without zooming (16px+ body)
- Forms use appropriate input types (tel, email)
- Sticky CTA on scroll
- Fast tap response (no 300ms delay)
- Images don't push content below fold

### Step 6 — Copywriting Assessment

| Element | Score (1-10) | Notes |
|---------|-------------|-------|
| Clarity | | Can a visitor understand the offer in 5 seconds? |
| Specificity | | Concrete numbers, not vague claims? |
| Emotional appeal | | Connects with pain points/desires? |
| Readability | | Short paragraphs, bullets, scannable? |
| Brand voice | | Matches DNA.json tone? |

### Step 7 — Output Report

```markdown
# Landing Page Audit — {Brand}
## Overall Score: {score}/10

### Pages Reviewed
| URL | Score | Top Issue |
...

### Critical Fixes (Immediate)
...

### Optimization Recommendations
...

### A/B Test Suggestions
1. Test: {element} | Hypothesis: {expected improvement}
...
```

Save to: `~/.openclaw/workspace/rooms/logs/ads-landing-{brand}-{date}.md`

## Scoring (5 categories)

| Category | Weight |
|----------|--------|
| Message Match | 25% |
| Conversion Elements | 25% |
| Technical Performance | 20% |
| Mobile UX | 15% |
| Copy Quality | 15% |

## Agent Roles

- **Dreami**: Evaluates copy quality, visual design, brand voice alignment, message match, conversion element effectiveness
- **Scout**: Technical assessment — page speed, mobile responsiveness, tracking pixel verification, Core Web Vitals

## GAIA Brand Context

Key landing pages by brand:
- **jade-oracle**: Shopify store, $1 intro reading funnel
- **pinxin-vegan / gaia-eats**: Food delivery ordering pages
- **dr-stan / rasaya**: Supplement product pages

Always load `~/.openclaw/brands/{brand}/DNA.json` to verify brand voice on page.

## Example

```
Audit the jade-oracle $1 intro reading landing page.
Ads on Meta are getting 3% CTR but only 1.2% conversion rate.
Check message match, mobile UX, and trust signals.
Suggest 3 A/B tests to improve conversion.
```
