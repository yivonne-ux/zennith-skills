# ref-picker — Visual Reference Image Picker

## What
Unified catalog + picker for all reference images across GAIA OS. Solves the "every time I need a ref I have to search manually" problem.

## Commands
```bash
ref-picker.sh catalog [--force]           # Scan & index all 485+ images
ref-picker.sh browse --brand mirra        # List refs for a brand
ref-picker.sh browse --type character     # List character refs
ref-picker.sh browse --tag locked         # List locked characters
ref-picker.sh pick --brand X --use-case X # Auto-suggest best 3 refs
ref-picker.sh suggest --brand X --use-case X  # Full NanoBanana command with refs
ref-picker.sh gallery [--brand X]         # HTML gallery at localhost:3848
```

## How It Works
1. `catalog` scans 6 image sources: brand references, brand assets, character vault, generated images, creative studio, Pinterest downloads
2. Builds scored index at `workspace/data/ref-catalog.jsonl`
3. `pick` auto-scores refs by: brand match (100), source quality (curated > generated), use-case match, tag relevance, locked character bonus
4. `suggest` outputs a ready-to-paste NanoBanana command with auto-picked refs

## Integration with NanoBanana
NanoBanana now has `--auto-ref` flag. For ad use cases (comparison, lifestyle, product, hero, recipe, social), refs are auto-picked even without the flag.

```bash
# Old way (manual ref search):
nanobanana-gen.sh generate --brand mirra --use-case comparison --prompt "..." --ref-image "/some/path/i/had/to/find/manually.jpg"

# New way (auto-pick):
nanobanana-gen.sh generate --brand mirra --use-case comparison --prompt "..."
# ^ refs auto-selected from catalog!

# Or explicit:
nanobanana-gen.sh generate --brand mirra --use-case comparison --prompt "..." --auto-ref
```

## Gallery
Open `file:///~/.openclaw/workspace/apps/ref-gallery/index.html` in browser. Filter by brand, type, agent, source. Click images to select, copy paths for --ref-image.

## Owner
Iris (visual decisions) + Taoz (infrastructure)
