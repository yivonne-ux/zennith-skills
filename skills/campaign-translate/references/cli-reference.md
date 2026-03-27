## 6. CLI Usage

```bash
# ─── SINGLE ASSET TRANSLATION ───

# Translate a campaign brief document
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh translate \
  --brand mirra \
  --input campaign-en.md \
  --to bm,zh

# Translate inline ad copy text
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh copy \
  --brand pinxin-vegan \
  --input "Healthy meals delivered to your door" \
  --to bm,zh

# Translate with specific tone override
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh copy \
  --brand mirra \
  --input "Try our new bento!" \
  --to bm \
  --tone casual

# Translate with Manglish register
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh copy \
  --brand pinxin-vegan \
  --input "Our rendang bowl is back!" \
  --to bm \
  --tone manglish

# ─── VIDEO SUBTITLES ───

# Translate SRT file (auto-adjusts timing)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh subtitle \
  --brand gaia-eats \
  --input video.srt \
  --to bm,zh

# Translate ASS/SSA file (preserves styling, adjusts fonts for CJK)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh subtitle \
  --brand mirra \
  --input video.ass \
  --to zh \
  --font "Noto Sans SC"

# ─── EMAIL / EDM ───

# Translate email template
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh email \
  --brand mirra \
  --input weekly-menu-edm.html \
  --to bm,zh

# Subject line only (for A/B testing)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh subject \
  --brand mirra \
  --input "This week's menu is fire 🔥" \
  --to bm,zh \
  --variants 3

# ─── BATCH OPERATIONS ───

# Batch translate all pending content for a brand
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh batch \
  --brand mirra \
  --since 7d

# Batch translate across multiple brands
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh batch \
  --brands mirra,pinxin-vegan,gaia-eats \
  --since 3d

# ─── UTILITY ───

# Detect language of content
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh detect \
  --input "Makanan sihat sampai ke pintu anda"

# Validate existing translations against brand voice
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh validate \
  --brand mirra \
  --input translations/

# Generate CTA dictionary for a brand
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh cta-dict \
  --brand mirra

# Dry run (preview what would be translated)
bash ~/.openclaw/skills/campaign-translate/scripts/campaign-translate.sh translate \
  --brand mirra \
  --input campaign-en.md \
  --to bm,zh \
  --dry-run
```

### CLI Flags Reference

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--brand` | Yes | — | Brand name (loads DNA.json) |
| `--input` | Yes | — | Input file path or inline text (quoted) |
| `--to` | Yes | — | Target languages, comma-separated (en, bm, zh) |
| `--from` | No | auto-detect | Source language override |
| `--tone` | No | from DNA.json | Tone override: formal, casual, manglish |
| `--platform` | No | general | Target platform: ig, fb, tiktok, shopee, edm, whatsapp |
| `--variants` | No | 1 | Number of translation variants per language |
| `--since` | No | — | For batch: time window (1d, 7d, 30d) |
| `--dry-run` | No | false | Preview only, no output files |
| `--font` | No | brand default | CJK font override for subtitle files |
| `--output` | No | same dir as input | Output directory |

