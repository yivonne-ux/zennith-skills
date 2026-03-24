"""
Shared pytest fixtures for Mirra Menu Pipeline tests.
"""

import sys
from datetime import date
from pathlib import Path

import pytest

# Ensure project root is on sys.path so `from src.data.models import ...` works
PROJECT_ROOT = str(Path(__file__).resolve().parent.parent)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

from src.data.models import (
    BaseIngredient,
    Dish,
    MealPeriod,
    MenuPlan,
    MenuSlot,
    PreviousMonthEntry,
)


# ---------------------------------------------------------------------------
# Dish catalogue (~10 varied dishes)
# ---------------------------------------------------------------------------

@pytest.fixture
def sample_dishes() -> dict[str, Dish]:
    """Return a dict of dish_id → Dish with varied cuisine/spicy/base."""
    return {
        "nasi-lemak": Dish(
            id="nasi-lemak", name="Nasi Lemak", cuisine="Malay",
            spicy=True, base_ingredient=BaseIngredient.RICE,
            preferred_meal_period=MealPeriod.LUNCH,
        ),
        "pad-thai": Dish(
            id="pad-thai", name="Pad Thai", cuisine="Thai",
            spicy=True, base_ingredient=BaseIngredient.NOODLE,
            preferred_meal_period=MealPeriod.DINNER,
        ),
        "falafel-pita": Dish(
            id="falafel-pita", name="Falafel Pita", cuisine="Middle Eastern",
            spicy=False, base_ingredient=BaseIngredient.PITA,
            preferred_meal_period=None,
        ),
        "tom-yum": Dish(
            id="tom-yum", name="Tom Yum Soup", cuisine="Thai",
            spicy=True, base_ingredient=BaseIngredient.SOUP,
            preferred_meal_period=MealPeriod.DINNER,
        ),
        "teriyaki-rice": Dish(
            id="teriyaki-rice", name="Teriyaki Rice", cuisine="Japanese",
            spicy=False, base_ingredient=BaseIngredient.RICE,
            preferred_meal_period=MealPeriod.LUNCH,
        ),
        "aglio-olio": Dish(
            id="aglio-olio", name="Aglio Olio", cuisine="Italian",
            spicy=True, base_ingredient=BaseIngredient.PASTA,
            preferred_meal_period=MealPeriod.DINNER,
        ),
        "buddha-bowl": Dish(
            id="buddha-bowl", name="Buddha Bowl", cuisine="Western",
            spicy=False, base_ingredient=BaseIngredient.SALAD,
            preferred_meal_period=MealPeriod.LUNCH,
        ),
        "rendang-rice": Dish(
            id="rendang-rice", name="Rendang Rice", cuisine="Malay",
            spicy=True, base_ingredient=BaseIngredient.RICE,
            preferred_meal_period=MealPeriod.LUNCH,
        ),
        "sushi-bowl": Dish(
            id="sushi-bowl", name="Sushi Bowl", cuisine="Japanese",
            spicy=False, base_ingredient=BaseIngredient.RICE,
            preferred_meal_period=MealPeriod.LUNCH,
        ),
        "burrito-wrap": Dish(
            id="burrito-wrap", name="Burrito Wrap", cuisine="Mexican",
            spicy=True, base_ingredient=BaseIngredient.WRAP,
            preferred_meal_period=MealPeriod.DINNER,
        ),
    }


# ---------------------------------------------------------------------------
# Simple 1-week valid plan (Mon-Fri, Week 1, April 2026)
# ---------------------------------------------------------------------------

def _make_slot(d: date, meal: MealPeriod, dish: Dish, week: int, is_new: bool = False) -> MenuSlot:
    day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    return MenuSlot(
        date=d,
        day_name=day_names[d.weekday()],
        meal_period=meal,
        week_number=week,
        assigned_dish=dish,
        is_new=is_new,
    )


@pytest.fixture
def sample_plan(sample_dishes: dict[str, Dish]) -> MenuPlan:
    """A valid 1-week plan: Mon 6 Apr – Fri 10 Apr 2026, 10 slots."""
    d = sample_dishes
    # 5 days × 2 meals, varied cuisines/bases
    slots = [
        _make_slot(date(2026, 4, 6), MealPeriod.LUNCH, d["nasi-lemak"], 1),
        _make_slot(date(2026, 4, 6), MealPeriod.DINNER, d["pad-thai"], 1),
        _make_slot(date(2026, 4, 7), MealPeriod.LUNCH, d["falafel-pita"], 1),
        _make_slot(date(2026, 4, 7), MealPeriod.DINNER, d["tom-yum"], 1),
        _make_slot(date(2026, 4, 8), MealPeriod.LUNCH, d["teriyaki-rice"], 1),
        _make_slot(date(2026, 4, 8), MealPeriod.DINNER, d["aglio-olio"], 1),
        _make_slot(date(2026, 4, 9), MealPeriod.LUNCH, d["buddha-bowl"], 1),
        _make_slot(date(2026, 4, 9), MealPeriod.DINNER, d["rendang-rice"], 1),
        _make_slot(date(2026, 4, 10), MealPeriod.LUNCH, d["sushi-bowl"], 1),
        _make_slot(date(2026, 4, 10), MealPeriod.DINNER, d["burrito-wrap"], 1),
    ]
    return MenuPlan(
        month="2026-04",
        slots=slots,
        new_dish_ids=[],
        generated_at="2026-04-01T00:00:00",
        csp_iterations=1,
    )


# ---------------------------------------------------------------------------
# Previous month entries (March 2026, last week)
# ---------------------------------------------------------------------------

@pytest.fixture
def sample_previous(sample_dishes: dict[str, Dish]) -> list[PreviousMonthEntry]:
    """Previous month entries for cross-month tests — last week of March 2026."""
    return [
        PreviousMonthEntry(
            dish_id="nasi-lemak", dish_name="Nasi Lemak",
            date=date(2026, 3, 23), meal_period=MealPeriod.LUNCH, month="2026-03",
        ),
        PreviousMonthEntry(
            dish_id="pad-thai", dish_name="Pad Thai",
            date=date(2026, 3, 23), meal_period=MealPeriod.DINNER, month="2026-03",
        ),
        PreviousMonthEntry(
            dish_id="falafel-pita", dish_name="Falafel Pita",
            date=date(2026, 3, 24), meal_period=MealPeriod.LUNCH, month="2026-03",
        ),
        PreviousMonthEntry(
            dish_id="tom-yum", dish_name="Tom Yum Soup",
            date=date(2026, 3, 25), meal_period=MealPeriod.DINNER, month="2026-03",
        ),
        PreviousMonthEntry(
            dish_id="teriyaki-rice", dish_name="Teriyaki Rice",
            date=date(2026, 3, 26), meal_period=MealPeriod.LUNCH, month="2026-03",
        ),
        PreviousMonthEntry(
            dish_id="aglio-olio", dish_name="Aglio Olio",
            date=date(2026, 3, 27), meal_period=MealPeriod.DINNER, month="2026-03",
        ),
    ]


# ---------------------------------------------------------------------------
# Helper: make_slot (exported for use in tests)
# ---------------------------------------------------------------------------

@pytest.fixture
def make_slot():
    """Factory fixture returning the _make_slot helper."""
    return _make_slot
