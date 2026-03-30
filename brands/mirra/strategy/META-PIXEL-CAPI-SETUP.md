# META PIXEL + CONVERSIONS API (CAPI) SETUP
## Subscription Meal Delivery Business — Implementation Guide
**Date:** 2026-03-13 | **Status:** Reference document

---

## TABLE OF CONTENTS
1. [Architecture Overview](#1-architecture-overview)
2. [Pixel Setup — Events & Parameters](#2-pixel-setup)
3. [Conversions API (CAPI) Setup](#3-capi-setup)
4. [Event Deduplication](#4-event-deduplication)
5. [Aggregated Event Measurement (AEM)](#5-aem)
6. [Value Optimization for Subscriptions](#6-value-optimization)
7. [Subscription Lifecycle Tracking](#7-subscription-lifecycle)
8. [iOS Privacy & First-Party Data](#8-ios-privacy)
9. [Event Match Quality (EMQ)](#9-emq)
10. [Third-Party Attribution Tools](#10-attribution-tools)
11. [Platform-Specific Setup](#11-platform-setup)
12. [UTM Strategy](#12-utm-strategy)
13. [Debugging & Validation](#13-debugging)
14. [Implementation Checklist](#14-checklist)

---

## 1. ARCHITECTURE OVERVIEW <a name="1-architecture-overview"></a>

### The Dual-Pipeline Model

```
USER BROWSER                          YOUR SERVER
     |                                     |
     |-- Meta Pixel (JS) -----> Meta       |
     |   (client-side)         Servers     |
     |                           ^         |
     |                           |         |
     |                    CAPI --+--- Your Backend
     |                    (server-side)    |
     |                                     |
     +-- event_id generated here ----------+
         (shared between both pipelines)
```

**Why both:** Pixel alone misses 30-60% of conversions due to ad blockers, iOS ATT, cookie restrictions. CAPI alone misses some browser-level signals (scroll depth, time on page). Together with deduplication, you get maximum signal coverage.

### What Goes Where

| Signal Type | Pixel (Browser) | CAPI (Server) |
|---|---|---|
| PageView | YES | Optional |
| ViewContent | YES | YES |
| AddToCart | YES | YES |
| InitiateCheckout | YES | YES |
| Purchase (first order) | YES | YES |
| Recurring Purchase | NO | YES (server-only) |
| Subscription lifecycle events | NO | YES (server-only) |
| Offline/WhatsApp orders | NO | YES (server-only) |
| Lead form submissions | YES | YES |

**Rule of thumb:** Browser events = top-of-funnel + checkout. Server events = everything post-purchase + subscription lifecycle + offline.

---

## 2. PIXEL SETUP — EVENTS & PARAMETERS <a name="2-pixel-setup"></a>

### 2.1 Standard Events to Implement

These are Meta's built-in standard events. Use these exact names — they unlock Meta's optimization algorithms.

#### Funnel Events (browser + server)

```javascript
// 1. PAGE VIEW — fires on every page load
fbq('track', 'PageView');

// 2. VIEW CONTENT — landing page, menu page, plan page
fbq('track', 'ViewContent', {
  content_name: 'Weekly Meal Plan - Weight Loss',
  content_category: 'meal-plan',
  content_type: 'product',
  content_ids: ['plan_weightloss_weekly'],
  value: 149.00,
  currency: 'MYR'
});

// 3. ADD TO CART — user selects a plan/adds meals
fbq('track', 'AddToCart', {
  content_name: 'Weekly Meal Plan - Weight Loss',
  content_type: 'product',
  content_ids: ['plan_weightloss_weekly'],
  value: 149.00,
  currency: 'MYR',
  num_items: 1
});

// 4. INITIATE CHECKOUT — enters checkout flow
fbq('track', 'InitiateCheckout', {
  content_ids: ['plan_weightloss_weekly'],
  content_type: 'product',
  value: 149.00,
  currency: 'MYR',
  num_items: 1
});

// 5. ADD PAYMENT INFO — enters payment details
fbq('track', 'AddPaymentInfo', {
  content_ids: ['plan_weightloss_weekly'],
  content_type: 'product',
  value: 149.00,
  currency: 'MYR'
});

// 6. PURCHASE — completes first order (REQUIRED: value + currency)
fbq('track', 'Purchase', {
  content_name: 'Weekly Meal Plan - Weight Loss',
  content_type: 'product',
  content_ids: ['plan_weightloss_weekly'],
  value: 149.00,
  currency: 'MYR',
  num_items: 5,                    // number of meals
  order_id: 'ORD-20260313-001',   // for dedup
  predicted_ltv: 1788.00           // 12 months * 149
});

// 7. START TRIAL — if offering trial period
fbq('track', 'StartTrial', {
  value: 29.00,
  currency: 'MYR',
  predicted_ltv: 1788.00
});

// 8. SUBSCRIBE — paid subscription begins
fbq('track', 'Subscribe', {
  value: 149.00,
  currency: 'MYR',
  predicted_ltv: 1788.00
});

// 9. COMPLETE REGISTRATION — account creation
fbq('track', 'CompleteRegistration', {
  content_name: 'Mirra Account',
  status: true,
  value: 0,
  currency: 'MYR'
});

// 10. LEAD — quiz completion, consultation booking
fbq('track', 'Lead', {
  content_name: 'Meal Plan Quiz',
  content_category: 'quiz',
  value: 0,
  currency: 'MYR'
});
```

### 2.2 Custom Events for Subscription Business

Custom events DO NOT unlock Meta's standard optimization (you cannot optimize campaigns toward them directly), but they are critical for building audiences and tracking the full lifecycle.

```javascript
// SUBSCRIPTION LIFECYCLE — all via CAPI (server-side only)

// Recurring purchase (each renewal)
fbq('trackCustom', 'RecurringPurchase', {
  subscription_id: 'SUB-001',
  value: 149.00,
  currency: 'MYR',
  renewal_number: 3,
  plan_type: 'weekly_weightloss',
  months_active: 3
});

// Subscription pause
fbq('trackCustom', 'SubscriptionPause', {
  subscription_id: 'SUB-001',
  months_active: 3,
  pause_reason: 'travel',
  total_spent: 447.00,
  currency: 'MYR'
});

// Subscription cancel
fbq('trackCustom', 'SubscriptionCancel', {
  subscription_id: 'SUB-001',
  months_active: 6,
  cancel_reason: 'budget',
  total_spent: 894.00,
  currency: 'MYR',
  ltv_actual: 894.00
});

// Win-back (reactivation)
fbq('trackCustom', 'SubscriptionReactivate', {
  subscription_id: 'SUB-001',
  months_churned: 2,
  value: 149.00,
  currency: 'MYR',
  reactivation_offer: 'welcome_back_20pct'
});

// Plan upgrade
fbq('trackCustom', 'PlanUpgrade', {
  subscription_id: 'SUB-001',
  old_plan: 'weekly_weightloss',
  new_plan: 'weekly_premium',
  value_increase: 50.00,
  new_value: 199.00,
  currency: 'MYR'
});

// Plan downgrade
fbq('trackCustom', 'PlanDowngrade', {
  subscription_id: 'SUB-001',
  old_plan: 'weekly_premium',
  new_plan: 'weekly_basic',
  value_decrease: 50.00,
  new_value: 99.00,
  currency: 'MYR'
});
```

### 2.3 Parameter Reference

| Parameter | Type | Use Case | Impact |
|---|---|---|---|
| `value` | float | Order/subscription value | REQUIRED for value optimization |
| `currency` | string | 'MYR' | REQUIRED with value |
| `content_ids` | array | Plan/product SKUs | Enables dynamic ads |
| `content_type` | string | 'product' or 'product_group' | Catalog matching |
| `content_name` | string | Human-readable plan name | Reporting |
| `content_category` | string | 'meal-plan', 'add-on' | Audience building |
| `num_items` | int | Number of meals/items | Reporting |
| `order_id` | string | Unique order ID | Deduplication |
| `predicted_ltv` | float | Expected lifetime value | Value optimization signal |
| `subscription_id` | string | Unique sub ID | Lifecycle tracking |

---

## 3. CONVERSIONS API (CAPI) SETUP <a name="3-capi-setup"></a>

### 3.1 Three Setup Methods — Decision Matrix

| Method | Cost | Setup Time | Technical Skill | Best For |
|---|---|---|---|---|
| **Partner Integration** (Shopify/WooCommerce plugin) | Free-$50/mo | 1-2 hours | Low | Shopify stores, standard events |
| **CAPI Gateway** (Meta-hosted) | $10-400/mo | 2-4 hours | Medium | Non-Shopify, no dev team |
| **Manual API** (custom code) | Dev time $500-5K | 1-4 weeks | High | Custom site, subscription lifecycle, full control |

### 3.2 Recommendation for Subscription Meal Delivery

**Start with Partner Integration + Manual CAPI for subscription events.**

Why: Partner integration handles standard funnel events (PageView through Purchase) automatically. Manual CAPI handles subscription-specific events that no plugin covers (RecurringPurchase, SubscriptionPause, etc.).

### 3.3 Manual CAPI Implementation

#### Prerequisites
1. Meta Business Manager account
2. Active Meta Pixel ID
3. System User access token (generated in Business Settings > System Users)
4. Your server environment (Node.js, Python, PHP, etc.)

#### API Endpoint
```
POST https://graph.facebook.com/v19.0/{PIXEL_ID}/events
```

#### Server-Side Event Structure (Python example)

```python
import requests
import hashlib
import time
import json

PIXEL_ID = 'YOUR_PIXEL_ID'
ACCESS_TOKEN = 'YOUR_SYSTEM_USER_TOKEN'
API_URL = f'https://graph.facebook.com/v19.0/{PIXEL_ID}/events'

def hash_data(value):
    """SHA-256 hash for PII — Meta requires this."""
    if value is None:
        return None
    return hashlib.sha256(value.strip().lower().encode('utf-8')).hexdigest()

def send_event(event_name, event_id, user_data, custom_data, event_time=None):
    """Send a single event to Meta CAPI."""
    payload = {
        'data': json.dumps([{
            'event_name': event_name,
            'event_time': event_time or int(time.time()),
            'event_id': event_id,  # MUST match Pixel event_id
            'event_source_url': 'https://mirra.my/checkout',
            'action_source': 'website',  # or 'app', 'phone_call', 'system_generated'
            'user_data': user_data,
            'custom_data': custom_data
        }]),
        'access_token': ACCESS_TOKEN
    }

    response = requests.post(API_URL, data=payload)
    return response.json()

# --- EXAMPLE: Purchase Event ---
user_data = {
    'em': [hash_data('customer@email.com')],     # hashed email
    'ph': [hash_data('+60123456789')],            # hashed phone
    'fn': hash_data('sarah'),                      # hashed first name
    'ln': hash_data('tan'),                        # hashed last name
    'ct': hash_data('kuala lumpur'),               # hashed city
    'st': hash_data('kl'),                         # hashed state
    'zp': hash_data('57000'),                      # hashed zip
    'country': hash_data('my'),                    # hashed country
    'external_id': [hash_data('CUST-12345')],     # your internal customer ID
    'client_ip_address': '103.x.x.x',            # user's IP
    'client_user_agent': 'Mozilla/5.0...',        # user's browser UA
    'fbc': 'fb.1.1234567890.AbCdEfGh',           # Facebook click ID (from _fbc cookie)
    'fbp': 'fb.1.1234567890.1234567890'           # Facebook browser ID (from _fbp cookie)
}

custom_data = {
    'value': 149.00,
    'currency': 'MYR',
    'content_ids': ['plan_weightloss_weekly'],
    'content_type': 'product',
    'content_name': 'Weekly Meal Plan - Weight Loss',
    'order_id': 'ORD-20260313-001',
    'num_items': 5,
    'predicted_ltv': 1788.00
}

result = send_event(
    event_name='Purchase',
    event_id='evt_purchase_ORD-20260313-001',  # SAME as Pixel event_id
    user_data=user_data,
    custom_data=custom_data
)

# --- EXAMPLE: Recurring Purchase (server-only, no Pixel equivalent) ---
recurring_data = {
    'value': 149.00,
    'currency': 'MYR',
    'content_ids': ['plan_weightloss_weekly'],
    'content_type': 'product',
    'order_id': 'ORD-20260320-001',
    'subscription_id': 'SUB-001',
    'renewal_number': 4
}

result = send_event(
    event_name='RecurringPurchase',  # Custom event name
    event_id='evt_recurring_ORD-20260320-001',
    user_data=user_data,
    custom_data=recurring_data,
    event_time=int(time.time())
)
```

#### action_source Values

| Value | When to Use |
|---|---|
| `website` | Browser-initiated events (purchase on site) |
| `app` | Mobile app events |
| `phone_call` | Phone order conversions |
| `chat` | WhatsApp/chat conversions |
| `system_generated` | Recurring charges, auto-renewals |
| `other` | Anything else |

For recurring subscription charges that fire automatically, use `action_source: 'system_generated'`.

### 3.4 Data Hashing Requirements

Meta requires SHA-256 hashing of all PII before sending. MUST be:
- Lowercase
- Trimmed (no leading/trailing whitespace)
- No formatting (phone: digits only, no dashes/spaces)

**Hash these fields:**
- `em` — email
- `ph` — phone (with country code, digits only: `60123456789`)
- `fn` — first name
- `ln` — last name
- `ct` — city
- `st` — state
- `zp` — zip/postal code
- `country` — 2-letter country code
- `external_id` — your customer ID
- `db` — date of birth (YYYYMMDD)
- `ge` — gender (m or f)

**DO NOT hash these:**
- `fbc` — Facebook click ID (send raw)
- `fbp` — Facebook browser ID (send raw)
- `client_ip_address` — send raw
- `client_user_agent` — send raw

---

## 4. EVENT DEDUPLICATION <a name="4-event-deduplication"></a>

### Why This Is Critical

Without deduplication, Meta counts the same conversion twice (once from Pixel, once from CAPI). This inflates conversion numbers, corrupts CPA calculations, and destroys campaign optimization.

### How It Works

Meta deduplicates when it receives two events with:
1. **Same `event_name`** (exact match, case-sensitive)
2. **Same `event_id`** (exact string match)
3. **Within 48-hour window**

### Implementation Pattern

```javascript
// STEP 1: Generate event_id ONCE on the client
// (This is the single source of truth)

function generateEventId(prefix) {
    return prefix + '_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
}

// STEP 2: Fire Pixel with event_id
var purchaseEventId = generateEventId('purchase');

fbq('track', 'Purchase', {
    value: 149.00,
    currency: 'MYR',
    content_ids: ['plan_weightloss_weekly']
}, { eventID: purchaseEventId });  // <-- eventID parameter

// STEP 3: Send same event_id to your server
fetch('/api/track-purchase', {
    method: 'POST',
    body: JSON.stringify({
        event_id: purchaseEventId,  // <-- SAME ID
        order_id: 'ORD-20260313-001',
        value: 149.00,
        // ... other data
    })
});

// STEP 4: Your server sends to CAPI with that same event_id
// (See Python example in Section 3.3)
```

### Common Dedup Mistakes

| Mistake | Result | Fix |
|---|---|---|
| Pixel sends `purchase_123`, CAPI sends `Purchase_123` | No dedup (case-sensitive) | Standardize naming |
| Pixel sends `ord-123`, CAPI sends `ord_123` | No dedup (different characters) | Generate once, share everywhere |
| event_id generated separately on client and server | Never matches | Generate on client, pass to server |
| Using user identifiers (email, fbp) for dedup | Does not work | Dedup uses event_name + event_id ONLY |
| Not sending event_id at all | Everything double-counted | Always include event_id |

### Server-Only Events (No Dedup Needed)

These events ONLY fire from your server, so deduplication is not required:
- RecurringPurchase (auto-renewals)
- SubscriptionPause
- SubscriptionCancel
- SubscriptionReactivate
- Offline conversion uploads

### Verification

In Events Manager > Diagnostics tab, check:
- "Duplicate pixel and server events" — should show high dedup rate
- "Server events not matched to pixel events" — investigate mismatches
- Target: close to 100% dedup rate for events sent from both sources

---

## 5. AGGREGATED EVENT MEASUREMENT (AEM) <a name="5-aem"></a>

### 2026 Update: 8-Event Limit Removed

As of June 2025, Meta removed the 8-event limit. All eligible standard and custom events are now automatically processed without manual prioritization. The old AEM configuration interface is gone.

### What This Means for You

- You no longer need to manually rank/prioritize events
- All events you fire (standard and custom) are eligible for optimization
- Meta handles aggregation automatically behind the scenes
- iOS opted-out users' conversions are still reported, but with some delay and modeling

### How AEM Still Works Under the Hood

For iOS users who opted out of tracking via ATT:
- Meta can only attribute ONE conversion event per user per domain
- Meta uses statistical modeling to estimate conversions
- Reporting may be delayed up to 72 hours
- Data is reported in aggregate (not individual-level)

### Practical Impact

Even though the 8-event limit is gone, you should still:
1. Ensure your highest-value events (Purchase, Subscribe) have the best data quality
2. Send as many user parameters as possible with these events
3. Focus CAPI implementation on revenue events first
4. Use value optimization (Section 6) so Meta knows WHICH purchases matter most

---

## 6. VALUE OPTIMIZATION FOR SUBSCRIPTIONS <a name="6-value-optimization"></a>

### What Value Optimization Does

Instead of treating all conversions equally, value optimization tells Meta: "Find me users who will spend MORE." For subscriptions, this means finding users who will subscribe longer and at higher tiers.

### 6.1 Sending Purchase Value

Every Purchase and RecurringPurchase event MUST include `value` and `currency`:

```javascript
// First purchase — send actual order value
fbq('track', 'Purchase', {
    value: 149.00,        // actual transaction value
    currency: 'MYR',
    content_ids: ['plan_weightloss_weekly']
}, { eventID: purchaseEventId });
```

### 6.2 Sending Predicted LTV

The `predicted_ltv` parameter tells Meta the expected lifetime value of this customer. This is the most powerful signal for subscription businesses.

```javascript
// Option A: Simple multiplier (e.g., average 8-month retention)
var predicted_ltv = order_value * 8;  // 149 * 8 = 1,192

// Option B: Tier-based prediction
var ltv_by_tier = {
    'trial': 500,
    'weekly_basic': 1200,
    'weekly_premium': 2400,
    'weekly_weightloss': 1800
};

fbq('track', 'Purchase', {
    value: 149.00,
    currency: 'MYR',
    predicted_ltv: ltv_by_tier['weekly_weightloss']
}, { eventID: purchaseEventId });
```

### 6.3 How to Calculate Predicted LTV

For a subscription meal delivery:

```
Predicted LTV = Monthly Price x Average Retention (months) x (1 + Upsell Rate)

Example:
- Monthly price: RM 149
- Average retention: 8 months
- Upsell rate: 15% upgrade to premium
- Predicted LTV = 149 x 8 x 1.15 = RM 1,371
```

Refine over time with actual data. Segment by:
- Acquisition source (Meta vs organic vs referral)
- Plan type (basic vs premium vs weight loss)
- Location (delivery zone)
- Quiz responses (health goals → retention predictor)

### 6.4 Value Rules for Audience Segments

In Meta Ads Manager > Events Manager > Value Rules:

| Segment | Value Multiplier | Rationale |
|---|---|---|
| Quiz completers | 1.3x | Higher intent = longer retention |
| Returning visitors (3+ visits) | 1.5x | Strong intent signal |
| Premium plan selectors | 2.0x | Higher ARPU |
| Referred customers | 1.4x | Social proof = stickier |
| Trial-only | 0.5x | Lower conversion rate |

### 6.5 Minimum Requirements for Value Optimization

- **30 attributed purchases** with value data in the past 7 days
- **At least 5 distinct values** (not all the same amount)
- Consistent `value` + `currency` on every Purchase event
- Campaign must use "Highest Value" or "Target ROAS" bid strategy

If you don't have 30 purchases/week yet, start with "Maximum Conversions" bid strategy and switch to value optimization once you hit volume.

---

## 7. SUBSCRIPTION LIFECYCLE TRACKING <a name="7-subscription-lifecycle"></a>

### 7.1 The Full Lifecycle

```
Lead → Trial → Active → [Paused] → [Resumed] → Churned → [Won Back]
                  |
                  +→ Upgraded
                  +→ Downgraded
                  +→ Recurring Purchase (each renewal)
```

### 7.2 Event Mapping

| Lifecycle Stage | Event Name | Standard/Custom | Source |
|---|---|---|---|
| Signs up | CompleteRegistration | Standard | Pixel + CAPI |
| Completes quiz | Lead | Standard | Pixel + CAPI |
| Starts trial | StartTrial | Standard | Pixel + CAPI |
| First paid order | Purchase | Standard | Pixel + CAPI |
| Subscribes | Subscribe | Standard | Pixel + CAPI |
| Each renewal | RecurringPurchase | Custom | CAPI only |
| Upgrades plan | PlanUpgrade | Custom | CAPI only |
| Downgrades plan | PlanDowngrade | Custom | CAPI only |
| Pauses | SubscriptionPause | Custom | CAPI only |
| Resumes | SubscriptionResume | Custom | CAPI only |
| Cancels | SubscriptionCancel | Custom | CAPI only |
| Win-back | SubscriptionReactivate | Custom | CAPI only |

### 7.3 Building Audiences from Lifecycle Events

In Meta Ads Manager, create Custom Audiences from these CAPI events:

| Audience | Definition | Use Case |
|---|---|---|
| High-LTV Subscribers | RecurringPurchase 6+ times | Lookalike source |
| At-Risk (Paused) | SubscriptionPause in last 30 days | Win-back campaign |
| Churned | SubscriptionCancel in last 90 days | Re-engagement |
| Trial Non-Converters | StartTrial but no Purchase in 14 days | Conversion campaign |
| Premium Upgraders | PlanUpgrade event | Lookalike for high-value |
| Won Back | SubscriptionReactivate | Exclude from win-back |

### 7.4 The High-LTV Lookalike Strategy

This is the most valuable audience you can build:

1. **Create source audience**: Custom Audience from customers with 6+ RecurringPurchase events AND total value > RM 900
2. **Create 1% Lookalike** from this source audience
3. **Use for prospecting campaigns** with value optimization enabled
4. **Refresh monthly** as more customers hit the threshold

This tells Meta: "Find me people who look like my BEST customers, not just any customer."

### 7.5 Sending Recurring Purchase Events

Your backend should fire this automatically on each subscription renewal:

```python
# Triggered by your payment system on each successful charge
def on_subscription_renewal(subscription, charge):
    send_event(
        event_name='RecurringPurchase',
        event_id=f'recurring_{charge.id}',
        user_data=build_user_data(subscription.customer),
        custom_data={
            'value': charge.amount,
            'currency': 'MYR',
            'content_ids': [subscription.plan_id],
            'content_type': 'product',
            'order_id': charge.id,
            'subscription_id': subscription.id,
            'renewal_number': subscription.renewal_count,
            'months_active': subscription.months_active,
            'predicted_ltv': calculate_remaining_ltv(subscription)
        },
        event_time=int(charge.created_at.timestamp())
    )

    # Also send as Purchase for value optimization
    # (Meta optimizes toward Purchase, not custom events)
    send_event(
        event_name='Purchase',
        event_id=f'purchase_{charge.id}',
        user_data=build_user_data(subscription.customer),
        custom_data={
            'value': charge.amount,
            'currency': 'MYR',
            'content_ids': [subscription.plan_id],
            'content_type': 'product',
            'order_id': charge.id
        },
        event_time=int(charge.created_at.timestamp())
    )
```

**Important:** Send renewals as BOTH `RecurringPurchase` (for audience building) AND `Purchase` (for value optimization). Meta can only optimize campaigns toward standard events.

### 7.6 Offline Conversions (Phone/WhatsApp Orders)

For orders taken via phone or WhatsApp:

```python
# After confirming a WhatsApp/phone order
def track_offline_order(order, customer):
    send_event(
        event_name='Purchase',
        event_id=f'offline_{order.id}',
        user_data={
            'em': [hash_data(customer.email)],
            'ph': [hash_data(customer.phone)],
            'fn': hash_data(customer.first_name),
            'ln': hash_data(customer.last_name),
            'country': hash_data('my'),
            'external_id': [hash_data(str(customer.id))]
        },
        custom_data={
            'value': order.total,
            'currency': 'MYR',
            'content_ids': [order.plan_id],
            'content_type': 'product',
            'order_id': order.id
        },
        event_time=int(order.confirmed_at.timestamp())
    )
```

**Upload rules:**
- Must be within 62 days of conversion
- Must be within 90 days of the user's last ad interaction
- Include as many user_data fields as possible for matching
- Use `action_source: 'phone_call'` or `action_source: 'chat'` for WhatsApp

---

## 8. iOS PRIVACY & FIRST-PARTY DATA <a name="8-ios-privacy"></a>

### 8.1 Current State of ATT (2026)

- iOS users are prompted to allow/deny tracking on app install
- ~75-85% of iOS users deny tracking (opt-out)
- This blocks: IDFA, third-party cookies, cross-app tracking
- This does NOT block: CAPI server-to-server data, first-party cookies, on-site behavior

### 8.2 How CAPI Bypasses Browser Restrictions

```
BROWSER RESTRICTIONS (affected):          CAPI (not affected):
- Third-party cookies blocked             - Server-to-server (no browser)
- Safari ITP limits cookies to 7 days     - Uses hashed first-party data
- Ad blockers strip pixel.js              - No JavaScript involved
- iOS ATT blocks IDFA                     - Matches on email/phone/IP
```

CAPI sends data directly from your server to Meta's server. No browser, no cookies, no JavaScript — so browser privacy measures don't apply.

### 8.3 What You CAN vs CANNOT Send

**CAN send (with consent):**
- Hashed email address
- Hashed phone number
- Hashed name, city, state, zip, country
- Customer's IP address
- Browser user agent
- Facebook click ID (`fbc` from URL parameter or cookie)
- Facebook browser ID (`fbp` from first-party cookie)
- Your internal customer ID (hashed)
- Purchase value, order details, subscription data
- Any on-site behavioral data collected with consent

**CANNOT send:**
- Raw (unhashed) PII via CAPI
- Data from users who explicitly opted out of YOUR data collection (respect your own privacy policy)
- IDFA from iOS users who denied ATT (you won't have it anyway)
- Cross-site browsing data
- Data from third-party sources without consent chain

### 8.4 First-Party Data Collection Best Practices

1. **Capture email EARLY** — quiz, lead magnet, account creation (before purchase)
2. **Capture phone** — delivery address form, WhatsApp opt-in
3. **Store `fbclid`** — when user arrives from Meta ad, the URL contains `?fbclid=xxx`. Capture and store it. Pass as `fbc` parameter.
4. **Preserve `_fbp` cookie** — Meta's first-party cookie. Read it server-side and include in CAPI calls.
5. **Login-based tracking** — logged-in users provide email every session. This is the most reliable identifier.
6. **Progressive profiling** — collect more data over time (quiz → account → order → profile)

### 8.5 The `fbc` and `fbp` Parameters

These are the two most impactful matching parameters after email:

```python
# Capture fbclid from URL when user arrives
# URL: https://mirra.my/plans?fbclid=AbCdEfGhIjKlMnOp
# Store in session/cookie

def get_fbc_from_url(request):
    fbclid = request.GET.get('fbclid')
    if fbclid:
        # Format: fb.{subdomain_index}.{creation_time}.{fbclid}
        fbc = f'fb.1.{int(time.time())}.{fbclid}'
        return fbc
    return None

def get_fbp_from_cookie(request):
    # Read Meta's _fbp first-party cookie
    return request.COOKIES.get('_fbp')
```

Always include both `fbc` and `fbp` in your CAPI user_data when available. These dramatically improve match rates.

---

## 9. EVENT MATCH QUALITY (EMQ) <a name="9-emq"></a>

### 9.1 What EMQ Is

Event Match Quality is Meta's score (1-10) measuring how well your server events can be matched to Meta user profiles. Higher EMQ = better optimization, lower CPAs.

### 9.2 Target Scores

| Event Type | Target EMQ | Minimum Acceptable |
|---|---|---|
| Purchase | 8.8 - 9.3 | 7.0 |
| AddToCart | 8.0+ | 6.5 |
| Lead | 7.5+ | 6.0 |
| PageView | 6.5 - 7.5 | 5.0 |
| ViewContent | 7.0+ | 5.5 |

Meta's internal benchmark is around 6/10. Aim for 8+ on revenue events.

### 9.3 Parameter Impact Ranking

Parameters ranked by matching impact (highest to lowest):

| Rank | Parameter | Impact | Notes |
|---|---|---|---|
| 1 | `em` (email) | HIGHEST | Tied to single person, used for login |
| 2 | `fbc` (click ID) | HIGHEST | Direct ad attribution link |
| 3 | `fbp` (browser ID) | HIGH | First-party cookie, session linking |
| 4 | `ph` (phone) | HIGH | Strong identifier, especially in MY/SEA |
| 5 | `external_id` | MEDIUM-HIGH | Your customer ID, cross-session |
| 6 | `client_ip_address` | MEDIUM | Helps with geo-matching |
| 7 | `client_user_agent` | MEDIUM | Browser fingerprint component |
| 8 | `fn` + `ln` (name) | MEDIUM | Combined with other signals |
| 9 | `ct` + `st` + `zp` | LOW-MEDIUM | Geographic confirmation |
| 10 | `country` | LOW | Broad, but helps narrow matching |
| 11 | `db` (date of birth) | LOW | Rarely available at checkout |
| 12 | `ge` (gender) | LOW | Rarely available at checkout |

### 9.4 How to Improve EMQ

**Quick wins (implement first):**
1. Enable Automatic Advanced Matching on your Pixel (Events Manager > Settings)
2. Always send `fbc` and `fbp` with CAPI events
3. Send hashed email with every server event
4. Send hashed phone number
5. Include `client_ip_address` and `client_user_agent`

**Medium effort:**
6. Capture and store `fbclid` from URL parameters in your database
7. Send `external_id` (your customer ID) consistently
8. Ensure email/phone formatting is consistent before hashing
9. Include geographic data (city, state, zip, country)

**Common mistakes that tank EMQ:**
| Mistake | Impact | Fix |
|---|---|---|
| Not trimming whitespace before hashing | Different hash = no match | `value.strip().lower()` |
| Hashing formatted phone (+60 12-345-6789) | Different hash | Strip to digits: `60123456789` |
| Not sending `fbc`/`fbp` | Lose best matching signals | Capture from cookie/URL |
| Different email casing (John@Email.com) | Different hash | Always lowercase before hash |
| Sending hashed IP address | Meta needs raw IP | Don't hash IP or user agent |
| Missing `external_id` | No cross-session linking | Always include your customer ID |

### 9.5 Checking Your EMQ

Events Manager > Data Sources > Your Pixel > Overview tab > Click on any event > "Event Match Quality" score shown.

Also check: Events Manager > Diagnostics tab for specific recommendations.

---

## 10. THIRD-PARTY ATTRIBUTION TOOLS <a name="10-attribution-tools"></a>

### 10.1 Do You Need One?

**At this stage (pre-launch / early): NO.** Meta's native tracking + CAPI is sufficient.

**When to consider:** Once you're spending RM 10,000+/month across 3+ channels and need to understand cross-channel attribution.

### 10.2 Tool Comparison

| Tool | Pricing (2026) | Best For | Platform | Key Feature |
|---|---|---|---|---|
| **Triple Whale** | $100-500/mo | Shopify-only stores | Shopify only | Clean dashboard, close to Meta's own numbers |
| **Northbeam** | $1,000+/mo | Multi-platform, analyst-driven teams | Any platform | True incrementality measurement, no over-attribution |
| **Hyros** | $500-2,000+/mo | High-ticket, phone sales | Any platform | AI call tracking, offline attribution |
| **Cometly** | $199-499/mo | Budget-friendly alternative | Any platform | Server-side tracking, UTM-based |
| **Polar Analytics** | $300-800/mo | DTC brands wanting simplicity | Shopify/custom | Cohort analysis, LTV tracking |

### 10.3 Decision Framework

```
Q: Are you Shopify-based?
  YES → Triple Whale (cheapest, easiest, Shopify-native)
  NO  → Continue below

Q: Monthly ad spend > RM 30,000?
  NO  → Meta native + CAPI is sufficient. Save the money.
  YES → Continue below

Q: Running ads on 3+ platforms (Meta, Google, TikTok)?
  YES → Northbeam (best cross-channel attribution)
  NO  → Continue below

Q: Significant phone/WhatsApp sales?
  YES → Hyros (best offline/call attribution)
  NO  → Cometly or Polar (budget-friendly, good enough)
```

### 10.4 For Mirra Specifically

**Recommendation: Start with Meta native + CAPI only.**

Reasons:
- Single-channel (Meta) at launch — no cross-channel attribution needed
- Subscription business with backend data — CAPI gives you everything
- WhatsApp orders can be tracked via offline conversion uploads
- Save RM 500-4,000/month for actual ad spend
- Revisit when scaling to RM 30K+/month ad spend across multiple platforms

---

## 11. PLATFORM-SPECIFIC SETUP <a name="11-platform-setup"></a>

### 11.1 If Using Shopify

**Native Integration (easiest):**
1. Shopify Admin > Sales Channels > Facebook & Instagram
2. Connect your Meta Business account
3. Set Data Sharing to **Maximum** (enables CAPI automatically)
4. Verify events in Meta Events Manager

**Limitations:**
- Standard events only (no custom subscription events)
- Third-party checkout apps (Recharge, Bold) may not be covered
- Need supplementary CAPI for subscription lifecycle events

**Recommended stack for Shopify + Subscriptions:**
- Shopify native integration for standard funnel events
- Recharge (or similar) for subscription management
- Elevar or Littledata for bridging Recharge events to CAPI
- Custom webhook → CAPI for lifecycle events (pause, cancel, reactivate)

### 11.2 If Using Custom Site

**Full manual implementation required:**
1. Install Meta Pixel base code on all pages
2. Implement standard event tracking in frontend JavaScript
3. Build CAPI integration in your backend
4. Implement event_id generation and sharing between client/server
5. Set up hashing utilities for PII
6. Configure webhook triggers for subscription lifecycle events

**Architecture:**
```
Frontend (JS)                   Backend (Python/Node/etc.)
    |                                    |
    |-- Pixel fires standard events      |
    |-- Generates event_id               |
    |-- Sends event_id to backend ------>|
    |                                    |-- CAPI fires same events
    |                                    |-- CAPI fires server-only events
    |                                    |-- Processes webhooks from
    |                                    |   payment system (Stripe, etc.)
    |                                    |-- Fires lifecycle events
```

### 11.3 WhatsApp Conversion Tracking

For click-to-WhatsApp ads:

**Challenge:** When a user clicks to WhatsApp, they leave your site. You lose browser tracking. The "conversion" (order placed via chat) happens in WhatsApp, not on your site.

**Solution: Offline conversion upload via CAPI**

```python
# When a WhatsApp order is confirmed by your team:
def track_whatsapp_order(order, customer_phone):
    send_event(
        event_name='Purchase',
        event_id=f'wa_order_{order.id}',
        user_data={
            'ph': [hash_data(customer_phone)],
            'em': [hash_data(customer.email)] if customer.email else [],
            'fn': hash_data(customer.first_name),
            'country': hash_data('my'),
            'external_id': [hash_data(str(customer.id))]
        },
        custom_data={
            'value': order.total,
            'currency': 'MYR',
            'content_ids': [order.plan_id],
            'content_type': 'product',
            'order_id': order.id
        },
        event_time=int(order.confirmed_at.timestamp())
    )
```

**Key considerations:**
- Phone number is the primary matching signal (user clicked from their phone)
- Upload within 62 days of conversion
- Use `action_source: 'chat'` for WhatsApp orders
- Track "Messaging Conversations Started" as a mid-funnel metric
- The gap between ad clicks and actual WhatsApp messages is typically 20-30%

### 11.4 WhatsApp Business Solution Providers (BSPs)

For better WhatsApp attribution, consider BSPs that capture click IDs:
- **WATI** — captures Meta click ID, matches to conversation and deal
- **Respond.io** — similar click ID tracking with CRM integration
- **Zoko** — end-to-end attribution from ad click to order

These are especially valuable if a significant portion of orders come through WhatsApp.

---

## 12. UTM STRATEGY <a name="12-utm-strategy"></a>

### 12.1 Dynamic UTM Template for Meta Ads

Set this in Meta Ads Manager > Ad level > URL Parameters field (NOT in the Website URL field):

```
utm_source=meta&utm_medium=paid_social&utm_campaign={{campaign.name}}&utm_id={{campaign.id}}&utm_content={{ad.name}}&utm_term={{adset.name}}&placement={{placement}}&ad_id={{ad.id}}
```

### 12.2 Naming Convention

**Campaign names:**
```
{objective}_{audience}_{offer}_{date}
```
Examples:
- `conv_lookalike1pct_trialpromo_2026q1`
- `conv_retarget_cart30d_winback_2026mar`
- `awareness_broad_brandstory_2026q1`
- `conv_highltv_premium_2026mar`

**Ad set names:**
```
{targeting}_{placement}_{bidstrategy}
```
Examples:
- `interest_healthfood_allplacements_maxconv`
- `lookalike_1pct_highltv_feed_valuebid`
- `retarget_visitorsnosub_stories_maxconv`

**Ad names:**
```
{creative_type}_{variant}_{format}
```
Examples:
- `hero_lifestyle_v1_feed45`
- `testimonial_sarah_v2_story`
- `ugc_unboxing_v1_reels`
- `boldtype_lowcal_v3_feed45`

### 12.3 Rules

- All lowercase, no spaces (use underscores)
- Never put UTMs in the Website URL field — use URL Parameters field only
- Dynamic placeholders `{{campaign.name}}` auto-populate from your ad structure
- Include `ad_id={{ad.id}}` for granular creative-level attribution
- Store UTM parameters in your database on landing — they're first-party data

---

## 13. DEBUGGING & VALIDATION <a name="13-debugging"></a>

### 13.1 Meta Pixel Helper (Chrome Extension)

1. Install "Meta Pixel Helper" from Chrome Web Store
2. Navigate to your site
3. Click the extension icon — shows all Pixel fires
4. Check: event name, parameters, event_id present
5. Green checkmark = event sent successfully
6. Warning/error = missing required parameters

### 13.2 Events Manager — Test Events

1. Go to Events Manager > Data Sources > Your Pixel
2. Click "Test Events" tab
3. Enter your website URL
4. Open your site and trigger events
5. Events appear in real-time in the Test Events panel
6. Verify both Pixel (browser) and CAPI (server) events appear
7. Check deduplication by looking for matching event_ids

### 13.3 Events Manager — Diagnostics

Check regularly for:
- "Duplicate pixel and server events" — dedup rate
- "Event match quality" — EMQ score per event
- "Missing parameters" — what data to add
- "Server events not matched" — dedup failures
- "Invalid parameters" — formatting issues

### 13.4 Payload Validation Checklist

For each CAPI event, verify:
- [ ] `event_name` matches Pixel event name exactly
- [ ] `event_time` is within 7 days (ideally within minutes)
- [ ] `event_id` matches Pixel eventID
- [ ] `action_source` is correct for the event type
- [ ] `user_data.em` is SHA-256 hashed, lowercase, trimmed
- [ ] `user_data.ph` is SHA-256 hashed, digits only (with country code)
- [ ] `user_data.fbc` is NOT hashed (raw)
- [ ] `user_data.fbp` is NOT hashed (raw)
- [ ] `user_data.client_ip_address` is NOT hashed (raw)
- [ ] `custom_data.value` is a number (not string)
- [ ] `custom_data.currency` is ISO 4217 code ('MYR')

### 13.5 CAPI Debug Mode

Add `test_event_code` to your payload during development:

```python
payload = {
    'data': json.dumps([{ ... }]),
    'access_token': ACCESS_TOKEN,
    'test_event_code': 'TEST12345'  # Get from Events Manager > Test Events
}
```

Events sent with test_event_code appear in Test Events panel but DO NOT affect your actual data or ad optimization.

---

## 14. IMPLEMENTATION CHECKLIST <a name="14-checklist"></a>

### Phase 1: Foundation (Week 1)

- [ ] Create Meta Business Manager (if not exists)
- [ ] Create Meta Pixel in Events Manager
- [ ] Generate System User access token for CAPI
- [ ] Install Pixel base code on all site pages
- [ ] Install Meta Pixel Helper Chrome extension
- [ ] Enable Automatic Advanced Matching in Pixel settings
- [ ] Set up `fbclid` capture on landing pages
- [ ] Set up `_fbp` cookie reading on server

### Phase 2: Standard Events (Week 2)

- [ ] Implement PageView (Pixel)
- [ ] Implement ViewContent (Pixel + CAPI)
- [ ] Implement AddToCart (Pixel + CAPI)
- [ ] Implement InitiateCheckout (Pixel + CAPI)
- [ ] Implement AddPaymentInfo (Pixel + CAPI)
- [ ] Implement Purchase (Pixel + CAPI) — with value + currency
- [ ] Implement Lead (Pixel + CAPI)
- [ ] Implement CompleteRegistration (Pixel + CAPI)
- [ ] Implement StartTrial (Pixel + CAPI) — if applicable
- [ ] Implement Subscribe (Pixel + CAPI)
- [ ] Generate and share event_id between Pixel and CAPI for all dual events
- [ ] Verify deduplication in Events Manager > Diagnostics

### Phase 3: Subscription Lifecycle (Week 3)

- [ ] Implement RecurringPurchase via CAPI (auto-renewals)
- [ ] Implement SubscriptionPause via CAPI
- [ ] Implement SubscriptionCancel via CAPI
- [ ] Implement SubscriptionReactivate via CAPI
- [ ] Implement PlanUpgrade / PlanDowngrade via CAPI
- [ ] Send renewals as both RecurringPurchase AND Purchase
- [ ] Set up offline conversion upload for WhatsApp/phone orders

### Phase 4: Optimization (Week 4)

- [ ] Check EMQ scores for all events — target 8+ for Purchase
- [ ] Add missing user_data parameters to improve EMQ
- [ ] Implement predicted_ltv on Purchase events
- [ ] Set up value rules in Events Manager
- [ ] Create Custom Audiences from lifecycle events
- [ ] Build High-LTV Lookalike Audience (once enough data)
- [ ] Configure UTM template in Ads Manager
- [ ] Set up dashboard to monitor conversion data quality

### Phase 5: Ongoing Monitoring

- [ ] Weekly: Check Events Manager > Diagnostics for errors
- [ ] Weekly: Monitor EMQ scores — investigate any drops
- [ ] Weekly: Verify deduplication rate stays near 100%
- [ ] Monthly: Refresh LTV predictions with actual data
- [ ] Monthly: Update High-LTV Lookalike source audience
- [ ] Quarterly: Audit all events firing correctly (test purchase flow end-to-end)

---

## QUICK REFERENCE: EVENT PRIORITY FOR CAMPAIGN OPTIMIZATION

When creating campaigns, optimize toward these events in this priority:

| Priority | Event | Campaign Type |
|---|---|---|
| 1 | Purchase (with value) | Conversion + Value Optimization |
| 2 | Subscribe | Subscription acquisition |
| 3 | StartTrial | Trial acquisition |
| 4 | Lead | Lead generation |
| 5 | InitiateCheckout | Mid-funnel optimization |
| 6 | AddToCart | Upper-funnel optimization |
| 7 | ViewContent | Awareness/traffic |

Custom events (RecurringPurchase, SubscriptionCancel, etc.) cannot be used as campaign optimization targets but are invaluable for audience building and reporting.

---

## Sources

- [Triple Whale — Facebook CAPI Guide](https://www.triplewhale.com/blog/facebook-capi)
- [DataAlly — How to Set Up Meta Conversions API 2026](https://www.dataally.ai/blog/how-to-set-up-meta-conversions-api)
- [Meta Business Help Center — Pixel Standard Events Specifications](https://www.facebook.com/business/help/402791146561655)
- [Meta for Developers — Pixel Reference](https://developers.facebook.com/docs/meta-pixel/reference)
- [Meta for Developers — Conversion Tracking](https://developers.facebook.com/docs/meta-pixel/implementation/conversion-tracking/)
- [Analyzify — Event Deduplication for Meta](https://analyzify.com/hub/event-deduplication-for-meta-conversions)
- [AGrowth — Event Deduplication in Meta Ads](https://agrowth.io/blogs/facebook-ads/event-deduplication-in-meta-ads)
- [Conversios — Meta AEM Explained](https://www.conversios.io/blog/meta-aggregated-event-measurement/)
- [Meta Business Help Center — About AEM](https://www.facebook.com/business/help/721422165168355)
- [Triple Whale — Event Match Quality](https://www.triplewhale.com/blog/event-match-quality)
- [Madgicx — Improve Event Match Quality](https://madgicx.com/blog/event-match-quality)
- [Analyzify — How to Improve Meta EMQ](https://analyzify.com/hub/how-to-improve-meta-event-match-quality)
- [Madgicx — Meta Ads LTV Prediction](https://madgicx.com/blog/meta-ads-ltv-prediction)
- [Angler AI — Predictive LTV-Based Bidding](https://www.getangler.ai/blog/predictive-ltv-based-bidding-on-meta-and-google-ads)
- [Angler AI — Meta Value Optimization Evolution](https://www.getangler.ai/blog/metas-value-optimization-evolution-how-brands-can-unlock-higher-roi-with-pltv-and-gross-margin-optimization)
- [Birch — Meta Value Optimization](https://bir.ch/blog/meta-value-optimization)
- [Ignite Visibility — Facebook Subscription Lifecycle Events](https://ignitevisibility.com/how-to-use-facebook-subscription-lifecycle-events/)
- [SeaMonster Studios — Acquiring Subscription Customers with Meta Ads](https://seamonsterstudios.com/2025/04/18/acquiring-subscription-customers-with-meta-ads/)
- [Littledata — Shopify to Meta CAPI](https://help.littledata.io/posts/how-it-works-shopify-to-meta-conversions-api)
- [Conversios — CAPI Gateway vs Manual Setup](https://www.conversios.io/blog/capi-gateway-vs-manual-setup/)
- [Stape — Meta CAPI Gateway vs Conversion API](https://stape.io/blog/meta-conversions-api-gateway-versus-conversion-api)
- [Elevar — Meta CAPI for Shopify Stores](https://getelevar.com/facebook/meta-capi-for-shopify-stores-why-and-how-to-implement/)
- [InsiderOne — Meta CAPI for Click-to-WhatsApp](https://academy.insiderone.com/docs/meta-conversions-api-for-click-to-whatsapp-ads)
- [Stape — WhatsApp Conversion API](https://stape.io/news/whatsapp-conversion-api)
- [Cometly — iOS Privacy Updates Affecting Ads 2026](https://www.cometly.com/post/ios-privacy-updates-affecting-ads)
- [wetracked.io — Meta Ads CAPI Explained 2026](https://www.wetracked.io/post/what-is-capi-meta-facebook-conversion-api)
- [HeadWest — Triple Whale vs Northbeam 2026](https://www.headwestguide.com/triple-whale-vs-northbeam)
- [SegmentStream — Triple Whale Alternatives 2026](https://segmentstream.com/blog/articles/triplewhale-alternatives)
- [AdManage — Triple Whale vs Northbeam](https://admanage.ai/blog/triple-whale-vs-northbeam)
- [Cometly — UTM Parameter Best Practices 2026](https://www.cometly.com/post/utm-parameter-tracking-best-practices)
- [Digital24 — UTM Tracking for Meta Ads](https://www.digitaltwentyfour.com/learn/utm-tracking-parameters-on-meta-ads/)
