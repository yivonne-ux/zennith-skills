---
name: Multi-Agent Audit — MiroFish investigation + practical implementation
description: MiroFish is a social media simulation engine (text-only, no vision) — wrong tool for image audit. The RIGHT approach is multi-perspective Claude prompts with different expert personas. 50 lines of Python, not simulation infrastructure.
type: feedback
---

## MULTI-AGENT AUDIT — PRACTICAL IMPLEMENTATION

### MiroFish Investigation (March 30, 2026)
MiroFish (github.com/666ghj/MiroFish) is a swarm intelligence simulation engine. It creates AI agents on simulated Twitter/Reddit. It CANNOT evaluate images — it's text-only social media simulation. Wrong tool for creative reference auditing.

### What Actually Works: Multi-Perspective Claude Prompts
For multi-agent creative audit, use multiple Claude/GPT-4V calls with different expert personas:

```python
AUDIT_PERSONAS = [
    {"name": "Design Critic", "focus": "layout, composition, visual weight, negative space, grid"},
    {"name": "Brand Auditor", "focus": "palette match, voice match, dietary compliance, off-brand elements"},
    {"name": "Typography Expert", "focus": "hierarchy, size, kerning, font choice, readability, rendering quality"},
    {"name": "Food Photography Judge", "focus": "food quality, sacred preservation, distortion, blending, editorial grade"},
    {"name": "Trend Analyst", "focus": "viral potential, shareability, DM test, trending format match, freshness"},
]
```

Each persona evaluates the same image → returns structured JSON (score + reasoning) → aggregator combines into weighted quality score.

**Why:** User wants "mirofish to audit scrapping reference or the output brief." The concept is right (multiple expert perspectives). The implementation is simpler than MiroFish infrastructure.

**How to apply:** Before using any scraped reference or presenting any output, run it through 3-5 expert persona prompts. Each scores independently. Disagreements flag for human review. Consensus = high confidence.
