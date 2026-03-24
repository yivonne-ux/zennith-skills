---
name: Meta Ads Hard Rules — learned from Pinxin Mar 17-22
description: Every mistake, every lesson, every rule. Compound learning from 6 days of live campaign management. NEVER repeat these mistakes.
type: feedback
---

## CAMPAIGN MANAGEMENT RULES

### 1. STOP CONSTANT CHANGES
Each change resets learning phase. Need 50 conversions in 7 days to exit learning.
Set up once, leave 14 days. One change at a time, wait 3-4 days.
Budget changes: max 20% per edit.

### 2. BID STRATEGY PROGRESSION
- Week 1-2: Lowest Cost (no caps, no floors)
- Week 3-4: Cost Cap at actual CPA + 20%
- Month 2+: Test Min ROAS (only if 50+ conversions/week)
- NEVER use ROAS floor on new campaigns
- Cost Cap > Bid Cap 90% of the time

### 3. NEVER SET RM500K BUDGET WITHOUT SPEND CAPS
Day 1 burned RM1,045 in 30 minutes. Always set ad set spend caps on new ad sets.

### 4. DUAL CHANNEL — DIFFERENT KILL RULES
Website: kill based on Meta pixel (CPA, ATC, purchases)
WhatsApp: NEVER kill based on pixel. CHECK GOOGLE SHEET first. Meta can't see WA orders.
Same ad can fail on website but succeed on WA.

### 5. 2-CAMPAIGN STRUCTURE
- Scale (80% budget): proven winners only, NEVER touch
- Test (20% budget): new creatives, weekly rotation
- Or separate campaigns per channel (Website + WA)

### 6. 10-15 ADS PER AD SET (Andromeda optimal)
- 50 is the hard limit (including paused!)
- DELETE (not pause) confirmed losers to make room
- Be CAREFUL with delete patterns — "BOFU-1" matched BOFU-10, BOFU-18

### 7. IDENTITY GIMMICK = BEST CREATIVE FORMULA
Same offer, identity-based hooks. TNG-PROMO = RM33 CPA, 4.78x ROAS.
Each hook needs UNIQUE artwork (not same image with different copy).

### 8. CREATIVE PRODUCTION RULES
- ALL text = NANO. PIL = resize + logo + grain ONLY
- References MUST be 9:16 before NANO
- NEVER crop NANO output — blur-extend pad only
- Food must blend INTO scene (matching lighting, shadows)
- Human approval REQUIRED before uploading to Meta
- Save to 06_exports/campaigns/[name]/ first, review, then upload

### 9. WA CAMPAIGN OBJECTIVE
- SALES objective (not ENGAGEMENT) for WhatsApp-dominant markets
- ENGAGEMENT finds chatters. SALES finds buyers who prefer WhatsApp.
- Old WA campaign (SALES obj) got RM10/convo. New CTWA (ENGAGEMENT) got RM380/convo.

### 10. PAYMENT & TOKEN
- Auto-payment prevents learning reset from payment failures
- Meta token: 60-day, exchange via Graph API
- Shopify token: auto-refreshes via client_credentials grant
- Keep tokens in _WORK/_shared/.meta-token and .shopify-token-pinxin
