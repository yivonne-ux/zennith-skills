# Autonomous Social Media Director — Deep Research
## Bloom & Bare | March 2026

---

# 1. INSTAGRAM GRAPH API — POSTING

## Authentication Setup

**Requirements:**
- Instagram Business or Creator account
- Connected Facebook Page
- Meta Developer App with approved permissions
- Server-side OAuth 2.0 flow (never expose secrets client-side)

**Permissions needed (Facebook Login path):**
- `instagram_basic`
- `instagram_content_publish`
- `pages_read_engagement`
- Optional: `ads_management`, `ads_read` (if user has Page role)

**Permissions needed (Instagram Login path):**
- `instagram_business_basic`
- `instagram_business_content_publish`
- Advanced or Standard Access level required

**Token:** Facebook Page access token (long-lived, 60 days; refresh before expiry)

## Core Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `POST /{IG_ID}/media` | POST | Create media container |
| `POST /{IG_ID}/media_publish` | POST | Publish container |
| `GET /{IG_CONTAINER_ID}?fields=status_code` | GET | Check publish eligibility |
| `GET /{IG_ID}/content_publishing_limit` | GET | Check rate limit usage |

**Base URL:** `https://graph.facebook.com/v25.0/`

## Single Image Post

```python
import requests
import time

IG_USER_ID = "YOUR_IG_BUSINESS_ACCOUNT_ID"
ACCESS_TOKEN = "YOUR_PAGE_ACCESS_TOKEN"
API_VERSION = "v25.0"
BASE_URL = f"https://graph.facebook.com/{API_VERSION}"

def post_single_image(image_url, caption):
    """Post a single image to Instagram."""

    # Step 1: Create media container
    container_url = f"{BASE_URL}/{IG_USER_ID}/media"
    container_params = {
        "image_url": image_url,  # Must be publicly accessible URL
        "caption": caption,
        "access_token": ACCESS_TOKEN,
    }
    resp = requests.post(container_url, params=container_params)
    container_id = resp.json()["id"]

    # Step 2: Wait for container to be ready
    status = "IN_PROGRESS"
    while status == "IN_PROGRESS":
        time.sleep(5)
        check = requests.get(
            f"{BASE_URL}/{container_id}",
            params={"fields": "status_code", "access_token": ACCESS_TOKEN}
        )
        status = check.json().get("status_code", "IN_PROGRESS")

    # Step 3: Publish
    publish_url = f"{BASE_URL}/{IG_USER_ID}/media_publish"
    publish_params = {
        "creation_id": container_id,
        "access_token": ACCESS_TOKEN,
    }
    result = requests.post(publish_url, params=publish_params)
    return result.json()
```

## Carousel Post (Up to 10 items)

```python
def post_carousel(image_urls, caption):
    """Post a carousel (2-10 images) to Instagram."""

    # Step 1: Create child containers for each image
    child_ids = []
    for url in image_urls:
        resp = requests.post(
            f"{BASE_URL}/{IG_USER_ID}/media",
            params={
                "image_url": url,
                "is_carousel_item": "true",
                "access_token": ACCESS_TOKEN,
            }
        )
        child_ids.append(resp.json()["id"])
        time.sleep(1)  # Respect rate limits

    # Step 2: Create parent carousel container
    carousel_resp = requests.post(
        f"{BASE_URL}/{IG_USER_ID}/media",
        params={
            "media_type": "CAROUSEL",
            "children": ",".join(child_ids),
            "caption": caption,
            "access_token": ACCESS_TOKEN,
        }
    )
    carousel_id = carousel_resp.json()["id"]

    # Step 3: Wait for processing
    status = "IN_PROGRESS"
    while status == "IN_PROGRESS":
        time.sleep(5)
        check = requests.get(
            f"{BASE_URL}/{carousel_id}",
            params={"fields": "status_code", "access_token": ACCESS_TOKEN}
        )
        status = check.json().get("status_code", "IN_PROGRESS")

    # Step 4: Publish
    result = requests.post(
        f"{BASE_URL}/{IG_USER_ID}/media_publish",
        params={
            "creation_id": carousel_id,
            "access_token": ACCESS_TOKEN,
        }
    )
    return result.json()
```

