"""Master Scheduler — orchestrates the full menu generation pipeline."""

from datetime import datetime
from ..data.models import (
    Dish, MenuSlot, MenuPlan, MealPeriod,
    PreviousMonthEntry, ComplianceReport,
)
from .slot_builder import SlotBuilder
from .constraint_checker import ConstraintChecker
from .backtracker import CSPBacktracker


class MasterScheduler:
    """Orchestrates slot building → CSP solving → compliance checking."""

    def generate_menu(
        self,
        target_month: str,
        previous_entries: list[PreviousMonthEntry],
        dishes: list[Dish],
        holidays: list = None,
        desired_new_dishes: int = 3,
        new_dish_pool: list[Dish] = None,
    ) -> tuple[MenuPlan, dict]:
        """
        Full generation flow.
        Returns (MenuPlan, assignment_dict).
        """
        holidays = holidays or []

        # 1. Build slots
        builder = SlotBuilder(holidays=holidays)
        slots = builder.build_slots(target_month)
        print(f"[Scheduler] Built {len(slots)} slots for {target_month} "
              f"({len(slots)//2} days, {builder.get_week_count(slots)} weeks)")

        # 2. Set up constraint checker
        checker = ConstraintChecker(previous_entries, dishes, target_month)

        # 3. Run CSP solver (up to 3 retries)
        for attempt in range(1, 4):
            print(f"[Scheduler] Attempt {attempt}/3...")
            solver = CSPBacktracker(checker, target_month)
            assignment = solver.solve(
                slots, dishes,
                new_dish_pool=new_dish_pool,
                required_new_count=desired_new_dishes,
            )
            if assignment is not None:
                print(f"[Scheduler] Solved in {solver.iteration_count} iterations")
                break
            print(f"[Scheduler] Attempt {attempt} failed")
        else:
            raise RuntimeError(f"Could not generate valid menu after 3 attempts")

        # 4. Build MenuPlan
        new_ids = [d.id for d in (new_dish_pool or [])[:desired_new_dishes]]
        plan = MenuPlan(
            month=target_month,
            slots=slots,
            new_dish_ids=new_ids,
            generated_at=datetime.now().isoformat(),
            csp_iterations=solver.iteration_count,
        )

        return plan, assignment

    def print_menu(self, plan: MenuPlan, assignment: dict):
        """Pretty-print the generated menu."""
        current_week = 0
        for slot in sorted(plan.slots, key=lambda s: (s.date, s.meal_period.value)):
            if slot.week_number != current_week:
                current_week = slot.week_number
                print(f"\n{'='*50}")
                print(f"  WEEK {current_week}")
                print(f"{'='*50}")

            dish = assignment.get(slot)
            if dish is None:
                continue

            prefix = "L" if slot.meal_period == MealPeriod.LUNCH else "D"
            spicy = " 🌶️" if dish.spicy else ""
            new = " (NEW)" if slot.is_new else ""
            cn = f" | {dish.name_cn}" if dish.name_cn else ""

            if slot.meal_period == MealPeriod.LUNCH:
                print(f"\n  {slot.day_name[:3].upper()} {slot.date.day:2d}  "
                      f"{prefix} - {dish.name}{spicy}{new}{cn}")
            else:
                print(f"          {prefix} - {dish.name}{spicy}{new}{cn}")
