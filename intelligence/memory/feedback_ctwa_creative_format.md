---
name: CTWA ads MUST use WhatsApp CTA, not website link
description: W3 WA ads had delivery errors because they used ORDER_NOW → website. CTWA ads need WHATSAPP_MESSAGE → wa.me link. Apply to ALL brands.
type: feedback
---

**BUG (March 26):** 3 Pinxin W3 WA ads had delivery errors — zero impressions.

**Cause:** Uploaded with `call_to_action: ORDER_NOW` + `link: pinxinvegan.com`. This is a WEBSITE CTA in a WHATSAPP ad set. Meta can't deliver it because the ad set optimizes for WA conversations but the creative sends users to a website.

**Fix:** CTWA ads MUST use:
```json
{
  "link": "https://wa.me/{phone}",
  "call_to_action": {
    "type": "WHATSAPP_MESSAGE",
    "value": {"link": "https://wa.me/{phone}"}
  }
}
```

**Phone numbers:**
- Pinxin: `wa.me/60196237832`
- Mirra: check existing CTWA ads for the number

**RULE: Before uploading ANY ad to a CTWA ad set, verify:**
- [ ] CTA type = `WHATSAPP_MESSAGE` (not ORDER_NOW, not SHOP_NOW)
- [ ] Link = `wa.me/{phone}` (not website URL)
- [ ] Copy ends with soft WA CTA ("想了解更多？发个消息给我们 👋")

**Add to PREFLIGHT-ROUTER.md under UPLOADING TO META section.**
