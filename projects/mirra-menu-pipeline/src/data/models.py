"""Mirra Auto-Menu Pipeline — Data Models."""

from dataclasses import dataclass, field
from datetime import date
from enum import Enum
from typing import Optional


class MealPeriod(str, Enum):
    LUNCH = "Lunch"
    DINNER = "Dinner"


class BaseIngredient(str, Enum):
    RICE = "rice"
    NOODLE = "noodle"
    PITA = "pita"
    POKE = "poke"
    BREAD = "bread"
    WRAP = "wrap"
    PASTA = "pasta"
    SALAD = "salad"
    SOUP = "soup"
    CONGEE = "congee"
    OTHER = "other"


class ViolationSeverity(str, Enum):
    CRITICAL = "CRITICAL"
    IMPORTANT = "IMPORTANT"
    OPTIMIZATION = "OPTIMIZATION"


class AuditMode(str, Enum):
    CONTENT = "content"
    DESIGN = "design"
    MARKERS = "markers"


@dataclass
class Dish:
    id: str
    name: str
    cuisine: str
    spicy: bool
    base_ingredient: BaseIngredient
    preferred_meal_period: Optional[MealPeriod] = None
    is_active: bool = True
    tags: list[str] = field(default_factory=list)
    notes: str = ""
    name_cn: str = ""

@dataclass
class PreviousMonthEntry:
    dish_id: str
    dish_name: str
    date: date
    meal_period: MealPeriod
    month: str

@dataclass
class MenuSlot:
    date: date
    day_name: str
    meal_period: MealPeriod
    week_number: int
    assigned_dish: Optional[Dish] = None
    is_new: bool = False

    def __hash__(self):
        return hash((self.date, self.meal_period))

    def __eq__(self, other):
        if not isinstance(other, MenuSlot):
            return False
        return self.date == other.date and self.meal_period == other.meal_period

@dataclass
class MenuPlan:
    month: str
    slots: list[MenuSlot]
    new_dish_ids: list[str]
    generated_at: str
    csp_iterations: int

    def get_lunches(self):
        return [s for s in self.slots if s.meal_period == MealPeriod.LUNCH]

    def get_dinners(self):
        return [s for s in self.slots if s.meal_period == MealPeriod.DINNER]

    def get_week(self, week_number):
        return [s for s in self.slots if s.week_number == week_number]

    def get_day(self, d):
        return [s for s in self.slots if s.date == d]

@dataclass
class Violation:
    rule_number: int
    rule_name: str
    severity: ViolationSeverity
    description: str
    affected_dates: list
    affected_dishes: list
    suggested_fix: str

@dataclass
class ComplianceReport:
    month: str
    violations: list
    score: float
    grade: str
    is_approved: bool
    critical_count: int
    important_count: int
    optimization_count: int
    ai_review_notes: str = ""

@dataclass
class AuditIssue:
    mode: AuditMode
    page_number: int
    location: str
    expected: str
    found: str
    severity: ViolationSeverity
    fix_instruction: str

@dataclass
class IterationLog:
    iteration: int
    issues_found: list
    patches_applied: list
    pdf_path: str
    timestamp: str

@dataclass
class AuditResult:
    passed: bool
    total_iterations: int
    final_pdf_path: str
    remaining_issues: list
    iteration_logs: list
