#!/usr/bin/env bash
# jade-engagement-bot.sh — Instagram engagement bot for Jade Oracle
#
# Likes and comments on competitor followers' posts to attract them
# to the Jade Oracle brand. Uses Playwright (Python) with a persistent
# browser profile so the user's existing Instagram session is reused.
#
# Usage:
#   bash jade-engagement-bot.sh --target mysticmichaela --action like --count 5
#   bash jade-engagement-bot.sh --target spiritdaughter --action both --count 10
#   bash jade-engagement-bot.sh --all --action like --count 5
#   bash jade-engagement-bot.sh --target mysticmichaela --dry-run
#
# Rate limits (avoid ban):
#   - Max 10-15 likes/hour, max 3-5 comments/hour
#   - Random 30-90s delay between actions
#   - Stops after --count profiles
#
# macOS Bash 3.2 compatible.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCLAW_DIR="$HOME/.openclaw"
PYTHON3="$(command -v python3 2>/dev/null || echo "/usr/bin/python3")"
PROFILE_DIR="$HOME/.openclaw/browser-profiles/meta-dev"
LOG_DIR="$OPENCLAW_DIR/workspace/data/social-publish"
ENGAGEMENT_LOG="$LOG_DIR/engagement-log.jsonl"

# Hardcoded competitor targets
TARGETS="mysticmichaela spiritdaughter girl_and_her_moon theholisticpsychologist the.tarot.teacher"

# Defaults
TARGET=""
ACTION="like"
COUNT=10
DRY_RUN=0
ALL_MODE=0

###############################################################################
# Argument parsing
###############################################################################
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGET="$2"; shift 2 ;;
        --action)
            ACTION="$2"; shift 2 ;;
        --count)
            COUNT="$2"; shift 2 ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        --all)
            ALL_MODE=1; shift ;;
        -h|--help)
            echo "Usage: bash jade-engagement-bot.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --target ACCOUNT   Competitor account to engage their followers"
            echo "  --action ACTION    like|comment|both (default: like)"
            echo "  --count N          Number of profiles to engage (default: 10)"
            echo "  --dry-run          Log what would happen without acting"
            echo "  --all              Engage across all competitor accounts"
            echo ""
            echo "Competitor targets:"
            echo "  $TARGETS"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Validate
if [[ "$ALL_MODE" -eq 0 && -z "$TARGET" ]]; then
    echo "ERROR: Must specify --target ACCOUNT or --all" >&2
    exit 1
fi

if [[ "$ACTION" != "like" && "$ACTION" != "comment" && "$ACTION" != "both" ]]; then
    echo "ERROR: --action must be like, comment, or both" >&2
    exit 1
fi

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [[ "$COUNT" -lt 1 ]]; then
    echo "ERROR: --count must be a positive integer" >&2
    exit 1
fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Ensure browser profile directory exists
if [[ ! -d "$PROFILE_DIR" ]]; then
    echo "ERROR: Browser profile not found at $PROFILE_DIR" >&2
    echo "       Log into Instagram first via Playwright persistent context." >&2
    exit 1
fi

log() {
    echo "[jade-engagement-bot $(date +%H:%M:%S)] $1"
}

log "Starting engagement bot"
log "  Action: $ACTION | Count: $COUNT | Dry run: $DRY_RUN"
if [[ "$ALL_MODE" -eq 1 ]]; then
    log "  Mode: ALL targets ($TARGETS)"
else
    log "  Target: $TARGET"
fi

