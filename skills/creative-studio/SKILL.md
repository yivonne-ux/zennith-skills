# creative-studio — GAIA Creative Studio

Control room for character and asset creation workflows.
Studio orchestrates: refs in (Library) → generation engine (ComfyUI/NanoBanana) → outputs stored (Registry) → review → approval.

## Architecture

```
Studio = control room (orchestrator, state machine)
ComfyUI = generation engine (external, API or manual)
Library = truth layer (ref-library + visual-registry)
Taxonomy = classification (creative-taxonomy)
Video pipeline = downstream consumer of approved masters
```

## MANDATORY RULE: ALL CHARACTER GENERATION GOES THROUGH STUDIO.SH

**NEVER call nanobanana-gen.sh directly for characters.**
Always use `studio.sh generate` — it enforces ref-image after face lock, tracks state, and auto-stores outputs.

## Commands

```bash
# Launch a new character master workflow
studio.sh launch --brand <brand> --character <name> [--engine nanobanana]

# Generate via NanoBanana (default — quick single images)
studio.sh generate --run <run-id> --prompt "..." --ratio 3:4 --shot-type portrait_front

# Generate via ComfyUI Cloud (multi-angle, consistency, advanced pipelines)
studio.sh generate --run <run-id> --engine comfyui --workflow <api-format.json> --shot-type portrait_front

# Store outputs/references manually
studio.sh store --run <run-id> --stage <0|1|2|3|4> --files <file1,...> --shot-type <type>

# Review a run against proof-of-done criteria
studio.sh review --run <run-id>

# Show status of all runs
studio.sh status [--brand <brand>]

# Approve outputs and register in Library
studio.sh approve --run <run-id> --outputs <output-ids>

# Export approved master pack for downstream (video pipeline, ads)
studio.sh export --run <run-id> --format pack
```

## Character Generation Workflow (MANDATORY)

1. `studio.sh launch --brand X --character Y` — creates run with empty reference stack
2. Generate FIRST image (no ref) — get face right first
3. **Jenn approves face** — this is the gate
4. `studio.sh store --run X --stage 0 --files locked-face.png --shot-type face_ref` — lock the face
5. ALL subsequent gens use `studio.sh generate` which AUTOMATICALLY passes locked face as `--ref-image`
6. Generate different poses/scenes — ONE CHANGE per iteration
7. `studio.sh review` to check proof-of-done
8. `studio.sh export` when complete

**The generate command REFUSES to run without a locked face reference after Stage 1 has approved outputs.**

## Photorealistic Rule

Read `/Users/jennwoeiloh/.openclaw/skills/character-design/scripts/photorealistic-gen.md` BEFORE generating any character. Key rules:
- Prompt like a PHOTOGRAPHER, not an artist
- "photorealistic photograph, real skin with pores, NOT illustration, NOT cartoon, NOT CG"
- Simple clothing (linen, silk), natural light, real locations
- NO fantasy elements (crystal crowns, jade robes, cosmic aura)

## ComfyUI Cloud Pipeline

```bash
# Upload reference image to ComfyUI Cloud
comfyui-api upload --file <local-image.png>

# Generate customized workflow from template
comfyui-workflow-gen --template flux-kontext-character-v1 \
  --prompt "..." --ref-image <cloud-filename.png> \
  --seed 42 --denoise 0.70 --prefix "luna-pose" \
  --output /tmp/workflow.json

# Submit and wait for completion
comfyui-api submit --workflow /tmp/workflow.json --poll --timeout 600

# Download outputs
comfyui-api download --job <job-id> --output-dir ./outputs/
```

**Templates:**
- `flux-kontext-character-v1` — Flux Kontext face-locked gen (API format, **recommended**)
- `flux-ipadapter-character-v1` — XLabs IP-Adapter (UI format, local only)

**Luna's uploaded ref:** `8b12b13c8e285c5b0c154424d45b571b54c0c6586b72299aa2d6424c664cf3cb.png`

## Workflow: comfyui-character-master-v1

See `workflows/comfyui-character-master-v1.json` for machine-readable spec.

### Stages
1. **Angle/coverage generation** — portrait front, 3/4, full-body, side, angle sheet
2. **Consistency expansion** — same character across multiple scenes/framings
3. **Realism refinement** — skin enhancement, relighting, upscaling
4. **Approval pack assembly** — hero portrait, full body, 3/4, multi-angle sheet, consistency set, master image

### Proof of Done
All must exist before a run is "complete":
- 1+ approved hero portrait
- 1+ approved full-body image
- 1+ angle/coverage set
- 1+ realism-refined master image
- All outputs labeled with metadata
- Pack exportable to video pipeline

## Integration Points

| System | How Studio Uses It |
|--------|--------------------|
| **ref-library** | `query` to load reference stack before launch; `add` to store approved outputs as refs |
| **visual-registry** | `register` approved characters with multi-angle data |
| **creative-taxonomy** | `classify-asset.sh` to tag outputs with structure/format/purpose |
| **character-design** | Prompt templates, learnings.jsonl, correction loop |
| **brand-studio** | `audit.sh` for visual QA scoring on outputs |
| **video pipeline** | Exports approved packs as input for UGC/ad video generation |

## Storage

```
~/.openclaw/output/creative-studio/{brand}/{run-id}/
  run.json              # Run metadata + state
  refs/                 # Symlinks to ref-library sources
  stage-1/              # Angle/coverage outputs
  stage-2/              # Consistency outputs
  stage-3/              # Realism-refined outputs
  stage-4/              # Approval pack (finals)
  review.json           # Review results
```

## Owner
Iris (Art Director) — workflow decisions
Taoz (CTO) — infrastructure
Dreami — creative briefs feeding into runs