## Reels Post

```python
def post_reel(video_url, caption, cover_url=None):
    """Post a Reel to Instagram."""
    params = {
        "media_type": "REELS",
        "video_url": video_url,
        "caption": caption,
        "access_token": ACCESS_TOKEN,
    }
    if cover_url:
        params["cover_url"] = cover_url

    resp = requests.post(f"{BASE_URL}/{IG_USER_ID}/media", params=params)
    container_id = resp.json()["id"]

    # Wait for video processing (can take minutes)
    status = "IN_PROGRESS"
    while status == "IN_PROGRESS":
        time.sleep(10)
        check = requests.get(
            f"{BASE_URL}/{container_id}",
            params={"fields": "status_code", "access_token": ACCESS_TOKEN}
        )
        status = check.json().get("status_code", "IN_PROGRESS")

    result = requests.post(
        f"{BASE_URL}/{IG_USER_ID}/media_publish",
        params={"creation_id": container_id, "access_token": ACCESS_TOKEN}
    )
    return result.json()
```

## Stories Post

```python
def post_story(image_url):
    """Post a Story (Business accounts only)."""
    resp = requests.post(
        f"{BASE_URL}/{IG_USER_ID}/media",
        params={
            "media_type": "STORIES",
            "image_url": image_url,
            "access_token": ACCESS_TOKEN,
        }
    )
    container_id = resp.json()["id"]

    time.sleep(5)
    result = requests.post(
        f"{BASE_URL}/{IG_USER_ID}/media_publish",
        params={"creation_id": container_id, "access_token": ACCESS_TOKEN}
    )
    return result.json()
```

## Image Requirements

- **Format:** JPEG only (no MPO, JPS, or extended JPEG)
- **Carousel:** All images cropped to match first image's aspect ratio (default 1:1)
- **Recommended sizes:** 1080x1080 (square), 1080x1350 (4:5 portrait), 1080x566 (1.91:1 landscape)
- **Max file size:** 8MB for images
- **Image URL:** Must be publicly accessible (use cloud storage like S3, Cloudinary, or Filestack)

## Rate Limits

| Limit | Value |
|-------|-------|
| API-published posts per 24h | **100** (carousels = 1 post) |
| Carousel-specific limit | **50 published posts per 24h** |
| API requests per hour | **200 requests/hour** |
| Graph API calls per hour per user | **200** |

## Unsupported Features
- Shopping tags
- Branded content tags
- Filters
- Location tagging (varies by API version)
- Alt text added March 2025 (`alt_text` parameter)

---

# 2. INSTAGRAM INSIGHTS API

## Post-Level Metrics

**Endpoint:** `GET /{ig-media-id}/insights`

```python
def get_post_insights(media_id):
    """Get performance metrics for a specific post."""
    metrics = [
        "impressions",
        "reach",
        "engagement",
        "saved",
        "shares",
        "comments",
        "likes",
        "views",          # NEW as of March 2025
        "total_interactions",
    ]

    resp = requests.get(
        f"{BASE_URL}/{media_id}/insights",
        params={
            "metric": ",".join(metrics),
            "access_token": ACCESS_TOKEN,
        }
    )
    return resp.json()
```

## Account-Level Metrics

**Endpoint:** `GET /{IG_USER_ID}/insights`

```python
def get_account_insights(period="day", since=None, until=None):
    """Get account-level performance metrics."""
    # Day-level metrics
    day_metrics = [
        "reach",
        "follower_count",
        "views",              # Replaced "impressions" in v22
        "profile_views",      # Replaced in v22
    ]

    params = {
        "metric": ",".join(day_metrics),
        "period": period,  # "day", "week", "days_28"
        "access_token": ACCESS_TOKEN,
    }
    if since:
        params["since"] = since
    if until:
        params["until"] = until

    resp = requests.get(f"{BASE_URL}/{IG_USER_ID}/insights", params=params)
    return resp.json()


def get_audience_demographics():
    """Get follower demographics (requires 100+ followers)."""
    lifetime_metrics = [
        "audience_gender_age",
        "audience_locale",
        "audience_country",
        "audience_city",
        "online_followers",   # When followers are online (by hour)
    ]

    resp = requests.get(
        f"{BASE_URL}/{IG_USER_ID}/insights",
        params={
            "metric": ",".join(lifetime_metrics),
            "period": "lifetime",
            "access_token": ACCESS_TOKEN,
        }
    )
    return resp.json()
```

