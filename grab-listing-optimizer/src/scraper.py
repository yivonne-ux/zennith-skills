"""Scrape current GrabFood listing state from merchant portal + consumer page.

Two modes:
1. Merchant portal (merchant.grab.com) — needs login, gets editable data
2. Consumer page (food.grab.com) — public, gets what customers see
"""

import json
import logging
from dataclasses import dataclass, field
from typing import Optional

from src.browser import GrabBrowser, human_delay, safe_visible, safe_wait
from src.config import (
    GRAB_MERCHANT_MENU, GRAB_MERCHANT_DASHBOARD,
    GRAB_MERCHANT_REVIEWS, GRAB_CONSUMER_URL,
)

log = logging.getLogger("grab.scraper")


@dataclass
class MenuItem:
    name: str = ""
    price: float = 0.0
    description: str = ""
    category: str = ""
    has_photo: bool = False
    photo_url: str = ""
    is_available: bool = True
    tags: list = field(default_factory=list)


@dataclass
class StoreData:
    store_name: str = ""
    store_id: str = ""
    description: str = ""
    rating: float = 0.0
    review_count: int = 0
    categories: list = field(default_factory=list)
    menu_items: list = field(default_factory=list)
    total_items: int = 0
    items_with_photos: int = 0
    address: str = ""
    operating_hours: str = ""


