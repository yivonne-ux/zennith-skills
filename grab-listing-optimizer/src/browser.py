"""Core headless browser engine for GrabFood merchant portal.

Handles login, session persistence, anti-detection, and page navigation.
Each merchant gets an isolated browser context with persistent cookies.
"""

import asyncio
import random
import logging
from pathlib import Path
from typing import Optional

from playwright.async_api import async_playwright, Browser, BrowserContext, Page
from playwright_stealth import Stealth

from src.config import (
    SESSIONS_DIR, GRAB_MERCHANT_LOGIN, GRAB_MERCHANT_DASHBOARD,
    BROWSER_HEADLESS, BROWSER_SLOW_MO,
    ACTION_DELAY_MIN, ACTION_DELAY_MAX,
    MAX_RETRIES, SCREENSHOT_ON_ERROR, SCREENSHOTS_DIR,
    PROXY_URL,
)

log = logging.getLogger("grab.browser")


async def human_delay(min_s: float = ACTION_DELAY_MIN, max_s: float = ACTION_DELAY_MAX):
    """Random delay to mimic human behavior."""
    await asyncio.sleep(random.uniform(min_s, max_s))


async def safe_visible(locator, timeout: int = 3000) -> bool:
    """Check if a locator is visible, returning False on timeout instead of raising."""
    try:
        return await locator.is_visible(timeout=timeout)
    except Exception:
        return False


async def safe_wait(page, selector: str, timeout: int = 10000):
    """Wait for selector, return None on timeout instead of raising."""
    try:
        return await page.wait_for_selector(selector, timeout=timeout)
    except Exception:
        return None


