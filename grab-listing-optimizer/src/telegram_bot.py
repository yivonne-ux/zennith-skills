"""Telegram bot interface for GrabFood Listing Optimizer.

Commands:
/start     — Onboard new store
/photo     — Upload food photo → AI enhances → returns optimized image
/menu      — Generate optimized menu copy from current items
/audit     — Audit a GrabFood listing (paste store link)
/optimize  — Full optimization run (photos + copy + upload)
/track     — Get performance report
/status    — Check bot/browser status
/help      — Show available commands
"""

import asyncio
import logging
import os
import tempfile
from pathlib import Path

from telegram import Update, BotCommand
from telegram.ext import (
    Application, CommandHandler, MessageHandler,
    ConversationHandler, ContextTypes, filters,
)

from src.config import TELEGRAM_BOT_TOKEN, PHOTOS_DIR
from src.browser import GrabBrowser
from src.scraper import GrabScraper
from src.editor import GrabEditor
from src.photo_pipeline import PhotoPipeline
from src.copy_generator import generate_menu_copy, generate_item_description
from src.tracker import PerformanceTracker

log = logging.getLogger("grab.bot")

# Conversation states
ONBOARD_EMAIL, ONBOARD_PASSWORD, ONBOARD_STORE = range(3)
PHOTO_WAITING = 10
AUDIT_WAITING = 20

# Store active browser sessions
active_sessions: dict[int, GrabBrowser] = {}  # telegram_user_id → GrabBrowser


def get_session(user_id: int) -> GrabBrowser | None:
    return active_sessions.get(user_id)


# ── /start — Onboard ──────────────────────────────────────────────

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🍜 *GrabFood Listing Optimizer*\n\n"
        "I help hawker stalls get more orders on GrabFood!\n\n"
        "What I do:\n"
        "📸 AI-enhance your food photos\n"
        "✍️ Write bilingual menu descriptions with emojis\n"
        "📊 Track your performance over time\n"
        "🚀 Upload everything to your GrabFood listing\n\n"
        "Commands:\n"
        "/onboard — Connect your GrabMerchant account\n"
        "/photo — Enhance a food photo\n"
        "/menu — Generate menu copy\n"
        "/audit — Audit any GrabFood listing\n"
        "/track — Performance report\n"
        "/help — All commands",
        parse_mode="Markdown",
    )


# ── /onboard — Connect merchant account ───────────────────────────

async def onboard_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🔐 Let's connect your GrabMerchant account.\n\n"
        "Please send your GrabMerchant *email*:\n\n"
        "_(Your credentials are stored locally and never shared)_",
        parse_mode="Markdown",
    )
    return ONBOARD_EMAIL


