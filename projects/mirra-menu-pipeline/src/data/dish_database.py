"""Mirra Dish Database — enriched from historical data + inference."""

import hashlib
from datetime import date
from typing import Optional
from .models import Dish, BaseIngredient, MealPeriod, PreviousMonthEntry


def _dish_id(name: str) -> str:
    return hashlib.sha256(name.encode()).hexdigest()[:12]


def _infer_cuisine(name: str) -> str:
    n = name.lower()
    if any(k in n for k in ["nasi lemak", "rendang", "asam", "laksa", "nasi tomato", "masak merah", "nasi ulam", "nyonya", "jawa"]):
        return "Malaysian"
    if any(k in n for k in ["bibimbap", "bulgogi", "gochujang", "kimchi", "jap chae", "kimbap", "yakisoba"]):
        return "Korean"
    if any(k in n for k in ["teriyaki", "japanese", "furikake", "soba", "karaage", "katsu"]):
        return "Japanese"
    if any(k in n for k in ["tomyam", "pad thai", "thai"]):
        return "Thai"
    if any(k in n for k in ["fusilli", "pesto", "bolognese", "pasta"]):
        return "Western"
    if any(k in n for k in ["mapo", "kung pao", "dark sauce", "three cup", "zha jiang", "mei cai", "lu rou", "eight treasure", "golden eryngii", "black vinegar", "sweet & sour", "ginger beancurd"]):
        return "Chinese"
    if any(k in n for k in ["taiwanese"]):
        return "Taiwanese"
    if any(k in n for k in ["falafel", "pita", "tortilla", "chickpea masala"]):
        return "Middle Eastern"
    if any(k in n for k in ["gado", "indonesia"]):
        return "Indonesian"
    if any(k in n for k in ["bbq", "burrito", "smoked"]):
        return "Mexican"
    if any(k in n for k in ["kurma", "curry"]):
        return "Indian"
    if any(k in n for k in ["bak kut teh", "herbal soup"]):
        return "Chinese"
    if any(k in n for k in ["tempeh"]):
        return "Japanese"
    if any(k in n for k in ["lemon mushroom", "tomato beancurd", "oats hericium", "pumpkin cauliflower", "fragrant butter"]):
        return "Fusion"
    if any(k in n for k in ["vegan squid", "vegan chicken"]):
        return "Local"
    return "Fusion"


def _infer_spicy(name: str) -> bool:
    n = name.lower()
    return any(k in n for k in [
        "rendang", "curry", "spicy", "tomyam", "kimchi", "gochujang",
        "kung pao", "asam laksa", "jawa mee", "bibimbap", "karaage",
        "masak merah", "thai minced", "konjac asam", "fiery",
    ])


def _infer_base(name: str) -> BaseIngredient:
    n = name.lower()
    if any(k in n for k in ["fusilli", "pasta", "pesto", "bolognese", "spaghetti"]):
        return BaseIngredient.PASTA
    if any(k in n for k in ["noodle", "bihun", "soba", "yakisoba", "mee", "laksa", "pad thai", "jap chae", "konjac"]) and "rice" not in n:
        return BaseIngredient.NOODLE
    if any(k in n for k in ["pita", "guabao", "bao"]):
        return BaseIngredient.PITA
    if any(k in n for k in ["wrap", "burrito", "tortilla"]):
        return BaseIngredient.WRAP
    if any(k in n for k in ["congee", "porridge", "eight treasure"]):
        return BaseIngredient.CONGEE
    if any(k in n for k in ["soup", "herbal soup", "bak kut teh"]):
        return BaseIngredient.SOUP
    if any(k in n for k in ["salad"]):
        return BaseIngredient.SALAD
    if any(k in n for k in ["falafel", "buddha bowl", "poke"]):
        return BaseIngredient.OTHER
    # Default: most Mirra dishes are rice-based
    return BaseIngredient.RICE


