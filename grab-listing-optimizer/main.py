"""GrabFood Listing Optimizer — Main entry point.

Usage:
    python main.py bot          # Start Telegram bot
    python main.py audit <id>   # Audit a GrabFood listing
    python main.py photo <path> # Enhance a food photo
    python main.py optimize <merchant_id> <email> <password>  # Full optimization run
"""

import asyncio
import sys
import logging

from rich.console import Console
from rich.logging import RichHandler

console = Console()

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
    handlers=[RichHandler(console=console, rich_tracebacks=True)],
)
log = logging.getLogger("grab")


async def cmd_bot():
    """Start the Telegram bot."""
    from src.telegram_bot import run_bot
    console.print("[bold green]🍜 Starting GrabFood Listing Optimizer Bot...[/]")
    await run_bot()


async def cmd_audit(store_slug: str):
    """Audit a GrabFood listing."""
    from src.browser import GrabBrowser
    from src.scraper import GrabScraper

    console.print(f"[bold]🔍 Auditing store: {store_slug}[/]")

    browser = GrabBrowser(merchant_id=f"audit_{store_slug}")
    try:
        await browser.start()
        scraper = GrabScraper(browser)
        audit = await scraper.audit_listing(store_slug)

        grade_colors = {"A": "green", "B": "yellow", "C": "orange3", "D": "red"}
        color = grade_colors.get(audit["grade"], "white")

        console.print(f"\n[bold {color}]Grade: {audit['grade']}[/] ({audit['score']}/{audit['max_score']})")
        console.print(f"Store: {audit.get('store_name', store_slug)}")
        console.print(f"Rating: {audit['rating']}")
        console.print(f"Photos: {audit['photo_coverage']}")

        if audit["issues"]:
            console.print("\n[bold red]Issues:[/]")
            for issue in audit["issues"]:
                console.print(f"  ⚠️  {issue}")

        if audit["recommendations"]:
            console.print("\n[bold yellow]Recommendations:[/]")
            for rec in audit["recommendations"]:
                console.print(f"  💡 {rec}")

    finally:
        await browser.stop()


async def cmd_photo(photo_path: str, item_name: str = ""):
    """Enhance a food photo."""
    from src.photo_pipeline import PhotoPipeline

    console.print(f"[bold]📸 Enhancing: {photo_path}[/]")

    pipeline = PhotoPipeline(merchant_id="cli")
    result = await pipeline.process(
        input_path=photo_path,
        item_name=item_name or "food_item",
        skip_foodshot=True,  # Skip FoodShot unless API key is set
    )

    console.print(f"[bold green]✅ Done: {result}[/]")
    console.print(f"   800x800px | Warm colors | Exposure boosted | GrabFood ready")


async def cmd_optimize(merchant_id: str, email: str, password: str):
    """Full optimization run for a merchant."""
    from src.browser import GrabBrowser
    from src.scraper import GrabScraper
    from src.editor import GrabEditor
    from src.copy_generator import generate_menu_copy
    from src.tracker import PerformanceTracker

    console.print(f"[bold]🚀 Full optimization: {merchant_id}[/]")

    browser = GrabBrowser(merchant_id=merchant_id)
    try:
        await browser.start()

        # Login
        console.print("  🔐 Logging in...")
        if not await browser.ensure_logged_in(email, password):
            console.print("[bold red]  ❌ Login failed[/]")
            return

        scraper = GrabScraper(browser)
        editor = GrabEditor(browser)
        tracker = PerformanceTracker(browser)

        # Register merchant
        tracker.register_merchant(merchant_id, email)

        # Step 1: Take before snapshot
        console.print("  📊 Taking before snapshot...")
        await tracker.take_snapshot()

        # Step 2: Scrape current menu
        console.print("  📋 Scraping current menu...")
        items = await scraper.scrape_menu()
        console.print(f"     Found {len(items)} menu items")

        # Step 3: Generate optimized copy
        if items:
            console.print("  ✍️  Generating optimized menu copy...")
            item_dicts = [
                {"name": i.name, "price": i.price, "description": i.description, "category": i.category}
                for i in items
            ]
            menu_copy = await generate_menu_copy(item_dicts, store_name=merchant_id)

            if menu_copy:
                console.print(f"     Generated {len(menu_copy.get('categories', []))} categories")

                # Step 4: Apply updates
                console.print("  📤 Applying menu updates...")
                updates = []
                for cat in menu_copy.get("categories", []):
                    for item in cat.get("items", []):
                        updates.append({
                            "item_name": item.get("original_name", ""),
                            "new_name": item.get("name", ""),
                            "new_desc": item.get("description", ""),
                            "new_price": item.get("price", 0),
                        })

                if updates:
                    results = await editor.batch_update_menu(updates)
                    console.print(f"     ✅ {results['success']} updated, ❌ {results['failed']} failed")

                    # Log optimization
                    tracker.log_optimization(
                        "menu_copy",
                        f"Updated {results['success']} items with optimized bilingual copy + emojis",
                    )

        # Step 5: Take after snapshot
        console.print("  📊 Taking after snapshot...")
        await tracker.take_snapshot()

        # Report
        console.print("\n" + "=" * 50)
        report = tracker.generate_report()
        console.print(f"[bold green]✅ Optimization complete![/]")
        console.print(f"   Period: {report.get('period', 'N/A')}")
        console.print(f"   Optimizations: {report.get('optimizations_applied', 0)}")
        console.print(f"\n   Use /track in Telegram for ongoing monitoring.")

    finally:
        await browser.stop()


def main():
    if len(sys.argv) < 2:
        console.print("[bold]🍜 GrabFood Listing Optimizer[/]\n")
        console.print("Usage:")
        console.print("  python main.py bot                              Start Telegram bot")
        console.print("  python main.py audit <store_id>                 Audit a listing")
        console.print("  python main.py photo <path> [name]              Enhance a photo")
        console.print("  python main.py optimize <id> <email> <pass>     Full optimization")
        console.print("\nExamples:")
        console.print("  python main.py audit 1-C4KGTGJDCBW3TA")
        console.print("  python main.py photo ./prawn_noodle.jpg \"Prawn Noodle\"")
        console.print("  python main.py bot")
        sys.exit(0)

    cmd = sys.argv[1]

    if cmd == "bot":
        asyncio.run(cmd_bot())

    elif cmd == "audit":
        if len(sys.argv) < 3:
            console.print("[red]Usage: python main.py audit <store_id>[/]")
            sys.exit(1)
        asyncio.run(cmd_audit(sys.argv[2]))

    elif cmd == "photo":
        if len(sys.argv) < 3:
            console.print("[red]Usage: python main.py photo <path> [name][/]")
            sys.exit(1)
        name = sys.argv[3] if len(sys.argv) > 3 else ""
        asyncio.run(cmd_photo(sys.argv[2], name))

    elif cmd == "optimize":
        if len(sys.argv) < 5:
            console.print("[red]Usage: python main.py optimize <merchant_id> <email> <password>[/]")
            sys.exit(1)
        asyncio.run(cmd_optimize(sys.argv[2], sys.argv[3], sys.argv[4]))

    else:
        console.print(f"[red]Unknown command: {cmd}[/]")
        sys.exit(1)


if __name__ == "__main__":
    main()
