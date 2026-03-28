---
name: character-lock
agents:
  - dreami
  - taoz
---

# Character Lock — Zennith OS Identity Enforcement System

## What This Is

Mandatory character identity enforcement for ALL image/video generation. Stores character specs, reference images, environments, props, wardrobe, and voice profiles in ONE canonical location. Every generation tool MUST load the character spec before producing output.

**Problem this solves:** Jade generated as illustration, wrong face, different hair — because scripts don't enforce character specs.

## The Rules

1. **NEVER generate without loading character spec first**
2. **Face refs must be ≥60% of all reference images** (below 60% = face drift)
3. **Hair ALWAYS in ALL CAPS** in prompts (prevents model from ignoring)
4. **Prompt suffix ALWAYS appended** (anti-drift + anti-illustration)
5. **Style-seed + ref-image = FORBIDDEN** (causes chaos)
6. **Signature item MUST be visible** (Jade = pendant, Iris = helmet)
7. **"editorial" is BANNED** for Jade (use "iPhone candid" instead)

## File Structure (Canonical)

```
~/.openclaw/brands/{brand}/characters/{name}/
├── spec.json              # THE source of truth (standardized schema)
├── locked/
│   ├── faces/             # Canonical face references (NEVER delete)
│   │   ├── face-primary.png
│   │   ├── face-angle2.png
│   │   └── face-angle3.png
│   ├── bodies/            # Headless body refs
│   ├── accessories/       # Signature items (pendant, helmet, etc.)
│   └── metadata.json      # Counts, last audit, quality scores
├── environments/          # Approved scene references
│   ├── home-living.png
│   ├── cafe.png
│   └── outdoor-city.png
├── wardrobe/              # Approved outfit references
│   ├── casual-cream.png
│   ├── sage-cardigan.png
│   └── black-silk-cami.png
├── variations/            # Generated variations (not canonical)
└── audit/
    ├── scores.jsonl       # Quality tracking
    └── failures/          # Failed generations + reasons
```

## Usage

```bash
# Load character spec (outputs prompt suffix + ref image paths)
character-lock.sh load --brand jade-oracle --character jade

# Validate a prompt against character rules
character-lock.sh validate --brand jade-oracle --character jade --prompt "..."

# Build reference image array for NanoBanana
character-lock.sh refs --brand jade-oracle --character jade --use-case lifestyle

# Audit a generated image against character spec
character-lock.sh audit --brand jade-oracle --character jade --image output.png

# Initialize new character from template
character-lock.sh init --brand mirra --character mira-girl

# List all locked characters
character-lock.sh list
```

## How Generation Tools Use This

```bash
# BEFORE any NanoBanana call:
SPEC=$(character-lock.sh load --brand jade-oracle --character jade --json)
REFS=$(character-lock.sh refs --brand jade-oracle --character jade --use-case lifestyle)
SUFFIX=$(echo "$SPEC" | jq -r '.rules.prompt_suffix')

# THEN generate:
nanobanana-gen.sh generate --brand jade-oracle \
  --prompt "Jade reading oracle cards in café $SUFFIX" \
  --ref-image "$REFS" \
  --use-case character
```

## Character Specs Available

| Brand | Character | Status | Spec |
|-------|-----------|--------|------|
| jade-oracle | Jade | LOCKED | jade.character.json |
| jade-oracle | Luna | PARTIAL | needs spec.json |
| gaia-os | Iris | LOCKED | needs migration to schema |
| mirra | (brand-only) | N/A | No character needed |
