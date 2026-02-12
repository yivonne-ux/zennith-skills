#!/usr/bin/env python3
"""Instagram Reels/Hashtag trends scraper using Playwright.

Scrapes public Instagram hashtag and explore pages for:
- Trending content formats
- Caption patterns and hooks
- Hashtag strategies
- Engagement signals

Note: Instagram may block automated access. This scraper handles
rate limiting and login walls gracefully.

Usage:
    python3 scrape_ig_trends.py --hashtag veganfood --max-posts 20
    python3 scrape_ig_trends.py --hashtag "veganfood,plantbased" --max-posts 15
    python3 scrape_ig_trends.py --explore --max-posts 20
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from datetime import datetime, timezone


FORMAT_KEYWORDS = {
    "tutorial": ["how to", "tutorial", "recipe", "step by step", "easy", "diy", "guide", "tips"],
    "pov": ["pov", "point of view", "when you", "that moment"],
    "before_after": ["before", "after", "transformation", "glow up", "results"],
    "grwm": ["grwm", "get ready", "getting ready", "morning routine"],
    "transition": ["transition", "outfit change", "switch"],
    "product_review": ["review", "unboxing", "haul", "try on", "first impression", "honest"],
    "day_in_life": ["day in", "vlog", "daily", "routine", "what i eat"],
}

RELEVANCE_KEYWORDS = {
    "food": ["vegan", "plant-based", "recipe", "cooking", "foodie", "healthy", "organic",
             "meal", "snack", "rendang", "sambal", "food"],
    "fashion": ["fashion", "ootd", "outfit", "style", "streetwear", "sustainable"],
    "home": ["home", "decor", "wellness", "aromatherapy", "aesthetic", "minimalist"],
    "marketing": ["business", "marketing", "brand", "sell", "ecommerce", "ugc"],
}


def detect_format(text: str) -> str:
    text_lower = text.lower()
    for fmt, keywords in FORMAT_KEYWORDS.items():
        if any(kw in text_lower for kw in keywords):
            return fmt
    return "other"


def score_relevance(text: str) -> tuple[str, int]:
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
        print("Error: playwright not installed.")
        return False


def scrape_hashtag(hashtag: str, max_posts: int = 20) -> list:
    """Scrape posts from an Instagram hashtag page."""
    from playwright.sync_api import sync_playwright

    tag = hashtag.lstrip("#")
    url = f"https://www.instagram.com/explore/tags/{tag}/"
    posts = []

    print(f"[ig] Scraping #{tag}...")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        )
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)

            # Check for login wall
            page_text = page.inner_text("body")
            if "Log in" in page_text[:500] and "sign up" in page_text[:500].lower():
                print(f"[ig] Login wall detected for #{tag}. Trying alternative approach...")
                # Try the API-like approach via explore
                page.goto(f"https://www.instagram.com/explore/search/keyword/?q=%23{tag}", timeout=30000)
                time.sleep(3)

            # Scroll to load posts
            for _ in range(min(5, max_posts // 4)):
                page.evaluate("window.scrollBy(0, 1000)")
                time.sleep(3)  # Slower scrolling for IG

            # Extract posts - Instagram uses article or image grid
            post_elements = page.query_selector_all('article a[href*="/p/"], article a[href*="/reel/"]')
            if not post_elements:
                post_elements = page.query_selector_all('a[href*="/p/"], a[href*="/reel/"]')

            for elem in post_elements[:max_posts]:
                try:
                    href = elem.get_attribute("href") or ""
                    alt_text = ""
                    img = elem.query_selector("img")
                    if img:
                        alt_text = img.get_attribute("alt") or ""

                    is_reel = "/reel/" in href

                    # Extract hashtags from alt text
                    found_hashtags = re.findall(r'#\w+', alt_text)
                    format_type = detect_format(alt_text)
                    category, rel_score = score_relevance(alt_text)

                    # Try to get engagement metrics (often in aria-label or alt)
                    likes_est = ""
                    comments_est = ""
                    for text in [alt_text, elem.get_attribute("aria-label") or ""]:
                        like_match = re.search(r'(\d[\d,.]*[KMB]?)\s*like', text, re.IGNORECASE)
                        comment_match = re.search(r'(\d[\d,.]*[KMB]?)\s*comment', text, re.IGNORECASE)
                        if like_match:
                            likes_est = like_match.group(1)
                        if comment_match:
                            comments_est = comment_match.group(1)

                    post_data = {
                        "url": f"https://www.instagram.com{href}" if href.startswith("/") else href,
                        "caption": alt_text[:500],
                        "hashtags": found_hashtags[:20],
                        "likes_estimate": likes_est,
                        "comments_estimate": comments_est,
                        "format_type": format_type,
                        "is_reel": is_reel,
                        "gaia_relevance": category,
                        "relevance_score": rel_score,
                    }
                    posts.append(post_data)
                    print(f"[ig] Post {len(posts)}: {format_type} — {category} ({rel_score}/10)")

                except Exception as e:
                    continue

            # Fallback: if no structured posts found, get page content
            if not posts:
                print(f"[ig] Structured extraction failed. Capturing page text...")
                body = page.inner_text("body")
                hashtags_found = re.findall(r'#\w+', body)
                # At minimum, report what hashtags appear on the page
                for ht in hashtags_found[:max_posts]:
                    cat, score = score_relevance(ht)
                    posts.append({
                        "caption": ht,
                        "hashtags": [ht],
                        "format_type": "unknown",
                        "is_reel": False,
                        "gaia_relevance": cat,
                        "relevance_score": score,
                    })

        except Exception as e:
            print(f"[ig] Error: {e}")
        finally:
            browser.close()

    return posts


def scrape_explore(max_posts: int = 20) -> list:
    """Scrape Instagram explore page for trending content."""
    from playwright.sync_api import sync_playwright

    posts = []
    print("[ig] Scraping explore page...")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        )
        page = context.new_page()

        try:
            page.goto("https://www.instagram.com/explore/", wait_until="networkidle", timeout=30000)
            time.sleep(3)

            for _ in range(3):
                page.evaluate("window.scrollBy(0, 800)")
                time.sleep(3)

            links = page.query_selector_all('a[href*="/p/"], a[href*="/reel/"]')
            for elem in links[:max_posts]:
                try:
                    href = elem.get_attribute("href") or ""
                    img = elem.query_selector("img")
                    alt = img.get_attribute("alt") if img else ""
                    cat, score = score_relevance(alt or "")
                    posts.append({
                        "url": f"https://www.instagram.com{href}" if href.startswith("/") else href,
                        "caption": (alt or "")[:500],
                        "format_type": detect_format(alt or ""),
                        "is_reel": "/reel/" in href,
                        "gaia_relevance": cat,
                        "relevance_score": score,
                    })
                except Exception:
                    continue

        except Exception as e:
            print(f"[ig] Error: {e}")
        finally:
            browser.close()

    return posts


def main():
    parser = argparse.ArgumentParser(description="Scrape Instagram trends")
    parser.add_argument("--hashtag", "-t", help="Hashtag(s) to scrape (comma-separated)")
    parser.add_argument("--explore", action="store_true", help="Scrape explore page")
    parser.add_argument("--max-posts", "-n", type=int, default=20, help="Max posts per hashtag")
    parser.add_argument("--output", "-o", help="Output JSON file path")
    args = parser.parse_args()

    if not args.hashtag and not args.explore:
        parser.error("Must provide --hashtag or --explore")

    if not check_playwright():
        sys.exit(1)

    all_posts = []

    if args.hashtag:
        tags = [t.strip().lstrip("#") for t in args.hashtag.split(",")]
        for tag in tags:
            posts = scrape_hashtag(tag, args.max_posts)
            all_posts.extend(posts)
    elif args.explore:
        all_posts = scrape_explore(args.max_posts)

    result = {
        "source": "instagram",
        "hashtag": args.hashtag or "explore",
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "posts": all_posts,
        "total_found": len(all_posts),
        "format_breakdown": {},
    }

    # Count format types
    for post in all_posts:
        fmt = post.get("format_type", "other")
        result["format_breakdown"][fmt] = result["format_breakdown"].get(fmt, 0) + 1

    output_path = args.output or "/tmp/ig-reels-trends.json"
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print(f"\n[ig] {len(all_posts)} posts saved to {output_path}")
    print(f"[ig] Format breakdown: {result['format_breakdown']}")


if __name__ == "__main__":
    main()
