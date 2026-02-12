#!/usr/bin/env python3
"""YouTube search scraper using Playwright.

Searches YouTube for marketing education content — no API key needed.
Extracts video metadata, descriptions, and learning briefs.

Usage:
    python3 scrape_youtube.py --query "how to create UGC" --max-results 15
    python3 scrape_youtube.py --query "Meta ads 2026" --max-results 10
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
    "ugc": ["ugc", "user generated", "creator", "brief", "influencer content"],
    "ads": ["meta ads", "facebook ads", "tiktok ads", "google ads", "ad creative", "roas", "cpa"],
    "content": ["a-roll", "b-roll", "storyboard", "分镜", "editing", "shoot", "filming", "product photo"],
    "ecommerce": ["shopee", "lazada", "tiktok shop", "ecommerce", "product listing", "conversion"],
    "strategy": ["marketing strategy", "performance marketing", "dtc", "brand building", "email marketing"],
    "social": ["instagram", "reels", "tiktok", "content calendar", "posting", "engagement", "hashtag"],
}


def categorize_video(text: str) -> tuple[str, int]:
    text_lower = text.lower()
    best_cat = "general"
    best_score = 0
    for category, keywords in RELEVANCE_KEYWORDS.items():
        matches = sum(1 for kw in keywords if kw in text_lower)
        score = min(10, matches * 3 + 1)
        if score > best_score:
            best_score = score
            best_cat = category
    return best_cat, best_score


def check_playwright():
    try:
        from playwright.sync_api import sync_playwright
        return True
    except ImportError:
        print("Error: playwright not installed.")
        return False


def scrape_youtube(query: str, max_results: int = 15) -> dict:
    """Search YouTube and extract video metadata."""
    from playwright.sync_api import sync_playwright

    url = f"https://www.youtube.com/results?search_query={query.replace(' ', '+')}&sp=CAISAhAB"
    # sp=CAISAhAB = sort by upload date (recent first)
    videos = []

    print(f"[youtube] Searching: {query}")

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={"width": 1280, "height": 900},
            user_agent="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
        )
        page = context.new_page()

        try:
            page.goto(url, wait_until="networkidle", timeout=30000)
            time.sleep(3)

            # Scroll to load more results
            for _ in range(min(5, max_results // 3)):
                page.evaluate("window.scrollBy(0, 1000)")
                time.sleep(2)

            # Extract video renderers
            video_elements = page.query_selector_all('ytd-video-renderer, ytd-rich-item-renderer')

            if not video_elements:
                # Fallback: try broader selectors
                video_elements = page.query_selector_all('[id="dismissible"]')

            for elem in video_elements:
                if len(videos) >= max_results:
                    break

                try:
                    # Title
                    title_elem = elem.query_selector('#video-title, a#video-title')
                    title = title_elem.inner_text().strip() if title_elem else ""
                    video_url = title_elem.get_attribute("href") if title_elem else ""
                    if video_url and video_url.startswith("/"):
                        video_url = f"https://www.youtube.com{video_url}"

                    if not title:
                        continue

                    # Channel name
                    channel_elem = elem.query_selector('#channel-name a, ytd-channel-name a, .ytd-channel-name a')
                    channel = channel_elem.inner_text().strip() if channel_elem else ""

                    # Metadata (views, upload date)
                    meta_elem = elem.query_selector('#metadata-line, .ytd-video-meta-block')
                    meta_text = meta_elem.inner_text().strip() if meta_elem else ""

                    views = ""
                    upload_date = ""
                    for part in meta_text.split("\n"):
                        part = part.strip()
                        if "view" in part.lower():
                            views = part
                        elif any(t in part.lower() for t in ["ago", "hour", "day", "week", "month", "year", "streamed"]):
                            upload_date = part

                    # Description snippet
                    desc_elem = elem.query_selector('.metadata-snippet-text, #description-text')
                    description = desc_elem.inner_text().strip()[:300] if desc_elem else ""

                    # Duration
                    duration_elem = elem.query_selector('[class*="time-status"], ytd-thumbnail-overlay-time-status-renderer')
                    duration = duration_elem.inner_text().strip() if duration_elem else ""

                    category, score = categorize_video(title + " " + description + " " + channel)

                    video_data = {
                        "title": title[:200],
                        "url": video_url,
                        "channel": channel[:100],
                        "views": views,
                        "upload_date": upload_date,
                        "duration": duration,
                        "description": description,
                        "category": category,
                        "relevance_score": score,
                    }
                    videos.append(video_data)
                    print(f"[youtube] {len(videos)}. {title[:60]} — {channel} ({views})")

                except Exception as e:
                    continue

            # Fallback if structured extraction failed
            if not videos:
                print("[youtube] Structured extraction failed, trying text extraction...")
                page_text = page.inner_text("body")
                # Extract titles from page text
                # YouTube titles are often in specific patterns
                lines = page_text.split("\n")
                for line in lines:
                    line = line.strip()
                    if len(line) > 20 and len(line) < 200 and not line.startswith("http"):
                        if any(kw in line.lower() for cat_kws in RELEVANCE_KEYWORDS.values() for kw in cat_kws):
                            cat, score = categorize_video(line)
                            videos.append({
                                "title": line,
                                "url": "",
                                "channel": "",
                                "views": "",
                                "category": cat,
                                "relevance_score": score,
                            })
                            if len(videos) >= max_results:
                                break

        except Exception as e:
            print(f"[youtube] Error: {e}")
        finally:
            browser.close()

    return {
        "source": "youtube",
        "query": query,
        "scraped_at": datetime.now(timezone.utc).isoformat(),
        "videos": videos,
        "total_found": len(videos),
        "category_breakdown": {},
    }


def main():
    parser = argparse.ArgumentParser(description="Scrape YouTube for marketing intel")
    parser.add_argument("--query", "-q", required=True, help="Search query")
    parser.add_argument("--max-results", "-n", type=int, default=15, help="Max results")
    parser.add_argument("--output", "-o", help="Output JSON file path")
    args = parser.parse_args()

    if not check_playwright():
        sys.exit(1)

    result = scrape_youtube(args.query, args.max_results)

    # Category breakdown
    for video in result["videos"]:
        cat = video.get("category", "general")
        result["category_breakdown"][cat] = result["category_breakdown"].get(cat, 0) + 1

    output_path = args.output or "/tmp/youtube-intel.json"
    with open(output_path, "w") as f:
        json.dump(result, f, indent=2, ensure_ascii=False)
    print(f"\n[youtube] {len(result['videos'])} videos saved to {output_path}")


if __name__ == "__main__":
    main()
