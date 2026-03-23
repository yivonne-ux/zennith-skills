"""Merchant portal editor — upload photos, edit menu, create promos.

All operations via headless browser on merchant.grab.com.
Each action screenshots before/after for audit trail.
"""

import logging
from pathlib import Path

from src.browser import GrabBrowser, human_delay, safe_visible, safe_wait
from src.config import (
    GRAB_MERCHANT_MENU, GRAB_MERCHANT_PROMOS,
    SCREENSHOTS_DIR, MAX_RETRIES,
)

log = logging.getLogger("grab.editor")


class GrabEditor:
    """Edit GrabFood listings via headless browser on merchant portal."""

    def __init__(self, browser: GrabBrowser):
        self.browser = browser
        self.merchant_id = browser.merchant_id

    # ── Photo Upload ───────────────────────────────────────────────

    async def upload_item_photo(self, item_name: str, photo_path: str) -> bool:
        """Upload a photo for a specific menu item."""
        page = self.browser.page

        for attempt in range(1, MAX_RETRIES + 1):
            try:
                await self.browser.goto(GRAB_MERCHANT_MENU)
                await page.wait_for_timeout(3000)

                item_el = page.locator(f'text="{item_name}"').first
                if not await safe_visible(item_el, 3000):
                    item_el = page.locator(f':text-matches("{item_name[:20]}", "i")').first

                if not await safe_visible(item_el, 3000):
                    log.error(f"[{self.merchant_id}] Item not found: {item_name}")
                    return False

                await item_el.click()
                await human_delay(1, 2)
                await self.browser.screenshot(f"edit_{item_name[:20]}_before")

                file_input = page.locator('input[type="file"]').first
                if await file_input.count() == 0:
                    upload_area = page.locator(
                        '.upload-area, .photo-upload, [data-testid="photo-upload"], '
                        '.add-photo, button:has-text("Upload"), button:has-text("Add photo"), '
                        '.image-placeholder, [class*="upload"]'
                    ).first
                    if await safe_visible(upload_area, 5000):
                        await upload_area.click()
                        await human_delay(0.5, 1)
                    file_input = page.locator('input[type="file"]').first

                await file_input.set_input_files(photo_path)
                await human_delay(2, 4)

                await safe_wait(
                    page,
                    '.upload-success, .photo-preview, img[src*="upload"], '
                    '[class*="uploaded"], [class*="preview"]',
                    15000,
                )

                save_btn = page.locator(
                    'button:has-text("Save"), button:has-text("Update"), '
                    'button:has-text("Confirm"), button[type="submit"]'
                ).first
                if await safe_visible(save_btn, 5000):
                    await save_btn.click()
                    await human_delay(2, 3)

                await self.browser.screenshot(f"edit_{item_name[:20]}_after")
                log.info(f"[{self.merchant_id}] Photo uploaded for: {item_name}")
                return True

            except Exception as e:
                log.error(f"[{self.merchant_id}] Photo upload attempt {attempt} failed: {e}")
                await self.browser.screenshot(f"edit_{item_name[:20]}_error_{attempt}")
                if attempt < MAX_RETRIES:
                    await human_delay(2, 4)

        return False

    async def upload_store_banner(self, photo_path: str) -> bool:
        """Upload store banner/cover photo."""
        page = self.browser.page
        try:
            await self.browser.goto(GRAB_MERCHANT_MENU)
            await page.wait_for_timeout(3000)
            await self.browser.screenshot("banner_before")

            banner_area = page.locator(
                '.store-banner, .cover-photo, [data-testid="store-photo"], '
                '.banner-upload, [class*="banner"], [class*="cover"]'
            ).first
            if await safe_visible(banner_area, 5000):
                await banner_area.click()
                await human_delay(0.5, 1)

            file_input = page.locator('input[type="file"]').first
            await file_input.set_input_files(photo_path)
            await human_delay(2, 4)

            save_btn = page.locator('button:has-text("Save"), button:has-text("Update")').first
            if await safe_visible(save_btn, 5000):
                await save_btn.click()
                await human_delay(2, 3)

            await self.browser.screenshot("banner_after")
            log.info(f"[{self.merchant_id}] Banner uploaded")
            return True
        except Exception as e:
            log.error(f"[{self.merchant_id}] Banner upload failed: {e}")
            await self.browser.screenshot("banner_error")
            return False

    # ── Menu Editing ───────────────────────────────────────────────

    async def update_item(self, item_name: str, new_name: str = "", new_desc: str = "", new_price: float = 0) -> bool:
        """Update a menu item's name, description, or price."""
        page = self.browser.page
        try:
            await self.browser.goto(GRAB_MERCHANT_MENU)
            await page.wait_for_timeout(3000)

            item_el = page.locator(f'text="{item_name}"').first
            if not await safe_visible(item_el, 5000):
                item_el = page.locator(f':text-matches("{item_name[:20]}", "i")').first
            if not await safe_visible(item_el, 3000):
                log.error(f"[{self.merchant_id}] Item not found: {item_name}")
                return False

            await item_el.click()
            await human_delay(1, 2)

            if new_name:
                name_input = page.locator(
                    'input[name="name"], input[name="itemName"], '
                    'input[placeholder*="name" i], [data-testid="item-name-input"]'
                ).first
                if await safe_visible(name_input, 3000):
                    await name_input.click()
                    await name_input.fill("")
                    await name_input.type(new_name, delay=30)
                    await human_delay(0.3, 0.8)

            if new_desc:
                desc_input = page.locator(
                    'textarea[name="description"], textarea[name="itemDescription"], '
                    'textarea[placeholder*="description" i], [data-testid="item-desc-input"]'
                ).first
                if await safe_visible(desc_input, 3000):
                    await desc_input.click()
                    await desc_input.fill("")
                    await desc_input.type(new_desc, delay=30)
                    await human_delay(0.3, 0.8)

            if new_price > 0:
                price_input = page.locator(
                    'input[name="price"], input[name="itemPrice"], '
                    'input[placeholder*="price" i], [data-testid="item-price-input"]'
                ).first
                if await safe_visible(price_input, 3000):
                    await price_input.click()
                    await price_input.fill("")
                    await price_input.type(f"{new_price:.2f}", delay=50)
                    await human_delay(0.3, 0.8)

            save_btn = page.locator('button:has-text("Save"), button:has-text("Update"), button[type="submit"]').first
            if await safe_visible(save_btn, 5000):
                await save_btn.click()
                await human_delay(2, 3)

            log.info(f"[{self.merchant_id}] Updated item: {item_name} → {new_name or '(name unchanged)'}")
            return True
        except Exception as e:
            log.error(f"[{self.merchant_id}] Item update failed: {e}")
            await self.browser.screenshot(f"edit_{item_name[:20]}_error")
            return False

    async def batch_update_menu(self, updates: list[dict]) -> dict:
        """Apply multiple menu updates sequentially."""
        results = {"success": 0, "failed": 0, "errors": []}
        for i, update in enumerate(updates):
            log.info(f"[{self.merchant_id}] Batch update {i+1}/{len(updates)}: {update.get('item_name', '?')}")
            if update.get("photo_path"):
                ok = await self.upload_item_photo(update["item_name"], update["photo_path"])
                if not ok:
                    results["errors"].append(f"Photo upload failed: {update['item_name']}")
            if any(update.get(k) for k in ("new_name", "new_desc", "new_price")):
                ok = await self.update_item(
                    item_name=update["item_name"],
                    new_name=update.get("new_name", ""),
                    new_desc=update.get("new_desc", ""),
                    new_price=update.get("new_price", 0),
                )
                if ok:
                    results["success"] += 1
                else:
                    results["failed"] += 1
                    results["errors"].append(f"Update failed: {update['item_name']}")
            await human_delay(1, 2)
        log.info(f"[{self.merchant_id}] Batch complete: {results['success']} ok, {results['failed']} failed")
        return results

    # ── Promotions ─────────────────────────────────────────────────

    async def create_promotion(self, promo_type="percentage", discount_value=20, min_order=15, max_discount=5, **kwargs) -> bool:
        """Create a new promotion on GrabMerchant portal."""
        page = self.browser.page
        try:
            await self.browser.goto(GRAB_MERCHANT_PROMOS)
            await page.wait_for_timeout(3000)
            await self.browser.screenshot("promo_before")

            create_btn = page.locator(
                'button:has-text("Create"), button:has-text("New"), '
                'button:has-text("Add promotion"), a:has-text("Create")'
            ).first
            if await safe_visible(create_btn, 5000):
                await create_btn.click()
                await human_delay(1, 2)

            if promo_type == "percentage":
                type_sel = page.locator('[value="percentage"], :text("Percentage off"), [data-testid="pct-discount"]').first
                if await safe_visible(type_sel, 3000):
                    await type_sel.click()
                    await human_delay(0.5, 1)

            value_input = page.locator('input[name="discount"], input[name="value"], input[placeholder*="discount" i]').first
            if await safe_visible(value_input, 3000):
                await value_input.fill(str(int(discount_value)))
                await human_delay(0.3, 0.8)

            min_input = page.locator('input[name="minOrder"], input[name="minimum"], input[placeholder*="minimum" i]').first
            if await safe_visible(min_input, 3000):
                await min_input.fill(f"{min_order:.2f}")
                await human_delay(0.3, 0.8)

            cap_input = page.locator('input[name="maxDiscount"], input[name="cap"], input[placeholder*="cap" i], input[placeholder*="maximum" i]').first
            if await safe_visible(cap_input, 3000):
                await cap_input.fill(f"{max_discount:.2f}")
                await human_delay(0.3, 0.8)

            submit_btn = page.locator('button:has-text("Create"), button:has-text("Save"), button[type="submit"]').first
            if await safe_visible(submit_btn, 5000):
                await submit_btn.click()
                await human_delay(2, 3)

            await self.browser.screenshot("promo_after")
            log.info(f"[{self.merchant_id}] Promotion created: {promo_type} {discount_value}%")
            return True
        except Exception as e:
            log.error(f"[{self.merchant_id}] Promo creation failed: {e}")
            await self.browser.screenshot("promo_error")
            return False