## 2025 Metric Deprecations (CRITICAL)

### January 2025 (Graph API v21) — DEPRECATED:
- `video_views` (non-Reels)
- `email_contacts`
- `profile_views` (time series)
- `website_clicks`
- `phone_call_clicks`
- `text_message_clicks`

### March 2025 (Graph API v22) — DEPRECATED:
- `impressions` (media-level) -> replaced by `views`
- `reel_plays` -> replaced by `views`
- `reel_replays` -> removed
- `reel_initial_plays` -> removed
- `story_impressions` -> replaced by `story_views`
- `carousel_album_impressions` -> replaced by `views`
- `profile_impressions` -> replaced by `profile_views`

### NEW Metrics (v22+):
- `views` — Unified view metric across all content types
- `story_views` — Story-specific views
- `profile_views` — New profile view metric

## Fetching All Recent Posts + Insights

```python
def get_all_posts_with_insights(limit=25):
    """Fetch recent posts and their performance data."""
    # Get recent media
    media_resp = requests.get(
        f"{BASE_URL}/{IG_USER_ID}/media",
        params={
            "fields": "id,caption,media_type,timestamp,permalink,like_count,comments_count",
            "limit": limit,
            "access_token": ACCESS_TOKEN,
        }
    )
    posts = media_resp.json().get("data", [])

    # Enrich with insights
    for post in posts:
        try:
            insights = get_post_insights(post["id"])
            post["insights"] = {
                item["name"]: item["values"][0]["value"]
                for item in insights.get("data", [])
            }
        except Exception:
            post["insights"] = {}

    return posts
```

---

# 3. MALAYSIAN FESTIVE CALENDAR 2026

## Federal Public Holidays (16 gazetted days)

| Date | Day | Holiday | Content Angle for Bloom & Bare |
|------|-----|---------|-------------------------------|
| **Jan 1** | Thu | New Year's Day | New year, new play goals |
| **Jan 17** | Sat | Israk & Mikraj* | — |
| **Feb 1** | Sun | Federal Territory Day (KL/Putrajaya/Labuan) | KL pride, local families |
| **Feb 1** | Sun | Thaipusam | Cultural celebration post |
| **Feb 17-18** | Tue-Wed | Chinese New Year | **MAJOR** — CNY crafts, red packet play, family reunion |
| **Mar 7** | Sat | Nuzul Al-Quran | Gratitude/reflection |
| **Mar 21-22** | Sat-Sun | Hari Raya Aidilfitri | **MAJOR** — Raya crafts, open house, family play |
| **May 1** | Fri | Labour Day | Appreciate parents, family time |
| **May 27-28** | Wed-Thu | Hari Raya Haji | Family togetherness |
| **May 31** | Sun | Wesak Day | Mindfulness, gentle play |
| **Jun 6** | Sat | Yang di-Pertuan Agong Birthday | — |
| **Jun 17** | Wed | Awal Muharram (Islamic New Year) | New beginnings |
| **Aug 26** | Wed | Maulidur Rasul* | — |
| **Aug 31** | Mon | Merdeka Day | **MAJOR** — Malaysia flag crafts, patriotic play |
| **Sep 16** | Wed | Malaysia Day | **MAJOR** — Malaysian pride, cultural diversity play |
| **Nov 8** | Sun | Deepavali | **MAJOR** — Diwali crafts, light play, rangoli |
| **Dec 25** | Fri | Christmas | **MAJOR** — Holiday crafts, winter wonderland play |

*Islamic dates subject to moon sighting confirmation.

## School Holidays 2026 (Group B — KL/Selangor)

