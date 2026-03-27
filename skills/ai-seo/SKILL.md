---
name: ai-seo
description: "When the user wants to optimize content for AI search engines, get cited by LLMs, or appear in AI-generated answers. Also use when the user mentions 'AI SEO,' 'AEO,' 'GEO,' 'LLMO,' 'answer engine optimization,' 'generative engine optimization,' 'LLM optimization,' 'AI Overviews,' 'optimize for ChatGPT,' 'optimize for Perplexity,' 'AI citations,' 'AI visibility,' 'zero-click search,' 'how do I show up in AI answers,' 'LLM mentions,' or 'optimize for Claude/Gemini.'"
agents:
  - scout
  - dreami
---

# AI SEO -- Get Cited by AI Search Engines

Optimize content for AI search engines (ChatGPT, Perplexity, Claude, Gemini, Google AI Overviews) so GAIA brands get cited as sources in AI-generated answers. Traditional SEO gets you ranked. AI SEO gets you **cited**.

## GAIA Brand Context

Before any AI SEO work, load the brand's DNA:
- `~/.openclaw/brands/{brand}/DNA.json` -- always load first
- Run `brand-voice-check.sh` before publishing any optimized content

| Vertical | Brands | High-Value AI Queries |
|----------|--------|----------------------|
| F&B / Vegan | pinxin-vegan, wholey-wonder, gaia-eats | "best vegan food KL," "plant-based meal delivery Malaysia" |
| Weight Management | mirra | "healthy meal subscription Malaysia," "weight management bento KL" |
| Wellness / Supplements | dr-stan, rasaya, gaia-supplements, serein | "best wellness supplements Malaysia," "natural health remedies" |
| Spiritual / Oracle | jade-oracle | "oracle card reading online," "spiritual guidance AI" |
| Education | gaia-learn | "AI learning platform," "wellness education online" |
| E-commerce | iris, gaia-print | "custom wellness products," "health-focused e-commerce" |

MIRRA = bento-style weight management meal subscription (NOT skincare, NOT the-mirra.com).

> Load `references/platform-source-selection.md` for how each AI platform selects sources, critical stats, content types that get cited most, and AI bot access requirements.

## AI Visibility Audit

### Step 1: Check AI Answers for Key Queries

Test 10-20 queries across platforms:

| Query | Google AIO | ChatGPT | Perplexity | Brand Cited? | Competitors Cited? |
|-------|:----------:|:-------:|:----------:|:------------:|:------------------:|
| [query] | Y/N | Y/N | Y/N | Y/N | [who] |

### Step 2: Content Extractability Check

For each priority page, verify: clear first-paragraph definition, self-contained answer blocks, statistics with sources, comparison tables, FAQ section, schema markup, expert attribution, freshness (<6 months), query-matching headings, AI bots allowed in robots.txt.

### Step 3: AI Bot Access Check

Verify robots.txt allows GPTBot, ChatGPT-User, PerplexityBot, ClaudeBot, anthropic-ai, Google-Extended, Bingbot.

## Three Pillars of AI SEO

> Load `references/three-pillars.md` for detailed pillar implementations, Princeton GEO research data, schema markup tables, and GAIA-specific guidelines.

1. **Structure** -- Make content extractable. Lead with direct answers, 40-60 word passages, query-matching headings.
2. **Authority** -- Make content citable. Cite sources (+40%), add statistics (+37%), expert quotations (+30%). Never keyword stuff (-10%).
3. **Presence** -- Be where AI looks. Google Business Profile, YouTube, Reddit, review sites. Third-party citations > own site.

## Monitoring AI Visibility

| Metric | How to Check |
|--------|-------------|
| AI Overview presence | Manual check or Semrush/Ahrefs |
| Brand citation rate | Otterly AI, Peec AI, ZipTie |
| Share of AI voice | Compare citations vs competitors |
| Citation sentiment | How AI describes the brand |
| Source attribution | Which pages get cited |

**DIY Monthly Check**: Pick top 20 queries, run through ChatGPT/Perplexity/Google, record citations, track month-over-month, feed into `seed-store.sh`.

> Load `references/vertical-playbooks.md` for brand-specific playbooks (Jade Oracle, Wellness, F&B, E-commerce) and hallucination handling.

## Workflow

1. **Audit** -- Run AI visibility audit for the brand's top queries
2. **Prioritize** -- Rank pages by citation opportunity
3. **Optimize** -- Apply three pillars: Structure, Authority, Presence
4. **Schema** -- Add/fix structured data markup
5. **Monitor** -- Monthly AI visibility check
6. **Compound** -- Feed learnings into `knowledge-compound`

## Common Mistakes

- Ignoring AI search (45% of Google searches show AI Overviews)
- No freshness signals -- undated content loses
- Gating all content -- AI cannot access gated content
- No structured data / blocking AI bots
- Keyword stuffing (actively reduces visibility by 10%)
- Ignoring third-party presence (Google Business Profile, Reddit, review sites)

## Related Skills

- **seo-audit** -- Traditional technical and on-page SEO
- **firecrawl-scrape** -- Scrape competitor pages for structure analysis
- **growth** -- SEO + SMO + CRO growth support
- **content-repurpose** -- Reformat content for multi-platform presence
