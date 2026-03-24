"""PIL Renderer — composites text onto the real Mirra floral background."""

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from ..data.models import MenuPlan, MenuSlot, MealPeriod


class MirraPILRenderer:
    """Renders menu pages using the actual Mirra background + PIL text overlay."""

    # Page dimensions (matching the Canva template at 300dpi)
    W = 3375
    H = 4219

    def __init__(self, bg_path: str = None):
        if bg_path is None:
            bg_path = str(Path(__file__).parent.parent.parent / "templates" / "bg_clean_final.png")
        self.bg = Image.open(bg_path).convert("RGBA")
        if self.bg.size != (self.W, self.H):
            self.bg = self.bg.resize((self.W, self.H), Image.LANCZOS)

        # Load fonts
        font_dir = Path.home() / "Library" / "Fonts"
        self.font_header = ImageFont.truetype(str(font_dir / "PlayfairDisplay-Italic.otf"), 140)
        self.font_week = ImageFont.truetype(str(font_dir / "PlayfairDisplay-Regular.otf"), 88)
        self.font_day_label = ImageFont.truetype(str(font_dir / "TT Interphases Pro Trial Bold.ttf"), 38)
        self.font_day_num = ImageFont.truetype(str(font_dir / "PlayfairDisplay-Regular.otf"), 100)
        self.font_meal = ImageFont.truetype(str(font_dir / "TT Interphases Pro Trial Medium.ttf"), 52)
        self.font_meal_bold = ImageFont.truetype(str(font_dir / "TT Interphases Pro Trial Bold.ttf"), 52)
        self.font_logo = ImageFont.truetype(str(font_dir / "TT Interphases Pro Trial Black.ttf"), 100)
        self.font_holiday = ImageFont.truetype(str(font_dir / "TT Interphases Pro Trial Medium.ttf"), 48)
        self.font_new = ImageFont.truetype(str(font_dir / "TT Interphases Pro Trial Bold.ttf"), 42)
        # CN font
        try:
            self.font_meal_cn = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 52)
            self.font_week_cn = ImageFont.truetype("/System/Library/Fonts/STHeiti Medium.ttc", 80)
        except:
            self.font_meal_cn = self.font_meal
            self.font_week_cn = self.font_week

        self.text_color = (42, 42, 42)
        self.muted_color = (90, 74, 74)

    def render_all_pages(
        self,
        plan: MenuPlan,
        assignment: dict,
        holidays: dict = None,
        lang: str = "en",
        output_dir: str = "output",
    ) -> list[str]:
        """Render all pages as PNG files. Returns list of paths."""
        holidays = holidays or {}
        pages_data = self._build_pages(plan, assignment, holidays, lang)
        output_paths = []
        out = Path(output_dir)
        out.mkdir(exist_ok=True)

        for i, page in enumerate(pages_data):
            img = self._render_page(page, lang)
            path = str(out / f"mirra_menu_{plan.month}_{lang}_p{i+1}.png")
            img.save(path, "PNG", quality=95)
            print(f"  Page {i+1}: {path}")
            output_paths.append(path)

        return output_paths

    def render_pdf(
        self,
        plan: MenuPlan,
        assignment: dict,
        holidays: dict = None,
        lang: str = "en",
        output_path: str = None,
    ) -> str:
        """Render all pages into a single PDF."""
        holidays = holidays or {}
        pages_data = self._build_pages(plan, assignment, holidays, lang)
        images = []
        for page in pages_data:
            img = self._render_page(page, lang).convert("RGB")
            images.append(img)

        if output_path is None:
            output_path = f"output/mirra_menu_{plan.month}_{lang}.pdf"

        Path(output_path).parent.mkdir(exist_ok=True)
        if images:
            images[0].save(output_path, "PDF", save_all=True, append_images=images[1:])
            print(f"  PDF: {output_path} ({Path(output_path).stat().st_size // 1024} KB)")
        return output_path

    def _render_page(self, page: dict, lang: str) -> Image.Image:
        """Render a single page onto the background."""
        img = self.bg.copy()
        draw = ImageDraw.Draw(img)

        # Starting positions
        x_label = 150      # Day label column
        x_num = 150         # Day number column
        x_meals = 360       # Meal text column
        y = 120             # Starting Y

        # Header: "Weekly Menu"
        draw.text((x_label, y), "Weekly Menu", fill=self.text_color, font=self.font_header)
        y += 170

        for week in page["weeks"]:
            # Week label
            month_name = page.get("month_name", "April")
            if lang == "cn":
                cn_months = {"January": "一月", "February": "二月", "March": "三月",
                             "April": "四月", "May": "五月", "June": "六月",
                             "July": "七月", "August": "八月", "September": "九月",
                             "October": "十月", "November": "十一月", "December": "十二月"}
                cn_weeks = {1: "第一周", 2: "第二周", 3: "第三周", 4: "第四周", 5: "第五周"}
                wn = week['number']
                week_text = f"{cn_months.get(month_name, month_name)}: {cn_weeks.get(wn, f'第{wn}周')}"
                draw.text((x_label, y), week_text, fill=self.text_color, font=self.font_week_cn)
            else:
                week_text = f"{month_name}: Week {week['number']}"
                draw.text((x_label, y), week_text, fill=self.text_color, font=self.font_week)
            y += 120

            for day in week["days"]:
                # Day label (MON, TUE, etc.)
                draw.text((x_label, y), day["day_short"], fill=self.text_color, font=self.font_day_label)
                # Day number
                draw.text((x_label, y + 38), str(day["date_num"]), fill=self.text_color, font=self.font_day_num)

                if day["is_holiday"]:
                    draw.text((x_meals, y + 20), day["holiday_name"], fill=self.muted_color, font=self.font_holiday)
                    draw.text((x_meals, y + 72), "No Delivery", fill=self.muted_color, font=self.font_holiday)
                    y += 160
                else:
                    # Lunch line
                    lunch = day["lunch"]
                    lunch_text = f"L - {lunch['name']}"
                    draw.text((x_meals, y + 10), "L", fill=self.text_color, font=self.font_meal_bold)
                    meal_font = self.font_meal_cn if lang == "cn" else self.font_meal
                    draw.text((x_meals + 40, y + 10), f" - {lunch['name']}", fill=self.text_color, font=meal_font)
                    # Spicy emoji
                    x_end = x_meals + 40 + meal_font.getlength(f" - {lunch['name']}")
                    if lunch["spicy"]:
                        draw.text((x_end + 8, y + 10), "🌶️", fill=(220, 50, 50), font=self.font_meal)
                        x_end += 60
                    if lunch.get("is_new"):
                        draw.text((x_end + 8, y + 16), "(New)", fill=self.text_color, font=self.font_new)

                    # Dinner line
                    dinner = day["dinner"]
                    draw.text((x_meals, y + 72), "D", fill=self.text_color, font=self.font_meal_bold)
                    draw.text((x_meals + 40, y + 72), f" - {dinner['name']}", fill=self.text_color, font=meal_font)
                    x_end_d = x_meals + 40 + meal_font.getlength(f" - {dinner['name']}")
                    if dinner["spicy"]:
                        draw.text((x_end_d + 8, y + 72), "🌶️", fill=(220, 50, 50), font=self.font_meal)
                        x_end_d += 60
                    if dinner.get("is_new"):
                        draw.text((x_end_d + 8, y + 78), "(New)", fill=self.text_color, font=self.font_new)

                    y += 160

            y += 50  # Gap between weeks

        # MIRRA logo — bottom right
        logo_x = self.W - 550
        logo_y = self.H - 180
        draw.text((logo_x, logo_y), "MIRRA", fill=self.text_color, font=self.font_logo)

        return img

    def _build_pages(self, plan, assignment, holidays, lang) -> list[dict]:
        """Split weeks into pages (2 weeks per page)."""
        weeks = self._build_weeks(plan, assignment, holidays, lang)
        month_name = self._month_name(plan.month)
        pages = []
        for i in range(0, len(weeks), 2):
            pages.append({
                "weeks": weeks[i:i+2],
                "month_name": month_name,
            })
        return pages

    def _build_weeks(self, plan, assignment, holidays, lang):
        week_numbers = sorted(set(s.week_number for s in plan.slots))
        weeks = []
        for wn in week_numbers:
            week_slots = sorted(
                [s for s in plan.slots if s.week_number == wn],
                key=lambda s: (s.date, s.meal_period.value)
            )
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
                days.append({
                    "date_num": d.day,
                    "day_short": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][d.weekday()],
                    "is_holiday": is_holiday,
                    "holiday_name": holidays.get(d, ""),
                    "lunch": days_map[d]["lunch"] or {"name": "—", "spicy": False, "is_new": False},
                    "dinner": days_map[d]["dinner"] or {"name": "—", "spicy": False, "is_new": False},
                })
            weeks.append({"number": wn, "days": days})
        return weeks

    def _month_name(self, month_str):
        months = {"01": "January", "02": "February", "03": "March", "04": "April",
                  "05": "May", "06": "June", "07": "July", "08": "August",
                  "09": "September", "10": "October", "11": "November", "12": "December"}
        return months.get(month_str[5:7], month_str)
