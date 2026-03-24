"""Template Renderer — injects MenuPlan into Jinja2 HTML."""

import json
from datetime import date
from pathlib import Path
from jinja2 import Template
from ..data.models import MenuPlan, MenuSlot, MealPeriod


class TemplateRenderer:
    """Renders MenuPlan into Mirra-branded HTML."""

    def __init__(self, template_path: str = None):
        if template_path is None:
            template_path = str(Path(__file__).parent.parent.parent / "templates" / "menu_template.html")
        with open(template_path) as f:
            self.template = Template(f.read())

    def render(self, plan: MenuPlan, assignment: dict, holidays: dict = None, lang: str = "en") -> str:
        """Render menu to HTML string. lang='en' or 'cn'."""
        holidays = holidays or {}
        pages = self._build_pages(plan, assignment, holidays, lang)
        month_name = self._month_name(plan.month)
        
        # Inject month_name into each page
        for page in pages:
            page["month_name"] = month_name

        return self.template.render(pages=pages)

    def _build_pages(self, plan, assignment, holidays, lang) -> list[dict]:
        """Split weeks into pages (2 weeks per page, last page may have 1)."""
        weeks = self._build_weeks(plan, assignment, holidays, lang)
        pages = []
        for i in range(0, len(weeks), 2):
            page_weeks = weeks[i:i+2]
            pages.append({"weeks": page_weeks})
        return pages

    def _build_weeks(self, plan, assignment, holidays, lang) -> list[dict]:
        """Build structured week data."""
        week_numbers = sorted(set(s.week_number for s in plan.slots))
        weeks = []
        
        for wn in week_numbers:
            week_slots = sorted(
                [s for s in plan.slots if s.week_number == wn],
                key=lambda s: (s.date, s.meal_period.value)
            )
            
            # Group by date
            days_map = {}
            for slot in week_slots:
                if slot.date not in days_map:
                    days_map[slot.date] = {"lunch": None, "dinner": None}
                dish = assignment.get(slot)
                if dish:
                    meal_data = {
                        "name": dish.name_cn if lang == "cn" and dish.name_cn else dish.name,
                        "spicy": dish.spicy,
                        "is_new": slot.is_new,
                    }
                    if slot.meal_period == MealPeriod.LUNCH:
                        days_map[slot.date]["lunch"] = meal_data
                    else:
                        days_map[slot.date]["dinner"] = meal_data

            days = []
            for d in sorted(days_map.keys()):
                is_holiday = d in holidays
                day_data = {
                    "date_num": d.day,
                    "day_short": ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"][d.weekday()],
                    "is_holiday": is_holiday,
                    "holiday_name": holidays.get(d, ""),
                    "lunch": days_map[d]["lunch"] or {"name": "—", "spicy": False, "is_new": False},
                    "dinner": days_map[d]["dinner"] or {"name": "—", "spicy": False, "is_new": False},
                }
                days.append(day_data)

            weeks.append({"number": wn, "days": days})
        
        return weeks

    def _month_name(self, month_str: str) -> str:
        months = {
            "01": "January", "02": "February", "03": "March",
            "04": "April", "05": "May", "06": "June",
            "07": "July", "08": "August", "09": "September",
            "10": "October", "11": "November", "12": "December",
        }
        return months.get(month_str[5:7], month_str)
