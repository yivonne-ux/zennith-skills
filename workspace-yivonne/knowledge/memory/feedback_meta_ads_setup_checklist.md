---
name: Meta ads setup checklist — never skip these again
description: Complete checklist for Meta ad deployment. Every ad set and ad must match working campaign patterns exactly.
type: feedback
---

When deploying Meta ads, ALWAYS match the working campaign patterns. Never use generic/lazy defaults.

## Ad Set checklist:
1. **Gender**: Female only (`"genders": [2]`)
2. **Age**: 18-65 (not 22-45)
3. **Geo**: KL/Selangor specific — Ampang, Bangsar, Subang Jaya cities + Taman Desa 13km radius + MyTOWN 2km + Damansara Heights 2km + Kinrara Puchong 2km + Pavilion Bukit Jalil 2km
4. **Advantage audience**: ON (`advantage_audience: 1`)
5. **WhatsApp number**: `60193837832` in promoted_object
6. **promoted_object**: `{"page_id": "318283048041590", "whatsapp_phone_number": "60193837832"}`

## Ad creative checklist:
1. **instagram_user_id**: `17841467066982906` — ALWAYS include
2. **WhatsApp link**: `https://api.whatsapp.com/send?phone=60126817828`
3. **page_welcome_message**: Chat builder with "Hey there! Welcome to Mirra" + autofill "I'd like to see your menu and package!"
4. **Ad copy structure**: Primary text with emojis, bullet points (50+ dishes, free delivery, pricing tiers), CTA line "text us on whatsapp: 'hi, i want to try the RM19 bento'"
5. **headline** (name field) + **description** field — both required

**Why:** User corrected — I used lazy defaults (countries: MY, no gender, no IG link, no chat builder, bare copy). Working ads that are converting have all these fields properly set.
**How to apply:** Before any Meta ad deployment, check EVERY field against this list. Copy geo_locations JSON from working ad sets, never type from scratch.
