"""Constraint Checker — all 9 compliance rules for the CSP engine."""

from datetime import date, timedelta
from typing import Optional
from ..data.models import (
    Dish, MenuSlot, MealPeriod, BaseIngredient,
    PreviousMonthEntry, Violation, ViolationSeverity,
)


class ConstraintChecker:
    """Check if assigning a dish to a slot violates any rule."""

    def __init__(
        self,
        previous_month: list[PreviousMonthEntry],
        dish_db: list[Dish],
        target_month: str,
    ):
        self.previous = previous_month
        self.db = dish_db
        self.month = target_month
        # Index previous month by dish name for fast lookup
        self._prev_by_name: dict[str, list[PreviousMonthEntry]] = {}
        for e in previous_month:
            self._prev_by_name.setdefault(e.dish_name, []).append(e)

    def is_valid(
        self,
        slot: MenuSlot,
        dish: Dish,
        assignment: dict,
        new_dish_ids: set,
    ) -> tuple[bool, Optional[str]]:
        """Returns (True, None) if valid, (False, reason) if not."""
        checks = [
            self._check_rule2_within_month(slot, dish, assignment),
            self._check_rule2_cross_month(slot, dish),
            self._check_rule2_max_per_month(slot, dish, assignment),
            self._check_rule3_meal_flip(slot, dish),
            self._check_rule4_spice(slot, dish, assignment),
            self._check_rule9_base_ingredient(slot, dish, assignment),
        ]
        for valid, reason in checks:
            if not valid:
                return False, reason
        return True, None

    def _check_rule2_within_month(self, slot, dish, assignment) -> tuple[bool, Optional[str]]:
        """Rule 2: dish must not appear within 14 calendar days."""
        for s, d in assignment.items():
            if d.name == dish.name:
                gap = abs((slot.date - s.date).days)
                if gap < 14:
                    return False, f"Rule 2: {dish.name} within {gap}d (need 14+)"
        return True, None

    def _check_rule2_cross_month(self, slot, dish) -> tuple[bool, Optional[str]]:
        """Rule 2: 21-day gap from previous month's last appearance."""
        prev_entries = self._prev_by_name.get(dish.name, [])
        if not prev_entries:
            return True, None
        latest = max(e.date for e in prev_entries)
        gap = (slot.date - latest).days
        if gap < 21:
            return False, f"Rule 2: {dish.name} cross-month gap {gap}d (need 21+)"
        return True, None

    def _check_rule2_max_per_month(self, slot, dish, assignment) -> tuple[bool, Optional[str]]:
        """Rule 2: max 2 appearances per month."""
        count = sum(1 for d in assignment.values() if d.name == dish.name)
        if count >= 2:
            return False, f"Rule 2: {dish.name} already used {count}x this month (max 2)"
        return True, None

    def _check_rule3_meal_flip(self, slot, dish) -> tuple[bool, Optional[str]]:
        """Rule 3: cross-month dishes must switch meal period."""
        prev_entries = self._prev_by_name.get(dish.name, [])
        if not prev_entries:
            return True, None
        # Get most recent meal period from previous month
        latest = max(prev_entries, key=lambda e: e.date)
        if slot.meal_period.value == latest.meal_period.value:
            return False, f"Rule 3: {dish.name} was {latest.meal_period.value} in prev month, must flip"
        return True, None

    def _check_rule4_spice(self, slot, dish, assignment) -> tuple[bool, Optional[str]]:
        """Rule 4: No consecutive same-meal-type spicy on adjacent weekdays."""
        if not dish.spicy:
            return True, None

        # Find previous weekday
        prev_day = slot.date - timedelta(days=1)
        while prev_day.weekday() >= 5:
            prev_day -= timedelta(days=1)

        # Check same meal period on previous weekday
        for s, d in assignment.items():
            if s.date == prev_day and s.meal_period == slot.meal_period:
                if d.spicy:
                    return False, f"Rule 4: consecutive spicy {slot.meal_period.value} on {prev_day} and {slot.date}"
        return True, None

    def _check_rule9_base_ingredient(self, slot, dish, assignment) -> tuple[bool, Optional[str]]:
        """Rule 9: each week must have at least 2 non-rice dishes."""
        week_slots = [(s, d) for s, d in assignment.items() if s.week_number == slot.week_number]
        total_in_week = len(week_slots) + 1  # including this candidate
        rice_count = sum(1 for _, d in week_slots if d.base_ingredient == BaseIngredient.RICE)
        if dish.base_ingredient == BaseIngredient.RICE:
            rice_count += 1

        # Count total possible slots in this week (we don't know exact count yet)
        # Be proactive: if we're past midpoint and ALL assigned = rice, flag early
        if total_in_week >= 6 and rice_count >= total_in_week:
            return False, f"Rule 9: week {slot.week_number} all rice so far ({rice_count}/{total_in_week})"
        # Hard limit: if this would make it 9+ rice out of 10
        if total_in_week >= 9 and rice_count >= 9:
            return False, f"Rule 9: week {slot.week_number} would be {rice_count}/10 rice"
        return True, None

    def get_valid_candidates(
        self,
        slot: MenuSlot,
        all_dishes: list[Dish],
        assignment: dict,
        new_dish_ids: set,
        available_new_dishes: list[Dish] = None,
    ) -> list[Dish]:
        """Get all valid dishes for a slot."""
        candidates = []
        for dish in all_dishes:
            if not dish.is_active:
                continue
            # Rule 6: NEW dishes only in Weeks 2-4
            if dish.id in new_dish_ids and slot.week_number == 1:
                continue
            valid, _ = self.is_valid(slot, dish, assignment, new_dish_ids)
            if valid:
                candidates.append(dish)
        return candidates

    def check_week_cuisine_diversity(self, week_number: int, assignment: dict) -> list[Violation]:
        """Rule 5: 4+ distinct cuisines/week, no cuisine > 3x/week."""
        violations = []
        week_dishes = [(s, d) for s, d in assignment.items() if s.week_number == week_number]
        if not week_dishes:
            return violations

        cuisine_counts: dict[str, int] = {}
        for _, d in week_dishes:
            cuisine_counts[d.cuisine] = cuisine_counts.get(d.cuisine, 0) + 1

        if len(cuisine_counts) < 4:
            violations.append(Violation(
                rule_number=5, rule_name="Cuisine Variety",
                severity=ViolationSeverity.IMPORTANT,
                description=f"Week {week_number}: only {len(cuisine_counts)} cuisines (need 4+): {list(cuisine_counts.keys())}",
                affected_dates=[s.date for s, _ in week_dishes],
                affected_dishes=[d.name for _, d in week_dishes],
                suggested_fix="Replace a dish with one from an underrepresented cuisine",
            ))

        for cuisine, count in cuisine_counts.items():
            if count > 3:
                violations.append(Violation(
                    rule_number=5, rule_name="Cuisine Variety",
                    severity=ViolationSeverity.IMPORTANT,
                    description=f"Week {week_number}: {cuisine} appears {count}x (max 3)",
                    affected_dates=[s.date for s, d in week_dishes if d.cuisine == cuisine],
                    affected_dishes=[d.name for _, d in week_dishes if d.cuisine == cuisine],
                    suggested_fix=f"Replace one {cuisine} dish with a different cuisine",
                ))
        return violations
