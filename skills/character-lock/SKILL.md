---
name: character-lock
description: Face lock and body consistency rules for NanoBanana character generation. Learned from Luna Solaris v3.
agents: [dreami, taoz]
version: 1.0.0
---

# Character Lock — Face & Body Consistency for NanoBanana

## What This Does
Ensures generated character images maintain face identity and body type across scenes, poses, outfits, and lighting conditions. Encodes hard-won rules from Luna Solaris v3 generation — every rule here was learned from a failure.

---

## Rules

### 1. Face Lock (CRITICAL)

**Reference weight ratio** — Face refs must be AT LEAST 60% of total refs. If you have 3 face refs and want to add body refs, duplicate face refs to maintain dominance.

| Setup | Face % | Result |
|-------|--------|--------|
| 5 face + 2 body | 71% | GOOD — face holds |
| 3 face + 3 body | 50% | RISKY — face may drift |
| 3 face + 6 body | 33% | BAD — face WILL drift |

**Ref image ordering matters** — Put face refs in slots 1-3 (highest priority in Gemini). Body refs go last.

**Prompt must explicitly label refs** — Tell the model which refs are face and which are body:
```
Reference images 1, 2, 3 show the FACE — keep this EXACT face.
Reference images 4, 5 show BODY TYPE ONLY.
```

**Face lock prompt formula** — Always include in every prompt:
```
EXACT SAME WOMAN from reference images 1-N — do NOT generate a different woman.
Her face, bone structure, eyes, nose, jawline, smile, and hair MUST be identical
to references 1-N.
```

**Model selection for face lock**:
- **Flash** (`gemini-3.1-flash-image-preview`) — holds face lock better in full-body scenes. Use for action shots, full-body, multi-element compositions.
- **Pro** (`gemini-3-pro-image-preview`) — more beautiful output but drifts more. Use for close-up portraits and headshots ONLY when face lock is critical.

### 2. Body Type Control

**Direct measurements DO NOT work** — "34-24-35" means nothing to the model. It ignores numeric measurements.

**Editorial fashion language WORKS** — Use fashion/editorial vocabulary:
- "decolletage", "voluptuous hourglass", "silk following every curve"
- "slim petite frame (115 lbs), naturally full 33D bust, proportionally prominent on her small body"
- Describe how fabric INTERACTS with the body, not the body dimensions

**External body refs** — Generate body type separately using Flux or Z-Image Turbo, then feed as ref into NanoBanana. This anchors the body shape visually instead of relying on text description alone.

### 3. QA Scoring

**Use `--mode character` for character images** — Brand audit (`--mode brand`) checks logo, food, typography and will always fail on character shots.

Character audit checks:
- `photorealism` — overall realism score
- `face_quality` — face detail and consistency
- `hand_quality` — hand/finger correctness
- `artifacts` — visual glitches, seams, distortion
- `mood` — emotional tone match
- `avoid_violations` — content policy compliance
- `face_consistency` — match to reference face
- `body_consistency` — match to reference body type

**Plasticky skin detection** — Standard photorealism score misses it. Manually review for:
- Pore visibility
- Skin texture variation (not uniform)
- Subsurface scattering (light through thin skin areas)
- Specular highlights (natural, not uniform sheen)
- Hair strand quality (individual strands, not helmet)

---

## Anti-Patterns (Things That Break Face Lock)

1. **Too many body refs diluting face signal** — body refs push face refs below 60% threshold
2. **Body refs from different ethnicities/ages** — confuses the model's understanding of the character
3. **Not duplicating primary face ref for weight** — single face ref gets overridden by multiple body/scene refs
4. **Using Pro for full-body scenes** — Pro drifts more than Flash in complex compositions
5. **Relying on prompt alone without ref images** — text description is never enough for face consistency
6. **Changing too many elements at once** — change pose OR outfit OR lighting, never all three

---

## Scripts

