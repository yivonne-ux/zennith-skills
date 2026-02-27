# Creative Production Skill (Compounding)

## Purpose
End-to-end creative production workflow — from brief to published assets.
This skill captures the PROCESS of how we create, so every project gets better.

## The Production Cycle

### Phase 1: Brief & References
1. Collect graphic/style references → `brands/{brand}/graphic-refs/`
2. Collect character references → `brands/{brand}/character-refs/`
3. Study award-winning websites for UI/UX patterns
4. Write Design DNA → `brands/{brand}/DESIGN-DNA.md`
5. Write Story/Copy → `brands/{brand}/STORY.md`
6. Create Asset Inventory → what we HAVE vs what we NEED

### Phase 2: Asset Generation (use Creative Studio)
7. Generate characters using Character Builder (character-design skill)
8. Generate scenes/environments using infinity canvas
9. Generate textures/backgrounds
10. Each generation → save to library → log in learnings.jsonl

### Phase 3: Assembly (Taoz builds via Claude Code)
11. Write detailed build brief with all design specs
12. Include: typography, colors, layout rules, copy, sections
13. Taoz builds using Claude Code CLI (Opus 4.6)
14. Run regression testing after every change

### Phase 4: Review (Multi-agent)
15. Iris reviews UI/UX (creative-review skill)
16. Hermes reviews CRO
17. Dreami reviews brand DNA alignment
18. Feed reviews back → iterate

### Phase 5: Feedback & Compound
19. User reviews output → 👍/👎 + feedback
20. Log everything to learnings.jsonl
21. Nightly compound: extract patterns → update skills
22. Git commit all updates

## Key Learnings (2026-02-25)

### Character Generation
- **gemini-2.5-flash-image** works well for character portraits
- Direct description prompts with specific details (attire, jewelry, background) produce good results
- Parallel generation (multiple curl requests) is fast — generate 2-3 characters simultaneously
- Save to library immediately — don't just return base64
- All 5 new GAIA agents generated in first attempt with 8+ quality

### Landing Page Production
- V1 was generic (dark SaaS look) — ALWAYS start with Design DNA
- V2 improved but still missing personality — need REAL story/copy
- V3 with story + award-winning patterns + proper typography = quality jump
- Cormorant Garamond + Space Mono = excellent editorial serif + mono pairing
- Coordinates ticker (fromroswell.com pattern) adds sophistication
- [CLASSIFIED] placeholders for missing assets = intentional mystery, not broken
- Film grain + crosshairs + data labels = editorial brutalist feel

### Process
- Brief size matters — 7KB brief with specific CSS examples > vague instructions
- Claude Code (Opus 4.6) via CLI produces better results than subagent spawning
- Always pipe brief via stdin: `cat brief.md | claude --print --dangerously-skip-permissions`
- Regression testing catches build failures before manual review
- Copy character images to public/ directory for proper Vite serving

## Phase 5: Agent Collaboration — Creative Handoff Protocol

The handoff protocol defines the multi-agent pipeline for creative production.
Full spec: `handoff-protocol.md` (same directory as this SKILL.md).

### Pipeline

```
BRIEF (Dreami) -> ART DIRECTION (Iris) -> GENERATION (Iris + Tools) -> POST-PROD (Taoz) -> REVIEW (Iris + Dreami + Hermes) -> PLACEMENT (Hermes)
```

### Handoff Dispatch CLI

Script: `scripts/handoff-dispatch.sh`

**Start a new pipeline:**
```bash
bash handoff-dispatch.sh start \
  --brand pinxin-vegan \
  --campaign cny-2026 \
  --funnel-stage TOFU \
  --output-type hero \
  --prompt "CNY celebration hero image with festive red and gold"
```

**Check status:**
```bash
bash handoff-dispatch.sh status --handoff-id ho-1709000000
```

**List all handoffs:**
```bash
bash handoff-dispatch.sh list --brand pinxin-vegan --status active
```

**Advance to next stage** (called by agents after completing their stage):
```bash
bash handoff-dispatch.sh advance \
  --handoff-id ho-1709000000 \
  --artifact-path brands/pinxin-vegan/campaigns/cny-2026/art-direction/art-dir-ho-1709000000.json
```

**Send back for revision** (called during REVIEW if changes needed):
```bash
bash handoff-dispatch.sh revise \
  --handoff-id ho-1709000000 \
  --target-stage ART_DIRECTION \
  --feedback "Colors too muted, need more vibrant reds for CNY"
```

### Key Rules
- Max 2 revision cycles before escalating to human (posts to approvals.jsonl)
- Each revision must reference the review feedback
- All handoff messages go to `creative.jsonl` room
- Handoff manifests stored in `brands/{brand}/campaigns/{campaign}/handoff-{id}.json`
- Campaign working dirs auto-created: briefs/, art-direction/, generated/, final/, reviews/

### Generation Metadata
- All generated assets now log full metadata: model, prompt, brand, campaign, funnel_stage, style_seed_id, output_type, references, generated_by, handoff_id
- NanoBanana registers images in the image seed bank with campaign and funnel context
- Creative Studio logs the same fields via generation_params in library.db

## Anti-Patterns
- Building without Design DNA (produces generic output)
- Writing vague briefs ("make it pretty") instead of specific design specs
- Not studying reference websites before building
- Generating characters without the Character Design Bible
- Forgetting to log learnings after each production
- Skipping multi-agent review
- Skipping the handoff protocol for production content (ad-hoc is fine for experiments)