| Period | Dates | Duration | Content Strategy |
|--------|-------|----------|------------------|
| **Term 1 Break** | Mar 21-29 | ~9 days | Overlaps Raya — family activities push |
| **Mid-Year Break** | May 23 - Jun 7 | ~16 days | **PEAK** — summer camp, workshops, birthday parties |
| **Term 2 Break** | Aug 22-30* | ~9 days | Merdeka activities, patriotic crafts |
| **End-of-Year** | Nov 21 - Jan 3, 2027* | ~6 weeks | **PEAK** — holiday programs, year-end parties |

*Approximate dates — confirm with MOE.

## Content Calendar Mega-Moments (Bloom & Bare Specific)

### Tier 1 — Full Campaign (2-3 weeks lead-up)
1. **Chinese New Year** (Feb 17-18) — CNY craft workshops, red packet art, dragon play
2. **Hari Raya Aidilfitri** (Mar 21-22) — Ketupat crafts, Raya-themed sensory play
3. **Mid-Year School Holidays** (May 23 - Jun 7) — Workshop series, camp registrations
4. **Merdeka + Malaysia Day** (Aug 31 + Sep 16) — Malaysian pride month
5. **Year-End Holidays** (Nov-Dec) — Christmas workshops, holiday party packages
6. **Deepavali** (Nov 8) — Rangoli art, light-themed sensory play

### Tier 2 — Single Feature Post
- Thaipusam, Labour Day, Wesak, Father's Day (Jun 21), Mother's Day (May 10)
- International Children's Day (Jun 1), World Play Day (May 28)
- Back to School (Jan, Jul)

### Tier 3 — Story/Quick Post
- Valentine's Day (Feb 14), Earth Day (Apr 22), Halloween (Oct 31)
- Monthly birthday celebration round-ups

---

# 4. CHILDREN'S PLAY SPACE INSTAGRAM BEST PRACTICES

## Benchmark Brands to Study

| Brand | Strategy | Why It Works |
|-------|----------|-------------|
| **Jellycat** | Character-driven, collectible hype | Emotional connection, UGC |
| **Toca Boca** | Colorful, kid-created content | Empowerment, play celebration |
| **KidZania** | Behind-the-scenes, event recaps | FOMO, social proof |
| **Play Factory** (MY) | Local play space reference | Malaysian market tactics |
| **Gymboree Play** | Educational play, parent tips | Value-add content |

## Optimal Posting Strategy

### Frequency
- **Feed posts:** 4-5x per week (3-4 Reels + 1-2 carousels/static)
- **Stories:** Daily (behind-the-scenes, polls, countdowns)
- **Carousels:** 2-3x per week (highest engagement format at 2.9% ER)

### Content Mix (Weekly)
| Day | Content Type | Template |
|-----|-------------|----------|
| Mon | Educational tip (carousel) | T7 — "5 sensory play ideas at home" |
| Tue | Reel — kids playing / workshop BTS | T5 — Photo story |
| Wed | Values/quote post | T2 — Brand values |
| Thu | Event/workshop promo | T3 — Event poster |
| Fri | Community spotlight / UGC repost | T5 — Photo story |
| Sat | Weekend activity post (Reel) | T1 — Schedule / weekend plan |
| Sun | Story-only (rest day) | Polls, Q&A, countdown |

### Children's Brand Industry Benchmarks (2025-2026)
- **Average engagement rate:** 2.4% (Reels), 2.3% (static), 2.9% (carousel)
- **Good ER:** 3-6%
- **Excellent ER:** 6%+
- **Views per Reel:** 70K+ for children's brands (with trending audio)
- **Posting sweet spot:** 2-5 posts/week with high quality > daily low quality

## Malaysian Market Specifics

### Hashtag Strategy
**Brand hashtags:**
- #BloomAndBare #BloomAndBarePlay #BukitJalilKids

**Community hashtags:**
- #KLMoms #MalaysianMoms #KLKids #BukitJalilMoms
- #KualaLumpurKids #MalaysiaParenting

**Activity hashtags:**
- #SensoryPlay #CreativePlay #KidsActivitiesKL
- #PlayBasedLearning #MessyPlay #KidsWorkshop