```
# Placeholder — scripts to be built

# generate-locked.sh — Generate with face lock protocol
#   Input: character name, brand, scene prompt
#   Auto-loads face refs from locked-face dir
#   Auto-duplicates face refs to maintain 60%+ ratio
#   Auto-prepends face lock prompt formula
~/.openclaw/skills/character-lock/scripts/generate-locked.sh

# audit-character.sh — Run character-mode QA audit
#   Input: image path, character ref dir
#   Checks face_consistency, body_consistency, photorealism
#   Flags plasticky skin with micro-detail review
~/.openclaw/skills/character-lock/scripts/audit-character.sh

# lock-face.sh — Save validated face refs to locked dir
#   Input: image paths to lock
#   Copies to workspace/data/characters/{brand}/{character}-locked-face-*.png
#   Validates face quality before locking
~/.openclaw/skills/character-lock/scripts/lock-face.sh
```

---

## Usage Examples

### Generate a face-locked full-body scene
```bash
# 1. Ensure face refs exist
ls workspace/data/characters/jade-oracle/luna-locked-face-*.png

# 2. Build ref array: 5 face + 2 body = 71% face
REFS=(
  "workspace/data/characters/jade-oracle/luna-locked-face-01.png"  # slot 1
  "workspace/data/characters/jade-oracle/luna-locked-face-02.png"  # slot 2
  "workspace/data/characters/jade-oracle/luna-locked-face-03.png"  # slot 3
  "workspace/data/characters/jade-oracle/luna-locked-face-01.png"  # slot 4 (duplicate for weight)
  "workspace/data/characters/jade-oracle/luna-locked-face-02.png"  # slot 5 (duplicate for weight)
  "workspace/data/images/jade-oracle/ref-body-hourglass-01.png"    # slot 6 (body)
  "workspace/data/images/jade-oracle/ref-body-hourglass-02.png"    # slot 7 (body)
)

# 3. Prompt with face lock formula + explicit ref labeling
PROMPT="Reference images 1-5 show the FACE — keep this EXACT face.
Reference images 6-7 show BODY TYPE ONLY.
EXACT SAME WOMAN from reference images 1-5 — do NOT generate a different woman.
Her face, bone structure, eyes, nose, jawline, smile, and hair MUST be identical to references 1-5.

Luna Solaris standing in a jade-tiled temple, wearing a flowing emerald silk dress,
decolletage visible, slim petite frame with naturally full bust proportionally prominent
on her small body. Soft golden hour light from behind. Editorial fashion photography."

# 4. Use Flash for full-body (better face lock)
MODEL="gemini-3.1-flash-image-preview"

# 5. Run QA in character mode
visual-audit.py --mode character --refs workspace/data/characters/jade-oracle/ output.png
```

### Close-up portrait (Pro is OK here)
```bash
# Fewer refs needed — 3 face, 0 body = 100% face
REFS=(
  "workspace/data/characters/jade-oracle/luna-locked-face-01.png"
  "workspace/data/characters/jade-oracle/luna-locked-face-02.png"
  "workspace/data/characters/jade-oracle/luna-locked-face-03.png"
)
MODEL="gemini-3-pro-image-preview"  # Pro OK for close-ups — better beauty
```

---

## File Conventions

```
# Locked face refs (validated, canonical)
workspace/data/characters/{brand}/{character}-locked-face-*.png

# Body type refs (generated via Flux/Z-Image Turbo)
workspace/data/images/{brand}/ref-body-*.png

# Generated character images
workspace/data/images/{brand}/YYYYMMDD_HHMMSS_character_*.png

# QA audit results
/tmp/char-audit-*.json
```

---

## Dependencies

- **NanoBanana skill** (`~/.openclaw/skills/nanobanana/`) — image generation API
- **visual-audit.py** (`~/.openclaw/skills/nanobanana/scripts/visual-audit.py`) — QA scoring
- **Gemini API key** — loaded from `~/.openclaw/secrets/gemini.env`
- **Flux / Z-Image Turbo** — for generating body type reference images
- **NanoBanana models**: `gemini-3.1-flash-image-preview` (face-critical), `gemini-3-pro-image-preview` (beauty)
