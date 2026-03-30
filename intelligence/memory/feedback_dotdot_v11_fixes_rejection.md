---
name: DotDot v11-fixes REJECTED — wrong art style, poor composition vs v10/v11-final
description: v11-fixes mascot posts rejected. Using v10 as Image 1 at 0.55 strength changed the art style away from editorial. v11-final (direct) and v10-integrated (original) had better composition and correct style. Save as negative example.
type: feedback
---

## v11-fixes REJECTION (30 March 2026)

### What was rejected:
All 4 mascot posts in v11-fixes/ — M1, M2, M3, M4

### Why:
- Art style drifted — using v10 (non-editorial) as Image 1 at 0.55 strength pulled the style AWAY from flat editorial toward v10's outlined kawaii style
- Composition was WORSE than both v11-final and v10-integrated
- User verdict: "v11-final mascots and v10-mascot-posts are better"

### What was approved instead:
- **v11-final/M1-M4**: correct size (no bars), good composition, editorial mascot style
- **v10-integrated/M1-M4**: wrong size (has bars) but better art style integration
- Both sets copied to APPROVED-PROPOSAL/ for client to choose

### Root cause:
Using a DIFFERENT version's output as Image 1 anchor at low strength changes the art style. v10-integrated had outlined kawaii mascot. When used as Image 1 for v11-fixes at 0.55 strength, NANO averaged between editorial and kawaii = neither style done well.

### Rule:
**Never mix style anchors across versions.** If the approved style is "editorial mascot" (from v10-final-fixes/mascot-editorial-*.png), use THOSE as Image 1. Don't use a different version's output that has a different art style, even if its composition is better.

Composition is controlled via PROMPT TEXT. Art style is controlled via IMAGE 1.

### APPROVED PROPOSAL FOLDER
`06_exports/APPROVED-PROPOSAL/` — 21 posts total:
- B1-B3: Brief adaptations (v6)
- B4-B6: XHS infographics (v7+v9)
- N1-N5: New education/exercise/trust (v6)
- P1-P3: Product posts (v10 product-fix)
- M1-M4: Mascot posts (v11-final) + M1-M4 v10 alternates

**How to apply:** Always check which version's style was approved before using it as Image 1. Composition differences should be driven by prompt text, not by swapping Image 1 anchors from rejected versions.
