# META CONVERSIONS API (CAPI) FOR CLICK-TO-WHATSAPP (CTWA) ADS
## Complete Setup Guide — Mirra Meal Subscriptions
**Date:** 2026-03-19 | **Status:** Actionable reference

---

## WHY THIS IS DIFFERENT FROM STANDARD CAPI

The existing `META-PIXEL-CAPI-SETUP.md` covers website pixel + server-side CAPI for web conversions. **This document covers something fundamentally different:**

When you run Click-to-WhatsApp (CTWA) ads, there is NO website visit. The user clicks the ad and lands directly in WhatsApp. The Meta Pixel never fires. The ONLY way to tell Meta "this person bought" is through the **Conversions API for Business Messaging**.

**Without CAPI for CTWA:**
- Meta optimizes for "Conversations Started" (anyone who messages)
- Meta has zero visibility into who actually BOUGHT
- You pay the same for tire-kickers and buyers
- Algorithm cannot learn what a buyer looks like

**With CAPI for CTWA:**
- Meta sees: Ad Click → WhatsApp Conversation → Lead Qualified → Purchase
- Algorithm optimizes for BUYERS, not message-senders
- CPA drops significantly (businesses report 40-60% fewer spam leads)
- ROAS becomes measurable for CTWA campaigns

---

## TABLE OF CONTENTS

