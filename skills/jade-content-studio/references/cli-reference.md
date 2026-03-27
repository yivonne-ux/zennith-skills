## 13. CLI Usage

```bash
# === IG CONTENT ===

# Generate Jade IG content for a specific day/pillar
bash scripts/jade-content-studio.sh ig-post \
  --day monday --pillar educational

# Generate a specific scene
bash scripts/jade-content-studio.sh ig-post \
  --scene "Farmers market, white wrap blouse, jeans, holding wildflowers, laughing"

# Generate weekly content batch (7 posts, one per day)
bash scripts/jade-content-studio.sh weekly --brand jade-oracle

# === ADS ===

# Generate ad creative with specific hook
bash scripts/jade-content-studio.sh ad \
  --hook "Your tarot reader can't do math" \
  --platform tiktok

# Generate ad for specific funnel stage
bash scripts/jade-content-studio.sh ad \
  --stage mofu --platform meta

# === QUALITY GATES ===

# Run quality gate on generated image
bash scripts/jade-content-studio.sh quality-gate \
  --image /path/to/image.png

# Face lock check (compare against refs)
bash scripts/jade-content-studio.sh face-check \
  --image /path/to/new.png \
  --refs ~/.openclaw/workspace/data/characters/jade-oracle/jade/face-refs/

# === CHARACTER GENERATION ===

# Body pairing generation
bash scripts/jade-content-studio.sh body-pair \
  --wardrobe "burgundy wrap dress" \
  --setting "candlelit reading room" \
  --vibe spiritual

# Generate full funnel content batch
bash scripts/jade-content-studio.sh funnel \
  --stage tofu --count 5

# === VIDEO ===

# Full video pipeline (script → voice → talking head → B-roll → edit)
bash scripts/jade-content-studio.sh video \
  --topic "birth year 1988 reading" \
  --platform tiktok

# Generate voice audio from script
bash scripts/jade-content-studio.sh voice \
  --script output/scripts/hook-001.txt

# Batch video production
bash scripts/jade-content-studio.sh batch \
  --topics topics.txt --count 5

# === UTILITIES ===

# Check current face lock status
bash scripts/jade-content-studio.sh status

# View production learnings
bash scripts/jade-content-studio.sh learnings

# Run competitor intelligence scan
bash scripts/jade-content-studio.sh intel
```

### NanoBanana Command (Direct)

For manual generation bypassing the studio script:

```bash
bash ~/.openclaw/skills/nanobanana/scripts/nanobanana-gen.sh generate \
  --brand jade-oracle \
  --use-case character \
  --prompt "$PROMPT" \
  --ref-image "$FACE_REF1,$FACE_REF2,$FACE_REF3,$FACE_REF1,$FACE_REF2,$BODY_REF" \
  --model pro \
  --ratio 4:5 \
  --size 2K
```

Flags:
- `--brand jade-oracle` — required
- `--use-case character` — MANDATORY (skips brand injection)
- `--model pro` — better face consistency for character work (use `flash` for full-body)
- `--ratio 4:5` — Instagram feed standard
- `--size 2K` — good quality without excessive file size
- `--ref-image` — comma-separated, face refs FIRST, body ref LAST

### Batch Generation Pattern

```bash
# Launch all pairs in parallel (rate limit handled internally — 6s between calls, 15 slots max)
for i in 1 2 3 4 5 6 7 8; do
  nanobanana-gen.sh generate \
    --brand jade-oracle \
    --use-case character \
    --prompt "<prompt_$i>" \
    --ref-image "<face_$i>,<body_$i>" \
    --model pro \
    --size 2K \
    --ratio 4:5 &
done
wait
echo "All pairs complete"
```

