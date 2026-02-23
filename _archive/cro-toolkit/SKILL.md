---
name: cro-toolkit
description: Conversion Rate Optimization toolkit — A/B test analysis, funnel optimization, landing page scoring
version: 1.0.0
agent: athena
---

# CRO Toolkit

Enables Athena to analyze and optimize conversion rates across GAIA's digital properties.

## Capabilities

### 1. Landing Page Scoring
Score any landing page on CRO best practices (1-10 per dimension):

| Dimension | What to Check |
|-----------|--------------|
| **Clarity** | Is the value prop clear in <5 seconds? Single focus? |
| **Visual hierarchy** | Does the eye flow headline -> image -> CTA? |
| **CTA strength** | Is CTA visible, benefit-driven, high contrast? |
| **Social proof** | Reviews, testimonials, trust badges present? |
| **Mobile UX** | Responsive? Touch-friendly? Fast load? |
| **Copy quality** | Benefit-driven? Scannable? No jargon? |
| **Trust signals** | Guarantees, security badges, return policy? |
| **Page speed** | <3s load time? Optimized images? |
| **Friction** | Minimal form fields? Easy checkout? Guest option? |
| **Urgency** | Scarcity, limited time, countdown (without being manipulative)? |

Overall CRO score = weighted average. Target: >=7.5

### 2. A/B Test Framework
Structure for planning and analyzing A/B tests:

```json
{
  "test_id": "ab-{date}-{short-name}",
  "hypothesis": "Changing {element} from {control} to {variant} will increase {metric} because {reason}",
  "element": "headline|cta|hero_image|layout|price_display|social_proof",
  "control": "Current version description",
  "variant": "New version description",
  "primary_metric": "conversion_rate|ctr|add_to_cart|time_on_page",
  "secondary_metrics": ["bounce_rate", "scroll_depth"],
  "sample_size_needed": "calculated based on baseline and MDE",
  "duration": "min 7 days, 2 full business cycles",
  "status": "planned|running|completed|winner_deployed"
}
```

### 3. Funnel Analysis
Analyze conversion funnels step by step:

**Standard e-commerce funnel:**
1. Landing/Product page visit
2. Add to cart
3. Initiate checkout
4. Complete purchase

**For each step, analyze:**
- Drop-off rate (% who leave)
- Friction points (what might cause abandonment)
- Optimization opportunities (what to test)
- Benchmark vs industry average

### 4. Shopee/Lazada CRO
Platform-specific optimization:
- **Title optimization**: Keyword + benefit + variant (max 120 chars for Shopee, 255 for Lazada)
- **Image optimization**: Main image = product on white, gallery = lifestyle + detail + size reference
- **Price psychology**: Strikethrough pricing, bundle savings display, voucher stacking
- **Review management**: Response templates, review request timing, photo review incentives
- **Listing SEO**: Category-specific keywords, backend search terms, attribute completeness

### 5. Content Performance CRO
Optimize content for conversions (not just engagement):
- Hook -> Value -> CTA framework
- Bio link optimization (link-in-bio structure)
- Caption CTA placement (early vs end vs both)
- Story/Reel swipe-up/link optimization
- Comment-to-DM automation opportunities

### 6. Reporting Format
When producing CRO analysis, always output:

```
CRO ANALYSIS: {page/funnel name}
Brand: {brand}
Date: {date}

SCORES:
  Clarity:        8/10
  Visual hierarchy: 7/10
  CTA strength:   6/10
  ...
  OVERALL:        7.2/10

TOP 3 OPPORTUNITIES:
  1. [Highest impact] {description} -- Expected lift: {X%}
  2. [Medium impact] {description} -- Expected lift: {X%}
  3. [Quick win] {description} -- Expected lift: {X%}

RECOMMENDED A/B TESTS:
  1. {test description + hypothesis}
  2. {test description + hypothesis}

BENCHMARKS:
  Industry avg conversion: {X%}
  Current estimated: {X%}
  Target after optimization: {X%}
```

## Integration
- Read Brand DNA for brand-consistent optimization recommendations
- Store A/B test plans in: `~/.openclaw/workspace/data/ab-tests.jsonl`
- Coordinate with Art Director for visual variant creation
- Coordinate with Apollo for copy variant creation
- Post CRO reports to exec room
- Tag insights in seed bank: `bash seed-store.sh add --type insight --text "CRO finding" --tags "cro,{page-type}"`

## Data Sources
- Google Analytics (when available via API)
- Shopee Seller Centre analytics
- Lazada Seller Centre analytics
- Meta Ads Manager (ad landing page metrics)
- Manual data entry from screenshots/exports
