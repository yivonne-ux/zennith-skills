## CLI Usage

```bash
# Full pipeline for a product (all 3 modules)
bash scripts/product-studio.sh generate \
  --brand mirra \
  --product "bento-box-a" \
  --ref-image /path/to/photo.jpg

# Pack shots only (Module A)
bash scripts/product-studio.sh packshot \
  --brand pinxin-vegan \
  --product "nasi-lemak-set"

# Pack shots with custom angles
bash scripts/product-studio.sh packshot \
  --brand gaia-eats \
  --product "rendang-paste" \
  --angles "front,hero-45,overhead,closeup"

# Product placement only (Module B)
bash scripts/product-studio.sh placement \
  --brand rasaya \
  --product "turmeric-latte" \
  --scene kitchen

# Product placement with multiple scenes
bash scripts/product-studio.sh placement \
  --brand rasaya \
  --product "turmeric-latte" \
  --scenes "kitchen,morning-routine,heritage-prep"

# Model swap (Module C)
bash scripts/product-studio.sh model-swap \
  --brand wholey-wonder \
  --product "acai-bowl" \
  --demographics diverse

# Model swap with specific demographic
bash scripts/product-studio.sh model-swap \
  --brand mirra \
  --product "bento-box-a" \
  --model "Malay woman 30, hijab, professional, warm smile"

# Outfit swap (keep same model, change clothes)
bash scripts/product-studio.sh outfit-swap \
  --brand gaia-print \
  --product "eco-tee-v1" \
  --face-refs "/path/to/locked-face-01.png,/path/to/locked-face-02.png" \
  --outfits "casual-streetwear,office-smart,weekend-outdoor"

# Batch all products for a brand (full pipeline)
bash scripts/product-studio.sh batch --brand mirra

# Batch pack shots only for a brand
bash scripts/product-studio.sh batch --brand mirra --module packshot

# Campaign-specific generation
bash scripts/product-studio.sh generate \
  --brand mirra \
  --product "bento-box-a" \
  --campaign cny-2026 \
  --funnel-stage TOFU

# Dry run (show what would be generated, no API calls)
bash scripts/product-studio.sh generate \
  --brand mirra \
  --product "bento-box-a" \
  --dry-run
```

### CLI Flags Reference

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--brand` | Yes | -- | Brand slug (e.g., mirra, pinxin-vegan) |
| `--product` | Yes* | -- | Product slug (* not needed for batch) |
| `--ref-image` | No | -- | Path to real product photo (comma-separated for multiple) |
| `--module` | No | all | `packshot`, `placement`, `model-swap`, or `all` |
| `--angles` | No | type default | Comma-separated angle list |
| `--scenes` | No | brand default | Comma-separated scene list |
| `--demographics` | No | brand default | `diverse` or specific model description |
| `--model` | No | -- | Specific model description for model-swap |
| `--face-refs` | No | -- | Comma-separated locked face ref paths |
| `--outfits` | No | -- | Comma-separated outfit descriptions for outfit-swap |
| `--campaign` | No | -- | Campaign slug for campaign-specific overrides |
| `--funnel-stage` | No | -- | TOFU / MOFU / BOFU |
| `--size` | No | 2K | Image size: 1K, 2K, 4K |
| `--ratio` | No | 1:1 | Aspect ratio |
| `--all-products` | No | false | Process all products from DNA.json |
| `--dry-run` | No | false | Show plan without generating |
| `--output-dir` | No | canonical | Override output directory |

