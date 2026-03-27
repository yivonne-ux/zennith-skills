## 6. Quality Gate (6 Checks — ALL Must PASS)

Run this on EVERY generated image before it enters the content library.

### Check 1: Face Consistency
Compare against locked face refs. Hair must be dark brown, eyes warm brown, jawline matches. If face looks like a different person, REJECT and regenerate.

**Method:** Manual comparison or CLIP score against `face-refs/` directory. Use `visual-audit.py --mode character --refs` for automated scoring.

### Check 2: Anti-Pattern Scan
Scan for ANY of these instant-fail patterns:
- Cosmic/celestial/galaxy backgrounds
- Purple/violet color dominance
- Crystal ball cliches
- CG/3D render look (too perfect skin, no pores)
- Sacred geometry overlays
- Gothic/witchy aesthetic
- Cartoon/anime/illustration style

If ANY detected, REJECT immediately.

### Check 3: Brand Voice (Caption)
Caption must match Jade's voice: warm, wise, approachable, slightly mysterious. Run through `brand-voice-check.sh` before publishing. Must NOT be: preachy, mystical-cliche ("dear one, the universe whispers..."), or overly casual/slangy.

### Check 4: Physical Realism
- Real skin texture visible (K-beauty smooth but not plastic)
- Natural poses, no extra fingers, no melted hands
- Correct finger count
- Natural body proportions (no elongation, no shrinkage)
- Hair looks natural (not helmet-like)
- Jade pendant visible and physically correct

### Check 5: Copy Quality
Run all captions/copy through `fast-iterate` scoring. Must score >= 8/10 before publishing. Check for:
- Hook strength (first line must stop the scroll)
- CTA presence and clarity
- Hashtag strategy compliance
- Appropriate length for platform

### Check 6: Platform Specs
- Instagram Feed: 4:5 (1080x1350)
- Instagram Story/Reel: 9:16 (1080x1920)
- TikTok: 9:16 (1080x1920)
- Safe zones: no critical content in top/bottom 15% (UI overlays)
- Hashtags: mix of spiritual (#oraclereading #qmdj #energyreading) and lifestyle (#morningritual #selfcare #wellness)