**Bilingual hashtags (EN + CN):**
- #亲子活动 #儿童乐园 #感官游戏 #创意玩乐

### Content That Works for Malaysian Family Audiences
1. **Bilingual captions** — EN primary, CN secondary (or alternating)
2. **Relatable parent humor** — "When you need 5 minutes of peace" with kids playing
3. **Educational value** — "Why sensory play matters for brain development"
4. **Social proof** — Birthday party recaps, workshop photos, parent testimonials
5. **FOMO triggers** — "Only 3 spots left for Saturday's workshop!"
6. **Behind-the-scenes** — Setting up activities, mascot appearances

---

# 5. SCHEDULING VIA API

## Native API Scheduling

The Instagram Graph API supports a `published_at` / `publish_time` parameter on the media container creation endpoint, allowing scheduling posts for future publication.

**However, the scheduling capability is limited:**
- Not all content types support scheduling
- Stories and Live cannot be scheduled via API
- The reliability varies

## Recommended Architecture: Self-Managed Scheduler

For a robust autonomous system, build your own scheduler:

```python
import schedule
import time
from datetime import datetime
import json

class InstagramScheduler:
    """Autonomous Instagram post scheduler."""

    def __init__(self, ig_user_id, access_token):
        self.ig_user_id = ig_user_id
        self.access_token = access_token
        self.queue = []  # List of scheduled posts

    def add_to_queue(self, post_data, publish_time):
        """
        post_data: {
            "type": "image" | "carousel" | "reel" | "story",
            "media_urls": [list of public URLs],
            "caption": "post caption",
        }
        publish_time: datetime object
        """
        self.queue.append({
            "data": post_data,
            "scheduled_for": publish_time,
            "status": "queued",
        })
        self.queue.sort(key=lambda x: x["scheduled_for"])

    def check_and_publish(self):
        """Check queue and publish any due posts."""
        now = datetime.now()
        for post in self.queue:
            if post["status"] == "queued" and post["scheduled_for"] <= now:
                try:
                    result = self._publish(post["data"])
                    post["status"] = "published"
                    post["result"] = result
                    post["published_at"] = now.isoformat()
                    print(f"Published: {post['data']['caption'][:50]}...")
                except Exception as e:
                    post["status"] = "failed"
                    post["error"] = str(e)
                    print(f"Failed: {e}")

    def _publish(self, post_data):
        """Route to correct publishing method."""
        if post_data["type"] == "carousel":
            return post_carousel(post_data["media_urls"], post_data["caption"])
        elif post_data["type"] == "image":
            return post_single_image(post_data["media_urls"][0], post_data["caption"])
        elif post_data["type"] == "reel":
            return post_reel(post_data["media_urls"][0], post_data["caption"])
        elif post_data["type"] == "story":
            return post_story(post_data["media_urls"][0])

    def run(self):
        """Run the scheduler loop."""
        schedule.every(1).minutes.do(self.check_and_publish)
        while True:
            schedule.run_pending()
            time.sleep(30)
```

## Production-Grade Architecture

For a real autonomous system, use:

1. **Cron job / Cloud Functions** — AWS Lambda or Google Cloud Functions triggered on schedule
2. **Database** — SQLite or PostgreSQL for post queue, status tracking, analytics
3. **Image hosting** — S3 bucket or Cloudinary for public image URLs
4. **Token management** — Auto-refresh long-lived tokens before 60-day expiry
5. **Error handling** — Retry logic with exponential backoff, alerting on failures
6. **Rate limit awareness** — Track API calls, respect 200/hour and 100 posts/day limits

```
ARCHITECTURE:

[Content Generator] --> [Post Queue DB] --> [Scheduler (cron)]
       |                      |                    |
       v                      v                    v
  [Image Renderer]     [Token Manager]     [Instagram API]
  (Pillow pipeline)    (auto-refresh)      (publish)
       |                                         |
       v                                         v
  [Cloud Storage]                          [Insights Collector]
  (S3/Cloudinary)                          (daily cron pull)
       |                                         |
       v                                         v
  [Public URLs]                            [Analytics DB]
                                                 |
                                                 v
                                          [Performance Engine]
                                          (score, learn, adapt)
```

