#!/usr/bin/env python3
"""
MIRRA Social Post Scheduler — replaces cron.
Runs every 10 minutes via launchd. Posts anything that's due.
Idempotent: checks post-log to avoid duplicates.
Handles sleep/wake: catches up on missed posts when machine wakes.
"""
import json, time, sys, os
from pathlib import Path
from datetime import datetime, timedelta, timezone

MYT = timezone(timedelta(hours=8))
NOW = datetime.now(MYT)

LOG = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/06_exports/social/42-posts/.post-log.json")
SCHEDULER_LOG = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/06_exports/social/42-posts/.scheduler-log.txt")
SCRIPT = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/05_scripts/post_single.py")

# Batch 2 folder + file mapping (indices 100+)
BATCH2_DIR = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/06_exports/social/batch2-v4")
BATCH2_FILES = {
    100: "B2-03-healing-era.png",
    101: "B2-17-heart-insane.png",
    102: "B2-20-neon-soft.png",
    103: "F2-nasi-poster.png",
    104: "B2-32-cat-prioritizing.png",
    105: "B2-21-reinventing.png",
    106: "B2-02-double-coffee.png",
    107: "B2-18-self-care.png",
    108: "F6-eat-little-lot.png",
    109: "B2-05-two-moods.png",
    110: "B2-33-head-empty.png",
    111: "B2-36-demand.png",
    112: "B2-09-midnight-promises.png",
    113: "B2-19-standing-business.png",
    114: "B2-35-stopped-explaining.png",
    115: "F9-girl-dinner.png",
    116: "B2-24-saving-money.png",
    117: "F8-four-minutes.png",
    118: "B2-22-monday-no-thanks.png",
    119: "B2-34-drama-queen.png",
    120: "B2-37-soft-life-strong.png",
    121: "B2-04-pretending-to-work.png",
    122: "B2-08-its-later.png",
    123: "F11-calorically.png",
    124: "B2-06-reply-all.png",
    125: "B2-26-carrots.png",
    126: "F4-quit-job-dinner.png",
    127: "B2-07-soft-life.png",
    128: "B2-01-corporate-npc.png",
    129: "B2-10-what-ill-be.png",
}

# Batch 2 captions (Mirra voice — no exclamation marks, girlboss, minimal)
BATCH2_CAPTIONS = {
    100: "the glow up is real.\n\n#mirra #glowup #healingera #beforeafter",
    101: "and that's on self belief.\n\n#mirra #queenenergy #unbothered #insane",
    102: "soft is my favourite kind of strength.\n\n#mirra #softlife #strength #feminineenergy",
    103: "future plans? lunch.\n\n#mirra #nasilemak #lunchgoals #foodposter",
    104: "priorities.\n\n#mirra #queencat #selfcare #prioritizeme",
    105: "note to self.\n\n#mirra #reinventing #3am #selflove",
    106: "we've all been there.\n\n#mirra #coffee #morningroutine #relatable",
    107: "me being financially irresponsible in the name of self care.\n\n#mirra #selfcare #treatyourself #queenlife",
    108: "same calories. read that again.\n\n#mirra #volumeeating #eatmore #dietbento",
    109: "two settings. both involve food.\n\n#mirra #twomoods #goblinmode #thatgirl",
    110: "no thoughts. head empty.\n\n#mirra #nothoughts #vibes #sparkle",
    111: "demand what you want like it's non-negotiable.\n\n#mirra #queenenergy #standards #nonnegotiable",
    112: "we all know how this ends.\n\n#mirra #midnightpromises #sleepytime #relatable",
    113: "standing on business.\n\n#mirra #confidence #business #unbothered",
    114: "she stopped explaining herself and her life got quieter.\n\n#mirra #peace #boundaries #lettinggo",
    115: "girl dinner but make it actually nutritious.\n\n#mirra #girldinner #dietbento #cleaneating",
    116: "saving money this month vs me ordering delivery for the 5th time.\n\n#mirra #savingmoney #delivery #relatable",
    117: "saving half for later. four minutes later.\n\n#mirra #foodhumor #bentobox #relatable",
    118: "monday is a state of mind. mine is 'no thanks.'\n\n#mirra #monday #nothanks #corporatelife",
    119: "drama queen energy. no apologies given.\n\n#mirra #dramaqueen #noapologies #queenenergy",
    120: "soft life, strong woman.\n\n#mirra #softlife #strongwoman #identity",
    121: "just admit it y'all are pretending to work most of the time.\n\n#mirra #pretendingtowork #corporate #9to5",
    122: "12pm: saving the other half for later. 12:10pm: it's later.\n\n#mirra #foodhumor #bento #relatable",
    123: "whatever happen calorically this weekend can never happen again.\n\n#mirra #weekendcalories #dietbento #mondaymotivation",
    124: "everything will work out because i'm insane.\n\n#mirra #replyall #corporatelife #insane",
    125: "carrots are a great thing to eat when you are hungry and want to stay that way.\n\n#mirra #carrots #foodhumor #ordermirra",
    126: "i should quit my job to focus on dinner.\n\n#mirra #quitjob #dinner #foodpriorities",
    127: "i want a soft life. ease. rest — not as a reward but as practice.\n\n#mirra #softlife #rest #selfcare",
    128: "equal parts professional and unhinged.\n\n#mirra #corporatenpc #workvshome #relatable",
    129: "me at 29 wondering what i'll be when i grow up.\n\n#mirra #adulting #career #relatable",
}

