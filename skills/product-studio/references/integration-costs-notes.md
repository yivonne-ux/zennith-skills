## Integration

### Feeds Into
- **`content-supply-chain`** (`~/.openclaw/skills/content-supply-chain/`) -- product images flow into the weekly content production pipeline
- **`ad-composer`** (`~/.openclaw/skills/ad-composer/`) -- pack shots and lifestyle scenes become inputs for ad creative generation
- **`creative-studio`** (`~/.openclaw/skills/creative-studio/`) -- model shots feed into campaign visual workflows
- **`brand-studio`** (`~/.openclaw/skills/brand-studio/`) -- generated images can be audited and looped through the brand-studio quality gate

### References (Dependencies)
- **`nanobanana`** (`~/.openclaw/skills/nanobanana/`) -- image generation engine (NanoBanana Flash + Pro via Gemini API). ALWAYS use `nanobanana-gen.sh`, NEVER call Gemini API directly.
- **`style-control`** (`~/.openclaw/skills/style-control/`) -- brand style enforcement, style seed management
- **`character-lock`** (`~/.openclaw/skills/character-lock/`) -- face lock and body consistency protocol for Module C model shots
- **`visual-registry`** (`~/.openclaw/skills/visual-registry/`) -- asset tracking and registration for all generated images
- **Brand DNA files** (`~/.openclaw/brands/{brand}/DNA.json`) -- source of truth for all visual parameters, colors, avoid-lists, and audience data

### Agent Responsibilities
- **Dreami** -- writes creative briefs, selects scenes and model descriptions, art-directs the pipeline
- **Taoz** -- builds and maintains the scripts, handles technical pipeline issues (via Claude Code CLI)
- **Iris** -- runs visual QA audits on generated images, flags quality issues

---

## Cost Estimate

| Operation | Approx Cost | Images |
|-----------|-------------|--------|
| Single pack shot (1 angle) | ~$0.02 | 1 |
| Full pack shot set (8 images) | ~$0.16 | 8 |
| Single placement scene | ~$0.02-0.04 | 1 |
| Full placement set (5 scenes) | ~$0.10-0.20 | 5 |
| Single model shot | ~$0.02-0.04 | 1 |
| Full model set (4 poses) | ~$0.08-0.16 | 4 |
| Quality audit per image | ~$0.01 | -- |
| **Full pipeline (1 product)** | **~$0.50-0.80** | **15-20** |
| **Full pipeline with retries** | **~$0.80-1.50** | **15-20** |
| **Batch (all products, 1 brand)** | **~$3-10** | varies |

All images include SynthID watermarks (Gemini standard). Use NanoBanana Flash for high-volume iterations and NanoBanana Pro for final production assets.

---

## Notes

- **MIRRA is a weight management meal subscription** (bento format) -- NOT cosmetics, NOT skincare, NOT the-mirra.com. Always generate food photography for calorie-controlled meals and weekly meal plans, never beauty/skincare products.
- **gaia-os and iris are non-product brands** -- they are system/agent brands. No physical product photography. Use concept art and digital identity workflows instead.
- **Real product photos as reference are ALWAYS preferred** over text-only prompts. Check `~/.openclaw/workspace/data/images/{brand}/` for existing product photography before generating from scratch.
- **One change at a time** -- when iterating on a generation, change ONE element (angle, lighting, background, model, outfit). Changing multiple elements causes drift.
- **Label text limitation** -- NanoBanana can produce readable text but frequently warps it. For e-commerce images where label text must be pixel-perfect, consider post-production text overlay or using real product photo crops.
- **Face lock is approximate** -- NanoBanana uses reference images as "inspiration" and drifts 20-40%. For critical face consistency across a campaign, use Kling 3.0 elements or LoRA training as fallback.
- **Malaysian context matters** -- scenes should feel authentically Malaysian (kopitiam, mamak, home kitchen, tropical outdoor) unless the brand specifically targets international audiences.
- **Always run `brand-voice-check.sh`** before publishing any image that includes text overlays.
- **Git commit after every significant batch** -- product-studio outputs are tracked in the visual-registry and should be committed.
