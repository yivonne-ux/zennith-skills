"""Pinxin Offline Conversions Pipeline — Upload WA sales data to Meta.

Reads WhatsApp sales from Google Sheet → extracts phone from free-text blob →
hashes phone numbers → uploads as Purchase events to Meta Conversions API.

Usage:
    python scripts/offline_conversions_pinxin.py                  # Upload last 7 days
    python scripts/offline_conversions_pinxin.py --dry-run        # Preview without uploading
    python scripts/offline_conversions_pinxin.py --backfill       # Upload max lookback

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
SHEET_ID = "1Wuz9gvmfDVFufgth6cZECuj1N4ZuwDw9HRfbkI6QCnc"
ORDERS_GID = "0"  # Raw transaction data (gid=0)
PIXEL_ID = "961906233966610"  # malaysia Pin Xin's Pixel
GRAPH_VERSION = "v21.0"
GRAPH_BASE = f"https://graph.facebook.com/{GRAPH_VERSION}"

# Column indices (0-based) from the Google Sheet
COL_PIC = 1
COL_DO_NUMBER = 2
COL_CUSTOMER_TYPE = 3  # "New Customer" / "Repeat Customer"
COL_NAME = 4           # FB Name
COL_PAGE = 5           # "Whatsapp" / "facebook"
COL_AMOUNT = 6         # "MYR129.50"
COL_DATE = 7           # DD/MM/YYYY
COL_PAYMENT_METHOD = 8
COL_CUSTOMER_DETAIL = 9  # Free-text blob with phone embedded


def load_token() -> str:
    """Load Meta access token."""
    import os
    token = os.environ.get("META_TOKEN", "")
    if token:
        return token

    token_path = Path.home() / "Desktop/_WORK/_shared/.meta-token"
    if token_path.exists():
        return token_path.read_text().strip()

    print("ERROR: No Meta token found.")
    sys.exit(1)


def extract_phone(detail_blob: str) -> Optional[str]:
    """Extract Malaysian phone number from free-text Customer Detail blob.

    The blob contains name, phone, email, address in various formats:
    - "Phone Number: 0123962683"
    - "CHANG KAM HOK，60192921436"
    - inline digits like "01234567890"
    """
    if not detail_blob:
        return None

    # Try explicit phone patterns first
    patterns = [
        r"(?:phone|tel|hp|no\s*hp)[:\s]*(\+?6?0\d[\d\s-]{7,})",
        r"(\+?60\d[\d\s-]{8,})",
        r"(01[0-9][\d\s-]{7,9})",
    ]

    for pattern in patterns:
        match = re.search(pattern, detail_blob, re.IGNORECASE)
        if match:
            digits = re.sub(r"[^\d]", "", match.group(1))
            if 9 <= len(digits) <= 13:
                return normalize_phone(digits)

    # Fallback: find any 10-12 digit sequence starting with 01 or 60
    all_nums = re.findall(r"\b((?:60|0)1\d{8,9})\b", re.sub(r"[^\d\s]", " ", detail_blob))
    if all_nums:
        return normalize_phone(all_nums[0])

    return None


def normalize_phone(phone: str) -> Optional[str]:
    """Normalize Malaysian phone number to +60 format."""
    digits = re.sub(r"[^\d]", "", phone)

    if not digits or len(digits) < 9:
        return None

    if digits.startswith("60"):
        return f"+{digits}"
    elif digits.startswith("0"):
        return f"+6{digits}"
    elif digits.startswith("1") and len(digits) >= 9:
        return f"+60{digits}"

    return f"+{digits}"


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
    """Extract numeric amount from strings like 'MYR129.50'."""
    cleaned = re.sub(r"[^\d.]", "", amount_str)
    try:
        val = float(cleaned)
        return val if val > 0 else None
    except ValueError:
        return None


def sha256_hash(value: str) -> str:
    """SHA-256 hash for Meta's user data matching."""
    return hashlib.sha256(value.strip().lower().encode("utf-8")).hexdigest()