# ── Full schedule: (year, month, day, hour, minute) → index ──
# UPDATED Mar 30: 6 posts/day at 8am, 10am, 12pm, 3pm, 6pm, 9pm MYT
# Remaining 41 pending posts (index 0 + 6-41 + 43-46) at 6/day = ~7 days
# Grid rhythm applied: BOLD → PHOTO → CLEAN per row of 3
# Posts already published (indices 1,2,3,4,5,42) are NOT in this schedule.
SCHEDULE = {
    # === ALREADY POSTED (keep for log consistency) ===
    (2026, 3, 28, 21, 0): 1,
    (2026, 3, 29, 12, 0): 2,
    (2026, 3, 29, 21, 0): 4,
    (2026, 3, 30, 10, 0): 1,   # repost
    (2026, 3, 30, 10, 1): 3,
    (2026, 3, 30, 12, 0): 5,
    (2026, 3, 30, 14, 0): 42,

    # === DAY 4 — Tue Mar 31 (6 posts) ===
    # Row 1: BOLD → PHOTO → CLEAN
    (2026, 3, 31, 8, 0): 0,    # D01-1 feminine-urge (BOLD illustration)
    (2026, 3, 31, 10, 0): 6,   # D03-1 delulu-solulu (BOLD illustration — grid break, but varied format)
    (2026, 3, 31, 12, 0): 7,   # D03-2 carrying-everything (illustration)
    # Row 2:
    (2026, 3, 31, 15, 0): 8,   # D03-3 window-right-people (illustration)
    (2026, 3, 31, 18, 0): 9,   # D04-1 corporate-girl (illustration)
    (2026, 3, 31, 21, 0): 10,  # D04-2 empire-nap (illustration)

    # === DAY 5 — Wed Apr 1 (6 posts) ===
    (2026, 4, 1, 8, 0): 11,    # D04-3 she-is-poster
    (2026, 4, 1, 10, 0): 12,   # D05-1 dont-compete
    (2026, 4, 1, 12, 0): 13,   # D05-2 note-future-self
    (2026, 4, 1, 15, 0): 14,   # D05-3 2026-energy
    (2026, 4, 1, 18, 0): 15,   # D06-1 mirror-pep-talk
    (2026, 4, 1, 21, 0): 16,   # D06-2 comfort-food-world

    # === DAY 6 — Thu Apr 2 (6 posts) ===
    (2026, 4, 2, 8, 0): 17,    # D06-3 flip-phone
    (2026, 4, 2, 10, 0): 18,   # D07-1 eat-little-eat-lot
    (2026, 4, 2, 12, 0): 19,   # D07-2 bank-account
    (2026, 4, 2, 15, 0): 20,   # D07-3 toxic-trait-20
    (2026, 4, 2, 18, 0): 21,   # D08-1 too-many-tabs
    (2026, 4, 2, 21, 0): 22,   # D08-2 more-fries

    # === DAY 7 — Fri Apr 3 (6 posts) ===
    (2026, 4, 3, 8, 0): 23,    # D08-3 be-strong-coffee
    (2026, 4, 3, 10, 0): 24,   # D09-1 motivation-fail
    (2026, 4, 3, 12, 0): 25,   # D09-2 same-calories
    (2026, 4, 3, 15, 0): 26,   # D09-3 volume-comparison
    (2026, 4, 3, 18, 0): 27,   # D10-1 expectations-reality
    (2026, 4, 3, 21, 0): 28,   # D10-2 labeled-morning

    # === DAY 8 — Sat Apr 4 (6 posts) ===
    (2026, 4, 4, 8, 0): 29,    # D10-3 yishigan-dict (CN)
    (2026, 4, 4, 10, 0): 30,   # D11-1 cart-close
    (2026, 4, 4, 12, 0): 31,   # D11-2 note-reminder
    (2026, 4, 4, 15, 0): 32,   # D11-3 she-doesnt-cn
    (2026, 4, 4, 18, 0): 33,   # D12-1 hot-girls-order-in
    (2026, 4, 4, 21, 0): 34,   # D12-2 love-language

    # === DAY 9 — Sun Apr 5 (6 posts) ===
    (2026, 4, 5, 8, 0): 35,    # D12-3 manifesting-cn
    (2026, 4, 5, 10, 0): 36,   # D13-1 labeled-pad-thai
    (2026, 4, 5, 12, 0): 37,   # D13-2 cat-eating
    (2026, 4, 5, 15, 0): 38,   # D13-3 two-moods-glitter
    (2026, 4, 5, 18, 0): 39,   # D14-1 morning-routine
    (2026, 4, 5, 21, 0): 40,   # D14-2 toxic-job-cn

    # === DAY 10 — Mon Apr 6 (5 posts — batch 1 final) ===
    (2026, 4, 6, 8, 0): 41,    # D14-3 plot-twist
    (2026, 4, 6, 10, 0): 43,   # EXTRA labeled-curry-konjac
    (2026, 4, 6, 12, 0): 44,   # EXTRA labeled-eryngii-rice
    (2026, 4, 6, 15, 0): 45,   # EXTRA labeled-lemon-mushroom
    (2026, 4, 6, 18, 0): 46,   # EXTRA labeled-teriyaki-bowl

    # ================================================================
    # BATCH 2 — 30 posts, Apr 7-11 (6/day)
    # Source: 06_exports/social/batch2-v4/
    # Indices 100+ to avoid collision with batch 1 (0-46)
    # Grid rhythm: BOLD → PHOTO → CLEAN per row of 3
    # ================================================================

    # === DAY 11 — Tue Apr 7 (6 posts) ===
    # Row 1: BOLD illustration → PHOTO sparkle → CLEAN editorial
    (2026, 4, 7, 8, 0): 100,   # B2-03 healing-era (BOLD — strong opener, blue→pink contrast)
    (2026, 4, 7, 10, 0): 101,  # B2-17 heart-insane cat bath (PHOTO — sparkle queen)
    (2026, 4, 7, 12, 0): 102,  # B2-20 neon-soft strength (CLEAN — pink gradient)
    # Row 2: BOLD food → PHOTO sparkle → CLEAN editorial
    (2026, 4, 7, 15, 0): 103,  # F2 NASI. poster (BOLD — food typography, lunch slot)
    (2026, 4, 7, 18, 0): 104,  # B2-32 cat-prioritizing flamingo (PHOTO — sparkle cat sunset)
    (2026, 4, 7, 21, 0): 105,  # B2-21 reinventing note card (CLEAN — blush paper)

    # === DAY 12 — Wed Apr 8 (6 posts) ===
    (2026, 4, 8, 8, 0): 106,   # B2-02 double-coffee (BOLD — morning relatable)
    (2026, 4, 8, 10, 0): 107,  # B2-18 self-care beach (PHOTO — sparkle beach)
    (2026, 4, 8, 12, 0): 108,  # F6 eat-little-lot split (CLEAN — grey/blush editorial)
    (2026, 4, 8, 15, 0): 109,  # B2-05 two-moods 2x2 (BOLD — weekend energy)
    (2026, 4, 8, 18, 0): 110,  # B2-33 head-empty pink sparkle (PHOTO — pink sparkle)
    (2026, 4, 8, 21, 0): 111,  # B2-36 demand non-negotiable (CLEAN — pink gradient stars)

    # === DAY 13 — Thu Apr 9 (6 posts) ===
    (2026, 4, 9, 8, 0): 112,   # B2-09 midnight-promises (BOLD — morning contrast)
    (2026, 4, 9, 10, 0): 113,  # B2-19 standing-business digicam (PHOTO — pink retro)
    (2026, 4, 9, 12, 0): 114,  # B2-35 stopped-explaining (CLEAN — watercolor editorial)
    (2026, 4, 9, 15, 0): 115,  # F9 GIRL DINNER. (BOLD — food viral, afternoon)
    (2026, 4, 9, 18, 0): 116,  # B2-24 saving-money meme (PHOTO — vintage film)
    (2026, 4, 9, 21, 0): 117,  # F8 four-minutes-later split (CLEAN — blush editorial)

    # === DAY 14 — Fri Apr 10 (6 posts) ===
    (2026, 4, 10, 8, 0): 118,  # B2-22 monday-no-thanks (BOLD — illustration, works any day)
    (2026, 4, 10, 10, 0): 119, # B2-34 drama-queen balloon (PHOTO — pink balloon)
    (2026, 4, 10, 12, 0): 120, # B2-37 SOFT LIFE STRONG WOMAN (CLEAN — massive block pink)
    (2026, 4, 10, 15, 0): 121, # B2-04 pretending-to-work (BOLD — work humor)
    (2026, 4, 10, 18, 0): 122, # B2-08 its-later bento (BOLD — food illustration)
    (2026, 4, 10, 21, 0): 123, # F11 calorically-weekend (CLEAN — salmon bold type)

    # === DAY 15 — Sat Apr 11 (6 posts) ===
    (2026, 4, 11, 8, 0): 124,  # B2-06 reply-all (BOLD — work panic)
    (2026, 4, 11, 10, 0): 125, # B2-26 carrots (BOLD — food humor illustration)
    (2026, 4, 11, 12, 0): 126, # F4 quit-job-dinner (BOLD — food poster, lunch)
    (2026, 4, 11, 15, 0): 127, # B2-07 soft-life (BOLD — self-care)
    (2026, 4, 11, 18, 0): 128, # B2-01 corporate-npc (BOLD — work humor)
    (2026, 4, 11, 21, 0): 129, # B2-10 what-ill-be (BOLD — career humor)
}


