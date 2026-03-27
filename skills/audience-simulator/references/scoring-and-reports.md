# Scoring Rubrics, Report Formats & Response Frameworks

## Scoring Dimensions

Each persona scores on 4 dimensions (1-10 scale):

| Dimension | What It Measures | Scoring Guide |
|-----------|-----------------|---------------|
| **Attention** | Would this stop my scroll? | 1-3: scrolls past. 4-6: glances but moves on. 7-8: stops, reads. 9-10: stops, screenshots. |
| **Relevance** | Is this for me? | 1-3: wrong audience entirely. 4-6: adjacent but not quite. 7-8: speaks to my situation. 9-10: feels personally written for me. |
| **Emotion** | How does this make me feel? | 1-3: nothing / negative. 4-6: mild interest. 7-8: genuine desire or curiosity. 9-10: "I need this NOW." |
| **Action** | Would I do something? | 1-3: no action. 4-6: might save for later. 7-8: would click / inquire. 9-10: would buy / sign up immediately. |

**Overall score** = average of 4 dimensions across all personas.

## Brand Coverage & Priority

| # | Brand Slug | Display Name | Personas | Priority | Notes |
|---|-----------|-------------|----------|----------|-------|
| 1 | `pinxin-vegan` | Pinxin Vegan | 4 | **P0 -- Core F&B** | Plant-based Malaysian food |
| 2 | `wholey-wonder` | Wholey Wonder | 2 | **P0 -- Core F&B** | Smoothie bowls & superfoods |
| 3 | `mirra` | MIRRA | 4 | **P0 -- Core F&B** | Bento-style health food (NOT skincare) |
| 4 | `rasaya` | Rasaya | 2 | **P0 -- Core F&B** | Traditional wellness drinks |
| 5 | `gaia-eats` | Gaia Eats | 2 | **P0 -- Core F&B** | Multi-restaurant delivery |
| 6 | `dr-stan` | Dr. Stan | 2 | **P0 -- Core F&B** | Evidence-based supplements |
| 7 | `serein` | Serein | 2 | **P0 -- Core F&B** | Self-care rituals & wellness |
| 8 | `jade-oracle` | Jade Oracle | 4 | **P1 -- Active** | Tarot, QMDJ, metaphysics |
| 9 | `iris` | Iris | 2 | **P1 -- Active** | Visual QA & brand identity |
| 10 | `gaia-os` | Gaia OS | 2 | **P2 -- Platform** | AI operating system |
| 11 | `gaia-learn` | Gaia Learn | 2 | **P2 -- Platform** | Educational content |
| 12 | `gaia-print` | Gaia Print | 2 | **P2 -- Platform** | Print-on-demand merch |
| 13 | `gaia-recipes` | Gaia Recipes | 2 | **P2 -- Platform** | Recipe content platform |
| 14 | `gaia-supplements` | Gaia Supplements | 2 | **P2 -- Platform** | Health supplements line |

**Priority tiers:**
- **P0 -- Core F&B:** These brands run paid ads and publish content daily. Every piece of ad copy MUST be audience-simulated before spend.
- **P1 -- Active:** Regular content, simulate before campaigns.
- **P2 -- Platform:** Simulate on launch campaigns and major content pushes.

## Markdown Report Format (default)

```markdown
# Audience Simulation Report
**Brand:** mirra | **Content type:** ad copy | **Date:** 2026-03-23

## Content Tested
> "Your weight management meals, delivered fresh daily. Order now."

## Persona Reactions

| Persona | Attention | Relevance | Emotion | Action | Overall | Key Feedback |
|---------|-----------|-----------|---------|--------|---------|--------------|
| Sarah, 32 | 7 | 9 | 6 | 7 | 7.3 | "Relevant but the CTA is generic -- I see 'order now' 50 times a day" |
| Aishah, 28 | 8 | 8 | 7 | 8 | 7.8 | "Would click, but where's the halal cert? I need to see JAKIM logo" |
| Michelle, 38 | 6 | 7 | 5 | 5 | 5.8 | "How much per meal? Is there a family plan? I'm feeding 4 people lah" |
| Priya, 26 | 5 | 6 | 4 | 4 | 4.8 | "So boring. Show me the food. Show me someone eating it. This is just words" |

## Aggregate Score: 6.4 / 10 -- REFINE

## Segment Breakdown
- **LOVE IT (>= 8):** None
- **NEUTRAL (5-7):** Sarah, Aishah, Michelle
- **TURNED OFF (< 5):** Priya

## Dimension Breakdown
- Attention: 6.5 avg (weakest for Priya -- no visual hook)
- Relevance: 7.5 avg (strongest dimension -- product-market fit is there)
- Emotion: 5.5 avg (too rational, no desire trigger)
- Action: 6.0 avg (CTA is generic, no urgency or specificity)

## Improvement Suggestions
1. **Add specific numbers** for Sarah and Aishah -- they track macros.
2. **Show halal cert** or mention JAKIM for Aishah -- non-negotiable.
3. **Add family pricing** for Michelle -- "From RM12/meal, family plans available."
4. **Make it visual** for Priya -- text-only won't work for her feed.
5. **Replace generic CTA** -- Try "Try your first week at RM10/meal" or "See this week's menu."

## Suggested Revision
> "380 cal bentos that actually taste like real food. JAKIM halal certified. KL delivery, fresh daily. Your lunch upgrade starts at RM12/meal. [See this week's menu]"

## Revised Score Estimate: 7.6 / 10 -- PASS
```

