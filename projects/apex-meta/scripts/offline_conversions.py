"""Mirra Offline Conversions Pipeline — Upload sales data to Meta.

Reads WhatsApp sales from Google Sheet → hashes phone numbers → uploads
as Purchase events to Meta Conversions API → Meta learns which ads drive SALES.

Usage:
    python scripts/offline_conversions.py                  # Upload last 7 days
    python scripts/offline_conversions.py --days 30        # Upload last 30 days
    python scripts/offline_conversions.py --dry-run        # Preview without uploading
    python scripts/offline_conversions.py --backfill       # Upload ALL March data

Requires: META_TOKEN in env or .meta-token file
"""

import argparse
import csv
import hashlib
import io
import json
import re
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional


# --- Config ---
SHEET_ID = "1mNP3AAySkP8xzCIbyznm3sqFtFZatSca6wLVnu35Vs0"
ORDERS_GID = "82276829"
AD_ACCOUNT = "830110298602617"
PIXEL_ID = "3289065677934626"
GRAPH_VERSION = "v21.0"
GRAPH_BASE = f"https://graph.facebook.com/{GRAPH_VERSION}"

# Column indices (0-based) from the Google Sheet
COL_DATE = 1
COL_CUSTOMER_TYPE = 2
COL_LANGUAGE = 3
COL_ADS = 4
COL_NAME = 5
COL_PHONE = 6
COL_PAGE = 8
COL_PAYMENT = 13


def load_token() -> str:
    """Load Meta access token."""
    import os
    token = os.environ.get("META_TOKEN", "")
    if token:
        return token

    token_paths = [
        Path.home() / "Desktop/_WORK/_shared/.meta-token",
        Path(".env"),
    ]
    for p in token_paths:
        if p.exists():
            content = p.read_text().strip()
            if p.name == ".env":
                for line in content.split("\n"):
                    if line.startswith("META_SYSTEM_USER_TOKEN="):
                        return line.split("=", 1)[1].strip()
            else:
                return content

    print("ERROR: No Meta token found. Set META_TOKEN env var or create .meta-token")
    sys.exit(1)


def fetch_orders() -> list[dict]:
    """Fetch all orders from Google Sheet."""
    url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&gid={ORDERS_GID}"
    print(f"Fetching orders from Google Sheet...")
    resp = urllib.request.urlopen(url)
    data = resp.read().decode("utf-8")
    reader = csv.reader(io.StringIO(data))
    header = next(reader)

    orders = []
    for row in reader:
        if len(row) <= COL_PAYMENT:
            continue

        date_str = row[COL_DATE].strip()
        phone = row[COL_PHONE].strip()
        payment_str = row[COL_PAYMENT].strip()
        name = row[COL_NAME].strip()

        if not date_str or not phone or not payment_str:
            continue

        # Parse date
        order_date = parse_date(date_str)
        if not order_date:
            continue

        # Parse payment amount
        amount = parse_amount(payment_str)
        if not amount or amount <= 0:
            continue

        # Clean phone number
        clean_phone = normalize_phone(phone)
        if not clean_phone:
            continue

        orders.append({
            "date": order_date,
            "phone": clean_phone,
            "phone_raw": phone,
            "amount": amount,
            "name": name,
            "customer_type": row[COL_CUSTOMER_TYPE].strip(),
            "language": row[COL_LANGUAGE].strip(),
            "ad_id": row[COL_ADS].strip(),
            "page": row[COL_PAGE].strip(),
        })

    print(f"  Found {len(orders)} valid orders")
    return orders


def parse_date(date_str: str) -> Optional[datetime]:
    """Parse date from various formats."""
    formats = ["%d/%m/%Y", "%Y-%m-%d", "%m/%d/%Y", "%d-%m-%Y"]
    for fmt in formats:
        try:
            dt = datetime.strptime(date_str, fmt)
            return dt.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def parse_amount(amount_str: str) -> Optional[float]:
    """Extract numeric amount from strings like 'RM 433.00'."""
    cleaned = re.sub(r"[^\d.]", "", amount_str)
    try:
        return float(cleaned)
    except ValueError:
        return None