class GrabScraper:
    """Scrape listing data from GrabFood."""

    def __init__(self, browser: GrabBrowser):
        self.browser = browser
        self.merchant_id = browser.merchant_id

    # ── Merchant Portal Scraping ───────────────────────────────────

    async def scrape_dashboard(self) -> dict:
        """Scrape key metrics from merchant dashboard."""
        page = self.browser.page
        await self.browser.goto(GRAB_MERCHANT_DASHBOARD)
        await page.wait_for_timeout(3000)
        await self.browser.screenshot("dashboard_before")

        metrics = {}
        try:
            revenue_el = page.locator('[data-testid="revenue"], .revenue-value, .metric-revenue').first
            if await safe_visible(revenue_el, 3000):
                metrics["revenue"] = await revenue_el.text_content()

            orders_el = page.locator('[data-testid="orders"], .orders-value, .metric-orders').first
            if await safe_visible(orders_el, 3000):
                metrics["orders"] = await orders_el.text_content()

            rating_el = page.locator('[data-testid="rating"], .rating-value, .metric-rating').first
            if await safe_visible(rating_el, 3000):
                metrics["rating"] = await rating_el.text_content()
        except Exception as e:
            log.warning(f"[{self.merchant_id}] Dashboard scrape partial: {e}")

        if not metrics:
            try:
                metrics["raw_text"] = await page.locator("main, .dashboard, #app").first.text_content()
            except Exception:
                metrics["raw_text"] = ""

        log.info(f"[{self.merchant_id}] Dashboard metrics: {list(metrics.keys())}")
        return metrics

    async def scrape_menu(self) -> list[MenuItem]:
        """Scrape all menu items from merchant portal menu editor."""
        page = self.browser.page
        await self.browser.goto(GRAB_MERCHANT_MENU)
        await page.wait_for_timeout(3000)
        await self.browser.screenshot("menu_before")

        items = []
        item_selectors = [
            '.menu-item', '.item-card', '[data-testid="menu-item"]',
            '.food-item', 'tr.item-row', '.menu-list-item',
        ]

        for selector in item_selectors:
            item_els = page.locator(selector)
            count = await item_els.count()
            if count > 0:
                log.info(f"[{self.merchant_id}] Found {count} items with selector: {selector}")
                for i in range(count):
                    el = item_els.nth(i)
                    item = MenuItem()

                    name_el = el.locator('.item-name, .name, h3, h4, [data-testid="item-name"]').first
                    if await safe_visible(name_el, 1000):
                        item.name = (await name_el.text_content()).strip()

                    price_el = el.locator('.item-price, .price, [data-testid="item-price"]').first
                    if await safe_visible(price_el, 1000):
                        price_text = (await price_el.text_content()).strip()
                        price_num = ''.join(c for c in price_text if c.isdigit() or c == '.')
                        if price_num:
                            item.price = float(price_num)

                    desc_el = el.locator('.item-description, .description, [data-testid="item-desc"]').first
                    if await safe_visible(desc_el, 1000):
                        item.description = (await desc_el.text_content()).strip()

                    photo_el = el.locator('img.item-photo, img.food-image, img[src*="item"]').first
                    if await safe_visible(photo_el, 1000):
                        item.has_photo = True
                        item.photo_url = await photo_el.get_attribute("src") or ""

                    if item.name:
                        items.append(item)
                break

        # Strategy 2: extract from page JSON
        if not items:
            log.info(f"[{self.merchant_id}] Trying JSON extraction from page")
            try:
                scripts = await page.locator('script[type="application/json"], script#__NEXT_DATA__').all()
                for script in scripts:
                    text = await script.text_content()
                    if text and ("menu" in text.lower() or "item" in text.lower()):
                        try:
                            json.loads(text)
                            log.info(f"[{self.merchant_id}] Found JSON data in script tag")
                            break
                        except json.JSONDecodeError:
                            continue
            except Exception as e:
                log.warning(f"[{self.merchant_id}] JSON extraction failed: {e}")

        # Strategy 3: raw text
        if not items:
            log.warning(f"[{self.merchant_id}] Falling back to raw text extraction")
            try:
                raw = await page.locator("main, #app, body").first.text_content()
                log.info(f"[{self.merchant_id}] Raw menu text ({len(raw)} chars)")
            except Exception:
                pass

        log.info(f"[{self.merchant_id}] Scraped {len(items)} menu items")
        return items

    async def scrape_reviews(self) -> list[dict]:
        """Scrape recent reviews from merchant portal."""
        page = self.browser.page
        await self.browser.goto(GRAB_MERCHANT_REVIEWS)
        await page.wait_for_timeout(3000)

        reviews = []
        review_els = page.locator('.review-item, .review-card, [data-testid="review"]')
        count = await review_els.count()

        for i in range(min(count, 20)):
            el = review_els.nth(i)
            review = {}

            rating_el = el.locator('.rating, .stars, [data-testid="rating"]').first
            if await safe_visible(rating_el, 1000):
                review["rating"] = (await rating_el.text_content()).strip()

            comment_el = el.locator('.comment, .review-text, [data-testid="comment"]').first
            if await safe_visible(comment_el, 1000):
                review["comment"] = (await comment_el.text_content()).strip()

            if review:
                reviews.append(review)

        log.info(f"[{self.merchant_id}] Scraped {len(reviews)} reviews")
        return reviews

    # ── Consumer Page Scraping ─────────────────────────────────────

    async def scrape_consumer_listing(self, store_slug: str) -> StoreData:
        """Scrape the public-facing GrabFood listing."""
        page = self.browser.page
        url = f"{GRAB_CONSUMER_URL}/restaurant/online-delivery/{store_slug}"
        await self.browser.goto(url, wait="networkidle")
        await page.wait_for_timeout(3000)
        await self.browser.screenshot(f"consumer_{store_slug}")

        store = StoreData(store_id=store_slug)

        name_el = page.locator('h1, .restaurant-name, [class*="restaurantName"]').first
        if await safe_visible(name_el, 5000):
            store.store_name = (await name_el.text_content()).strip()

        rating_el = page.locator('[class*="rating"], .rating-score').first
        if await safe_visible(rating_el, 3000):
            rating_text = (await rating_el.text_content()).strip()
            # Extract rating (1.0-5.0 range) from text like "4.7 (513 ratings)"
            import re
            match = re.search(r'([1-5]\.\d)', rating_text)
            if match:
                store.rating = float(match.group(1))

        item_els = page.locator('[class*="menuItem"], [class*="MenuItem"], .dish-card')
        count = await item_els.count()
        store.total_items = count

        for i in range(count):
            el = item_els.nth(i)
            item = MenuItem()

            name_el = el.locator('h3, h4, [class*="itemName"], [class*="name"]').first
            if await safe_visible(name_el, 1000):
                item.name = (await name_el.text_content()).strip()

            price_el = el.locator('[class*="price"], [class*="Price"]').first
            if await safe_visible(price_el, 1000):
                price_text = (await price_el.text_content()).strip()
                nums = ''.join(c for c in price_text if c.isdigit() or c == '.')
                if nums:
                    item.price = float(nums)

            photo_el = el.locator('img').first
            if await safe_visible(photo_el, 1000):
                src = await photo_el.get_attribute("src") or ""
                item.has_photo = bool(src and "placeholder" not in src.lower())
                item.photo_url = src

            if item.name:
                store.menu_items.append(item)

        store.items_with_photos = sum(1 for i in store.menu_items if i.has_photo)
        log.info(
            f"[{self.merchant_id}] Consumer listing: {store.store_name} | "
            f"{store.total_items} items | {store.items_with_photos} with photos | "
            f"rating: {store.rating}"
        )
        return store

    # ── Audit ──────────────────────────────────────────────────────

    async def audit_listing(self, store_slug: str) -> dict:
        """Full audit of a GrabFood listing. Returns score + recommendations."""
        store = await self.scrape_consumer_listing(store_slug)

        score = 0
        max_score = 100
        issues = []
        recommendations = []

        # Photo coverage (40 points)
        if store.total_items > 0:
            photo_pct = store.items_with_photos / store.total_items
            score += int(photo_pct * 40)
            if photo_pct < 1.0:
                missing = store.total_items - store.items_with_photos
                issues.append(f"{missing} menu items have no photo")
                recommendations.append(f"Add professional photos to all {missing} items without photos")
        else:
            issues.append("No menu items found")

        # Rating (20 points)
        if store.rating >= 4.5:
            score += 20
        elif store.rating >= 4.0:
            score += 15
            recommendations.append("Improve rating to 4.5+ (respond to negative reviews, add thank-you notes)")
        elif store.rating > 0:
            score += int(store.rating * 4)
            issues.append(f"Rating {store.rating} is below 4.0 — 50% visibility penalty!")
            recommendations.append("URGENT: Improve rating above 4.0 to avoid visibility penalty")

        # Description quality (15 points)
        has_description = bool(store.description and len(store.description) > 20)
        has_emoji = any(ord(c) > 0x1F600 for c in (store.description or ""))
        has_bilingual = any('\u4e00' <= c <= '\u9fff' for c in (store.store_name or ""))

        if has_description:
            score += 5
        else:
            issues.append("Missing or too short store description")
            recommendations.append("Add compelling description with USP, cuisine type, emojis (under 150 chars)")

        if has_emoji:
            score += 5
        else:
            recommendations.append("Add emojis to store name/description for visual appeal")

        if has_bilingual:
            score += 5
        else:
            recommendations.append("Add Chinese characters to store name for bilingual appeal")

        # Menu structure (15 points)
        categories = set(item.category for item in store.menu_items if item.category)
        if 3 <= len(categories) <= 8:
            score += 15
        elif len(categories) > 0:
            score += 8
            if len(categories) > 8:
                recommendations.append(f"Reduce categories from {len(categories)} to 5-8")
            else:
                recommendations.append("Add more menu categories (aim for 5-8)")
        else:
            recommendations.append("Organize menu into clear categories with emoji prefixes")

        # Item descriptions (10 points)
        items_with_desc = sum(1 for i in store.menu_items if i.description and len(i.description) > 10)
        if store.total_items > 0:
            desc_pct = items_with_desc / store.total_items
            score += int(desc_pct * 10)
            if desc_pct < 0.5:
                recommendations.append("Add appetite-triggering descriptions to all menu items")

        audit = {
            "store_name": store.store_name,
            "store_id": store.store_id,
            "score": score,
            "max_score": max_score,
            "grade": "A" if score >= 80 else "B" if score >= 60 else "C" if score >= 40 else "D",
            "rating": store.rating,
            "total_items": store.total_items,
            "items_with_photos": store.items_with_photos,
            "photo_coverage": f"{store.items_with_photos}/{store.total_items}",
            "issues": issues,
            "recommendations": recommendations,
        }

        log.info(f"[{self.merchant_id}] Audit: {audit['grade']} ({score}/{max_score})")
        return audit
