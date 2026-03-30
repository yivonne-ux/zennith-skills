---
name: Mirra LIVE campaigns — March 16 2026 state
description: Both EN + CN campaigns LIVE with all IDs, ad sets, budgets, ad counts, and Chat Builder templates. Resume any campaign work from here.
type: project
---

## Mirra LIVE Campaign State (2026-03-16)

### Campaigns
| Campaign | ID | Status |
|---|---|---|
| MIRRA-TEST-EN | 120242860196120787 | ACTIVE |
| MIRRA-TEST-CN | 120242860196260787 | ACTIVE |

### Ad Sets
| Ad Set | ID | Campaign | Budget |
|---|---|---|---|
| TOFU-EN | 120242860814300787 | EN | RM250/day |
| MOFU-EN | 120242860859160787 | EN | RM250/day |
| BOFU-EN | 120242860859620787 | EN | RM250/day |
| EN-MIX | 120242860860030787 | EN | RM250/day |
| CN-STATIC | 120242860860650787 | CN | RM250/day |
| CN-MIX | 120242860861020787 | CN | RM250/day |

**Total daily budget: ~RM1,500/day** (matching previous spend level)

### Ad Counts
- 84 static ads (copy restored V5, all working)
- 34 video ads (in MIX ad sets, from active post IDs)
- Total: 118 ads across 6 ad sets

### Chat Builder Templates (CORRECT — verified)
- EN ads → template_id `1191680448537213` ("Whatsapp English- Mirra- OL")
- CN ads → template_id `1407221790666819` ("MIRRA CN START CONVERSATION")

### CN Language Targeting
- Both CN ad sets have locale targeting: Chinese Simplified (44) + Traditional (45)

### Key IDs
- Ad Account: `act_830110298602617`
- Page ID: `318283048041590`
- IG ID: `17841467066982906`
- WhatsApp link: `https://api.whatsapp.com/send?phone=60126817828`

### Previous 3 campaigns PAUSED
- User paused them manually when new ones launched

### Scripts used
- `/tmp/mirra_copy_v5.py` — main script (84/84 success, copy + Chat Builder in one pass)
- `/tmp/mirra_chatbuilder_fix.py` — DEPRECATED, caused copy wipe bug

**Why:** This is the source of truth for campaign state. Any new session should read this first before touching Meta API.

**How to apply:** Use these IDs directly when checking performance, modifying budgets, adding/pausing ads, or pulling insights via Graph API.
