"""CSP Backtracker — constraint satisfaction solver with MRV + randomization."""

import random
import time
from typing import Optional
from ..data.models import Dish, MenuSlot, MenuPlan, MealPeriod
from .constraint_checker import ConstraintChecker


class CSPBacktracker:
    """Backtracking CSP solver with MRV heuristic and randomization."""

    def __init__(self, checker: ConstraintChecker, target_month: str):
        self.checker = checker
        self.month = target_month
        self.iteration_count = 0
        self.max_iterations = 100_000
        self.start_time = 0.0
        self.timeout_seconds = 30.0
        self.relaxed_rules: list[str] = []

    def solve(
        self,
        slots: list[MenuSlot],
        dishes: list[Dish],
        new_dish_pool: list[Dish] = None,
        required_new_count: int = 3,
    ) -> Optional[dict[MenuSlot, Dish]]:
        """Main entry point. Returns slot→dish assignment or None."""
        self.iteration_count = 0
        self.start_time = time.time()
        new_dish_pool = new_dish_pool or []
        new_dish_ids = set()

        # Pre-select NEW dishes (from pool, placed in weeks 2-4)
        if new_dish_pool and required_new_count > 0:
            random.shuffle(new_dish_pool)
            for d in new_dish_pool[:required_new_count]:
                new_dish_ids.add(d.id)

        assignment: dict[MenuSlot, Dish] = {}
        unassigned = list(slots)

        result = self._backtrack(unassigned, assignment, dishes, new_dish_ids)
        if result is not None:
            return result

        # If failed, try relaxing Rule 9, then retry
        print(f"[CSP] Failed after {self.iteration_count} iterations. Relaxing Rule 9...")
        self.relaxed_rules.append("rule9")
        self.iteration_count = 0
        self.start_time = time.time()
        assignment = {}
        return self._backtrack(list(slots), assignment, dishes, new_dish_ids)

    def _backtrack(
        self,
        unassigned: list[MenuSlot],
        assignment: dict[MenuSlot, Dish],
        all_dishes: list[Dish],
        new_dish_ids: set,
    ) -> Optional[dict[MenuSlot, Dish]]:
        if not unassigned:
            return assignment

        if self.iteration_count >= self.max_iterations:
            return None
        if time.time() - self.start_time > self.timeout_seconds:
            return None

        self.iteration_count += 1

        # MRV: pick slot with fewest candidates
        slot = self._select_slot(unassigned, assignment, all_dishes, new_dish_ids)
        candidates = self.checker.get_valid_candidates(
            slot, all_dishes, assignment, new_dish_ids
        )

        # Randomize for variety
        random.shuffle(candidates)

        # Prefer NEW dishes for week 2-4 slots if we still need them
        if slot.week_number >= 2:
            new_candidates = [c for c in candidates if c.id in new_dish_ids]
            other_candidates = [c for c in candidates if c.id not in new_dish_ids]
            # Only force new if we haven't placed enough yet
            placed_new = sum(1 for d in assignment.values() if d.id in new_dish_ids)
            remaining_slots = len(unassigned)
            needed_new = len(new_dish_ids) - placed_new
            if needed_new > 0 and remaining_slots <= needed_new * 3:
                candidates = new_candidates + other_candidates

        remaining = [s for s in unassigned if s != slot]

        for dish in candidates:
            assignment[slot] = dish
            slot.assigned_dish = dish
            if dish.id in new_dish_ids:
                slot.is_new = True

            result = self._backtrack(remaining, assignment, all_dishes, new_dish_ids)
            if result is not None:
                return result

            # Backtrack
            del assignment[slot]
            slot.assigned_dish = None
            slot.is_new = False

        return None

    def _select_slot(
        self,
        unassigned: list[MenuSlot],
        assignment: dict,
        all_dishes: list[Dish],
        new_dish_ids: set,
    ) -> MenuSlot:
        """MRV: pick slot with fewest valid candidates. Tie-break: earliest date."""
        best_slot = None
        best_count = float("inf")
        for slot in unassigned:
            count = len(self.checker.get_valid_candidates(
                slot, all_dishes, assignment, new_dish_ids
            ))
            if count < best_count or (count == best_count and
                    (best_slot is None or slot.date < best_slot.date)):
                best_count = count
                best_slot = slot
        return best_slot or unassigned[0]
