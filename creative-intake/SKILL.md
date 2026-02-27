# creative-intake

**agents**: [zenni, iris, dreami, artemis]
**version**: 1.0
**created**: 2026-02-27

## Description

Reference-to-Production Machine. Any input (link, image, video, text brief) gets auto-classified, analyzed, and routed to the right production workflow — or triggers the creation of a new output type.

This is the single entry point for all creative inputs into the GAIA content factory. Whether Jenn sends a Pinterest link via WhatsApp, Artemis discovers a competitor ad, or a studio upload comes in via API — it all flows through here.

## Entry Points

1. **WhatsApp** — Human sends link/image/text to Zenni, Zenni routes to agent, agent posts to `intake.jsonl`
2. **Agent dispatch** — Any agent discovering creative reference material posts to `intake.jsonl`
3. **Studio upload** — API posts directly to `intake.jsonl`

All three converge on the same room: `~/.openclaw/workspace/rooms/intake.jsonl`

## Input Types Handled

### URL (type: link)
- Classified by `classify-link.sh` (zero-cost, keyword-based)
- visual-reference (Pinterest, Behance, Dribbble) -> Iris reverse-prompts via Gemini Vision
- competitor ad -> Artemis for competitive analysis
- tutorial/article -> Artemis + Dreami for technique extraction
- product -> Iris for product photography workflow

### Image (type: image)
- Iris reverse-prompts via Gemini Vision API (gemini-2.5-flash)
- Extracts: style, mood, colors[], composition, subject, suggested_output_type, confidence
- Creates style seed in content-seed-bank
- Checks if analysis suggests a new output type not in output-types.json
- If new type detected -> calls register-output-type.sh
- If existing type matched -> dispatches to production with style seed

### Video (type: video)
- FFmpeg extracts 5 evenly-spaced keyframes
- Frames sent to Gemini Vision for analysis
- Extracts: technique, hooks, effects, editing_style, pacing
- Matches against existing output types
- If new technique -> calls register-output-type.sh
- If existing -> logs technique as learning in content-seed-bank

### Text Brief (type: text)
- Dispatched to Dreami as creative brief
- Dreami parses intent, creates structured brief
- Routes to appropriate production pipeline

## Output

Each intake event produces:
- A classification result (type, category, confidence)
- A routing decision (which agent, which workflow)
- Either routes to an existing production workflow OR calls `register-output-type.sh` to create a new one
- Logs to `intake.jsonl` room and `creative.jsonl` room
- Creates seeds in content-seed-bank when visual/video analysis yields reusable patterns

## Room

`~/.openclaw/workspace/rooms/intake.jsonl`

## Scripts

| Script | Purpose |
|--------|---------|
| `intake-processor.sh` | Main processor. Reads JSON from stdin, classifies, analyzes, routes. |
| `intake-classify.sh` | Lightweight type classifier. Zero API cost. |
| `intake-watch.sh` | Room watcher. Tails intake.jsonl, processes new entries. |

## Dependencies

- `~/.openclaw/skills/link-digester/scripts/classify-link.sh` (URL classification)
- `~/.openclaw/skills/workflow-automation/scripts/register-output-type.sh` (new output type registration)
- `~/.openclaw/skills/content-seed-bank/scripts/seed-store.sh` (seed storage)
- `~/.openclaw/skills/mission-control/scripts/dispatch.sh` (inter-agent messaging)
- Gemini API (gemini-2.5-flash) for image/video analysis
- FFmpeg for video frame extraction

## Integration with digest-link.sh

The link-digester's `digest-link.sh` automatically posts to `intake.jsonl` after every link classification. This means any URL processed by the system automatically enters the creative intake pipeline.
