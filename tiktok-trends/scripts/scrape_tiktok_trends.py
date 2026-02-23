#!/usr/bin/env python3
"""TikTok Creative Center scraper using Playwright.

Scrapes ads.tiktok.com/business/creativecenter (public, no auth) for:
- Trending hashtags by country
- Trending sounds/music
- Top ads showcase
- Keyword insights

Usage:
    python3 scrape_tiktok_trends.py --type hashtags --country MY
    python3 scrape_tiktok_trends.py --type sounds --country MY
    python3 scrape_tiktok_trends.py --type top-ads --country MY
    python3 scrape_tiktok_trends.py --type keyword --query "vegan food"
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timezone


RELEVANCE_KEYWORDS = {
    "food": ["vegan", "plant-based", "recipe", "cooking", "foodie", "healthy", "organic",
             "rendang", "sambal", "nasi", "makan", "food", "snack", "superfood", "nutrition"],
    "fashion": ["fashion", "streetwear", "sustainable", "outfit", "ootd", "style", "clothing",
                "accessories", "tshirt", "hoodie", "print", "design", "delulu"],
    "home": ["home", "decor", "wellness", "aromatherapy", "candle", "lifestyle", "minimalist",
             "cozy", "interior", "room", "aesthetic"],
    "mobility": ["travel", "commute", "bag", "accessory", "gadget", "portable"],
    "marketing": ["ads", "ugc", "marketing", "ecommerce", "shopee", "tiktok shop", "business",
                  "entrepreneur", "brand", "sell", "dropship"],
}


def score_relevance(text: str) -> tuple[str, int]:
    """Score text relevance to GAIA categories."""
    text_lower = text.lower()
    best_cat = "general"
    best_score = 0

    for category, keywords in RELEVANCE_KEYWORDS.items():
        matches = sum(1 for kw in keywords if kw in text_lower)
        score = min(10, matches * 3)
        if score > best_score:
            best_score = score
            best_cat = category

    return best_cat, max(1, best_score)


def check_playwright():
    try:
        from playwright.sync_api import sync_playwright
        return True
    except ImportError:
        print("Error: playwright not installed. Run: pip3 install playwright && python3 -m playwright install chromium")
        return False


def scrape_hashtags(country: str = "MY", max_results: int = 30) -> dict:
    """Scrape trending hashtags from TikTok Creative Center via API interception."""
    from playwright.sync_api import sync_playwright

    url = f"https://ads.tiktok.com/business/creativecenter/inspiration/popular/hashtag/pc/en?countryCode={country}&period=7"
    trends = []
    api_data = []

    print(f"[tiktok] Scraping trending hashtags for {country}...")

    def handle_response(response):
        """Intercept API responses for hashtag data."""
        try:
            if "popular/hashtag/list" in response.url or "trending/hashtag" in response.url:
                data = response.json()
                if isinstance(data, dict):
                    items = data.get("data", {}).get("list", data.get("data", {}).get("hashtag_list", []))
                    if isinstance(items, list):
                        api_data.extend(items)
                        print(f"[tiktok] API intercepted: {len(items)} hashtags")
        except Exception:
            pass

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        )
        page = context.new_page()
        page.on("response", handle_response)

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)

            for _ in range(3):
                page.evaluate("window.scrollBy(0, 800)")
                time.sleep(2)

            # Method 1: Use intercepted API data
            if api_data:
                for item in api_data[:max_results]:
                    name = item.get("hashtag_name", item.get("name", ""))
                    if not name:
                        continue
                    if not name.startswith("#"):
                        name = "#" + name
                    views = item.get("publish_cnt", item.get("video_views", item.get("view_count", "N/A")))
                    growth = item.get("trend", item.get("growth_rate", "N/A"))
                    if isinstance(growth, (int, float)):
                        growth = f"{growth:+.1f}%"
                    category, score = score_relevance(name)
                    trends.append({
                        "rank": len(trends) + 1,
                        "name": name,
                        "views": str(views),
                        "growth": str(growth),
                        "gaia_relevance": category,
                        "relevance_score": score,
                    })
                    print(f"[tiktok] #{len(trends)}: {name} ({views}) — {category} ({score}/10)")

            # Method 2: DOM fallback with better selectors
            if not trends:
                # Try table rows with actual hashtag text
                rows = page.query_selector_all('table tbody tr')
                if not rows:
                    rows = page.query_selector_all('[class*="CardPc"], [class*="RankingCard"]')

                for row in rows:
                    if len(trends) >= max_results:
                        break
                    try:
                        text = row.inner_text().strip()
                        if not text or len(text) < 3:
                            continue
                        lines = [l.strip() for l in text.split("\n") if l.strip()]
                        hashtag_name = ""
                        views = ""
                        growth = ""

                        for line in lines:
                            if line.startswith("#") and len(line) > 2:
                                hashtag_name = line
                            elif re.search(r'\d+\.?\d*[KMBkmb]', line):
                                if not views:
                                    views = line
                                else:
                                    growth = line
                            elif "%" in line and re.search(r'[\d.]+%', line):
                                growth = line

                        # Skip numeric-only "hashtags" (garbage from UI elements)
                        if hashtag_name and not re.match(r'^#\d+$', hashtag_name):
                            category, score = score_relevance(hashtag_name + " " + " ".join(lines))
                            trends.append({
                                "rank": len(trends) + 1,
                                "name": hashtag_name,
                                "views": views or "N/A",
                                "growth": growth or "N/A",
                                "gaia_relevance": category,
                                "relevance_score": score,
                                "raw": text[:200],
                            })
                            print(f"[tiktok] #{len(trends)}: {hashtag_name} ({views}) — {category} ({score}/10)")
                    except Exception:
                        continue

            # Method 3: Regex fallback from page text
            if not trends:
                page_text = page.inner_text("body")
                hashtags = re.findall(r'#[A-Za-z]\w{2,}', page_text)
                seen = set()
                for tag in hashtags:
                    if tag.lower() not in seen and len(seen) < max_results:
                        seen.add(tag.lower())
                        category, score = score_relevance(tag)
                        trends.append({
                            "rank": len(trends) + 1,
                            "name": tag,
                            "views": "N/A",
                            "growth": "N/A",
                            "gaia_relevance": category,
                            "relevance_score": score,
                        })

            # Method 4: Web scraping fallback - try public trending page if Creative Center fails
            if not trends:
                print("[tiktok] No results from API/DOM methods. Falling back to public trending page scrape...")
                public_url = "https://www.tiktok.com"
                try:
                    page.goto(public_url, wait_until="networkidle", timeout=30000)
                    time.sleep(4)
                    
                    # Try to scroll and look for trending content
                    for _ in range(5):
                        page.evaluate("window.scrollBy(0, 1500)")
                        time.sleep(1.5)
                    
                    # Get all visible text from the page
                    page_text = page.inner_text("body")
                    
                    # Look for trending hashtags in various formats
                    patterns = [
                        r'#\w{3,}',  # Basic hashtag pattern
                        r'trending.*?#(\w+)',  # "trending #hashtag" pattern
                        r'#\w+.*?view.*?\d+[KMBkmb]',  # Hashtag with views
                    ]
                    
                    found_tags = set()
                    for pattern in patterns:
                        matches = re.findall(pattern, page_text, re.IGNORECASE)
                        for match in matches:
                            if isinstance(match, tuple):
                                match = match[0] if match[0] else match[1] if len(match) > 1 else ""
                            if match:
                                tag = f"#{match}" if not match.startswith("#") else match
                                if len(tag) > 2 and len(tag) < 50:
                                    found_tags.add(tag.lower())
                    
                    for tag in found_tags:
                        if len(trends) >= max_results:
                            break
                        category, score = score_relevance(tag)
                        trends.append({
                            "rank": len(trends) + 1,
                            "name": tag,
                            "views": "N/A",
                            "growth": "N/A",
                            "gaia_relevance": category,
                            "relevance_score": score,
                            "source": "public-trending-page-fallback",
                        })
                    print(f"[tiktok] Public page fallback: {len(trends)} hashtags found")
                except Exception as e:
                    print(f"[tiktok] Public page fallback failed: {e}")

        except Exception as e:
            print(f"[tiktok] Error: {e}")
        finally:
            browser.close()

    return {
        "type": "hashtags",
        "country": country,
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "trends": trends,
        "total_found": len(trends),
    }


def scrape_sounds(country: str = "MY", max_results: int = 20) -> dict:
    """Scrape trending sounds from TikTok Creative Center."""
    from playwright.sync_api import sync_playwright

    url = f"https://ads.tiktok.com/business/creativecenter/inspiration/popular/music/pc/en?countryCode={country}&period=7"
    trends = []

    print(f"[tiktok] Scraping trending sounds for {country}...")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1280, "height": 900})
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)

            for _ in range(3):
                page.evaluate("window.scrollBy(0, 800)")
                time.sleep(2)

            rows = page.query_selector_all('tr, [class*="music"], [class*="song"], [class*="item"]')

            for row in rows:
                if len(trends) >= max_results:
                    break
                try:
                    text = row.inner_text().strip()
                    if not text or len(text) < 5:
                        continue
                    lines = [l.strip() for l in text.split("\n") if l.strip()]
                    if lines:
                        trends.append({
                            "rank": len(trends) + 1,
                            "title": lines[0][:100],
                            "artist": lines[1][:100] if len(lines) > 1 else "Unknown",
                            "usage_count": lines[2] if len(lines) > 2 else "N/A",
                            "raw": text[:200],
                        })
                except Exception:
                    continue

            if not trends:
                page_text = page.inner_text("body")
                print(f"[tiktok] Fallback: page has {len(page_text)} chars. May need updated selectors.")

        except Exception as e:
            print(f"[tiktok] Error: {e}")
        finally:
            browser.close()

    return {
        "type": "sounds",
        "country": country,
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "trends": trends,
        "total_found": len(trends),
    }


def scrape_top_ads(country: str = "MY", max_results: int = 20) -> dict:
    """Scrape top ads from TikTok Creative Center."""
    from playwright.sync_api import sync_playwright

    url = f"https://ads.tiktok.com/business/creativecenter/inspiration/topads/pc/en?countryCode={country}&period=7"
    ads = []

    print(f"[tiktok] Scraping top ads for {country}...")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1280, "height": 900})
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)

            for _ in range(3):
                page.evaluate("window.scrollBy(0, 800)")
                time.sleep(2)

            cards = page.query_selector_all('[class*="card"], [class*="ad-item"], [class*="video"]')

            for card in cards:
                if len(ads) >= max_results:
                    break
                try:
                    text = card.inner_text().strip()
                    if not text or len(text) < 10:
                        continue
                    lines = [l.strip() for l in text.split("\n") if l.strip()]
                    category, score = score_relevance(text)
                    ads.append({
                        "rank": len(ads) + 1,
                        "title": lines[0][:200] if lines else "",
                        "description": " ".join(lines[1:3])[:300] if len(lines) > 1 else "",
                        "gaia_relevance": category,
                        "relevance_score": score,
                        "raw": text[:300],
                    })
                except Exception:
                    continue

        except Exception as e:
            print(f"[tiktok] Error: {e}")
        finally:
            browser.close()

    return {
        "type": "top-ads",
        "country": country,
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "ads": ads,
        "total_found": len(ads),
    }


def scrape_keyword(query: str) -> dict:
    """Search TikTok keyword insights."""
    from playwright.sync_api import sync_playwright

    url = f"https://ads.tiktok.com/business/creativecenter/keyword-insights/pc/en?keyword={query}"
    results = []

    print(f"[tiktok] Searching keyword insights for: {query}")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1280, "height": 900})
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)

            page_text = page.inner_text("body")
            category, score = score_relevance(query)

            results.append({
                "keyword": query,
                "page_content": page_text[:2000],
                "gaia_relevance": category,
                "relevance_score": score,
            })

        except Exception as e:
            print(f"[tiktok] Error: {e}")
        finally:
            browser.close()

    return {
        "type": "keyword",
        "query": query,
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "results": results,
    }


def main():
    parser = argparse.ArgumentParser(description="Scrape TikTok Creative Center")
    parser.add_argument("--type", "-t", required=True,
                        choices=["hashtags", "sounds", "top-ads", "keyword"],
                        help="Type of data to scrape")
    parser.add_argument("--country", "-c", default="MY", help="Country code (default: MY)")
    parser.add_argument("--query", "-q", help="Search query (for keyword type)")
    parser.add_argument("--max-results", "-n", type=int, default=20, help="Max results")
    parser.add_argument("--output", "-o", help="Output JSON file path")
    args = parser.parse_args()

    if not check_playwright():
        sys.exit(1)

    if args.type == "hashtags":
        result = scrape_hashtags(args.country, args.max_results)
    elif args.type == "sounds":
        result = scrape_sounds(args.country, args.max_results)
    elif args.type == "top-ads":
        result = scrape_top_ads(args.country, args.max_results)
    elif args.type == "keyword":
        if not args.query:
            parser.error("--query required for keyword type")
        result = scrape_keyword(args.query)

    output_path = args.output or f"/tmp/tiktok-trends-{args.type}.json"
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print(f"\n[tiktok] Saved to {output_path}")
    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
