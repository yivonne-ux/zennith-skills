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

## Anti-Patterns
- ❌ Building without Design DNA (produces generic output)
- ❌ Writing vague briefs ("make it pretty") instead of specific design specs
- ❌ Not studying reference websites before building
- ❌ Generating characters without the Character Design Bible
- ❌ Forgetting to log learnings after each production
- ❌ Skipping multi-agent review