---

# 6. PERFORMANCE FORENSICS — FEEDBACK LOOP

## What Defines a "Winning" Post

### 2026 Algorithm Priority Signals (ranked)
1. **Watch time %** — For video/Reels: >75% is gold
2. **Saves per 1,000 views** — >3% is excellent
3. **Shares per 1,000 views** — >2% signals high virality
4. **DM shares** — Top 3 ranking factor (strongest endorsement signal)
5. **Comment depth** — Comments >5 words = "high social relevance"
6. **Reply rate** — Replying within first hour boosts distribution
7. **3-second hold rate** — >60% on Reels = 5-10x more reach than <40%

### Bloom & Bare Scoring System

```python
def score_post(insights, media_type="IMAGE"):
    """
    Score a post's performance. Returns 0-100.
    Weights calibrated for children's play space brand.
    """
    score = 0
    views = insights.get("views", 0) or insights.get("reach", 1)

    # Engagement rate (35% weight)
    total_engagement = (
        insights.get("likes", 0) +
        insights.get("comments", 0) +
        insights.get("saved", 0) +
        insights.get("shares", 0)
    )
    er = (total_engagement / max(views, 1)) * 100
    if er >= 6: score += 35
    elif er >= 3: score += 25
    elif er >= 1.5: score += 15
    else: score += 5

    # Save rate (25% weight) — signals bookmark-worthy content
    save_rate = (insights.get("saved", 0) / max(views, 1)) * 100
    if save_rate >= 3: score += 25
    elif save_rate >= 1.5: score += 18
    elif save_rate >= 0.5: score += 10
    else: score += 3

    # Share rate (25% weight) — signals virality
    share_rate = (insights.get("shares", 0) / max(views, 1)) * 100
    if share_rate >= 2: score += 25
    elif share_rate >= 1: score += 18
    elif share_rate >= 0.3: score += 10
    else: score += 3

    # Comment quality (15% weight)
    comment_count = insights.get("comments", 0)
    if comment_count >= 20: score += 15
    elif comment_count >= 10: score += 10
    elif comment_count >= 3: score += 5
    else: score += 2

    return score


def classify_post(score):
    """Classify post performance tier."""
    if score >= 80: return "WINNER"     # Scale: create variations
    if score >= 60: return "STRONG"     # Keep: optimize caption/timing
    if score >= 40: return "AVERAGE"    # Analyze: what held it back?
    if score >= 20: return "WEAK"       # Learn: identify failure pattern
    return "KILL"                        # Drop: never repeat this format
```

## Autonomous Feedback Loop

```python
class PerformanceEngine:
    """
    Post -> Measure -> Learn -> Improve cycle.
    Runs daily to analyze recent posts and update strategy.
    """

    def __init__(self, db_path="bloom_analytics.db"):
        self.db_path = db_path

    def daily_audit(self):
        """Run daily at midnight. Pulls insights for posts 24-72h old."""
        recent_posts = get_all_posts_with_insights(limit=10)

        for post in recent_posts:
            score = score_post(post.get("insights", {}))
            tier = classify_post(score)

            # Store in DB
            self._store_post_analysis(post, score, tier)

            # Extract learnings
            self._extract_patterns(post, score, tier)

    def _extract_patterns(self, post, score, tier):
        """Extract what worked or didn't."""
        caption = post.get("caption", "")
        media_type = post.get("media_type", "")
        timestamp = post.get("timestamp", "")

        pattern = {
            "media_type": media_type,
            "has_emoji": any(ord(c) > 127 for c in caption),
            "caption_length": len(caption),
            "has_cta": any(cta in caption.lower() for cta in [
                "book now", "link in bio", "dm us", "comment below",
                "save this", "share with", "tag a friend"
            ]),
            "has_question": "?" in caption,
            "day_of_week": timestamp[:10] if timestamp else "",
            "is_bilingual": any('\u4e00' <= c <= '\u9fff' for c in caption),
            "score": score,
            "tier": tier,
        }
        return pattern

    def get_winning_patterns(self):
        """Analyze what content patterns produce winners."""
        # Query DB for patterns of WINNER and STRONG posts
        # Compare against WEAK and KILL posts
        # Return actionable insights like:
        # - "Carousels with bilingual captions score 2.3x higher"
        # - "Posts with questions get 40% more comments"
        # - "Tuesday 10am posts outperform Monday posts by 35%"
        pass

    def recommend_next_post(self):
        """Based on patterns, recommend what to post next."""
        # Analyze:
        # 1. What content type has been performing best?
        # 2. What day/time slot is underutilized?
        # 3. What topic hasn't been covered recently?
        # 4. What template type (T1-T8) has highest avg score?
        # 5. Is there a festive moment coming in the next 7 days?
        pass
```

