---
name: visual-registry
agents:
  - iris
  - dreami
---

# visual-registry — Visual Asset Registry

## What
Multi-angle asset registration for SKUs, characters, models, scenes, props.
Assembly engine combines assets for consistent generation: SKU x Model x Scene → max 14 refs.

## Commands
```bash
visual-registry.sh scan                    # Auto-discover and register from existing files
visual-registry.sh register --name X --type sku --brand mirra --angles "front:a.png,top:b.png"
visual-registry.sh add-angle --id va-X --label "3/4-right" --image /path/to/image.png
visual-registry.sh gen-angles --id va-X --angles "front,3/4-left,side,back"  # Generate via NanoBanana
visual-registry.sh list [--brand X] [--type X]
visual-registry.sh info --id va-X
visual-registry.sh assemble --sku va-X --model va-Y --scene va-Z [--command]
```

## Asset Types
- **sku**: Products with multi-angle photos (front, top, side, detail)
- **character**: Agent avatars with locked refs, turnaround sheets, expressions
- **model**: Human/AI models for lifestyle shots
- **scene**: Backgrounds, settings, composition templates
- **prop**: Props, attire, accessories

## Assembly Engine
Combine any assets: `assemble --sku va-X --model va-Y --scene va-Z`
- Scores and prioritizes refs (primary images first, then best angles)
- Respects NanoBanana's 14-ref max
- Use `--command` to get ready-to-paste NanoBanana CLI command

## Owner
Iris (visual curation) + Taoz (infrastructure)