1. [Architecture: How CTWA CAPI Works](#1-architecture)
2. [Prerequisites](#2-prerequisites)
3. [Option A: Direct Graph API (DIY — Free)](#3-option-a)
4. [Option B: Respond.io (Recommended)](#4-option-b)
5. [Option C: Other Platforms](#5-option-c)
6. [The Critical Piece: Capturing ctwa_clid](#6-ctwa-clid)
7. [Events to Send](#7-events)
8. [Complete Python Code: DIY Implementation](#8-code)
9. [Platform Comparison & Costs](#9-comparison)
10. [Testing & Validation](#10-testing)
11. [Implementation Checklist](#11-checklist)

---

## 1. ARCHITECTURE: HOW CTWA CAPI WORKS <a name="1-architecture"></a>

```
USER                        META                    YOUR SYSTEM
  |                           |                         |
  |-- Sees CTWA ad ---------> |                         |
  |-- Clicks "WhatsApp" ----> |                         |
  |   (Meta generates         |                         |
  |    ctwa_clid)             |                         |
  |                           |                         |
  |-- Opens WhatsApp -------> |-- Webhook fires ------> |
  |   sends first message     |   (includes ctwa_clid   |
  |                           |    in referral object)   |
  |                           |                         |
  |                           |                    STORE ctwa_clid
  |                           |                    linked to this
  |                           |                    contact/phone
  |                           |                         |
  |<-- Your team chats -------|<------------------------|
  |    qualifies lead         |                         |
  |                           |                         |
  |    [Lead qualified]       |                         |
  |                           |<-- CAPI: Lead event ----|
  |                           |    (with ctwa_clid)     |
  |                           |                         |
  |    [Purchase confirmed]   |                         |
  |                           |<-- CAPI: Purchase ------|
  |                           |    event (ctwa_clid     |
  |                           |    + value + currency)  |
  |                           |                         |
  |                    Meta now knows:                  |
  |                    "This ad click → this buyer"     |
  |                    Algorithm optimizes accordingly  |
```

### Key Differences from Website CAPI

| Parameter | Website CAPI | CTWA Business Messaging CAPI |
|-----------|-------------|------------------------------|
| `action_source` | `"website"` | `"business_messaging"` |
| `messaging_channel` | not used | `"whatsapp"` |
| User matching | `fbp`, `fbc`, cookies, email, phone | `ctwa_clid` + phone |
| Pixel ID vs Dataset ID | Pixel ID | **Dataset ID** (created in Events Manager) |
| API endpoint | `/{PIXEL_ID}/events` | `/{DATASET_ID}/events` |
| Event deduplication | `event_id` matching pixel | `event_id` (server-only, no pixel) |

---

## 2. PREREQUISITES <a name="2-prerequisites"></a>

You need:

1. **Meta Business Manager** with admin access
2. **WhatsApp Business API account** (Cloud API or BSP)
3. **A Dataset** in Meta Events Manager (NOT just a Pixel)
4. **System User Access Token** with `ads_management` and `business_management` permissions
5. **A server/backend** that receives WhatsApp webhooks (or a platform like Respond.io)

### 2.1 Create a Dataset in Events Manager

1. Go to **Meta Events Manager** → https://business.facebook.com/events_manager
2. Click **"Connect Data Sources"** (green button)
3. Select **"Messaging"** (NOT "Web" — this is critical)
4. Name it something like `mirra-whatsapp-conversions`
5. Choose **"Conversions API"** as the connection method
6. **Link the Dataset** to your:
   - Facebook Page (the one running CTWA ads)
   - WhatsApp Business Account (WABA)
7. Copy the **Dataset ID** — you'll use this instead of a Pixel ID

### 2.2 Generate Access Token

1. Go to **Meta Business Settings** → **System Users**
2. Create a system user (or use existing)
3. Assign `ads_management` permission to the system user
4. Generate a token with scopes: `ads_management`, `business_management`
5. Save this token securely — it doesn't expire unless revoked

---

## 3. OPTION A: DIRECT GRAPH API (DIY — FREE) <a name="3-option-a"></a>

**Cost:** Free (you already use the Graph API)
**Effort:** Medium — requires webhook handling code
**Best for:** Teams with developer resources who want full control

### How It Works

You already use the Meta Graph API for ad management. CAPI is just another Graph API endpoint. You POST conversion events to:

```
POST https://graph.facebook.com/v22.0/{DATASET_ID}/events
```

### What You Need to Build

1. **Webhook receiver** — catches incoming WhatsApp messages, extracts `ctwa_clid` from the referral object
2. **Contact storage** — stores `ctwa_clid` linked to each contact's phone number
3. **Event sender** — when your team confirms a lead/purchase, fires the CAPI event with the stored `ctwa_clid`

This is the most flexible option and costs nothing beyond your existing infrastructure. Full code in [Section 8](#8-code).

---

## 4. OPTION B: RESPOND.IO (RECOMMENDED) <a name="4-option-b"></a>

**Cost:** From $79/month (Starter) to $279/month (Advanced)
**Effort:** Low — visual workflow builder, no code
**Best for:** Teams that want CRM + WhatsApp + CAPI in one platform

### Why Respond.io is the Best Fit for Mirra

1. **Built-in CAPI workflow step** — drag-and-drop, no code required
2. **Automatically captures ctwa_clid** from CTWA ads
3. **WhatsApp Business API included** (no markup on Meta's messaging fees)
4. **Multi-channel inbox** — your team manages WhatsApp conversations in one place
5. **Workflow automation** — auto-qualify leads, auto-tag, auto-assign
6. **Malaysian company** (HQ in Kuala Lumpur) — local support, MYR billing

### Setup Steps in Respond.io

#### Step 1: Connect WhatsApp Business API
- Go to Settings → Channels → Add Channel → WhatsApp Business API
- Follow the Facebook login flow to connect your WABA
- Your WhatsApp number is now managed through Respond.io

#### Step 2: Connect Meta Events Manager Dataset
- Go to Settings → Integrations → Meta Conversions API
- Select your Facebook Page from the dropdown
- If your page doesn't appear: go to Meta Events Manager first, create a Dataset, and link it to your Facebook Page and WABA

#### Step 3: Build a CAPI Workflow
- Go to Workflows → Create New Workflow
- Set trigger: "Conversation Opened" or "Tag Added" (e.g., when agent tags "Purchase Confirmed")

**Lead Event Workflow:**
```
Trigger: Contact Tag Added = "Qualified Lead"
  → Step: Send Conversions API Event
    → Event Type: Lead Generated
    → Facebook Page: [Your Page]
    → Customer Info: auto-filled from Contact (phone, email, name)
```

**Purchase Event Workflow:**
```
Trigger: Contact Tag Added = "Purchase Confirmed"
  → Step: Send Conversions API Event
    → Event Type: Purchase
    → Facebook Page: [Your Page]
    → Currency: MYR
    → Value: {contact.custom_field.order_value}
    → Customer Info: auto-filled from Contact
```

#### Step 4: Train Your Team
- When a lead is qualified: add tag "Qualified Lead" → CAPI fires Lead event
- When a purchase is confirmed: add tag "Purchase Confirmed" + fill in order value → CAPI fires Purchase event
- That's it. No code. No API calls. Just tags.

### Respond.io Pricing Breakdown

| Plan | Price/month | Seats | Contacts | CAPI | Key Features |
|------|------------|-------|----------|------|-------------|
| Starter | $79 | 5 | 1,000 | YES | Workflows, WhatsApp API, basic automation |
| Growth | $159 | 10 | 3,000 | YES | + AI Agent, advanced workflows, integrations |
| Advanced | $279 | 25 | 5,000 | YES | + AI voice, deeper integrations |
| Enterprise | Custom | Custom | Custom | YES | Custom everything |

**WhatsApp messaging fees:** Passed through at cost (no markup). Meta charges per-message based on template category and country. Malaysia marketing messages ~$0.065/message.

---

## 5. OPTION C: OTHER PLATFORMS <a name="5-option-c"></a>

### 5.1 WATI

- **Pricing:** Growth $59/month (3 users), Pro $119/month (5 users), Business $299/month (10+ users)
- **CAPI support:** Yes, in Pro plan and above. CTWA tracking included.
- **Markup:** ~20% above Meta's WhatsApp messaging fees
- **Pros:** Affordable entry, Shopify integration, broadcast features
- **Cons:** Messaging markup adds up, fewer workflow capabilities than Respond.io

### 5.2 ManyChat

- **Pricing:** Free (basic), Pro $15/month (1,000 contacts)
- **CAPI support:** Yes, via action nodes in flows
- **Pros:** Cheapest option, good for Instagram + WhatsApp + Messenger
- **Cons:** Limited WhatsApp API features, less mature than Respond.io for CTWA specifically

### 5.3 Kommo (formerly amoCRM)

- **Pricing:** From $15/user/month
- **CAPI support:** Yes, built-in CAPI integration
- **Pros:** Full CRM with sales pipeline, affordable per-user pricing
- **Cons:** More complex setup, CRM-focused (not messaging-first)

### 5.4 AiSensy

- **Pricing:** From ~$20/month
- **CAPI support:** Yes, specifically designed for CTWA ads
- **Pros:** Indian company, very affordable, built specifically for WhatsApp marketing
- **Cons:** Less polished UI, smaller ecosystem

### 5.5 Interakt

- **Pricing:** From ~$15/month
- **CAPI support:** Yes, with up to 2 conversion points per CTWA ad
- **Pros:** Very affordable, good WhatsApp commerce features
- **Cons:** Limited to 2 conversion points, less flexible workflows

### 5.6 Zapier (No-Code Bridge)

- **Pricing:** From $19.99/month (Starter) to $69.99/month (Professional)
- **CAPI support:** Yes, via Meta Conversions API integration
- **How:** CRM trigger (e.g., deal closed in Google Sheets/Airtable) → Zapier → CAPI event
- **Pros:** Connects any CRM to CAPI with zero code
- **Cons:** Doesn't capture ctwa_clid (you'd need to capture that separately), adds latency, per-task pricing

---

## 6. THE CRITICAL PIECE: CAPTURING ctwa_clid <a name="6-ctwa-clid"></a>

This is the most important technical detail. Without `ctwa_clid`, Meta cannot attribute the conversion back to the specific ad click.

### 6.1 Where ctwa_clid Comes From

When a user clicks your CTWA ad and sends their first WhatsApp message, the WhatsApp Cloud API webhook includes a `referral` object:

```json
{
  "object": "whatsapp_business_account",
  "entry": [{
    "id": "WABA_ID",
    "changes": [{
      "value": {
        "messaging_product": "whatsapp",
        "metadata": {
          "display_phone_number": "60123456789",
          "phone_number_id": "PHONE_NUMBER_ID"
        },
        "contacts": [{
          "profile": { "name": "Customer Name" },
          "wa_id": "60187654321"
        }],
        "messages": [{
          "from": "60187654321",
          "id": "wamid.xxx",
          "timestamp": "1710835200",
          "type": "text",
          "text": { "body": "Hi, I saw your ad..." },
          "referral": {
            "source_url": "https://fb.me/...",
            "source_id": "AD_ID_123",
            "source_type": "ad",
            "headline": "Your Ad Headline",
            "body": "Your ad body text",
            "ctwa_clid": "ARAkLkA8rmlFeiCktEJQ-QTwRiyYHAFDLMNDBH0CD3qpjd0HR4irJ6LEkR7JwFF4XvnO2E4Nx0-eM-GABDLOPaOdRMv-_zfUQ2a"
          }
        }]
      }
    }]
  }]
}
```

### 6.2 What to Store

When you receive this webhook, immediately store:

| Field | Where to Find | Why |
|-------|--------------|-----|
| `ctwa_clid` | `messages[0].referral.ctwa_clid` | Required for CAPI attribution |
| `source_id` | `messages[0].referral.source_id` | The ad ID — useful for your own analytics |
| `wa_id` | `contacts[0].wa_id` | Customer's WhatsApp number |
| `timestamp` | `messages[0].timestamp` | When the conversation started |

### 6.3 Important Notes

- `ctwa_clid` is ONLY present in the **first message** from a CTWA ad click. If the user messages you organically (not from an ad), there's no referral object.
- Store `ctwa_clid` immediately and associate it with the contact's phone number in your CRM/database.
- A single user might click multiple ads over time — store the most recent `ctwa_clid` for attribution.
- `ctwa_clid` is valid for attribution within Meta's **7-day click** attribution window (default).

---

## 7. EVENTS TO SEND <a name="7-events"></a>

### 7.1 Recommended Event Funnel for Mirra

For a meal subscription business selling via WhatsApp, send these events in order:

| Stage | Event Name | When to Fire | Why |
|-------|-----------|-------------|-----|
| 1 | `Lead` | Customer provides phone/email or expresses interest | Mid-funnel signal — "this person is interested" |
| 2 | `Subscribe` | Customer confirms a subscription plan (10/20/40 meals) | High-intent signal — chose a specific product |
| 3 | `Purchase` | Payment received / order confirmed | Bottom-funnel — the money event. THIS is what you optimize for. |

### 7.2 Event Parameters

**Lead Event:**
```json
{
  "event_name": "Lead",
  "event_time": 1710835200,
  "action_source": "business_messaging",
  "messaging_channel": "whatsapp",
  "user_data": {
    "ph": ["<SHA256 hashed phone>"],
    "ctwa_clid": "ARAkLkA8rml...",
    "page_id": "<YOUR_FACEBOOK_PAGE_ID>"
  },
  "custom_data": {
    "lead_source": "whatsapp_ctwa",
    "content_name": "meal_subscription_inquiry"
  }
}
```

**Subscribe Event:**
```json
{
  "event_name": "Subscribe",
  "event_time": 1710835200,
  "action_source": "business_messaging",
  "messaging_channel": "whatsapp",
  "user_data": {
    "ph": ["<SHA256 hashed phone>"],
    "ctwa_clid": "ARAkLkA8rml...",
    "page_id": "<YOUR_FACEBOOK_PAGE_ID>"
  },
  "custom_data": {
    "value": 475.00,
    "currency": "MYR",
    "content_name": "Solo Glow 20 Meals",
    "content_category": "meal_subscription",
    "predicted_ltv": 2850.00
  }
}
```

**Purchase Event:**
```json
{
  "event_name": "Purchase",
  "event_time": 1710835200,
  "action_source": "business_messaging",
  "messaging_channel": "whatsapp",
  "user_data": {
    "ph": ["<SHA256 hashed phone>"],
    "em": ["<SHA256 hashed email>"],
    "fn": "<SHA256 hashed first name>",
    "ct": "<SHA256 hashed city>",
    "country": "<SHA256 hashed country code>",
    "ctwa_clid": "ARAkLkA8rml...",
    "page_id": "<YOUR_FACEBOOK_PAGE_ID>",
    "external_id": ["<SHA256 hashed customer ID>"]
  },
  "custom_data": {
    "value": 475.00,
    "currency": "MYR",
    "content_ids": ["solo_glow_20"],
    "content_type": "product",
    "content_name": "Solo Glow 20 Meals",
    "order_id": "MIRRA-2026-0319-001",
    "num_items": 20
  }
}
```

### 7.3 Hashing Requirements

Meta requires ALL user_data fields (except `ctwa_clid` and `page_id`) to be SHA-256 hashed:

```python
import hashlib

def hash_sha256(value):
    """Hash a value for Meta CAPI user_data fields."""
    if not value:
        return None
    # Lowercase, strip whitespace, then hash
    normalized = str(value).lower().strip()
    return hashlib.sha256(normalized.encode('utf-8')).hexdigest()

# Examples:
hash_sha256("+60187654321")  # phone — include country code
hash_sha256("customer@email.com")  # email
hash_sha256("kuala lumpur")  # city
hash_sha256("my")  # country code
```

**NOTE:** `ctwa_clid` is sent as-is (NOT hashed). `page_id` is sent as-is.

---

## 8. COMPLETE PYTHON CODE: DIY IMPLEMENTATION <a name="8-code"></a>

This is the full implementation for sending CAPI events via the Graph API. You already use the Graph API for ad management, so this is a natural extension.

### 8.1 Core CAPI Client

```python
"""
mirra_capi.py — Meta Conversions API client for CTWA ads
Sends Lead, Subscribe, and Purchase events back to Meta
so the algorithm optimizes for buyers, not conversations.
"""

import hashlib
import json
import time
import uuid
import requests
from typing import Optional, Dict, Any, List

# ============================================================
# CONFIGURATION — Replace with your actual values
# ============================================================
DATASET_ID = "YOUR_DATASET_ID"  # From Events Manager (NOT Pixel ID)
ACCESS_TOKEN = "YOUR_SYSTEM_USER_TOKEN"
FACEBOOK_PAGE_ID = "YOUR_PAGE_ID"
API_VERSION = "v22.0"
CAPI_ENDPOINT = f"https://graph.facebook.com/{API_VERSION}/{DATASET_ID}/events"

# ============================================================
# HASHING
# ============================================================
def hash_sha256(value: Optional[str]) -> Optional[str]:
    """SHA-256 hash for user_data fields (Meta requirement)."""
    if not value:
        return None
    normalized = str(value).lower().strip()
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def hash_phone(phone: str) -> str:
    """Hash phone number. Include country code, remove spaces/dashes."""
    cleaned = phone.replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
    if not cleaned.startswith("+"):
        # Assume Malaysian if no country code
        if cleaned.startswith("0"):
            cleaned = "+60" + cleaned[1:]
        else:
            cleaned = "+60" + cleaned
    return hash_sha256(cleaned)


# ============================================================
# CONTACT STORE (in production, use a database)
# ============================================================
# Maps WhatsApp phone number → ctwa_clid
# In production: use PostgreSQL, Redis, or your CRM
_ctwa_store: Dict[str, str] = {}


def store_ctwa_clid(phone: str, ctwa_clid: str):
    """Store ctwa_clid when a CTWA ad click starts a conversation."""
    _ctwa_store[phone] = ctwa_clid
    print(f"[CAPI] Stored ctwa_clid for {phone}: {ctwa_clid[:30]}...")


def get_ctwa_clid(phone: str) -> Optional[str]:
    """Retrieve stored ctwa_clid for a phone number."""
    return _ctwa_store.get(phone)


# ============================================================
# WEBHOOK HANDLER — Extract ctwa_clid from incoming messages
# ============================================================
def handle_whatsapp_webhook(payload: dict):
    """
    Call this when you receive a WhatsApp Cloud API webhook.
    Extracts and stores ctwa_clid from CTWA ad clicks.
    """
    try:
        for entry in payload.get("entry", []):
            for change in entry.get("changes", []):
                value = change.get("value", {})
                messages = value.get("messages", [])
                contacts = value.get("contacts", [])

                for i, message in enumerate(messages):
                    referral = message.get("referral")
                    if referral and "ctwa_clid" in referral:
                        # This message came from a CTWA ad click
                        phone = message.get("from", "")
                        ctwa_clid = referral["ctwa_clid"]
                        source_id = referral.get("source_id", "unknown")

                        store_ctwa_clid(phone, ctwa_clid)

                        print(f"[CAPI] CTWA click detected!")
                        print(f"  Phone: {phone}")
                        print(f"  Ad ID: {source_id}")
                        print(f"  ctwa_clid: {ctwa_clid[:40]}...")
    except Exception as e:
        print(f"[CAPI] Error processing webhook: {e}")


# ============================================================
# SEND CAPI EVENT
# ============================================================
def send_capi_event(
    event_name: str,
    phone: str,
    email: Optional[str] = None,
    first_name: Optional[str] = None,
    city: Optional[str] = None,
    custom_data: Optional[Dict[str, Any]] = None,
    event_id: Optional[str] = None,
    event_time: Optional[int] = None,
    external_id: Optional[str] = None,
) -> dict:
    """
    Send a conversion event to Meta via CAPI.

    Args:
        event_name: "Lead", "Subscribe", or "Purchase"
        phone: Customer's WhatsApp phone number (unhashed — will be hashed)
        email: Customer's email (optional, unhashed)
        first_name: Customer's first name (optional, unhashed)
        city: Customer's city (optional, unhashed)
        custom_data: Event-specific data (value, currency, content_ids, etc.)
        event_id: Unique event ID for deduplication (auto-generated if not provided)
        event_time: Unix timestamp (defaults to now)
        external_id: Your internal customer ID (optional, unhashed)
    """

    # Build user_data
    user_data = {
        "ph": [hash_phone(phone)],
        "page_id": FACEBOOK_PAGE_ID,
    }

    # Add ctwa_clid if we have it for this phone
    ctwa_clid = get_ctwa_clid(phone)
    if ctwa_clid:
        user_data["ctwa_clid"] = ctwa_clid

    # Add optional user_data fields
    if email:
        user_data["em"] = [hash_sha256(email)]
    if first_name:
        user_data["fn"] = hash_sha256(first_name)
    if city:
        user_data["ct"] = hash_sha256(city)
    if external_id:
        user_data["external_id"] = [hash_sha256(external_id)]

    # Always include country for Malaysian customers
    user_data["country"] = hash_sha256("my")

    # Build the event
    event = {
        "event_name": event_name,
        "event_time": event_time or int(time.time()),
        "event_id": event_id or str(uuid.uuid4()),
        "action_source": "business_messaging",
        "messaging_channel": "whatsapp",
        "user_data": user_data,
    }

    if custom_data:
        event["custom_data"] = custom_data

    # Send to Meta
    payload = {
        "data": json.dumps([event]),
        "access_token": ACCESS_TOKEN,
    }

    response = requests.post(CAPI_ENDPOINT, data=payload)
    result = response.json()

    if response.status_code == 200:
        events_received = result.get("events_received", 0)
        print(f"[CAPI] {event_name} event sent successfully. Events received: {events_received}")
    else:
        print(f"[CAPI] ERROR sending {event_name}: {result}")

    return result


# ============================================================
# CONVENIENCE FUNCTIONS — Call these from your business logic
# ============================================================

def track_lead(phone: str, email: Optional[str] = None, name: Optional[str] = None):
    """Fire when a WhatsApp contact is qualified as a lead."""
    return send_capi_event(
        event_name="Lead",
        phone=phone,
        email=email,
        first_name=name,
        custom_data={
            "lead_source": "whatsapp_ctwa",
            "content_name": "meal_subscription_inquiry",
        },
    )


def track_subscription(
    phone: str,
    plan_name: str,
    value: float,
    email: Optional[str] = None,
    name: Optional[str] = None,
):
    """Fire when customer chooses a subscription plan."""
    return send_capi_event(
        event_name="Subscribe",
        phone=phone,
        email=email,
        first_name=name,
        custom_data={
            "value": value,
            "currency": "MYR",
            "content_name": plan_name,
            "content_category": "meal_subscription",
        },
    )


def track_purchase(
    phone: str,
    order_id: str,
    value: float,
    plan_name: str,
    num_meals: int,
    email: Optional[str] = None,
    name: Optional[str] = None,
    customer_id: Optional[str] = None,
):
    """Fire when payment is confirmed / order is placed."""
    return send_capi_event(
        event_name="Purchase",
        phone=phone,
        email=email,
        first_name=name,
        external_id=customer_id,
        city="kuala lumpur",
        custom_data={
            "value": value,
            "currency": "MYR",
            "content_ids": [plan_name.lower().replace(" ", "_")],
            "content_type": "product",
            "content_name": plan_name,
            "order_id": order_id,
            "num_items": num_meals,
        },
    )


# ============================================================
# USAGE EXAMPLES
# ============================================================

if __name__ == "__main__":
    # Example 1: Simulate receiving a CTWA webhook
    sample_webhook = {
        "object": "whatsapp_business_account",
        "entry": [{
            "id": "WABA_ID",
            "changes": [{
                "value": {
                    "messaging_product": "whatsapp",
                    "metadata": {
                        "display_phone_number": "60123456789",
                        "phone_number_id": "PHONE_NUMBER_ID"
                    },
                    "contacts": [{
                        "profile": {"name": "Aisha"},
                        "wa_id": "60187654321"
                    }],
                    "messages": [{
                        "from": "60187654321",
                        "id": "wamid.xxx",
                        "timestamp": "1710835200",
                        "type": "text",
                        "text": {"body": "Hi, I want to know about your meal plans"},
                        "referral": {
                            "source_url": "https://fb.me/abc",
                            "source_id": "120242895523710787",
                            "source_type": "ad",
                            "headline": "Lose 5kg in 30 Days",
                            "body": "Plant-based meals delivered daily",
                            "ctwa_clid": "ARAkLkA8rmlFeiCktEJQ-QTwRiyYHAFDLMNDBH0CD3qpjd0HR4irJ6LEkR7JwFF4XvnO2E4Nx0-eM-GABDLOPaOdRMv-_zfUQ2a"
                        }
                    }]
                }
            }]
        }]
    }

    # Process the webhook — stores ctwa_clid
    handle_whatsapp_webhook(sample_webhook)

    # Example 2: Track a lead (after your team qualifies them)
    track_lead(
        phone="60187654321",
        email="aisha@example.com",
        name="Aisha",
    )

    # Example 3: Track subscription selection
    track_subscription(
        phone="60187654321",
        plan_name="Solo Glow 20 Meals",
        value=475.00,
        email="aisha@example.com",
        name="Aisha",
    )

    # Example 4: Track purchase (payment confirmed)
    track_purchase(
        phone="60187654321",
        order_id="MIRRA-2026-0319-001",
        value=475.00,
        plan_name="Solo Glow 20 Meals",
        num_meals=20,
        email="aisha@example.com",
        name="Aisha",
        customer_id="CUST-001",
    )
```

### 8.2 Flask Webhook Receiver (Minimal)

If you need a simple server to receive WhatsApp webhooks:

```python
"""
mirra_webhook_server.py — Minimal Flask server for WhatsApp webhooks
Run with: python mirra_webhook_server.py
"""

from flask import Flask, request, jsonify
from mirra_capi import handle_whatsapp_webhook

app = Flask(__name__)

VERIFY_TOKEN = "your_verify_token_here"  # Set this in your WhatsApp app config

@app.route("/webhook", methods=["GET"])
def verify():
    """WhatsApp webhook verification (required for setup)."""
    mode = request.args.get("hub.mode")
    token = request.args.get("hub.verify_token")
    challenge = request.args.get("hub.challenge")

    if mode == "subscribe" and token == VERIFY_TOKEN:
        return challenge, 200
    return "Forbidden", 403

@app.route("/webhook", methods=["POST"])
def webhook():
    """Receive WhatsApp messages and extract ctwa_clid."""
    payload = request.get_json()
    handle_whatsapp_webhook(payload)
    return jsonify({"status": "ok"}), 200

if __name__ == "__main__":
    app.run(port=5000, debug=True)
```

### 8.3 cURL Example (For Testing)

Test your CAPI setup without Python:

```bash
curl -X POST "https://graph.facebook.com/v22.0/YOUR_DATASET_ID/events" \
  -H "Content-Type: application/json" \
  -d '{
    "data": [{
      "event_name": "Purchase",
      "event_time": 1710835200,
      "event_id": "test_purchase_001",
      "action_source": "business_messaging",
      "messaging_channel": "whatsapp",
      "user_data": {
        "ph": ["a1b2c3d4e5f6..."],
        "ctwa_clid": "ARAkLkA8rmlFeiCktEJQ...",
        "page_id": "YOUR_PAGE_ID",
        "country": "d0cfc2e5319b082fbe7d9..."
      },
      "custom_data": {
        "value": 475.00,
        "currency": "MYR",
        "content_name": "Solo Glow 20 Meals",
        "order_id": "MIRRA-2026-0319-001"
      }
    }],
    "access_token": "YOUR_ACCESS_TOKEN"
  }'
```

Expected response:
```json
{
  "events_received": 1,
  "messages": [],
  "fbtrace_id": "AbCdEfGhIjKl..."
}
```

---

## 9. PLATFORM COMPARISON & COSTS <a name="9-comparison"></a>

| Platform | Monthly Cost | CAPI Built-in | ctwa_clid Auto-Capture | WA Markup | Setup Effort | Best For |
|----------|-------------|--------------|----------------------|-----------|-------------|---------|
| **DIY (Graph API)** | Free | You build it | You build it | None | High | Full control, dev team |
| **Respond.io** | $79-279 | YES (workflow step) | YES | None (pass-through) | Low | Best all-around for CTWA |
| **WATI** | $59-299 | YES (Pro+) | YES | ~20% markup | Low | Budget, Shopify integration |
| **ManyChat** | $15+ | YES (action node) | Partial | Varies | Low | Multi-channel, cheapest |
| **Kommo** | $15/user | YES | YES | None | Medium | Full CRM needed |
| **Zapier** | $20-70 | YES (bridge) | NO | N/A | Low | Bridge existing CRM to CAPI |
| **AiSensy** | ~$20 | YES | YES | Markup | Low | Budget WhatsApp marketing |
| **Interakt** | ~$15 | YES (2 events max) | YES | Markup | Low | Small business, limited needs |

### Recommendation for Mirra

**Short-term (now):** DIY via Graph API. You already use it. Add the `mirra_capi.py` module, have your WhatsApp team manually trigger events when they confirm purchases. Cost: $0.

**Medium-term (when scaling):** Respond.io Growth plan ($159/month). Gives you a proper WhatsApp CRM inbox, automated workflows that fire CAPI events on tag changes, and no messaging markup. The team can manage all WhatsApp conversations in one place instead of using the WhatsApp Business app directly.

---

## 10. TESTING & VALIDATION <a name="10-testing"></a>

### 10.1 Use Test Events in Events Manager

1. Go to Meta Events Manager → Your Dataset → **Test Events** tab
2. Use the test event code provided
3. Add `&test_event_code=TEST12345` to your CAPI requests during testing:

```python
payload = {
    "data": json.dumps([event]),
    "access_token": ACCESS_TOKEN,
    "test_event_code": "TEST12345",  # Remove in production
}
```

Test events show up in Events Manager immediately but are NOT used for ad optimization.

### 10.2 Check Event Match Quality (EMQ)

After sending events:
1. Go to Events Manager → Your Dataset → **Overview**
2. Check **Event Match Quality** score (target: 6.0+)
3. Higher EMQ = better attribution = better ad optimization
4. To improve EMQ: send more user_data fields (email, name, city, external_id)

### 10.3 Verify in Ads Manager

After CAPI is live and you've sent some real events:
1. Go to Ads Manager → Columns → Customize
2. Add columns: **"Messaging Purchases"** and **"Messaging Leads"**
3. These show conversions attributed to your CTWA ads via CAPI
4. Attribution window: 7-day click (default for CTWA)

### 10.4 Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Invalid parameter` | Wrong Dataset ID or using Pixel ID | Use Dataset ID from Events Manager (Messaging data source) |
| `(#100) param data must be...` | Data not JSON-stringified | `json.dumps([event])` not `json.dumps(event)` |
| `events_received: 0` | Missing required user_data | At least one of: ph, em, or ctwa_clid required |
| Events not showing in Ads Manager | Dataset not linked to Page/WABA | Go to Events Manager → Settings → Connected Assets |
| Low EMQ score | Too few user_data fields | Add email, name, city, external_id |

---

## 11. IMPLEMENTATION CHECKLIST <a name="11-checklist"></a>

### Phase 1: Foundation (Do Now)

- [ ] Create a **Dataset** in Meta Events Manager (type: Messaging)
- [ ] Link Dataset to your Facebook Page AND WhatsApp Business Account
- [ ] Generate a System User access token with `ads_management` permission
- [ ] Test sending a dummy event via cURL
- [ ] Verify test event appears in Events Manager → Test Events tab

### Phase 2: Webhook & ctwa_clid (Week 1)

- [ ] Set up WhatsApp Cloud API webhook to receive incoming messages
- [ ] Add ctwa_clid extraction logic to your webhook handler
- [ ] Store ctwa_clid linked to phone number in your database/CRM
- [ ] Verify ctwa_clid is being captured by running a test CTWA ad and clicking it

### Phase 3: Event Sending (Week 1-2)

- [ ] Implement `track_lead()` — fire when team qualifies a WhatsApp lead
- [ ] Implement `track_purchase()` — fire when payment is confirmed
- [ ] Add `track_subscription()` if you want mid-funnel signal
- [ ] Test all events with `test_event_code` parameter
- [ ] Remove test_event_code and send real events

### Phase 4: Optimization (Week 3+)

- [ ] Check Event Match Quality in Events Manager (target: 6.0+)
- [ ] Add "Messaging Purchases" column in Ads Manager
- [ ] Create a new CTWA campaign optimized for "Purchase" (not just Conversations)
- [ ] Monitor ROAS in Ads Manager — should improve as algorithm learns from purchase data
- [ ] Consider switching to Respond.io if manual event firing is too much friction

### Phase 5: Scale (Month 2+)

- [ ] Evaluate Respond.io Growth plan for automated CAPI workflows
- [ ] Set up automated Lead event on first reply
- [ ] Set up automated Purchase event on order confirmation
- [ ] Build retargeting audiences from CAPI events (Purchasers, Leads who didn't buy)
- [ ] Implement value-based lookalike audiences (high-value purchasers)

---

## REFERENCES

- [Meta Conversions API for Business Messaging (Official Docs)](https://developers.facebook.com/docs/marketing-api/conversions-api/business-messaging/)
- [Meta CAPI Business Messaging Guidebooks](https://developers.facebook.com/docs/marketing-api/fmp-tmp-guides/capi-business-messaging-guidebooks/)
- [Conversions API — Using the API](https://developers.facebook.com/docs/marketing-api/conversions-api/using-the-api/)
- [Respond.io — Send Conversions API Event Step](https://respond.io/help/workflows/step-send-conversions-api-event)
- [InsiderOne — Meta CAPI for Click-to-WhatsApp Ads](https://academy.insiderone.com/docs/meta-conversions-api-for-click-to-whatsapp-ads)
- [Stape — WhatsApp Conversion API](https://stape.io/news/whatsapp-conversion-api)
- [AiSensy — Meta CAPI for CTWA](https://m.aisensy.com/blog/meta-conversion-api-click-to-whatsapp-ads/)
- [Kommo — CAPI Setup](https://www.kommo.com/support/messenger-apps/capi-how-to-set-it-up/)
- [Sanoflow — WhatsApp Conversions API Guide](https://sanoflow.io/en/collection/whatsapp-business-api/whatsapp-conversions-api/)
- [Twilio — ctwa_clid Callback Parameter](https://www.twilio.com/en-us/changelog/new--click-id--callback-parameter-for-inbound-whatsapp-messages-)
- [WhatsApp Business — Conversions API Blog](https://business.whatsapp.com/blog/conversions-api-messaging)
- [ManyChat — CAPI Integration](https://help.manychat.com/hc/en-us/articles/14580897414300-Conversions-API-CAPI-integration)
- [Zapier — Meta Conversions API + CRM](https://zapier.com/l/meta-conversions-api-crm)
- [Landbot — Meta CAPI from WhatsApp Bot](https://help.landbot.io/article/ucxj0ybxrr-send-events-to-meta-s-conversions-api-from-your-whats-app-bot)
