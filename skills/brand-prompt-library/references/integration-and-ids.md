## 7. Integration

### Used By
- **`product-studio`** — pulls product photography prompts for e-commerce
- **`creative-studio`** — sources lifestyle and campaign prompts
- **`content-supply-chain`** — automated content generation pipeline
- **`ad-composer`** — ad creative prompts by funnel stage

### Reads From
- **`~/.openclaw/brands/{brand}/DNA.json`** — brand colors, mood, style, photography direction
- **`~/.openclaw/brands/{brand}/campaigns/{campaign}.json`** — campaign-specific overrides
- **NanoBanana SKILL.md** — generation best practices, API parameters, reference image techniques

### Stores Data
- **Prompt definitions**: `~/.openclaw/skills/brand-prompt-library/prompts/{brand}/`
- **Test results**: `~/.openclaw/skills/brand-prompt-library/prompts/{brand}/test-results/`
- **Score index**: `~/.openclaw/skills/brand-prompt-library/prompts/score-index.json`

### NanoBanana Generation Pipeline

When using `generate` command, the library:

1. Loads the prompt by ID from the library
2. Loads brand DNA from `~/.openclaw/brands/{brand}/DNA.json`
3. Injects brand color anchors if not already present
4. Passes to `nanobanana-gen.sh` with appropriate flags:
   - `--ratio` from the prompt's `[RATIO]` tag
   - `--style-seed` if prompt is `[SEED-COMPATIBLE]` and a campaign seed is active
   - `--ref-image` if prompt has `[REF]` tags and reference images are available
   - `--size` defaults to 2K for social, 4K for hero
5. Auto-registers the output in the image seed bank

### Example Integration Flow

```bash
# Creative Director (Dreami) generating a week of Mirra content:

# Monday: hero shot for Instagram feed
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate \
  --brand mirra --prompt-id "MIR-001" --ratio 1:1 --size 4K

# Tuesday: lifestyle for Stories
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate \
  --brand mirra --prompt-id "MIR-005" --ratio 9:16 --size 2K

# Wednesday: comparison post
bash ~/.openclaw/skills/brand-prompt-library/scripts/brand-prompt-library.sh generate \
  --brand mirra --prompt-id "MIR-009" --ratio 1:1 --size 4K

# All images auto-registered in seed bank with full metadata.
```

---

## 8. Prompt ID Convention

All prompts follow this ID format:

```
{BRAND_CODE}-{NUMBER}
```

| Brand | Code | Range |
|-------|------|-------|
| Pinxin Vegan | PXV | 001-020 |
| Wholey Wonder | WW | 001-015 |
| MIRRA | MIR | 001-015 |
| Rasaya | RAS | 001-012 |
| Dr. Stan | DST | 001-012 |
| Serein | SER | 001-012 |
| GAIA Eats | GE | 001-010 |
| GAIA Recipes | GR | 001-010 |
| GAIA Supplements | GS | 001-010 |
| GAIA Print | GP | 001-010 |
| Jade Oracle | JO | 001-008 |
| Iris | IRS | 001-008 |
| GAIA Learn | GL | 001-002 |
| GAIA OS | GO | 001-002 |
| Hari Raya | HR | 001-010 |
| Chinese New Year | CNY | 001-010 |
| Deepavali | DV | 001-008 |
| Merdeka | MY | 001-008 |
| Promotional | PROMO | 001-010 |

**Total: 200+ production-ready prompts.**