###############################################################################
# Build target list
###############################################################################
if [[ "$ALL_MODE" -eq 1 ]]; then
    # Split count across targets
    TARGET_LIST=($TARGETS)
    NUM_TARGETS=${#TARGET_LIST[@]}
    PER_TARGET=$(( COUNT / NUM_TARGETS ))
    # Ensure at least 1 per target
    [[ "$PER_TARGET" -lt 1 ]] && PER_TARGET=1
    log "  Engaging $PER_TARGET profiles per target ($NUM_TARGETS targets)"
    PYTHON_TARGETS=""
    for t in "${TARGET_LIST[@]}"; do
        PYTHON_TARGETS="${PYTHON_TARGETS}\"${t}\","
    done
    # Remove trailing comma
    PYTHON_TARGETS="${PYTHON_TARGETS%,}"
    PYTHON_COUNT="$PER_TARGET"
else
    PYTHON_TARGETS="\"$TARGET\""
    PYTHON_COUNT="$COUNT"
fi

###############################################################################
# Inline Python script
###############################################################################
PYTHON_SCRIPT=$(cat << 'PYEOF'
import sys
import os
import json
import random
import time
from datetime import datetime, timezone

from playwright.sync_api import sync_playwright

###############################################################################
# Config from environment (set by bash wrapper)
###############################################################################
TARGETS       = json.loads(os.environ["EB_TARGETS"])
ACTION        = os.environ["EB_ACTION"]
COUNT         = int(os.environ["EB_COUNT"])
DRY_RUN       = os.environ["EB_DRY_RUN"] == "1"
PROFILE_DIR   = os.environ["EB_PROFILE_DIR"]
LOG_FILE      = os.environ["EB_LOG_FILE"]

COMMENT_TEMPLATES = [
    "this is so beautiful \U0001f90d",
    "needed to hear this today",
    "love this energy \u2728",
    "saving this \U0001f4ab",
    "yes to all of this \U0001f64f",
    "wow this resonates so deeply",
    "absolutely love your page \U0001f33f",
    "this gave me chills",
]

# Rate-limit tracking
MAX_LIKES_PER_HOUR    = 12   # stay in 10-15 range
MAX_COMMENTS_PER_HOUR = 4    # stay in 3-5 range
MIN_DELAY = 30
MAX_DELAY = 90

###############################################################################
# Helpers
###############################################################################
def log(msg):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[jade-engagement-bot {ts}] {msg}", flush=True)

def log_action(entry):
    """Append a JSON line to the engagement log."""
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(json.dumps(entry) + "\n")

def human_delay(min_s=MIN_DELAY, max_s=MAX_DELAY):
    """Sleep a random human-like interval."""
    delay = random.uniform(min_s, max_s)
    log(f"  sleeping {delay:.0f}s ...")
    time.sleep(delay)

def short_delay():
    """Short delay for in-page actions (1-4s)."""
    time.sleep(random.uniform(1.0, 4.0))

def pick_comment(last_comment):
    """Pick a random comment, never repeating the last one."""
    pool = [c for c in COMMENT_TEMPLATES if c != last_comment]
    return random.choice(pool)

def scroll_slowly(page, times=2):
    """Scroll down in a human-like way."""
    for _ in range(times):
        page.mouse.wheel(0, random.randint(200, 500))
        time.sleep(random.uniform(0.5, 1.5))

###############################################################################
# Core engagement logic
###############################################################################
def get_follower_usernames(page, target_account, count):
    """
    Navigate to a competitor account and scrape follower usernames.
    Returns a list of up to `count` usernames.
    """
    log(f"Navigating to @{target_account} ...")
    page.goto(f"https://www.instagram.com/{target_account}/", wait_until="domcontentloaded")
    time.sleep(random.uniform(3.0, 5.0))

    # Click the followers link
    followers_link = page.locator(f'a[href="/{target_account}/followers/"]')
    if followers_link.count() == 0:
        # Try alternative selector
        followers_link = page.get_by_text("followers").first
    if followers_link.count() == 0:
        log(f"  WARNING: Could not find followers link for @{target_account}")
        return []

    followers_link.click()
    time.sleep(random.uniform(3.0, 5.0))

    # Collect usernames from the followers modal
    usernames = []
    seen = set()
    max_scrolls = 10

    for scroll_i in range(max_scrolls):
        # Find username links inside the followers dialog
        dialog = page.locator('[role="dialog"]')
        if dialog.count() == 0:
            # Fallback: look at the whole page
            dialog = page

        links = dialog.locator('a[href^="/"]')
        link_count = links.count()
        for i in range(link_count):
            try:
                href = links.nth(i).get_attribute("href", timeout=2000)
                if href and href.startswith("/") and href.endswith("/"):
                    username = href.strip("/")
                    # Filter out non-profile links
                    if (username
                        and "/" not in username
                        and username != target_account
                        and username not in seen
                        and username not in ("explore", "reels", "stories", "direct", "accounts")):
                        seen.add(username)
                        usernames.append(username)
                        if len(usernames) >= count:
                            break
            except Exception:
                continue

        if len(usernames) >= count:
            break

        # Scroll within the dialog
        try:
            scrollable = dialog.locator('div[style*="overflow"]').first
            if scrollable.count() > 0:
                scrollable.evaluate("el => el.scrollTop += 400")
            else:
                dialog.evaluate("el => el.scrollTop += 400")
        except Exception:
            pass
        time.sleep(random.uniform(1.5, 3.0))

    # Close the dialog
    try:
        page.keyboard.press("Escape")
        time.sleep(1.0)
    except Exception:
        pass

    log(f"  Found {len(usernames)} follower(s) for @{target_account}")
    return usernames[:count]


def like_latest_post(page, username):
    """
    Visit a user's profile and like their most recent post.
    Returns True if successful.
    """
    log(f"  Visiting @{username} to like ...")
    page.goto(f"https://www.instagram.com/{username}/", wait_until="domcontentloaded")
    time.sleep(random.uniform(2.5, 4.5))

    # Click the first post (grid thumbnail)
    posts = page.locator('article a[href*="/p/"], main a[href*="/p/"]')
    if posts.count() == 0:
        log(f"    No posts found for @{username}")
        return False

    posts.first.click()
    time.sleep(random.uniform(2.0, 4.0))

    # Find the like button (heart icon that is NOT already liked)
    # Instagram uses svg with aria-label="Like" or aria-label="Unlike"
    like_btn = page.locator('svg[aria-label="Like"]').first
    if like_btn.count() == 0:
        # Check if already liked
        unlike_btn = page.locator('svg[aria-label="Unlike"]')
        if unlike_btn.count() > 0:
            log(f"    Already liked @{username}'s latest post")
            page.keyboard.press("Escape")
            short_delay()
            return False
        log(f"    Could not find like button for @{username}")
        page.keyboard.press("Escape")
        short_delay()
        return False

    like_btn.click()
    short_delay()
    log(f"    Liked @{username}'s latest post")

    # Close the post modal
    page.keyboard.press("Escape")
    short_delay()
    return True


def comment_on_latest_post(page, username, comment_text):
    """
    Visit a user's profile and comment on their most recent post.
    Returns True if successful.
    """
    log(f"  Visiting @{username} to comment ...")
    page.goto(f"https://www.instagram.com/{username}/", wait_until="domcontentloaded")
    time.sleep(random.uniform(2.5, 4.5))

    # Click the first post
    posts = page.locator('article a[href*="/p/"], main a[href*="/p/"]')
    if posts.count() == 0:
        log(f"    No posts found for @{username}")
        return False

    posts.first.click()
    time.sleep(random.uniform(2.0, 4.0))

    # Find the comment input area
    comment_area = page.locator('textarea[aria-label="Add a comment…"], textarea[placeholder="Add a comment…"]')
    if comment_area.count() == 0:
        # Try clicking the comment icon first
        comment_icon = page.locator('svg[aria-label="Comment"]').first
        if comment_icon.count() > 0:
            comment_icon.click()
            time.sleep(random.uniform(1.0, 2.0))
            comment_area = page.locator('textarea[aria-label="Add a comment…"], textarea[placeholder="Add a comment…"]')

    if comment_area.count() == 0:
        log(f"    Could not find comment area for @{username}")
        page.keyboard.press("Escape")
        short_delay()
        return False

    # Type comment character by character (human-like)
    comment_area.click()
    time.sleep(random.uniform(0.5, 1.0))
    for char in comment_text:
        comment_area.type(char, delay=random.randint(30, 120))
    time.sleep(random.uniform(0.5, 1.5))

    # Post the comment
    post_btn = page.locator('div[role="button"]:has-text("Post"), button:has-text("Post")')
    if post_btn.count() > 0:
        post_btn.first.click()
        time.sleep(random.uniform(2.0, 4.0))
        log(f"    Commented on @{username}'s post: \"{comment_text}\"")
        page.keyboard.press("Escape")
        short_delay()
        return True
    else:
        # Try pressing Enter as fallback
        comment_area.press("Enter")
        time.sleep(random.uniform(2.0, 4.0))
        log(f"    Commented on @{username}'s post (via Enter): \"{comment_text}\"")
        page.keyboard.press("Escape")
        short_delay()
        return True


def engage_profile(page, username, action, last_comment, dry_run, stats):
    """
    Engage with a single profile. Returns updated (last_comment, stats).
    """
    did_like = False
    did_comment = False
    comment_used = None

    if action in ("like", "both"):
        if stats["likes_this_hour"] >= MAX_LIKES_PER_HOUR:
            log(f"  RATE LIMIT: Reached {MAX_LIKES_PER_HOUR} likes/hour, skipping like for @{username}")
        elif dry_run:
            log(f"  [DRY RUN] Would like @{username}'s latest post")
            did_like = True
        else:
            did_like = like_latest_post(page, username)
            if did_like:
                stats["likes_this_hour"] += 1
                stats["total_likes"] += 1

    if action in ("comment", "both"):
        if stats["comments_this_hour"] >= MAX_COMMENTS_PER_HOUR:
            log(f"  RATE LIMIT: Reached {MAX_COMMENTS_PER_HOUR} comments/hour, skipping comment for @{username}")
        else:
            comment_used = pick_comment(last_comment)
            if dry_run:
                log(f"  [DRY RUN] Would comment on @{username}'s post: \"{comment_used}\"")
                did_comment = True
            else:
                did_comment = comment_on_latest_post(page, username, comment_used)
                if did_comment:
                    stats["comments_this_hour"] += 1
                    stats["total_comments"] += 1

    # Build log entry
    entry = {
        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "brand": "jade-oracle",
        "target_username": username,
        "action": action,
        "liked": did_like,
        "commented": did_comment,
        "comment_text": comment_used if did_comment else None,
        "dry_run": dry_run,
    }
    log_action(entry)

    new_last_comment = comment_used if did_comment and comment_used else last_comment
    return new_last_comment, stats


###############################################################################
# Main
###############################################################################
def main():
    log("=" * 60)
    log("Jade Oracle Instagram Engagement Bot")
    log("=" * 60)
    log(f"Targets:  {TARGETS}")
    log(f"Action:   {ACTION}")
    log(f"Count:    {COUNT} per target")
    log(f"Dry run:  {DRY_RUN}")
    log(f"Profile:  {PROFILE_DIR}")
    log(f"Log:      {LOG_FILE}")
    log("")

    stats = {
        "likes_this_hour": 0,
        "comments_this_hour": 0,
        "total_likes": 0,
        "total_comments": 0,
        "total_profiles": 0,
        "errors": 0,
    }
    last_comment = None

    with sync_playwright() as pw:
        log("Launching browser (persistent context, headless=False) ...")
        context = pw.chromium.launch_persistent_context(
            user_data_dir=PROFILE_DIR,
            headless=False,
            viewport={"width": 1280, "height": 900},
            user_agent=(
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/125.0.0.0 Safari/537.36"
            ),
            locale="en-US",
            timezone_id="Asia/Kuala_Lumpur",
            args=["--disable-blink-features=AutomationControlled"],
        )

        page = context.new_page()

        # Quick login check
        log("Checking Instagram session ...")
        page.goto("https://www.instagram.com/", wait_until="domcontentloaded")
        time.sleep(random.uniform(3.0, 5.0))

        # If we see a login form, abort
        if page.locator('input[name="username"]').count() > 0:
            log("ERROR: Not logged into Instagram. Please log in manually first.")
            context.close()
            sys.exit(1)

        log("Session valid. Starting engagement ...\n")

        for target_account in TARGETS:
            log(f"--- Target: @{target_account} ---")

            try:
                follower_usernames = get_follower_usernames(page, target_account, COUNT)
            except Exception as e:
                log(f"  ERROR scraping followers of @{target_account}: {e}")
                stats["errors"] += 1
                continue

            if not follower_usernames:
                log(f"  No followers found, skipping @{target_account}")
                continue

            for idx, username in enumerate(follower_usernames):
                log(f"\n  [{idx+1}/{len(follower_usernames)}] Engaging @{username} ...")
                stats["total_profiles"] += 1

                try:
                    last_comment, stats = engage_profile(
                        page, username, ACTION, last_comment, DRY_RUN, stats
                    )
                except Exception as e:
                    log(f"    ERROR engaging @{username}: {e}")
                    stats["errors"] += 1
                    # Log the error
                    log_action({
                        "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        "brand": "jade-oracle",
                        "target_username": username,
                        "action": ACTION,
                        "liked": False,
                        "commented": False,
                        "error": str(e),
                        "dry_run": DRY_RUN,
                    })

                # Human-like delay between profiles (skip after last one)
                if idx < len(follower_usernames) - 1:
                    human_delay()

            # Delay between different target accounts
            if target_account != TARGETS[-1]:
                log(f"\nSwitching to next target, extra pause ...")
                human_delay(45, 120)

        # Close
        page.close()
        context.close()

    # Summary
    log("")
    log("=" * 60)
    log("ENGAGEMENT SUMMARY")
    log("=" * 60)
    log(f"  Profiles engaged: {stats['total_profiles']}")
    log(f"  Likes:            {stats['total_likes']}")
    log(f"  Comments:         {stats['total_comments']}")
    log(f"  Errors:           {stats['errors']}")
    log(f"  Dry run:          {DRY_RUN}")
    log(f"  Log file:         {LOG_FILE}")
    log("=" * 60)


if __name__ == "__main__":
    main()
PYEOF
)

###############################################################################
# Export environment for Python and run
###############################################################################
export EB_TARGETS="[$PYTHON_TARGETS]"
export EB_ACTION="$ACTION"
export EB_COUNT="$PYTHON_COUNT"
export EB_DRY_RUN="$DRY_RUN"
export EB_PROFILE_DIR="$PROFILE_DIR"
export EB_LOG_FILE="$ENGAGEMENT_LOG"

log "Launching Python engagement bot ..."
echo ""

"$PYTHON3" -c "$PYTHON_SCRIPT"
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
    log "ERROR: Python script exited with code $EXIT_CODE"
    exit $EXIT_CODE
fi

log "Done."