def get_posted_indices():
    """Read post-log and return set of successfully posted indices."""
    if not LOG.exists():
        return set()
    try:
        entries = json.loads(LOG.read_text())
        # Only count entries with ig_id (successful publishes)
        return {e["index"] for e in entries if e.get("ig_id")}
    except Exception:
        return set()


def log_msg(msg):
    """Append to scheduler log."""
    ts = NOW.strftime("%Y-%m-%d %H:%M:%S")
    with open(SCHEDULER_LOG, "a") as f:
        f.write(f"[{ts}] {msg}\n")


def post(index):
    """Run post_single.py for given index, or handle batch 2 directly."""
    import subprocess
    if index >= 100:
        # Batch 2 — post directly using Meta API
        filename = BATCH2_FILES.get(index)
        if not filename:
            return False, f"No file mapped for batch 2 index {index}"
        filepath = BATCH2_DIR / filename
        if not filepath.exists():
            return False, f"File not found: {filepath}"
        caption = BATCH2_CAPTIONS.get(index, "")
        # Use post_single.py with --file and --caption args
        result = subprocess.run(
            [sys.executable, str(SCRIPT), str(index), "--file", str(filepath), "--caption", caption],
            capture_output=True, text=True, timeout=120
        )
        return result.returncode == 0, result.stdout + result.stderr
    else:
        # Batch 1 — original behavior
        result = subprocess.run(
            [sys.executable, str(SCRIPT), str(index)],
            capture_output=True, text=True, timeout=120
        )
        return result.returncode == 0, result.stdout + result.stderr


if __name__ == "__main__":
    posted = get_posted_indices()
    due_posts = []

    for time_tuple, index in SCHEDULE.items():
        scheduled_time = datetime(*time_tuple, tzinfo=MYT)
        if scheduled_time <= NOW and index not in posted:
            due_posts.append((scheduled_time, index))

    if not due_posts:
        log_msg("No posts due.")
        sys.exit(0)

    # Sort by scheduled time (oldest first)
    due_posts.sort(key=lambda x: x[0])

    log_msg(f"{len(due_posts)} post(s) due: {[idx for _, idx in due_posts]}")

    for scheduled_time, index in due_posts:
        delay_mins = (NOW - scheduled_time).total_seconds() / 60
        log_msg(f"Posting index {index} (scheduled {scheduled_time.strftime('%m/%d %H:%M')}, delay: {delay_mins:.0f}min)")

        ok, output = post(index)
        if ok:
            log_msg(f"  OK: index {index}")
        else:
            log_msg(f"  FAILED: index {index}\n{output}")

        time.sleep(5)  # Rate limit buffer between posts

    log_msg("Scheduler run complete.")