async def onboard_email(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data["grab_email"] = update.message.text.strip()
    await update.message.reply_text("Now send your GrabMerchant *password*:", parse_mode="Markdown")
    # Delete the email message for security
    await update.message.delete()
    return ONBOARD_PASSWORD


async def onboard_password(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data["grab_password"] = update.message.text.strip()
    # Delete password message immediately
    await update.message.delete()

    await update.message.reply_text(
        "Finally, send your *store name* or *GrabFood store ID*\n"
        "(e.g., `1-C4KGTGJDCBW3TA` or just your store name):",
        parse_mode="Markdown",
    )
    return ONBOARD_STORE


async def onboard_store(update: Update, context: ContextTypes.DEFAULT_TYPE):
    store_id = update.message.text.strip()
    email = context.user_data.get("grab_email", "")
    password = context.user_data.get("grab_password", "")
    user_id = update.effective_user.id

    await update.message.reply_text("🔄 Connecting to GrabMerchant... (this takes ~30 seconds)")

    try:
        # Create browser session
        browser = GrabBrowser(merchant_id=store_id)
        await browser.start()

        # OTP callback via Telegram
        async def otp_callback():
            await update.message.reply_text(
                "🔑 Grab requires OTP verification.\n"
                "Please send the OTP code you received:"
            )
            # Wait for next message from this user
            # In production, use a proper ConversationHandler state
            await asyncio.sleep(60)  # placeholder — needs proper implementation
            return context.user_data.get("otp", "")

        success = await browser.ensure_logged_in(email, password, otp_callback)

        if success:
            active_sessions[user_id] = browser

            # Register in tracker
            tracker = PerformanceTracker(browser)
            tracker.register_merchant(store_id, email)

            # Take initial snapshot
            await tracker.take_snapshot()

            await update.message.reply_text(
                f"✅ Connected to GrabMerchant!\n\n"
                f"Store: `{store_id}`\n"
                f"Session saved — won't need to login again for ~7 days.\n\n"
                f"Try:\n"
                f"/audit — Audit your listing\n"
                f"/photo — Enhance a food photo\n"
                f"/track — See your metrics",
                parse_mode="Markdown",
            )
        else:
            await browser.stop()
            await update.message.reply_text(
                "❌ Login failed. Please check your credentials and try /onboard again."
            )
    except Exception as e:
        log.error(f"Onboard failed: {e}")
        await update.message.reply_text(f"❌ Error: {e}\nTry /onboard again.")

    # Clear credentials from context
    context.user_data.pop("grab_email", None)
    context.user_data.pop("grab_password", None)
    return ConversationHandler.END


async def onboard_cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data.pop("grab_email", None)
    context.user_data.pop("grab_password", None)
    await update.message.reply_text("Onboarding cancelled.")
    return ConversationHandler.END


# ── /photo — Enhance food photo ───────────────────────────────────

async def photo_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "📸 Send me a food photo and I'll make it GrabFood-ready!\n\n"
        "Optionally, include the dish name as caption."
    )
    return PHOTO_WAITING


async def photo_received(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not update.message.photo:
        await update.message.reply_text("Please send a photo (not a file).")
        return PHOTO_WAITING

    await update.message.reply_text("🤖 Enhancing your photo... (15-30 seconds)")

    # Download photo
    photo = update.message.photo[-1]  # Highest resolution
    file = await context.bot.get_file(photo.file_id)

    with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp:
        await file.download_to_drive(tmp.name)
        input_path = tmp.name

    # Get dish name from caption
    dish_name = update.message.caption or "food_item"

    # Run photo pipeline
    merchant_id = f"tg_{update.effective_user.id}"
    pipeline = PhotoPipeline(merchant_id)

    try:
        # Skip FoodShot for now (needs API key), run steps 2+3
        result_path = await pipeline.process(
            input_path=input_path,
            item_name=dish_name,
            skip_foodshot=True,
        )

        # Send back enhanced photo
        with open(result_path, "rb") as f:
            await update.message.reply_photo(
                photo=f,
                caption=(
                    f"✅ *Enhanced: {dish_name}*\n\n"
                    f"📐 800x800px (GrabFood ready)\n"
                    f"🎨 Warm colors + exposure boost\n"
                    f"📤 Ready to upload to your listing!"
                ),
                parse_mode="Markdown",
            )
    except Exception as e:
        log.error(f"Photo processing failed: {e}")
        await update.message.reply_text(f"❌ Processing failed: {e}")
    finally:
        os.unlink(input_path)

    return ConversationHandler.END


# ── /audit — Audit a listing ──────────────────────────────────────

async def audit_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🔍 Send me a GrabFood store link or store ID to audit.\n\n"
        "Example:\n"
        "`https://food.grab.com/my/en/restaurant/online-delivery/1-C4KGTGJDCBW3TA`\n"
        "or just: `1-C4KGTGJDCBW3TA`",
        parse_mode="Markdown",
    )
    return AUDIT_WAITING


async def audit_received(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.strip()

    # Extract store ID from URL or use directly
    store_slug = text
    if "food.grab.com" in text:
        # Extract ID from URL path
        parts = text.rstrip("/").split("/")
        store_slug = parts[-1].split("?")[0]
    elif "r.grab.com" in text:
        # Short link — need to extract from redirect
        if "-1-" in text:
            store_slug = "1-" + text.split("-1-")[-1]

    await update.message.reply_text(f"🔍 Auditing store `{store_slug}`... (30-60 seconds)", parse_mode="Markdown")

    try:
        # Create temporary browser for audit
        browser = GrabBrowser(merchant_id=f"audit_{store_slug}")
        await browser.start()
        scraper = GrabScraper(browser)

        audit = await scraper.audit_listing(store_slug)

        # Format audit results
        grade_emoji = {"A": "🟢", "B": "🟡", "C": "🟠", "D": "🔴"}.get(audit["grade"], "⚪")

        issues_text = "\n".join(f"  ⚠️ {i}" for i in audit["issues"]) or "  None!"
        recs_text = "\n".join(f"  💡 {r}" for r in audit["recommendations"]) or "  Looking good!"

        msg = f"""📋 *Listing Audit Report*

{grade_emoji} *Grade: {audit['grade']}* ({audit['score']}/{audit['max_score']})
🏪 Store: {audit['store_name'] or store_slug}
⭐ Rating: {audit['rating']}
📸 Photos: {audit['photo_coverage']}

*Issues:*
{issues_text}

*Recommendations:*
{recs_text}

_Want to fix these? Use /optimize after connecting with /onboard_"""

        await update.message.reply_text(msg, parse_mode="Markdown")
        await browser.stop()

    except Exception as e:
        log.error(f"Audit failed: {e}")
        await update.message.reply_text(f"❌ Audit failed: {e}")

    return ConversationHandler.END


# ── /track — Performance report ───────────────────────────────────

async def track_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    browser = get_session(user_id)

    if not browser:
        await update.message.reply_text("❌ No connected store. Use /onboard first.")
        return

    await update.message.reply_text("📊 Generating performance report...")

    try:
        tracker = PerformanceTracker(browser)
        await tracker.take_snapshot()
        report = tracker.format_telegram_report()
        await update.message.reply_text(report, parse_mode="Markdown")
    except Exception as e:
        log.error(f"Track failed: {e}")
        await update.message.reply_text(f"❌ Error: {e}")


# ── /help ─────────────────────────────────────────────────────────

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🍜 *GrabFood Listing Optimizer — Commands*\n\n"
        "/onboard — Connect GrabMerchant account\n"
        "/photo — Enhance a food photo (send photo after)\n"
        "/audit — Audit any GrabFood listing\n"
        "/optimize — Full optimization run\n"
        "/track — Performance report\n"
        "/menu — Generate menu copy\n"
        "/status — Check connection status\n"
        "/help — This message\n\n"
        "📸 *Quick photo enhance:* Just send any food photo anytime!",
        parse_mode="Markdown",
    )


# ── Status ────────────────────────────────────────────────────────

async def status_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user_id = update.effective_user.id
    browser = get_session(user_id)

    if browser:
        logged_in = await browser.is_logged_in()
        status = "🟢 Connected & logged in" if logged_in else "🟡 Connected but session expired"
        await update.message.reply_text(
            f"*Status:* {status}\n"
            f"Store: `{browser.merchant_id}`\n\n"
            f"{'Use /onboard to re-login' if not logged_in else 'All good! ✅'}",
            parse_mode="Markdown",
        )
    else:
        await update.message.reply_text("⚪ No store connected. Use /onboard to get started.")


# ── Build & Run ───────────────────────────────────────────────────

def build_app() -> Application:
    """Build the Telegram bot application."""
    app = Application.builder().token(TELEGRAM_BOT_TOKEN).build()

    # Onboard conversation
    onboard_conv = ConversationHandler(
        entry_points=[CommandHandler("onboard", onboard_start)],
        states={
            ONBOARD_EMAIL: [MessageHandler(filters.TEXT & ~filters.COMMAND, onboard_email)],
            ONBOARD_PASSWORD: [MessageHandler(filters.TEXT & ~filters.COMMAND, onboard_password)],
            ONBOARD_STORE: [MessageHandler(filters.TEXT & ~filters.COMMAND, onboard_store)],
        },
        fallbacks=[CommandHandler("cancel", onboard_cancel)],
    )

    # Photo conversation
    photo_conv = ConversationHandler(
        entry_points=[CommandHandler("photo", photo_command)],
        states={
            PHOTO_WAITING: [MessageHandler(filters.PHOTO, photo_received)],
        },
        fallbacks=[CommandHandler("cancel", onboard_cancel)],
    )

    # Audit conversation
    audit_conv = ConversationHandler(
        entry_points=[CommandHandler("audit", audit_command)],
        states={
            AUDIT_WAITING: [MessageHandler(filters.TEXT & ~filters.COMMAND, audit_received)],
        },
        fallbacks=[CommandHandler("cancel", onboard_cancel)],
    )

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_command))
    app.add_handler(CommandHandler("track", track_command))
    app.add_handler(CommandHandler("status", status_command))
    app.add_handler(onboard_conv)
    app.add_handler(photo_conv)
    app.add_handler(audit_conv)

    # Catch-all: any photo sent without command triggers enhancement
    app.add_handler(MessageHandler(filters.PHOTO, photo_received))

    return app


async def run_bot():
    """Start the Telegram bot."""
    if not TELEGRAM_BOT_TOKEN:
        log.error("TELEGRAM_BOT_TOKEN not set in .env")
        return

    app = build_app()

    # Set bot commands for menu
    await app.bot.set_my_commands([
        BotCommand("start", "Get started"),
        BotCommand("onboard", "Connect GrabMerchant account"),
        BotCommand("photo", "Enhance a food photo"),
        BotCommand("audit", "Audit a GrabFood listing"),
        BotCommand("track", "Performance report"),
        BotCommand("menu", "Generate menu copy"),
        BotCommand("help", "Show all commands"),
    ])

    log.info("🍜 GrabFood Listing Optimizer bot starting...")
    await app.run_polling(drop_pending_updates=True)