class GrabBrowser:
    """Manages a headless browser session for one GrabFood merchant."""

    def __init__(self, merchant_id: str):
        self.merchant_id = merchant_id
        self.session_dir = SESSIONS_DIR / merchant_id
        self.session_dir.mkdir(parents=True, exist_ok=True)
        self._playwright = None
        self._browser: Optional[Browser] = None
        self._context: Optional[BrowserContext] = None
        self._page: Optional[Page] = None

    @property
    def page(self) -> Page:
        if self._page is None:
            raise RuntimeError("Browser not started. Call start() first.")
        return self._page

    async def start(self) -> Page:
        """Launch browser with persistent context for this merchant."""
        self._playwright = await async_playwright().start()

        launch_args = {
            "headless": BROWSER_HEADLESS,
            "slow_mo": BROWSER_SLOW_MO,
            "args": [
                "--disable-blink-features=AutomationControlled",
                "--no-sandbox",
                "--disable-dev-shm-usage",
                "--disable-gpu",
            ],
        }

        if PROXY_URL:
            launch_args["proxy"] = {"server": PROXY_URL}

        # Persistent context = cookies survive between runs
        self._context = await self._playwright.chromium.launch_persistent_context(
            user_data_dir=str(self.session_dir),
            viewport={"width": 1366, "height": 768},
            locale="en-MY",
            timezone_id="Asia/Kuala_Lumpur",
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/131.0.0.0 Safari/537.36"
            ),
            **launch_args,
        )

        # Apply stealth to avoid bot detection
        stealth = Stealth(
            navigator_languages_override=("en-MY", "en"),
            navigator_platform_override="MacIntel",
        )
        await stealth.apply_stealth_async(self._context)

        self._page = self._context.pages[0] if self._context.pages else await self._context.new_page()

        log.info(f"[{self.merchant_id}] Browser started (headless={BROWSER_HEADLESS})")
        return self._page

    async def stop(self):
        """Close browser and save session."""
        if self._context:
            await self._context.close()
        if self._playwright:
            await self._playwright.stop()
        log.info(f"[{self.merchant_id}] Browser stopped, session saved")

    # ── Login ──────────────────────────────────────────────────────

    async def is_logged_in(self) -> bool:
        """Check if current session is still valid."""
        try:
            await self._page.goto(GRAB_MERCHANT_DASHBOARD, wait_until="domcontentloaded", timeout=15000)
            await self._page.wait_for_timeout(2000)
            url = self._page.url
            # If we're still on dashboard (not redirected to login), we're logged in
            return "sign-in" not in url and "login" not in url
        except Exception as e:
            log.warning(f"[{self.merchant_id}] Session check failed: {e}")
            return False

    async def login(self, email: str, password: str, otp_callback=None) -> bool:
        """Login to GrabMerchant portal.

        Args:
            email: Merchant's GrabMerchant email
            password: Merchant's password
            otp_callback: Async function that returns OTP string when called.
                          Used when Grab requires 2FA. If None, waits for manual input.
        """
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                log.info(f"[{self.merchant_id}] Login attempt {attempt}/{MAX_RETRIES}")
                await self._page.goto(GRAB_MERCHANT_LOGIN, wait_until="networkidle", timeout=30000)
                await human_delay()

                # Enter email
                email_input = self._page.locator('input[type="email"], input[name="email"], input[placeholder*="email" i]')
                await email_input.wait_for(state="visible", timeout=10000)
                await email_input.click()
                await email_input.fill("")
                await email_input.type(email, delay=random.randint(50, 120))
                await human_delay(0.5, 1.5)

                # Click next/continue if there's a separate email step
                next_btn = self._page.locator('button:has-text("Next"), button:has-text("Continue"), button[type="submit"]').first
                if await next_btn.is_visible():
                    await next_btn.click()
                    await human_delay()

                # Enter password
                pw_input = self._page.locator('input[type="password"], input[name="password"]')
                await pw_input.wait_for(state="visible", timeout=10000)
                await pw_input.click()
                await pw_input.fill("")
                await pw_input.type(password, delay=random.randint(50, 120))
                await human_delay(0.5, 1.5)

                # Click login
                login_btn = self._page.locator('button:has-text("Log in"), button:has-text("Sign in"), button[type="submit"]').first
                await login_btn.click()
                await human_delay(2, 4)

                # Handle OTP if required
                otp_input = self._page.locator('input[name="otp"], input[placeholder*="OTP" i], input[placeholder*="code" i]')
                if await safe_visible(otp_input, 5000):
                    log.info(f"[{self.merchant_id}] OTP required")
                    if otp_callback:
                        otp_code = await otp_callback()
                    else:
                        otp_code = input(f"Enter OTP for {self.merchant_id}: ")
                    await otp_input.type(otp_code, delay=random.randint(80, 150))
                    await human_delay(0.5, 1)
                    verify_btn = self._page.locator('button:has-text("Verify"), button:has-text("Submit"), button[type="submit"]').first
                    await verify_btn.click()
                    await human_delay(2, 4)

                # Verify login success
                await self._page.wait_for_url("**/dashboard**", timeout=15000)
                log.info(f"[{self.merchant_id}] Login successful")
                return True

            except Exception as e:
                log.error(f"[{self.merchant_id}] Login attempt {attempt} failed: {e}")
                if SCREENSHOT_ON_ERROR:
                    ss_path = SCREENSHOTS_DIR / f"{self.merchant_id}_login_error_{attempt}.png"
                    await self._page.screenshot(path=str(ss_path), full_page=True)
                    log.info(f"[{self.merchant_id}] Error screenshot: {ss_path}")
                if attempt < MAX_RETRIES:
                    await human_delay(3, 5)

        log.error(f"[{self.merchant_id}] Login failed after {MAX_RETRIES} attempts")
        return False

    async def ensure_logged_in(self, email: str, password: str, otp_callback=None) -> bool:
        """Check session, login if needed."""
        if await self.is_logged_in():
            log.info(f"[{self.merchant_id}] Existing session valid")
            return True
        return await self.login(email, password, otp_callback)

    # ── Navigation ─────────────────────────────────────────────────

    async def goto(self, url: str, wait: str = "domcontentloaded") -> Page:
        """Navigate to URL with human-like delay."""
        await self._page.goto(url, wait_until=wait, timeout=30000)
        await human_delay(1, 2)
        return self._page

    async def screenshot(self, name: str, full_page: bool = True) -> Path:
        """Take a screenshot and save it."""
        path = SCREENSHOTS_DIR / f"{self.merchant_id}_{name}.png"
        await self._page.screenshot(path=str(path), full_page=full_page)
        log.info(f"[{self.merchant_id}] Screenshot: {path}")
        return path

    # ── Utilities ──────────────────────────────────────────────────

    async def wait_and_click(self, selector: str, timeout: int = 10000):
        """Wait for element, then click with human delay."""
        el = self._page.locator(selector)
        await el.wait_for(state="visible", timeout=timeout)
        await human_delay(0.3, 0.8)
        await el.click()
        await human_delay()

    async def fill_field(self, selector: str, value: str, clear: bool = True):
        """Fill a field with human-like typing."""
        el = self._page.locator(selector)
        await el.wait_for(state="visible", timeout=10000)
        await el.click()
        if clear:
            await el.fill("")
        await el.type(value, delay=random.randint(30, 80))
        await human_delay(0.3, 0.8)

    async def upload_file(self, selector: str, file_path: str):
        """Upload a file via file input."""
        el = self._page.locator(selector)
        await el.set_input_files(file_path)
        await human_delay(1, 2)
        log.info(f"[{self.merchant_id}] Uploaded: {file_path}")