## Industry Benchmarks — Children's Brands on Instagram (2025-2026)

| Metric | Poor | Average | Good | Excellent |
|--------|------|---------|------|-----------|
| Engagement Rate | <1% | 1-2.4% | 2.4-6% | >6% |
| Save Rate | <0.3% | 0.3-1% | 1-3% | >3% |
| Share Rate | <0.2% | 0.2-0.5% | 0.5-2% | >2% |
| Comments per post | <2 | 2-5 | 5-15 | >15 |
| Reel views (10K followers) | <500 | 500-2K | 2K-10K | >10K |
| Story completion rate | <50% | 50-65% | 65-80% | >80% |
| Follower growth/month | <1% | 1-3% | 3-5% | >5% |
| Carousel swipe-through | <30% | 30-50% | 50-70% | >70% |

## Optimal Posting Times for Malaysian Audience

| Time Slot | Audience | Why |
|-----------|----------|-----|
| **7:00-8:30 AM** | Parents during breakfast/school run | Catching morning scroll |
| **12:00-1:00 PM** | Lunch break parents | Mid-day check |
| **8:00-10:00 PM** | Parents after kids' bedtime | **PRIME TIME** — highest engagement |
| **Saturday 9-11 AM** | Weekend planning parents | "What to do today?" moment |

Use `online_followers` API metric to validate and refine for Bloom & Bare's specific audience.

---

# 7. FULL SYSTEM ARCHITECTURE

```
+------------------------------------------------------------------+
|                AUTONOMOUS SOCIAL MEDIA DIRECTOR                    |
+------------------------------------------------------------------+
|                                                                    |
|  [1. CONTENT BRAIN]                                               |
|  ├── Festive Calendar Engine (Malaysian 2026)                     |
|  ├── Content Taxonomy (T1-T8 templates)                           |
|  ├── Caption Generator (bilingual EN/CN)                          |
|  ├── Hashtag Engine (brand + community + activity)                |
|  └── Grid Planner (BOLD|PHOTO|CLEAN row rhythm)                  |
|                                                                    |
|  [2. DESIGN ENGINE]                                               |
|  ├── Pillow Renderer (bloom_core.py pipeline)                     |
|  ├── Template System (8 archetypes)                               |
|  ├── Mascot Compositor (6 characters, rotation)                   |
|  ├── Font Renderer (DX Lactos + Mabry Pro)                       |
|  └── Post-Process (paper texture + grain)                         |
|                                                                    |
|  [3. PUBLISHING ENGINE]                                           |
|  ├── Instagram Graph API Client                                    |
|  ├── Post Queue (SQLite)                                          |
|  ├── Scheduler (cron-based)                                       |
|  ├── Token Manager (auto-refresh)                                 |
|  └── Image Host (S3/Cloudinary -> public URLs)                    |
|                                                                    |
|  [4. ANALYTICS ENGINE]                                            |
|  ├── Insights Collector (daily pull)                              |
|  ├── Post Scorer (0-100 scoring system)                           |
|  ├── Pattern Extractor (what works/fails)                         |
|  ├── Audience Demographics Tracker                                |
|  └── Competitor Monitor                                           |
|                                                                    |
|  [5. INTELLIGENCE LOOP]                                           |
|  ├── Performance Forensics (daily)                                |
|  ├── Weekly Strategy Report                                       |
|  ├── Content Recommendation Engine                                |
|  ├── A/B Test Tracker (caption, time, format)                    |
|  └── Festive Content Pre-loader (2-week lookahead)               |
|                                                                    |
+------------------------------------------------------------------+
```

