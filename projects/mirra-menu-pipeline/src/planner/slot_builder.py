"""Slot Builder — creates empty MenuSlots for a target month."""

import calendar
from datetime import date, timedelta
from ..data.models import MenuSlot, MealPeriod


class SlotBuilder:
    """Builds ordered list of empty MenuSlots for a given month."""

    def __init__(self, holidays: list[date] = None):
        self.holidays = set(holidays or [])

    def build_slots(self, month_str: str) -> list[MenuSlot]:
        """
        Args: month_str = "2026-04"
        Returns: ordered list of empty MenuSlots, Lunch before Dinner each day.
        Skips weekends and holidays.
        """
        year, month = int(month_str[:4]), int(month_str[5:7])
        _, days_in_month = calendar.monthrange(year, month)

        slots = []
        week_number = 1
        prev_iso_week = None

        for day in range(1, days_in_month + 1):
            d = date(year, month, day)
            # Skip weekends
            if d.weekday() >= 5:  # Saturday=5, Sunday=6
                continue
            # Skip holidays
            if d in self.holidays:
                continue

            # Calculate week number within the month
            iso_week = d.isocalendar()[1]
            if prev_iso_week is not None and iso_week != prev_iso_week:
                week_number += 1
            prev_iso_week = iso_week

            day_name = calendar.day_name[d.weekday()]

            # Lunch slot
            slots.append(MenuSlot(
                date=d,
                day_name=day_name,
                meal_period=MealPeriod.LUNCH,
                week_number=week_number,
            ))
            # Dinner slot
            slots.append(MenuSlot(
                date=d,
                day_name=day_name,
                meal_period=MealPeriod.DINNER,
                week_number=week_number,
            ))

        return slots

    def get_week_count(self, slots: list[MenuSlot]) -> int:
        if not slots:
            return 0
        return max(s.week_number for s in slots)