# CN translations for known dishes
_CN_MAP = {
    "Nasi Lemak Rendang": "仁当饭",
    "Teriyaki Mushroom Asada Burrito Bowl": "照烧猴头菇饭",
    "Golden Eryngii Fragrant Rice": "金黄杏鲍菇香饭",
    "Tomato Beancurd Rice": "番茄豆腐饭",
    "Tempeh Katsu Bowl": "天贝katsu饭",
    "Jap Chae": "韩式杂菜炒冬粉",
    "Classic Curry Bowl": "经典咖喱碗",
    "BBQ Pita Mushroom Wrap": "BBQ蘑菇皮塔",
    "Fusilli Bolognese": "螺旋红酱意面",
    "Vegan Squid Curry Rice": "素鱿鱼咖喱饭",
    "Dry Classic Curry Konjac Noodle": "干捞咖喱魔芋面",
    "Gochujang Hericium Mushroom Bowl": "韩式辣酱猴头菇饭",
    "Dark Sauce Hericium Mushroom Rice": "黑酱猴头菇饭",
    "Herbal Soup w/ Rice Balls": "肉菇茶饭",
    "Falafel Bowl": "中东甜菜根法拉费",
    "Bulgogi Rice Bowl with Steamed Broccoli": "韩式烤肉饭",
    "Soba Noodle w/ Teriyaki Noodle Bowl": "照烧荞麦面",
    "Lemon Mushroom Rice": "柠檬杏鲍菇饭",
    "Tomyam Fried Bihun": "青东炎炒糙米粉",
    "Ginger Beancurd Seaweed Rice": "姜汁豆腐海苔饭",
    "Korean Bibimbap Bowl": "韩式拌饭",
    "Sweet & Sour Hericium Rice": "酸甜咕噜猴头菇饭",
    "Fusilli Pesto": "意式青酱螺旋面",
    "Taiwanese Braised Mushroom Rice": "台式卤豆腐饭",
    "Eight Treasure Congee": "彩虹八宝粥",
    "Jawa Mee": "爪哇面",
    "Karaage Buddha Bowl": "炸猴头菇彩虹能量碗",
    "Kung Pao Hericium Mushroom Rice": "宫保猴头菇饭",
    "Nasi Lemak Classic Curry": "经典咖喱椰浆饭",
    "Japanese Furikake Rice": "日式香松饭",
    "Kimchi Fried Quinoa Rice": "泡菜炒藜麦饭",
    "Yakisoba": "日式炒面",
    "Nasi Tomato w/ Masak Merah": "马来式番茄饭",
    "Spicy Fusilli Pasta": "辣味螺旋面",
    "Japanese Curry Katsu Rice": "日式katsu咖喱饭",
    "Fragrant Butter Rice w/ Grilled Pumpkin": "香草奶油烤南瓜饭",
    "Thai Minced Beancurd Rice": "泰式碎豆腐饭",
    "Konjac Asam Laksa": "魔芋亚参叻沙",
    "Mapo Tofu Rice": "麻婆豆腐饭",
    "Green Curry Rice": "青咖喱饭",
    "Indonesia Gado Gado": "印尼加多加多",
    "Braised Tofu and Mushroom Rice": "卤豆腐香菇饭",
    "Kurma Curry Rice": "古尔玛咖喱饭",
    "Lu Rou Fan": "卤肉饭",
    "Konjac Pad Thai": "魔芋泰式炒面",
    "Korean Kimbap": "韩式紫菜卷",
    "Three Cup Tofu Rice": "三杯豆腐饭",
    "Vegan Chicken Rice": "素鸡饭",
    "Smoked BBQ Mushroom Bowl": "烟熏BBQ蘑菇碗",
    "Oats Hericium Mushroom Rice": "燕麦猴头菇饭",
}


