#!/usr/bin/env python3
"""
Mirra Auto-Menu Pipeline
━━━━━━━━━━━━━━━━━━━━━━━━
Usage:
  python3 run_pipeline.py generate --month 2026-04
  python3 run_pipeline.py generate --month 2026-04 --dry-run
"""

import sys
import json
import argparse
from datetime import date
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent))

from src.data.dish_database import MirraDishDatabase
from src.data.models import MealPeriod
from src.planner.master_scheduler import MasterScheduler
from src.auditor.logic_auditor import LogicAuditor
from src.design.pil_renderer import MirraPILRenderer


def cmd_generate(args):
    month = args.month  # e.g. "2026-04"
    print(f"\n{'='*60}")
    print(f"  MIRRA AUTO-MENU PIPELINE — {month}")
    print(f"{'='*60}\n")

    # 1. Load dish database
    print("[1/5] Loading dish database...")
    db = MirraDishDatabase().load_default()
    db.print_summary()

    # 2. Load previous month data
    print("\n[2/5] Loading March 2026 (previous month)...")
    previous = db.get_march_2026_entries()
    print(f"  {len(previous)} entries from March 2026")

    # 3. Configure holidays
    # April 2026 Malaysia: Nuzul Al-Quran = April 10 (check)
    holidays = [date(2026, 4, 10)]  # Nuzul Al-Quran
    print(f"\n[3/5] Holidays: {[str(h) for h in holidays]}")

    # 4. Generate menu
    print("\n[4/5] Running CSP solver...")
    scheduler = MasterScheduler()
    dishes = db.get_active_dishes()

    # New dish candidates (dishes NOT in March)
    march_names = set(e.dish_name for e in previous)
    new_pool = [d for d in dishes if d.name not in march_names]

    plan, assignment = scheduler.generate_menu(
        target_month=month,
        previous_entries=previous,
        dishes=dishes,
        holidays=holidays,
        desired_new_dishes=3,
        new_dish_pool=new_pool,
    )

    # 5. Audit
    print("\n[5/5] Running compliance audit...")
    auditor = LogicAuditor()
    report = auditor.audit(plan, previous)

    # Print results
    print(f"\n{'='*60}")
    print(f"  COMPLIANCE REPORT")
    print(f"{'='*60}")
    print(f"  Score: {report.score:.0f}/100  Grade: {report.grade}")
    print(f"  Critical: {report.critical_count}  Important: {report.important_count}  Optimization: {report.optimization_count}")
    print(f"  Approved: {'✅ YES' if report.is_approved else '❌ NO'}")

    if report.violations:
        print(f"\n  Violations:")
        for v in report.violations:
            print(f"    [{v.severity.value:12s}] Rule {v.rule_number} ({v.rule_name}): {v.description}")

    # Print menu
    print(f"\n{'='*60}")
    print(f"  APRIL 2026 MENU")
    print(f"{'='*60}")
    scheduler.print_menu(plan, assignment)

    # Export JSON
    if not args.dry_run:
        output_dir = Path(__file__).parent / "output"
        output_dir.mkdir(exist_ok=True)
        menu_data = []
        for slot in sorted(plan.slots, key=lambda s: (s.date, s.meal_period.value)):
            dish = assignment.get(slot)
            if dish:
                menu_data.append({
                    "date": str(slot.date),
                    "day": slot.day_name,
                    "week": slot.week_number,
                    "meal": slot.meal_period.value,
                    "dish": dish.name,
                    "dish_cn": dish.name_cn,
                    "cuisine": dish.cuisine,
                    "spicy": dish.spicy,
                    "base": dish.base_ingredient.value,
                    "is_new": slot.is_new,
                })
        
        out_path = output_dir / f"mirra_menu_{month}.json"
        with open(out_path, "w") as f:
            json.dump({
                "month": month,
                "generated_at": plan.generated_at,
                "csp_iterations": plan.csp_iterations,
                "score": report.score,
                "grade": report.grade,
                "violations": len(report.violations),
                "menu": menu_data,
            }, f, indent=2, ensure_ascii=False)
        print(f"\n  Saved: {out_path}")

    # Generate PDFs using PIL renderer (real floral background + text overlay)
    if not args.dry_run:
        print(f"\n[PDF] Rendering with real Mirra background...")
        holidays_dict = {date(2026, 4, 10): "Nuzul Al-Quran Holiday"}
        renderer = MirraPILRenderer()

        # English PDF
        pdf_en = str(output_dir / f"mirra_menu_{month}_en.pdf")
        renderer.render_pdf(plan, assignment, holidays=holidays_dict, lang="en", output_path=pdf_en)

        # Chinese PDF
        pdf_cn = str(output_dir / f"mirra_menu_{month}_cn.pdf")
        renderer.render_pdf(plan, assignment, holidays=holidays_dict, lang="cn", output_path=pdf_cn)

        # Also save individual PNGs
        renderer.render_all_pages(plan, assignment, holidays=holidays_dict, lang="en", output_dir=str(output_dir / "pages"))

    print(f"\n{'='*60}")
    print(f"  DONE — {plan.csp_iterations} CSP iterations")
    print(f"{'='*60}\n")


def main():
    parser = argparse.ArgumentParser(description="Mirra Auto-Menu Pipeline")
    sub = parser.add_subparsers(dest="command")

    gen = sub.add_parser("generate", help="Generate a new menu")
    gen.add_argument("--month", required=True, help="Target month (YYYY-MM)")
    gen.add_argument("--dry-run", action="store_true", help="Plan only, no export")

    args = parser.parse_args()
    if args.command == "generate":
        cmd_generate(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
