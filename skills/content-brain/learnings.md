# Learnings — content-brain

## 2026-03-28 — CONFIRMATION
**What happened:** Content brain orchestrator tested in 3 modes: produce (kinetic 8s), produce (full dry-run 9s), plan, brain
**What worked:** All 12 steps execute, character-lock auto-loads in Step 5, Remotion fallback renders when no video clips
**What failed:** CRE brief adapter (cre-to-brief.sh) doesn't accept --product/--output flags yet — falls back to minimal brief
**Pattern:** Pipeline should gracefully degrade: if a tool doesn't exist or fails, skip with warning and continue. Never block the full pipeline on one step.