# All known dishes
_ALL_DISHES_RAW = [
    # March 2026 dishes
    "Nasi Lemak Rendang", "Teriyaki Mushroom Asada Burrito Bowl",
    "Golden Eryngii Fragrant Rice", "Tomato Beancurd Rice",
    "Tempeh Katsu Bowl", "Jap Chae",
    "Classic Curry Bowl", "BBQ Pita Mushroom Wrap",
    "Fusilli Bolognese", "Vegan Squid Curry Rice",
    "Dry Classic Curry Konjac Noodle", "Gochujang Hericium Mushroom Bowl",
    "Dark Sauce Hericium Mushroom Rice", "Herbal Soup w/ Rice Balls",
    "Falafel Bowl", "Bulgogi Rice Bowl with Steamed Broccoli",
    "Soba Noodle w/ Teriyaki Noodle Bowl", "Lemon Mushroom Rice",
    "Tomyam Fried Bihun", "Ginger Beancurd Seaweed Rice",
    "Korean Bibimbap Bowl", "Sweet & Sour Hericium Rice",
    "Fusilli Pesto", "Taiwanese Braised Mushroom Rice",
    "Eight Treasure Congee", "Jawa Mee",
    "Karaage Buddha Bowl", "Kung Pao Hericium Mushroom Rice",
    "Nasi Lemak Classic Curry", "Japanese Furikake Rice",
    "Kimchi Fried Quinoa Rice", "Yakisoba",
    "Nasi Tomato w/ Masak Merah", "Spicy Fusilli Pasta",
    "Japanese Curry Katsu Rice", "Fragrant Butter Rice w/ Grilled Pumpkin",
    "Thai Minced Beancurd Rice", "Konjac Asam Laksa",
    # Historical dishes (not in March 2026)
    "Mapo Tofu Rice", "Korean Kimbap", "Green Curry Rice",
    "Indonesia Gado Gado", "Braised Tofu and Mushroom Rice",
    "Kurma Curry Rice", "Lu Rou Fan", "Mei Cai Fried Rice",
    "Namyu Tofu & Yam Rice", "Nasi Ulam",
    "Oats Hericium Mushroom Rice", "Pumpkin Cauliflower Florets Rice",
    "Smoked BBQ Mushroom Bowl",
    "Three Cup Tofu Rice", "Vegan Chicken Rice",
    "Veggie Curry Beancurd Rice", "Zha Jiang Konjac Noodle",
    "Konjac Pad Thai", "Fiery Burrito Bowl",
    "Black Vinegar Hericium Rice", "Gochujang Coconut Meat Bowl",
    "Tortilla w/ Chickpea Masala", "Nyonya Stew Rice",
    "Bak Kut Teh Rice Balls", "Black Pepper Hericium Mushroom Bowl",
    "Tempeh Katsu Kimbap", "Sweet Curry w/ Steamed Bao",
]


def _build_dish(name: str) -> Dish:
    return Dish(
        id=_dish_id(name),
        name=name,
        cuisine=_infer_cuisine(name),
        spicy=_infer_spicy(name),
        base_ingredient=_infer_base(name),
        name_cn=_CN_MAP.get(name, ""),
    )