def normalize_phone(phone: str) -> Optional[str]:
    """Normalize Malaysian phone number to +60 format."""
    digits = re.sub(r"[^\d]", "", phone)

    if not digits or len(digits) < 9:
        return None

    # Malaysian numbers
    if digits.startswith("60"):
        return f"+{digits}"
    elif digits.startswith("0"):
        return f"+6{digits}"
    elif digits.startswith("1") and len(digits) >= 9:
        return f"+60{digits}"

    return f"+{digits}"


def sha256_hash(value: str) -> str:
    """SHA-256 hash for Meta's user data matching."""
    return hashlib.sha256(value.strip().lower().encode("utf-8")).hexdigest()


def build_events(orders: list[dict], cutoff_date: datetime) -> list[dict]:
    """Build Meta Conversions API event payloads from orders."""
    events = []
    skipped = 0

    for order in orders:
        if order["date"] < cutoff_date:
            skipped += 1
            continue

        event = {
            "event_name": "Purchase",
            "event_time": int(order["date"].timestamp()),
            "action_source": "physical_store",  # offline purchase via WhatsApp
            "user_data": {
                "ph": [sha256_hash(order["phone"])],
                "country": [sha256_hash("my")],
            },
            "custom_data": {
                "currency": "MYR",
                "value": order["amount"],
                "content_name": "Mirra Bento",
                "order_id": f"mirra-{order['date'].strftime('%Y%m%d')}-{sha256_hash(order['phone'])[:8]}",
            },
        }

        # Add name if available (first name hash)
        if order["name"]:
            first_name = order["name"].split()[0] if order["name"] else ""
            if first_name:
                event["user_data"]["fn"] = [sha256_hash(first_name)]

        events.append(event)

    print(f"  Built {len(events)} events (skipped {skipped} before cutoff)")
    return events


