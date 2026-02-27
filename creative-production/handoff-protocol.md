# GAIA Creative Handoff Protocol v1

## Pipeline Stages

```
BRIEF -> ART DIRECTION -> GENERATION -> POST-PROD -> REVIEW -> PLACEMENT
```

### Stage 1: BRIEF (Owner: Dreami)
- Input: Campaign brief, brand slug, funnel stage, output type
- Process: Dreami writes creative brief with copy direction, visual direction, hook angles
- Output: `brief.json` saved to `brands/{brand}/campaigns/{campaign}/briefs/`
- Handoff: Dispatches to Iris with brief.json path

### Stage 2: ART DIRECTION (Owner: Iris)
- Input: Brief from Dreami
- Process: Iris creates art direction spec -- mood board refs, color palette, composition rules, typography, style seed selection
- Output: `art-direction.json` saved to `brands/{brand}/campaigns/{campaign}/art-direction/`
- Handoff: Dispatches to generation tools (NanoBanana for images, video-gen for video)

### Stage 3: GENERATION (Owner: Iris + Tools)
- Input: Art direction spec + style seeds
- Process: NanoBanana generates images, video-gen creates videos
- Output: Generated assets saved to `brands/{brand}/campaigns/{campaign}/generated/`
- Handoff: Dispatches to VideoForge for post-production (if video) or directly to Review (if image)

### Stage 4: POST-PRODUCTION (Owner: VideoForge/Taoz)
- Input: Raw generated video + output type
- Process: VideoForge applies production chain (captions, branding, music, effects, export)
- Output: Final assets in `brands/{brand}/campaigns/{campaign}/final/`
- Handoff: Dispatches to creative-review

### Stage 5: REVIEW (Owner: Iris + Dreami + Hermes)
- Input: Final assets
- Process: Multi-agent review
  - Iris: Visual quality, brand compliance, art direction adherence
  - Dreami: Copy accuracy, brand voice, hook effectiveness
  - Hermes: CRO check, CTA placement, conversion potential
- Output: Review verdict (approve/revise/reject) saved to `brands/{brand}/campaigns/{campaign}/reviews/`
- Handoff: If approved -> Hermes for placement. If revise -> back to Stage 2 or 3.

### Stage 6: PLACEMENT (Owner: Hermes)
- Input: Approved assets + campaign metadata
- Process: Hermes schedules placement across channels (Meta, TikTok, etc.)
- Output: Placement record in campaign history

## Handoff Message Format

Each handoff posts to `creative.jsonl` room with:
```json
{
  "ts": 1709000000000,
  "agent": "dreami",
  "type": "handoff",
  "stage": "BRIEF",
  "next_stage": "ART_DIRECTION",
  "next_agent": "iris",
  "brand": "pinxin-vegan",
  "campaign": "cny-2026",
  "funnel_stage": "TOFU",
  "output_type": "hero",
  "artifact_path": "brands/pinxin-vegan/campaigns/cny-2026/briefs/brief-001.json",
  "handoff_id": "ho-1709000000000"
}
```

## Retry Policy
- Max 2 revision cycles before escalating to human
- Each revision must reference the review feedback
- Escalation posts to approvals.jsonl for human decision
