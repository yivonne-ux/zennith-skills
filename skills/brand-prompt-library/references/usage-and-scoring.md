## 5. Usage

```bash
# List all prompts for a brand
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh list --brand mirra

# Get prompts for a specific use case
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh get --brand pinxin-vegan --use-case "hero-shot"

# Random prompt for inspiration
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh random --brand mirra

# Generate image using a library prompt (passes to nanobanana-gen.sh)
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate --brand mirra --prompt-id "MIR-001"

# Search prompts across all brands by keyword
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh search "turmeric"

# Search within a specific brand
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh search "bento" --brand mirra

# Add a new tested prompt to the library
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh add \
  --brand rasaya \
  --prompt "Fresh halia bara drink in clay cup..." \
  --tags "hero,drink,lifestyle" \
  --score 8

# List top-scoring prompts
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh top --limit 10

# Get all prompts tagged for a specific platform
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh list --tag "instagram-story"

# Export prompts for a campaign brief
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh export --brand pinxin-vegan --format json > campaign-prompts.json
```

---

## 6. Prompt Testing & Scoring

### Quality Scoring System

Each prompt in the library has a quality score based on test generations:

| Score | Rating | Status |
|-------|--------|--------|
| 9-10 | **Hero** | Top performer — use for hero/primary images |
| 7-8 | **Reliable** | Consistent quality — standard production use |
| 5-6 | **Flagged** | Needs revision — occasionally produces good results |
| 1-4 | **Retired** | Removed from active library — archived for reference |

### Scoring Criteria

1. **Subject Accuracy** (0-2): Does the generated image match the described subject?
2. **Brand Alignment** (0-2): Do colors, mood, and style match brand DNA?
3. **Technical Quality** (0-2): Resolution, focus, composition, no artifacts?
4. **Mood/Emotion** (0-2): Does the image evoke the intended feeling?
5. **Usability** (0-2): Can it be used immediately for the intended platform?

### Testing Protocol

```bash
# Test a prompt and score it
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh test \
  --prompt-id "PXV-001" \
  --iterations 3

# The script generates 3 images, displays them, and asks for scores.
# Average score is saved. Prompts scoring <7 are flagged for revision.
```

### A/B Testing

For critical hero images, generate two prompt variants and compare:

```bash
# A/B test two prompt variants
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh ab-test \
  --prompt-a "PXV-001" \
  --prompt-b "PXV-002" \
  --brand pinxin-vegan

# Generates both, presents side-by-side, records winner.
```

### Promotion Rules

- New prompts enter at "Untested" status
- After 3+ test generations with avg score >= 7: promoted to "Reliable"
- After 5+ test generations with avg score >= 9: promoted to "Hero"
- Hero prompts are prioritized in `random` and `top` commands
- Prompts scoring < 5 on 3 consecutive tests: auto-retired

---
