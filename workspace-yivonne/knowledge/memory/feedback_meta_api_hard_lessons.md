---
name: Meta API hard lessons — never repeat these mistakes
description: Compound learnings from March 16 campaign launch. Copy wipe bug, rate limiting, token expiry, post ID failures, creative recreation gotchas. Apply to ALL future Meta API work across ALL brands.
type: feedback
---

## Meta Graph API Hard Lessons (2026-03-16)

### 1. CREATIVE RECREATION WIPES COPY
When reading a creative's `object_story_spec.link_data`, the `message`, `name`, and `description` fields may return EMPTY even though the ad has copy. This is because copy is stored on the FACEBOOK POST level, not the creative spec level.

**If you create a new creative using these empty values, the ad goes live with ZERO copy.**

**Fix:** Always create new creatives with BOTH the correct copy AND any template fields (like `page_welcome_message`) in a SINGLE creative creation call. Never read copy from an existing creative and assume it's complete.

**Why:** This caused 84 ads to go live with blank captions. Critical brand damage.

### 2. RATE LIMITING IS REAL
After 168+ API calls in quick succession (84 creative creates + 84 ad updates), the ad account hits rate limits (error code 17, subcode 2446079: "Ad account has too many API calls").

**Fix:**
- Add `time.sleep(0.5)` between calls
- After heavy operations, wait 5-10 minutes before the next batch
- For 80+ operations, expect to need a cooldown

### 3. TOKENS EXPIRE FAST
Graph API Explorer tokens are SHORT-LIVED (~1 hour). During long sessions, you will need fresh tokens 3-4 times.

**Fix:** Always handle token expiry gracefully. When you get auth errors, ask for a fresh token immediately rather than debugging.

### 4. POST ID REUSE FAILURES
Using `object_story_id` (effective_object_story_id from an existing ad) to create new creatives fails with "Invalid parameter" (subcode 1815017) for some posts — likely CTWA destination incompatibility.

**Fix:** When post ID fails, fall back to reusing the original `creative_id` directly:
```python
api_post(ad_id, {"creative": json.dumps({"creative_id": original_creative_id})})
```

### 5. page_welcome_message MUST BE STRING
The `page_welcome_message` field in `link_data` must be passed as `json.dumps(welcome_dict)` (a JSON string), NOT as a raw dict. If you pass a dict, the API silently ignores it.

### 6. call_to_action CAN BE DICT OR STRING
In `link_data`, `call_to_action` can be passed as either a dict or `json.dumps(dict)`. Both work. But be consistent.

### 7. BUDGET CONFUSION
When a user says "minimum 6k per day," clarify whether they mean AD SPEND or SALES TARGET. RM6K ad spend ≠ RM6K sales target. At 4x ROAS, RM6K sales = ~RM1,500 ad spend.

**How to apply:** Before ANY Meta API batch operation:
1. Test with 1-2 ads first, verify the output
2. Add sleep between calls
3. Never trust read-back copy from creative specs
4. Always pass copy explicitly from your source data
5. Handle token expiry and rate limits in the script