## Implementation Priority

1. **Phase 1 (Week 1-2):** Instagram API auth + single image posting + insights pulling
2. **Phase 2 (Week 3-4):** Carousel posting + scheduler + post queue DB
3. **Phase 3 (Week 5-6):** Analytics engine + scoring system + daily audit
4. **Phase 4 (Week 7-8):** Content Brain + festive calendar + caption generator
5. **Phase 5 (Week 9-12):** Intelligence loop + pattern learning + autonomous recommendations

---

## Sources

### Instagram Graph API — Posting
- [Meta Official: Content Publishing](https://developers.facebook.com/docs/instagram-platform/content-publishing/)
- [Instagram Graph API: Complete Developer Guide 2026](https://elfsight.com/blog/instagram-graph-api-complete-developer-guide-for-2026/)
- [API to Post to Instagram 2026: Code Examples](https://zernio.com/blog/api-to-post-to-instagram)
- [Instagram API 2026: Complete Developer Guide](https://getlate.dev/blog/instagram-api)
- [Instagram Graph API 2026: OAuth Setup, Rate Limits & Code](https://zernio.com/blog/instagram-graph-api)
- [GitHub: instagram_simple_post (Python carousel example)](https://github.com/remc0r/instagram_simple_post)

### Instagram Insights API
- [Meta Official: Instagram User Insights](https://developers.facebook.com/docs/instagram-platform/api-reference/instagram-user/insights/)
- [Instagram Insights Metrics Deprecation April 2025](https://docs.emplifi.io/platform/latest/home/instagram-insights-metrics-deprecation-april-2025)
- [Instagram Insights Field Changes March 2025](https://docs.supermetrics.com/docs/instagram-insights-field-changes-march-25-2025)
- [How to Use Instagram API for Social Media Analytics](https://www.getphyllo.com/post/how-to-use-instagram-api-for-social-media-analytics)

### Malaysian Calendar
- [Time and Date: Malaysia Holidays 2026](https://www.timeanddate.com/holidays/malaysia/2026)
- [Calendar Malaysia: Public Holidays 2026](https://calendarmalaysia.com/public-holidays-2026/)
- [Malaysia Public Holiday 2026: Full List](https://quickhr.my/resources/blog/malaysia-public-holiday-2026)
- [Malaysia School Holidays 2026](https://cutisekolah.com.my/en/public-holidays-2026/)

### Instagram Best Practices & Benchmarks
- [Instagram Best Practices 2026 — Sprout Social](https://sproutsocial.com/insights/instagram-best-practices/)
- [How the Instagram Algorithm Works: 2026 Guide — Buffer](https://buffer.com/resources/instagram-algorithms/)
- [2025 Children and Baby Industry Benchmarks — Dash Social](https://www.dashsocial.com/social-media-benchmarks/children-and-baby-industry)
- [Instagram Engagement Rate Benchmark 2026](https://influenceflow.io/resources/instagram-engagement-rate-benchmark-complete-2026-guide-for-creators-brands/)
- [2026 Social Media Benchmarks — Social Insider](https://www.socialinsider.io/social-media-benchmarks/instagram)

### Scheduling
- [Instagram Scheduling API 2026](https://getlate.dev/instagram)
- [Schedule & Publish Instagram with Facebook Graph API — n8n](https://n8n.io/workflows/4498-schedule-and-publish-all-instagram-content-types-with-facebook-graph-api/)
- [Now You Can Schedule Posts with Instagram Graph API](https://business.instagram.com/blog/instagram-api-features-updates)

### Performance & Algorithm
- [Instagram Algorithm 2026: Complete Analysis — Hootsuite](https://blog.hootsuite.com/instagram-algorithm/)
- [Content Strategy for Instagram 2026 — Brafton](https://www.brafton.com/blog/social-media/content-strategy-for-instagram/)
- [How to Go Viral on Instagram in 2026](https://turrboo.com/blog/how-to-go-viral-on-instagram)
