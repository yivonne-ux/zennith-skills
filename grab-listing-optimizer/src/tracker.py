"""Performance tracker — scrape dashboard metrics, store in SQLite, trend over time.

Provides before/after comparison and weekly reports via Telegram.
"""

import sqlite3
import json
import logging
from datetime import datetime, date
from pathlib import Path

from src.browser import GrabBrowser, human_delay, safe_visible
from src.config import DB_PATH, GRAB_MERCHANT_DASHBOARD, GRAB_MERCHANT_ANALYTICS

log = logging.getLogger("grab.tracker")


def init_db():
    """Create tracking tables if they don't exist."""
    conn = sqlite3.connect(str(DB_PATH))
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS merchants (
            merchant_id TEXT PRIMARY KEY,
            store_name TEXT,
            email TEXT,
            added_date TEXT,
            notes TEXT
        );

        CREATE TABLE IF NOT EXISTS snapshots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant_id TEXT NOT NULL,
            snapshot_date TEXT NOT NULL,
            revenue TEXT,
            order_count INTEGER,
            avg_order_value REAL,
            rating REAL,
            review_count INTEGER,
            total_items INTEGER,
            items_with_photos INTEGER,
            raw_data TEXT,
            screenshot_path TEXT,
            FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
        );

        CREATE TABLE IF NOT EXISTS optimizations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            merchant_id TEXT NOT NULL,
            opt_date TEXT NOT NULL,
            opt_type TEXT,
            details TEXT,
            before_screenshot TEXT,
            after_screenshot TEXT,
            FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
        );

        CREATE INDEX IF NOT EXISTS idx_snapshots_merchant
            ON snapshots(merchant_id, snapshot_date);
    """)
    conn.close()
    log.info(f"Database initialized: {DB_PATH}")


class PerformanceTracker:
    """Track GrabFood store performance over time."""

    def __init__(self, browser: GrabBrowser):
        self.browser = browser
        self.merchant_id = browser.merchant_id
        init_db()

    def _conn(self) -> sqlite3.Connection:
        conn = sqlite3.connect(str(DB_PATH))
        conn.row_factory = sqlite3.Row
        return conn

    # ── Merchant Registration ──────────────────────────────────────

    def register_merchant(self, store_name: str, email: str, notes: str = ""):
        conn = self._conn()
        conn.execute(
            "INSERT OR REPLACE INTO merchants VALUES (?, ?, ?, ?, ?)",
            (self.merchant_id, store_name, email, date.today().isoformat(), notes),
        )
        conn.commit()
        conn.close()
        log.info(f"Merchant registered: {self.merchant_id} ({store_name})")

    # ── Snapshot ───────────────────────────────────────────────────

    async def take_snapshot(self) -> dict:
        """Scrape current metrics from dashboard and save to DB."""
        page = self.browser.page
        await self.browser.goto(GRAB_MERCHANT_DASHBOARD)
        await page.wait_for_timeout(3000)

        ss_path = await self.browser.screenshot(f"snapshot_{date.today().isoformat()}")

        # Extract metrics from dashboard
        metrics = {"snapshot_date": datetime.now().isoformat()}

        # Try to extract structured data
        # Note: exact selectors depend on actual portal DOM
        try:
            # Get all visible text from dashboard for parsing
            main_content = await page.locator("main, .dashboard, #app").first.text_content()
            metrics["raw_text"] = main_content[:5000]

            # Try common metric patterns
            for selector_group in [
                {"label": "revenue", "selectors": ['.revenue', '[data-testid="revenue"]', 'text=/RM \\d/']},
                {"label": "orders", "selectors": ['.orders', '[data-testid="orders"]', 'text=/\\d+ orders/i']},
                {"label": "rating", "selectors": ['.rating', '[data-testid="rating"]', 'text=/\\d\\.\\d/']},
            ]:
                for sel in selector_group["selectors"]:
                    el = page.locator(sel).first
                    if await safe_visible(el, 2000):
                        metrics[selector_group["label"]] = (await el.text_content()).strip()
                        break
        except Exception as e:
            log.warning(f"[{self.merchant_id}] Metric extraction partial: {e}")

        # Save to DB
        conn = self._conn()
        conn.execute(
            """INSERT INTO snapshots
               (merchant_id, snapshot_date, revenue, order_count, avg_order_value,
                rating, review_count, total_items, items_with_photos, raw_data, screenshot_path)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                self.merchant_id,
                metrics["snapshot_date"],
                metrics.get("revenue", ""),
                metrics.get("orders", 0),
                metrics.get("avg_order_value", 0),
                metrics.get("rating", 0),
                metrics.get("review_count", 0),
                metrics.get("total_items", 0),
                metrics.get("items_with_photos", 0),
                json.dumps(metrics),
                str(ss_path),
            ),
        )
        conn.commit()
        conn.close()

        log.info(f"[{self.merchant_id}] Snapshot saved: {metrics.get('revenue', 'n/a')}")
        return metrics

    # ── Log Optimization ───────────────────────────────────────────

    def log_optimization(self, opt_type: str, details: str, before_ss: str = "", after_ss: str = ""):
        """Record an optimization action for audit trail."""
        conn = self._conn()
        conn.execute(
            "INSERT INTO optimizations VALUES (NULL, ?, ?, ?, ?, ?, ?)",
            (self.merchant_id, datetime.now().isoformat(), opt_type, details, before_ss, after_ss),
        )
        conn.commit()
        conn.close()

    # ── Reports ────────────────────────────────────────────────────

    def get_history(self, days: int = 30) -> list[dict]:
        """Get snapshot history for this merchant."""
        conn = self._conn()
        rows = conn.execute(
            """SELECT * FROM snapshots
               WHERE merchant_id = ?
               ORDER BY snapshot_date DESC
               LIMIT ?""",
            (self.merchant_id, days),
        ).fetchall()
        conn.close()
        return [dict(r) for r in rows]

    def generate_report(self) -> dict:
        """Generate a before/after performance report."""
        history = self.get_history(90)
        if len(history) < 2:
            return {"message": "Not enough data yet. Need at least 2 snapshots."}

        latest = history[0]
        earliest = history[-1]

        # Parse revenue if available
        def parse_revenue(val):
            if not val:
                return 0
            nums = ''.join(c for c in str(val) if c.isdigit() or c == '.')
            return float(nums) if nums else 0

        report = {
            "merchant_id": self.merchant_id,
            "period": f"{earliest['snapshot_date'][:10]} → {latest['snapshot_date'][:10]}",
            "snapshots_count": len(history),
            "latest_revenue": latest.get("revenue", "N/A"),
            "earliest_revenue": earliest.get("revenue", "N/A"),
            "latest_rating": latest.get("rating", "N/A"),
            "earliest_rating": earliest.get("rating", "N/A"),
            "latest_orders": latest.get("order_count", "N/A"),
            "earliest_orders": earliest.get("order_count", "N/A"),
        }

        # Calculate deltas if numeric
        rev_latest = parse_revenue(latest.get("revenue"))
        rev_earliest = parse_revenue(earliest.get("revenue"))
        if rev_latest and rev_earliest:
            report["revenue_change_pct"] = round((rev_latest - rev_earliest) / rev_earliest * 100, 1)

        # Get optimization log
        conn = self._conn()
        opts = conn.execute(
            "SELECT * FROM optimizations WHERE merchant_id = ? ORDER BY opt_date",
            (self.merchant_id,),
        ).fetchall()
        conn.close()
        report["optimizations_applied"] = len(opts)

        return report

    def format_telegram_report(self) -> str:
        """Format report for Telegram message."""
        r = self.generate_report()

        if "message" in r:
            return r["message"]

        msg = f"""📊 *Performance Report*
🏪 Store: `{r['merchant_id']}`
📅 Period: {r['period']}

💰 Revenue: {r['earliest_revenue']} → {r['latest_revenue']}"""

        if "revenue_change_pct" in r:
            emoji = "📈" if r["revenue_change_pct"] > 0 else "📉"
            msg += f"\n{emoji} Change: {r['revenue_change_pct']:+.1f}%"

        msg += f"""
⭐ Rating: {r['earliest_rating']} → {r['latest_rating']}
📦 Orders: {r['earliest_orders']} → {r['latest_orders']}
🔧 Optimizations applied: {r['optimizations_applied']}
📸 Snapshots: {r['snapshots_count']}"""

        return msg
