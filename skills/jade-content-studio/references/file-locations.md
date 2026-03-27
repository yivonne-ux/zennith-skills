## 14. File Locations

```
# Character data (canonical)
~/.openclaw/workspace/data/characters/jade-oracle/
  ├── jade/
  │   ├── face-refs/                    # Locked face references
  │   │   ├── jade-d2-anchor.png
  │   │   ├── jade-d3-anchor.png
  │   │   ├── jade-ig2-market.png       # Confirmed IG: farmers market
  │   │   ├── jade-ig3-restaurant.png   # Confirmed IG: restaurant
  │   │   └── jade-ig4-journaling.png   # Confirmed IG: journaling
  │   ├── body-ref.jpg                  # Body type reference
  │   ├── ig-spec.json                  # IG generation spec (v1)
  │   └── jade-spec-v2.json            # Full character spec (v2, CANONICAL)
  ├── luna-v3-locked/                   # Secondary character (Luna)
  │   ├── CHARACTER-SPEC.md
  │   ├── luna-face-lock.png
  │   ├── luna-casual-cafe.png
  │   └── luna-polkadot-seated.png
  ├── CHARACTER-VISUAL-DNA.md           # Visual DNA analysis (Iris)
  ├── BRAND-NARRATIVE.md
  ├── CHARACTER-BACKSTORIES.md
  └── character.json

# Brand DNA
~/.openclaw/brands/jade-oracle/DNA.json

# Generated content
~/.openclaw/workspace/data/images/jade-oracle/

# Video output
~/.openclaw/workspace/data/videos/jade-oracle/
  ├── scripts/
  ├── voice/
  ├── video/
  ├── broll/
  └── final/

# This skill
~/.openclaw/skills/jade-content-studio/
  ├── SKILL.md (this file)
  └── scripts/
      └── jade-content-studio.sh

# Related skills (sources for this consolidated skill)
~/.openclaw/skills/character-design/        # Base character creation workflow
~/.openclaw/skills/character-lock/          # Face lock protocol
~/.openclaw/skills/character-body-pairing/  # Vibe matching system
~/.openclaw/skills/ig-character-gen/        # IG content generation
~/.openclaw/skills/ai-influencer/           # Full video pipeline
```
