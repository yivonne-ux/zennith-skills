# Compound Learning & Research Repository

Research compounds over time. Each notebook builds institutional knowledge that makes future research faster and more insightful.

## Knowledge Compounding Loop:

```
Cycle 1: Upload initial sources -> Generate baseline insights
Cycle 2: Add new sources + Cycle 1 findings -> Deeper insights, trend confirmation
Cycle 3: Add performance data from content created -> Learn what research -> content worked
Cycle N: Institutional knowledge builds -> Research-to-content gap shrinks
```

## How to Compound:

1. **Never delete notebooks** — archive old ones, they're historical knowledge
2. **Add content performance data back** — which research-backed content performed well?
3. **Cross-reference notebooks** — upload findings from one notebook as source in another
4. **Quarterly review** — listen to Audio Overviews of combined quarterly research
5. **Store key findings** — always save to `~/.openclaw/workspace/data/research/{brand}/`

## Research Repository Structure:

```
~/.openclaw/workspace/data/research/
├── mirra/
│   ├── handoff-weight-mgmt-trends-2026-01-15.md
│   ├── handoff-competitor-q1-2026-03-01.md
│   └── insights-audio-overview-2026-02-10.md
├── pinxin-vegan/
│   ├── handoff-vegan-market-2026-01-20.md
│   └── handoff-protein-science-2026-02-15.md
├── dr-stan/
│   ├── handoff-supplement-evidence-2026-01-10.md
│   └── handoff-npra-compliance-2026-03-05.md
├── rasaya/
├── wholey-wonder/
├── serein/
├── gaia-eats/
├── gaia-supplements/
├── iris/
├── jade-oracle/
├── gaia-print/
├── gaia-learn/
├── gaia-os/
├── gaia-recipes/
└── _cross-brand/
    ├── market-my-f&b-2026-q1.md
    └── audience-health-consumer-2026.md
```

## Tagging Research for Retrieval:

Every handoff doc should include tags for later search:
```yaml
tags: [mirra, competitor, weight-management, meal-subscription, pricing, q1-2026]
research_type: competitor
confidence: high  # high/medium/low based on source quality
actionable: true  # did this lead to content creation?
content_created: [ig-carousel-2026-01-20, blog-bento-guide]
```

## Research Quality Checklist

Before creating content from research, verify:

- [ ] Sources are from the last 12 months (or noted as historical context)
- [ ] At least one Malaysian/SEA-specific source included
- [ ] Health/nutrition claims have peer-reviewed source attribution
- [ ] Competitor data is current (not from archived/outdated pages)
- [ ] Insights are genuinely novel (not just restating obvious facts)
- [ ] Research covers counter-arguments (not just confirmation bias)
- [ ] Handoff document follows template format
- [ ] Handoff is saved to research repo with proper naming
- [ ] Tags are added for future retrieval
- [ ] Content request in handoff specifies brand, platform, language, persona
