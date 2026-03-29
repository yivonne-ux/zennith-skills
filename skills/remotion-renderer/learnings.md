# Learnings — remotion-renderer

## 2026-03-28 — PATTERN
**What happened:** Ported 15 Remotion components from Tricia's video-compiler
**What worked:** Direct copy + brandConfig.ts abstraction layer for multi-brand colors/fonts
**What failed:** kinetic_text block type needs flat props (kinetic_lines, kinetic_animation, kinetic_bg_color) not nested object
**Pattern:** UGCComposition props are FLAT per block — all kinetic/endcard/split fields are top-level block properties, not nested objects. Check schema before building props JSON.

## 2026-03-28 — CONFIRMATION
**What happened:** 5/5 render tests pass (HelloWorld, kinetic, endcard, multi-block, video-forge delegation)
**What worked:** Remotion v4.0.435 + React 18 works on macOS, renders 300 frames in ~8s
**What failed:** N/A
**Pattern:** Remotion renders are fast ($0) and deterministic — use for ALL templated content (kinetic text, oracle cards, brand reveals, captioned reels)