def upload_events(
    token: str, events: list[dict], dry_run: bool = False
) -> dict:
    """Upload events to Meta Conversions API in batches of 1000."""
    BATCH_SIZE = 1000
    total_uploaded = 0
    total_errors = 0
    results = []

    for i in range(0, len(events), BATCH_SIZE):
        batch = events[i : i + BATCH_SIZE]
        batch_num = (i // BATCH_SIZE) + 1
        total_batches = (len(events) + BATCH_SIZE - 1) // BATCH_SIZE

        if dry_run:
            print(f"  [DRY RUN] Batch {batch_num}/{total_batches}: {len(batch)} events")
            total_uploaded += len(batch)
            continue

        payload = {
            "data": json.dumps(batch),
            "access_token": token,
        }

        url = f"{GRAPH_BASE}/{PIXEL_ID}/events"
        encoded = urllib.parse.urlencode(payload).encode()
        req = urllib.request.Request(url, data=encoded, method="POST")

        try:
            resp = urllib.request.urlopen(req)
            result = json.loads(resp.read())
            events_received = result.get("events_received", 0)
            total_uploaded += events_received
            print(
                f"  Batch {batch_num}/{total_batches}: "
                f"{events_received} events received by Meta"
            )
            results.append(result)

            if result.get("messages"):
                for msg in result["messages"]:
                    print(f"    Warning: {msg}")

        except Exception as e:
            err_body = ""
            if hasattr(e, "read"):
                err_body = e.read().decode()
            print(f"  Batch {batch_num} FAILED: {e}")
            if err_body:
                try:
                    err_json = json.loads(err_body)
                    print(f"    Error: {err_json.get('error', {}).get('message', err_body[:200])}")
                except json.JSONDecodeError:
                    print(f"    Response: {err_body[:200]}")
            total_errors += len(batch)

        # Rate limiting
        if not dry_run:
            time.sleep(1)

    return {
        "total_events": len(events),
        "uploaded": total_uploaded,
        "errors": total_errors,
        "batches": len(results),
    }


def print_summary(orders: list[dict], events: list[dict], upload_result: dict) -> None:
    """Print a summary of the upload."""
    print("\n" + "=" * 60)
    print("OFFLINE CONVERSIONS UPLOAD SUMMARY")
    print("=" * 60)

    # Orders breakdown
    total_revenue = sum(o["amount"] for o in orders)
    with_ad_id = sum(1 for o in orders if o["ad_id"])
    by_language = {}
    by_customer = {}
    for o in orders:
        lang = o["language"] or "Unknown"
        by_language[lang] = by_language.get(lang, 0) + 1
        ctype = o["customer_type"] or "Unknown"
        by_customer[ctype] = by_customer.get(ctype, 0) + 1

    print(f"\nOrders in sheet: {len(orders)}")
    print(f"Total revenue: RM{total_revenue:,.2f}")
    print(f"With ad ID: {with_ad_id} ({with_ad_id/len(orders)*100:.1f}%)")
    print(f"By language: {by_language}")
    print(f"By customer type: {by_customer}")

    print(f"\nEvents uploaded: {upload_result['uploaded']}/{upload_result['total_events']}")
    if upload_result["errors"]:
        print(f"Errors: {upload_result['errors']}")

    print(f"\nPixel ID: {PIXEL_ID}")
    print(f"Ad Account: act_{AD_ACCOUNT}")

    print("\n" + "=" * 60)
    print("WHAT HAPPENS NEXT:")
    print("=" * 60)
    print("1. Meta will match phone numbers to WhatsApp conversations")
    print("2. Matched events appear in Events Manager within 24-48 hours")
    print("3. Meta's algorithm will start optimizing for PURCHASES, not just conversations")
    print("4. Run this script daily to keep feeding purchase data")
    print("5. After 7 days, check Events Manager for match rate")
    print(f"\nEvents Manager: https://business.facebook.com/events_manager2/list/pixel/{PIXEL_ID}/overview")


def main():
    parser = argparse.ArgumentParser(description="Upload Mirra sales to Meta Offline Conversions")
    parser.add_argument("--days", type=int, default=7, help="Upload orders from last N days (default: 7)")
    parser.add_argument("--dry-run", action="store_true", help="Preview without uploading")
    parser.add_argument("--backfill", action="store_true", help="Upload all March data")
    args = parser.parse_args()

    print("=" * 60)
    print("MIRRA OFFLINE CONVERSIONS PIPELINE")
    print("=" * 60)

    token = load_token()
    print(f"Token loaded: ...{token[-10:]}")

    # Fetch orders
    orders = fetch_orders()
    if not orders:
        print("No valid orders found!")
        return

    # Date filter
    # Meta CAPI requires events within the last 7 days
    max_lookback = datetime.now(timezone.utc) - timedelta(days=7)

    if args.backfill:
        cutoff = max_lookback
        print(f"\nBackfill mode: uploading last 7 days (Meta CAPI max lookback)")
    else:
        cutoff = datetime.now(timezone.utc) - timedelta(days=args.days)
        if cutoff < max_lookback:
            cutoff = max_lookback
            print(f"\n  Note: Meta CAPI only accepts events within 7 days")
        print(f"\nUploading orders since {cutoff.strftime('%Y-%m-%d')}")

    # Filter orders
    filtered = [o for o in orders if o["date"] >= cutoff]
    print(f"Orders in range: {len(filtered)}")

    if not filtered:
        print("No orders in the specified date range!")
        return

    # Show preview
    print(f"\nSample events:")
    for o in filtered[:5]:
        print(
            f"  {o['date'].strftime('%Y-%m-%d')} | "
            f"{o['phone_raw']:>15s} → {o['phone'][:8]}... | "
            f"RM{o['amount']:>8.2f} | "
            f"{o['customer_type'][:15]:15s} | "
            f"{'AD:' + o['ad_id'][:15] if o['ad_id'] else 'no ad ID'}"
        )

    # Build events
    events = build_events(filtered, cutoff)
    if not events:
        print("No valid events to upload!")
        return

    # Upload
    mode = "DRY RUN" if args.dry_run else "LIVE"
    print(f"\nUploading {len(events)} events [{mode}]...")
    result = upload_events(token, events, dry_run=args.dry_run)

    # Summary
    print_summary(filtered, events, result)


if __name__ == "__main__":
    main()