## JSON Report Format (with --json flag)

```json
{
  "brand": "mirra",
  "content_type": "ad-copy",
  "date": "2026-03-23",
  "content_tested": "Your weight management meals, delivered fresh daily. Order now.",
  "personas": [
    {
      "name": "Sarah",
      "age": 32,
      "scores": { "attention": 7, "relevance": 9, "emotion": 6, "action": 7 },
      "overall": 7.3,
      "segment": "neutral",
      "feedback": "Relevant but the CTA is generic",
      "suggestions": ["Add calorie count", "Replace generic CTA"]
    }
  ],
  "aggregate": {
    "overall": 6.4,
    "verdict": "REFINE",
    "by_dimension": { "attention": 6.5, "relevance": 7.5, "emotion": 5.5, "action": 6.0 }
  },
  "suggestions": ["Add specific numbers", "Show halal cert", "Add family pricing"],
  "revised_content": "380 cal bentos that actually taste like real food..."
}
```

## Quality Gate

| Score | Verdict | Action |
|-------|---------|--------|
| >= 7.0 | **PASS** | Content approved for publishing/ad spend |
| 5.0 - 6.9 | **REFINE** | Apply suggestions, re-test before publishing |
| < 5.0 | **FAIL** | Fundamental mismatch -- go back to brief/strategy |

No content should go to paid ad spend without scoring >= 7.0 across brand personas.

## CLI Flags Reference

| Flag | Description | Default |
|------|-------------|---------|
| `--brand` | Brand name (must match DNA.json) | Required |
| `--content` | Content string to test | Required (or --input) |
| `--type` | Content type: `ad-copy`, `caption`, `image-concept`, `product-desc`, `email-subject`, `campaign` | `ad-copy` |
| `--personas` | Comma-separated persona names to test against (lowercase, hyphenated) | All brand personas |
| `--input` | Path to file with multiple variants (one per line or JSON array) | -- |
| `--brief` | Path to campaign brief markdown file | -- |
| `--output` | Custom output path | `~/.openclaw/workspace/data/audience-sim/{brand}/` |
| `--verbose` | Show full persona reasoning, not just scores | `false` |
| `--json` | Output as JSON instead of markdown | `false` |

## CLI Examples (All Core F&B Brands)

```bash
# Pinxin Vegan
bash scripts/audience-simulator.sh test --brand pinxin-vegan --content "Vegan nasi lemak that'll make you forget it's plant-based"
bash scripts/audience-simulator.sh compare --brand pinxin-vegan --a "Plant-based rendang, zero compromise" --b "Your mak's rendang recipe, but vegan"

# Wholey Wonder
bash scripts/audience-simulator.sh test --brand wholey-wonder --content "28g protein per bowl. No powder taste. Just real fruit and gains."

# Gaia Eats
bash scripts/audience-simulator.sh test --brand gaia-eats --content "Team lunch sorted — everyone picks their own, one delivery fee"

# Dr. Stan
bash scripts/audience-simulator.sh test --brand dr-stan --content "Every ingredient, every dosage, every study — right on the label"

# Rasaya
bash scripts/audience-simulator.sh test --brand rasaya --content "Traditional jamu, modern standards. Same recipe your nenek trusted."

# Serein
bash scripts/audience-simulator.sh test --brand serein --content "10 minutes. 3 products. Calm that actually works."

# MIRRA
bash scripts/audience-simulator.sh test --brand mirra --content "Your weight management meals, delivered fresh daily. Order now."
bash scripts/audience-simulator.sh compare --brand mirra --a "Try our calorie-controlled bento" --b "Weight management has never tasted this good"
```

## Integration Points

### Feeds INTO (this skill's output is used by):
- **auto-research** -- as the eval/scoring function in optimization loops
- **fast-iterate** -- persona scores drive iteration priority
- **content-supply-chain** -- pre-flight check before publishing

### Feeds FROM (this skill consumes output from):
- **campaign-planner** -- campaign briefs to pre-test
- **meta-ads-creative** / **ad-composer** -- ad copy and image concepts to score
- **brand-prompt-library** -- image concepts and visual direction to validate

### Auto-Research Integration

```
auto-research generates variant
  --> audience-simulator scores it against brand personas
  --> score >= 7? keep variant : discard
  --> persona feedback feeds back into next variant generation
```

## Malaysian Market Calibration

All persona behaviors are calibrated for Malaysia:

- **Halal sensitivity** -- JAKIM certification specifically (not generic "halal")
- **Price anchoring in RM** -- "RM12/meal" resonates, "$3/meal" does not
- **Local purchase channels** -- Shopee, GrabFood, WhatsApp ordering
- **Manglish / code-switching** -- "Sedap gila" > "Absolutely delicious" for younger personas
- **WhatsApp as engagement channel** -- CTAs should point to WhatsApp, not "DM us"
- **Cultural calendar** -- Hari Raya, CNY, Deepavali shifts in persona behavior
- **Local reference points** -- Mamak, pasar malam, kopitiam, Jaya Grocer, TTDI market
- **Social proof dynamics** -- WhatsApp group recommendations and Xiaohongshu reviews over brand claims

## Output & Storage

- Reports saved to: `~/.openclaw/workspace/data/audience-sim/{brand}/`
- Filename format: `{brand}-{content-type}-{YYYY-MM-DD-HHmm}.md` (or `.json`)
- Historical reports enable trend analysis: "Is our MIRRA copy getting better over time?"
