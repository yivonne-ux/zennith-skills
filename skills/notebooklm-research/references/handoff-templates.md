# Export & Handoff to Claude

## Export Formats from NotebookLM

| Format | Best For | How to Export |
|--------|----------|---------------|
| **Study Guide** | Structured topic overview -> content outlines | Click "Study Guide" in notebook tools |
| **FAQ** | Question-answer pairs -> brand FAQ, chatbot training, Shopee Q&A | Click "FAQ" in notebook tools |
| **Timeline** | Chronological events -> brand story content, history posts | Click "Timeline" in notebook tools |
| **Briefing Doc** | Executive summary -> strategy briefs, campaign planning | Click "Briefing Doc" in notebook tools |
| **Table of Contents** | Topic structure -> blog series planning, content calendar | Click "Table of Contents" in notebook tools |
| **Raw Q&A** | Specific answers -> targeted content pieces | Copy-paste from chat interface |
| **Audio Overview Transcript** | Conversational insights -> social content, video scripts | Transcribe via WhisperX |

## Full Handoff Template

When passing NotebookLM research to Claude for content creation, use this template. Save to `~/.openclaw/workspace/data/research/{brand}/handoff-{topic}-{date}.md`:

```markdown
## Research Handoff: [Topic]

**Brand:** [brand name from: mirra, pinxin-vegan, rasaya, dr-stan, wholey-wonder, gaia-eats, serein, gaia-supplements, iris, jade-oracle, gaia-print, gaia-learn, gaia-os, gaia-recipes]
**Research Source:** NotebookLM notebook "[notebook name]"
**Sources Count:** [N sources uploaded]
**Date:** [YYYY-MM-DD]
**Research Type:** [competitor/trend/product/audience/seo/recipe/health-claims/campaign/positioning]

### Key Findings
1. [Finding 1 — the most important discovery]
2. [Finding 2 — supporting data point]
3. [Finding 3 — surprising or contrarian insight]
4. [Finding 4+ as needed]

### Insights & Content Angles
- [Insight that could become a carousel post]
- [Contrarian take worth exploring in a blog post]
- [Data point that makes a compelling ad hook]
- [Trend signal that suggests content timing]

### Evidence & Claims (with source attribution)
- "[Specific claim]" — Source: [source name, page/timestamp]
- "[Statistic or data point]" — Source: [source name]
(IMPORTANT: All health/nutrition claims MUST have source attribution for compliance)

### Competitive Intelligence
- [What competitors are doing]
- [Gap in market we can exploit]
- [Positioning opportunity]

### Audience Insights
- [Pain point discovered]
- [Language/phrasing the audience uses]
- [Unmet need or desire]

### Content Request
**Create:** [content type — e.g., IG carousel, blog post, ad copy, EDM, product description]
**Platform:** [IG / FB / TikTok / Shopee / Blog / EDM / WhatsApp / Shopify]
**Brand Voice:** Load from ~/.openclaw/brands/{brand}/DNA.json
**Target Persona:** [persona name or description]
**Language:** [EN / BM / ZH / mixed]
**Tone:** [educational / playful / authoritative / warm / urgent]
**CTA:** [desired call to action]
**Deadline:** [date]

### Raw Notes (optional)
[Paste NotebookLM study guide, FAQ, or raw Q&A output here for Claude to reference]
```

## Quick Handoff (for simple content needs):

```markdown
## Quick Handoff: [Topic]
Brand: [brand] | Date: [date] | Notebook: [name]

**TL;DR:** [One sentence summary of research findings]

**Key stat:** [Most compelling data point]
**Key insight:** [Most interesting angle]
**Key gap:** [Biggest opportunity found]

**Make this:** [content type] for [platform] in [language]
```