class MirraDishDatabase:
    """Complete dish database with metadata inference."""

    def __init__(self):
        self.dishes: list[Dish] = []

    def load_default(self) -> "MirraDishDatabase":
        """Load all known dishes with inferred metadata."""
        self.dishes = [_build_dish(name) for name in _ALL_DISHES_RAW]
        return self

    def get_active_dishes(self) -> list[Dish]:
        return [d for d in self.dishes if d.is_active]

    def get_dish_by_name(self, name: str) -> Optional[Dish]:
        for d in self.dishes:
            if d.name == name:
                return d
        return None

    def get_march_2026_entries(self) -> list[PreviousMonthEntry]:
        """Hardcoded from the March 2026 PDF — previous month for April generation."""
        entries = []
        march_menu = [
            # Week 1
            (2, "Nasi Lemak Rendang", MealPeriod.LUNCH),
            (2, "Teriyaki Mushroom Asada Burrito Bowl", MealPeriod.DINNER),
            (3, "Golden Eryngii Fragrant Rice", MealPeriod.LUNCH),
            (3, "Tomato Beancurd Rice", MealPeriod.DINNER),
            (4, "Tempeh Katsu Bowl", MealPeriod.LUNCH),
            (4, "Jap Chae", MealPeriod.DINNER),
            (5, "Classic Curry Bowl", MealPeriod.LUNCH),
            (5, "BBQ Pita Mushroom Wrap", MealPeriod.DINNER),
            (6, "Fusilli Bolognese", MealPeriod.LUNCH),
            (6, "Vegan Squid Curry Rice", MealPeriod.DINNER),
            # Week 2
            (9, "Dry Classic Curry Konjac Noodle", MealPeriod.LUNCH),
            (9, "Gochujang Hericium Mushroom Bowl", MealPeriod.DINNER),
            (10, "Dark Sauce Hericium Mushroom Rice", MealPeriod.LUNCH),
            (10, "Herbal Soup w/ Rice Balls", MealPeriod.DINNER),
            (11, "Falafel Bowl", MealPeriod.LUNCH),
            (11, "Bulgogi Rice Bowl with Steamed Broccoli", MealPeriod.DINNER),
            (12, "Soba Noodle w/ Teriyaki Noodle Bowl", MealPeriod.LUNCH),
            (12, "Lemon Mushroom Rice", MealPeriod.DINNER),
            (13, "Tomyam Fried Bihun", MealPeriod.LUNCH),
            (13, "Ginger Beancurd Seaweed Rice", MealPeriod.DINNER),
            # Week 3
            (16, "Korean Bibimbap Bowl", MealPeriod.LUNCH),
            (16, "Sweet & Sour Hericium Rice", MealPeriod.DINNER),
            (17, "Fusilli Pesto", MealPeriod.LUNCH),
            (17, "Taiwanese Braised Mushroom Rice", MealPeriod.DINNER),
            (18, "Eight Treasure Congee", MealPeriod.LUNCH),
            (18, "Jawa Mee", MealPeriod.DINNER),
            (19, "Karaage Buddha Bowl", MealPeriod.LUNCH),
            (19, "Kung Pao Hericium Mushroom Rice", MealPeriod.DINNER),
            # Week 4 (20, 23, 24 = Hari Raya holidays)
            (25, "Nasi Lemak Classic Curry", MealPeriod.LUNCH),
            (25, "Japanese Furikake Rice", MealPeriod.DINNER),
            (26, "Kimchi Fried Quinoa Rice", MealPeriod.LUNCH),
            (26, "Yakisoba", MealPeriod.DINNER),
            (27, "Nasi Tomato w/ Masak Merah", MealPeriod.LUNCH),
            (27, "Spicy Fusilli Pasta", MealPeriod.DINNER),
            # Week 5
            (30, "Japanese Curry Katsu Rice", MealPeriod.LUNCH),
            (30, "Fragrant Butter Rice w/ Grilled Pumpkin", MealPeriod.DINNER),
            (31, "Thai Minced Beancurd Rice", MealPeriod.LUNCH),
            (31, "Konjac Asam Laksa", MealPeriod.DINNER),
        ]
        for day, dish_name, period in march_menu:
            entries.append(PreviousMonthEntry(
                dish_id=_dish_id(dish_name),
                dish_name=dish_name,
                date=date(2026, 3, day),
                meal_period=period,
                month="2026-03",
            ))
        return entries

    def print_summary(self):
        cuisines = {}
        spicy_count = 0
        bases = {}
        for d in self.dishes:
            cuisines[d.cuisine] = cuisines.get(d.cuisine, 0) + 1
            bases[d.base_ingredient.value] = bases.get(d.base_ingredient.value, 0) + 1
            if d.spicy:
                spicy_count += 1
        print(f"Total dishes: {len(self.dishes)}")
        print(f"Spicy: {spicy_count} / {len(self.dishes)}")
        print(f"Cuisines: {dict(sorted(cuisines.items(), key=lambda x: -x[1]))}")
        print(f"Bases: {dict(sorted(bases.items(), key=lambda x: -x[1]))}")