def fetch_orders() -> list:
    """Fetch all orders from Google Sheet."""
    url = f"https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&gid={ORDERS_GID}"
    print("Fetching Pinxin orders from Google Sheet...")
    resp = urllib.request.urlopen(url)
    data = resp.read().decode("utf-8")
    reader = csv.reader(io.StringIO(data))
    header = next(reader)

    orders = []
    phone_found = 0
    phone_missing = 0

    for row in reader:
        if len(row) <= COL_CUSTOMER_DETAIL:
            continue

        date_str = row[COL_DATE].strip()
        amount_str = row[COL_AMOUNT].strip()
        name = row[COL_NAME].strip()
        detail = row[COL_CUSTOMER_DETAIL].strip()
        page = row[COL_PAGE].strip()
        customer_type = row[COL_CUSTOMER_TYPE].strip()

        if not date_str or not amount_str:
            continue

        order_date = parse_date(date_str)
        if not order_date:
            continue

        amount = parse_amount(amount_str)
        if not amount:
            continue

        phone = extract_phone(detail)
        if phone:
            phone_found += 1
        else:
            phone_missing += 1
            continue  # Need phone for CAPI matching

        orders.append({
            "date": order_date,
            "phone": phone,
            "amount": amount,
            "name": name,
            "customer_type": customer_type,
            "page": page,
        })

    print(f"  Found {len(orders)} valid orders (phone extracted: {phone_found}, missing: {phone_missing})")
    return orders


def build_events(orders: list, cutoff_date: datetime) -> list:
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
            "action_source": "physical_store",
            "user_data": {
                "ph": [sha256_hash(order["phone"])],
                "country": [sha256_hash("my")],
            },
            "custom_data": {
                "currency": "MYR",
                "value": order["amount"],
                "content_name": "Pinxin Frozen Vegan",
                "order_id": f"pinxin-{order['date'].strftime('%Y%m%d')}-{sha256_hash(order['phone'])[:8]}",
            },
        }

        if order["name"]:
            first_name = order["name"].split()[0]
            if first_name:
                event["user_data"]["fn"] = [sha256_hash(first_name)]

        events.append(event)

    print(f"  Built {len(events)} events (skipped {skipped} before cutoff)")
    return events


def upload_events(token: str, events: list, dry_run: bool = False) -> dict:
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
            print(f"  Batch {batch_num}/{total_batches}: {events_received} events received by Meta")
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

        if not dry_run:
            time.sleep(1)

    return {
        "total_events": len(events),
        "uploaded": total_uploaded,
        "errors": total_errors,
        "batches": len(results),
    }


def main():
    parser = argparse.ArgumentParser(description="Upload Pinxin WA sales to Meta Offline Conversions")
    parser.add_argument("--days", type=int, default=7, help="Upload orders from last N days (default: 7)")
    parser.add_argument("--dry-run", action="store_true", help="Preview without uploading")
    parser.add_argument("--backfill", action="store_true", help="Upload max lookback (7 days)")
    args = parser.parse_args()

    print("=" * 60)
    print("PINXIN OFFLINE CONVERSIONS PIPELINE")
    print("=" * 60)

    token = load_token()
    print(f"Token loaded: ...{token[-10:]}")

    orders = fetch_orders()
    if not orders:
        print("No valid orders found!")
        return

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

    filtered = [o for o in orders if o["date"] >= cutoff]
    print(f"Orders in range: {len(filtered)}")

    if not filtered:
        print("No orders in the specified date range!")
        return

    print(f"\nSample events:")
    for o in filtered[:5]:
        print(
            f"  {o['date'].strftime('%Y-%m-%d')} | "
            f"{o['phone'][:8]}... | "
            f"RM{o['amount']:>8.2f} | "
            f"{o['customer_type'][:15]:15s} | "
            f"{o['page']}"
        )

    events = build_events(filtered, cutoff)
    if not events:
        print("No valid events to upload!")
        return

    mode = "DRY RUN" if args.dry_run else "LIVE"
    print(f"\nUploading {len(events)} events [{mode}]...")
    result = upload_events(token, events, dry_run=args.dry_run)

    total_revenue = sum(o["amount"] for o in filtered)
    print(f"\n{'=' * 60}")
    print(f"PINXIN OFFLINE CONVERSIONS SUMMARY")
    print(f"{'=' * 60}")
    print(f"Orders: {len(filtered)} | Revenue: RM{total_revenue:,.2f}")
    print(f"Events uploaded: {result['uploaded']}/{result['total_events']}")
    if result["errors"]:
        print(f"Errors: {result['errors']}")
    print(f"Pixel: {PIXEL_ID}")
    print(f"\nEvents Manager: https://business.facebook.com/events_manager2/list/pixel/{PIXEL_ID}/overview")


if __name__ == "__main__":
    main()
