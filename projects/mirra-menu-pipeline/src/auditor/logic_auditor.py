"""Logic Auditor — Layer 1 compliance testing (pre-render)."""

from datetime import timedelta
from collections import Counter
from ..data.models import (
    MenuPlan, MealPeriod, BaseIngredient,
    PreviousMonthEntry, Violation, ViolationSeverity, ComplianceReport,
)


class LogicAuditor:
    """Run all 9 compliance rules against a MenuPlan."""

    def audit(self, plan: MenuPlan, previous: list[PreviousMonthEntry]) -> ComplianceReport:
        all_violations = []
        all_violations.extend(self.rule1_date_verification(plan))
        all_violations.extend(self.rule2_dish_rotation(plan, previous))
        all_violations.extend(self.rule3_meal_alternation(plan, previous))
        all_violations.extend(self.rule4_spice_distribution(plan))
        all_violations.extend(self.rule5_cuisine_variety(plan))
        all_violations.extend(self.rule6_new_products(plan))
        all_violations.extend(self.rule7_month_transition(plan, previous))
        all_violations.extend(self.rule9_base_ingredient_variation(plan))

        score = self.calculate_score(all_violations)
        grade = self._grade(score)
        critical = sum(1 for v in all_violations if v.severity == ViolationSeverity.CRITICAL)
        important = sum(1 for v in all_violations if v.severity == ViolationSeverity.IMPORTANT)
        optimization = sum(1 for v in all_violations if v.severity == ViolationSeverity.OPTIMIZATION)

        return ComplianceReport(
            month=plan.month,
            violations=all_violations,
            score=score,
            grade=grade,
            is_approved=critical == 0,
            critical_count=critical,
            important_count=important,
            optimization_count=optimization,
        )

    def rule1_date_verification(self, plan: MenuPlan) -> list[Violation]:
        """Mon-Fri only, no duplicates."""
        violations = []
        dates_seen = set()
        for slot in plan.slots:
            if slot.date.weekday() >= 5:
                violations.append(Violation(
                    rule_number=1, rule_name="Date Verification",
                    severity=ViolationSeverity.CRITICAL,
                    description=f"Weekend date: {slot.date} ({slot.day_name})",
                    affected_dates=[slot.date], affected_dishes=[],
                    suggested_fix="Remove weekend slots",
                ))
            key = (slot.date, slot.meal_period)
            if key in dates_seen:
                violations.append(Violation(
                    rule_number=1, rule_name="Date Verification",
                    severity=ViolationSeverity.CRITICAL,
                    description=f"Duplicate slot: {slot.date} {slot.meal_period.value}",
                    affected_dates=[slot.date], affected_dishes=[],
                    suggested_fix="Remove duplicate slot",
                ))
            dates_seen.add(key)
        return violations

    def rule2_dish_rotation(self, plan: MenuPlan, previous: list[PreviousMonthEntry]) -> list[Violation]:
        """14-day within month, 21-day cross-month, max 2x/month."""
        violations = []
        assigned = [(s, s.assigned_dish) for s in plan.slots if s.assigned_dish]

        # Within-month: 14-day gap
        dish_dates: dict[str, list] = {}
        for slot, dish in assigned:
            dish_dates.setdefault(dish.name, []).append(slot.date)

        for name, dates in dish_dates.items():
            dates.sort()
            # Max 2x per month
            if len(dates) > 2:
                violations.append(Violation(
                    rule_number=2, rule_name="Dish Rotation",
                    severity=ViolationSeverity.CRITICAL,
                    description=f"{name} appears {len(dates)}x (max 2)",
                    affected_dates=dates, affected_dishes=[name],
                    suggested_fix=f"Remove extra occurrences of {name}",
                ))
            # 14-day spacing
            for i in range(1, len(dates)):
                gap = (dates[i] - dates[i-1]).days
                if gap < 14:
                    violations.append(Violation(
                        rule_number=2, rule_name="Dish Rotation",
                        severity=ViolationSeverity.CRITICAL,
                        description=f"{name}: {gap}d gap between {dates[i-1]} and {dates[i]} (need 14+)",
                        affected_dates=[dates[i-1], dates[i]], affected_dishes=[name],
                        suggested_fix=f"Space {name} at least 14 days apart",
                    ))

        # Cross-month: 21-day gap
        prev_by_name: dict[str, list] = {}
        for e in previous:
            prev_by_name.setdefault(e.dish_name, []).append(e.date)

        for name, dates in dish_dates.items():
            if name in prev_by_name:
                prev_latest = max(prev_by_name[name])
                curr_earliest = min(dates)
                gap = (curr_earliest - prev_latest).days
                if gap < 21:
                    violations.append(Violation(
                        rule_number=2, rule_name="Dish Rotation",
                        severity=ViolationSeverity.IMPORTANT,
                        description=f"{name}: cross-month gap {gap}d (need 21+)",
                        affected_dates=[prev_latest, curr_earliest], affected_dishes=[name],
                        suggested_fix=f"Move {name} later or use a different dish",
                    ))
        return violations

    def rule3_meal_alternation(self, plan: MenuPlan, previous: list[PreviousMonthEntry]) -> list[Violation]:
        """Cross-month dishes must flip meal period."""
        violations = []
        prev_by_name: dict[str, MealPeriod] = {}
        for e in previous:
            prev_by_name[e.dish_name] = e.meal_period

        for slot in plan.slots:
            if slot.assigned_dish and slot.assigned_dish.name in prev_by_name:
                prev_period = prev_by_name[slot.assigned_dish.name]
                if slot.meal_period.value == prev_period.value:
                    violations.append(Violation(
                        rule_number=3, rule_name="Meal Alternation",
                        severity=ViolationSeverity.IMPORTANT,
                        description=f"{slot.assigned_dish.name}: was {prev_period.value} in prev month, still {slot.meal_period.value}",
                        affected_dates=[slot.date], affected_dishes=[slot.assigned_dish.name],
                        suggested_fix=f"Flip to {'Dinner' if prev_period == MealPeriod.LUNCH else 'Lunch'}",
                    ))
        return violations

    def rule4_spice_distribution(self, plan: MenuPlan) -> list[Violation]:
        """No consecutive same-meal-type spicy on adjacent weekdays."""
        violations = []
        assigned = {(s.date, s.meal_period): s for s in plan.slots if s.assigned_dish}

        for (d, period), slot in sorted(assigned.items()):
            if not slot.assigned_dish.spicy:
                continue
            # Find previous weekday
            prev = d - timedelta(days=1)
            while prev.weekday() >= 5:
                prev -= timedelta(days=1)
            prev_key = (prev, period)
            if prev_key in assigned and assigned[prev_key].assigned_dish.spicy:
                violations.append(Violation(
                    rule_number=4, rule_name="Spice Distribution",
                    severity=ViolationSeverity.IMPORTANT,
                    description=f"Consecutive spicy {period.value}: {prev} and {d}",
                    affected_dates=[prev, d],
                    affected_dishes=[assigned[prev_key].assigned_dish.name, slot.assigned_dish.name],
                    suggested_fix="Swap one spicy dish for a non-spicy alternative",
                ))
        return violations

    def rule5_cuisine_variety(self, plan: MenuPlan) -> list[Violation]:
        """4+ cuisines/week, no cuisine > 3x/week."""
        violations = []
        weeks = set(s.week_number for s in plan.slots)
        for wk in weeks:
            week_slots = [s for s in plan.slots if s.week_number == wk and s.assigned_dish]
            cuisines = Counter(s.assigned_dish.cuisine for s in week_slots)
            if len(cuisines) < 4 and len(week_slots) >= 6:
                violations.append(Violation(
                    rule_number=5, rule_name="Cuisine Variety",
                    severity=ViolationSeverity.IMPORTANT,
                    description=f"Week {wk}: {len(cuisines)} cuisines (need 4+)",
                    affected_dates=[s.date for s in week_slots],
                    affected_dishes=list(cuisines.keys()),
                    suggested_fix="Add dishes from underrepresented cuisines",
                ))
            for cuisine, count in cuisines.items():
                if count > 3:
                    violations.append(Violation(
                        rule_number=5, rule_name="Cuisine Variety",
                        severity=ViolationSeverity.IMPORTANT,
                        description=f"Week {wk}: {cuisine} appears {count}x (max 3)",
                        affected_dates=[s.date for s in week_slots if s.assigned_dish.cuisine == cuisine],
                        affected_dishes=[cuisine],
                        suggested_fix=f"Replace one {cuisine} dish",
                    ))
        return violations

    def rule6_new_products(self, plan: MenuPlan) -> list[Violation]:
        """3-4 NEW dishes, Weeks 2-4 only."""
        violations = []
        new_slots = [s for s in plan.slots if s.is_new]
        if len(new_slots) < 3:
            violations.append(Violation(
                rule_number=6, rule_name="New Products",
                severity=ViolationSeverity.OPTIMIZATION,
                description=f"Only {len(new_slots)} NEW dishes (target 3-4)",
                affected_dates=[], affected_dishes=[],
                suggested_fix="Add more NEW dishes in Weeks 2-4",
            ))
        if len(new_slots) > 4:
            violations.append(Violation(
                rule_number=6, rule_name="New Products",
                severity=ViolationSeverity.IMPORTANT,
                description=f"{len(new_slots)} NEW dishes (max 4)",
                affected_dates=[s.date for s in new_slots],
                affected_dishes=[s.assigned_dish.name for s in new_slots if s.assigned_dish],
                suggested_fix="Remove some NEW tags",
            ))
        for s in new_slots:
            if s.week_number == 1:
                violations.append(Violation(
                    rule_number=6, rule_name="New Products",
                    severity=ViolationSeverity.IMPORTANT,
                    description=f"NEW dish in Week 1: {s.assigned_dish.name if s.assigned_dish else '?'}",
                    affected_dates=[s.date],
                    affected_dishes=[s.assigned_dish.name if s.assigned_dish else ""],
                    suggested_fix="Move NEW dishes to Weeks 2-4",
                ))
        return violations

    def rule7_month_transition(self, plan: MenuPlan, previous: list[PreviousMonthEntry]) -> list[Violation]:
        """Previous month's last week dishes should not appear in current month's first week."""
        violations = []
        # Get last week of previous month
        if not previous:
            return violations
        max_prev_date = max(e.date for e in previous)
        last_week_start = max_prev_date - timedelta(days=4)
        prev_last_week = set(e.dish_name for e in previous if e.date >= last_week_start)

        # Get first week of current month
        first_week = [s for s in plan.slots if s.week_number == 1 and s.assigned_dish]
        for s in first_week:
            if s.assigned_dish.name in prev_last_week:
                violations.append(Violation(
                    rule_number=7, rule_name="Month Transition",
                    severity=ViolationSeverity.OPTIMIZATION,
                    description=f"{s.assigned_dish.name} in both prev last week and curr first week",
                    affected_dates=[s.date], affected_dishes=[s.assigned_dish.name],
                    suggested_fix="Use a different dish in Week 1",
                ))
        return violations

    def rule9_base_ingredient_variation(self, plan: MenuPlan) -> list[Violation]:
        """Each week must have at least 2 non-rice dishes."""
        violations = []
        weeks = set(s.week_number for s in plan.slots)
        for wk in weeks:
            week_slots = [s for s in plan.slots if s.week_number == wk and s.assigned_dish]
            if not week_slots:
                continue
            rice_count = sum(1 for s in week_slots if s.assigned_dish.base_ingredient == BaseIngredient.RICE)
            total = len(week_slots)
            non_rice = total - rice_count
            if total == rice_count:
                violations.append(Violation(
                    rule_number=9, rule_name="Base Ingredient Variation",
                    severity=ViolationSeverity.CRITICAL,
                    description=f"Week {wk}: ALL {total} dishes are rice-based",
                    affected_dates=[s.date for s in week_slots],
                    affected_dishes=[s.assigned_dish.name for s in week_slots],
                    suggested_fix="Add noodle/pasta/wrap/other base dishes",
                ))
            elif non_rice < 2 and total >= 6:
                violations.append(Violation(
                    rule_number=9, rule_name="Base Ingredient Variation",
                    severity=ViolationSeverity.IMPORTANT,
                    description=f"Week {wk}: only {non_rice} non-rice dishes (need 2+)",
                    affected_dates=[s.date for s in week_slots],
                    affected_dishes=[s.assigned_dish.name for s in week_slots if s.assigned_dish.base_ingredient == BaseIngredient.RICE],
                    suggested_fix="Replace some rice dishes with noodle/pasta/wrap",
                ))
        return violations

    def calculate_score(self, violations: list[Violation]) -> float:
        score = 100.0
        for v in violations:
            if v.severity == ViolationSeverity.CRITICAL:
                score -= 10
            elif v.severity == ViolationSeverity.IMPORTANT:
                score -= 5
            else:
                score -= 2
        return max(0.0, score)

    def _grade(self, score: float) -> str:
        if score >= 97: return "A+"
        if score >= 93: return "A"
        if score >= 88: return "B+"
        if score >= 83: return "B"
        if score >= 75: return "C"
        return "F"
