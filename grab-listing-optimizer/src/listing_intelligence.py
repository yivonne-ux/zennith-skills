"""Listing Intelligence Engine — the brain behind Grab listing optimization.

Combines:
1. Menu structure analysis (categories, naming, pricing)
2. Copy optimization (bilingual names, emoji, descriptions)
3. Photo-to-item mapping (which photo goes where)
4. Upload manifest generation (everything Grab Merchant portal needs)
5. Competitor benchmarking (pricing, structure patterns)

This module generates a complete upload_manifest.json that the
GrabEditor can consume to batch-update the entire listing.
"""

import json
import logging
from dataclasses import dataclass, field, asdict
from pathlib import Path
from typing import Optional

log = logging.getLogger("grab.intelligence")


# ── Data Models ──────────────────────────────────────────

@dataclass
class MenuItemSpec:
    """Complete specification for one Grab menu item."""
    code: str                        # e.g. "100"
    name_en: str = ""                # English name
    name_cn: str = ""                # Chinese name
    grab_name: str = ""              # Final name for Grab (bilingual + emoji)
    description: str = ""            # Appetite-triggering description
    category: str = ""               # Category slug
    category_display: str = ""       # Category display name with emoji
    price_small: float = 0.0         # Small size price (0 if no size option)
    price_large: float = 0.0         # Large size price (0 if no size option)
    price: float = 0.0               # Single price (when no size variants)
    photo_path: str = ""             # Path to grab-800 photo
    banner_path: str = ""            # Path to banner photo
    thumb_path: str = ""             # Path to 80px thumbnail
    is_available: bool = True
    tags: list = field(default_factory=list)  # BESTSELLER, SPICY, NEW, etc.
    variations: list = field(default_factory=list)  # size, noodle type, etc.
    add_ons: list = field(default_factory=list)
    sort_order: int = 0              # Within category


@dataclass
class CategorySpec:
    """Complete specification for one Grab menu category."""
    slug: str
    name_en: str
    name_cn: str
    display_name: str  # Emoji + bilingual
    sort_order: int = 0
    items: list = field(default_factory=list)  # list of MenuItemSpec


@dataclass
class StoreSpec:
    """Complete specification for a Grab store listing."""
    store_name: str = ""
    store_name_optimized: str = ""
    store_description: str = ""
    store_id: str = ""
    merchant_id: str = ""
    cuisine_type: str = ""
    banner_photo: str = ""
    categories: list = field(default_factory=list)  # list of CategorySpec
    total_items: int = 0
    items_with_photos: int = 0
    optimization_score: int = 0
    issues: list = field(default_factory=list)
    recommendations: list = field(default_factory=list)


# ── Listing Intelligence Engine ──────────────────────────

class ListingIntelligence:
    """Generates optimized listing specs from raw data."""

    def __init__(self, merchant_id: str, photos_dir: str):
        self.merchant_id = merchant_id
        self.photos_dir = Path(photos_dir)

    def build_uncle_chua_listing(self) -> StoreSpec:
        """Build complete optimized listing for Uncle Chua Prawn Noodle.

        This is the reference implementation — hardcoded from the audit.
        Future stores will use LLM-generated specs.
        """
        store = StoreSpec(
            store_name="Uncle Chua's Prawn Noodle - Medan Putrajaya",
            store_name_optimized="🍜 Uncle Chua's Prawn Noodle 泉记虾面 - Medan Putrajaya",
            store_description="Penang-style prawn noodle since 1985 🦐 Rich prawn broth, fresh tiger prawns, handmade noodles. Signature dry & soup styles. 传统槟城虾面，鲜虾浓汤",
            merchant_id=self.merchant_id,
            cuisine_type="Penang Hawker / Prawn Noodle",
        )

        # ── Category 1: Best Sellers ──
        bestsellers = CategorySpec(
            slug="best-sellers",
            name_en="Best Sellers",
            name_cn="招牌推荐",
            display_name="🔥 Best Sellers 招牌推荐",
            sort_order=1,
        )
        bestsellers.items = [
            MenuItemSpec(
                code="100", name_en="Prawn Noodle", name_cn="虾面",
                grab_name="🍜 Signature Prawn Noodle 招牌虾面",
                description="Rich prawn broth with fresh shrimps, sliced pork, egg, bean sprouts & pandan leaf. Our #1 bestseller!",
                category="best-sellers", category_display=bestsellers.display_name,
                price=21.90,
                photo_path=self._find_photo("100", "prawn-noodle"),
                tags=["BESTSELLER", "MOST_ORDERED"],
                variations=[
                    {"name": "Noodle Type", "options": ["Yellow Noodle", "Bee Hoon", "Lam Mee Sua", "Kuey Teow"]},
                ],
                sort_order=1,
            ),
            MenuItemSpec(
                code="101", name_en="Dry Prawn Noodle", name_cn="干捞虾面",
                grab_name="🍜 Signature Dry Prawn Noodle 招牌干捞虾面",
                description="Tossed in rich prawn paste with fresh shrimps, egg, pork slices & crispy shallots. Spicy & savoury!",
                category="best-sellers", category_display=bestsellers.display_name,
                price=21.90,
                photo_path=self._find_photo("101", "dry-prawn-noodle"),
                tags=["BESTSELLER", "SIGNATURE"],
                variations=[
                    {"name": "Noodle Type", "options": ["Yellow Noodle", "Bee Hoon", "Lam Mee Sua", "Kuey Teow"]},
                ],
                sort_order=2,
            ),
            MenuItemSpec(
                code="200", name_en="Lam Mee", name_cn="煨面",
                grab_name="🍜 Penang Lam Mee 槟城煨面",
                description="Prawn-based egg drop soup with fresh shrimps, pork, spring onions & fried shallots. Comfort in a bowl!",
                category="best-sellers", category_display=bestsellers.display_name,
                price=21.90,
                photo_path=self._find_photo("200", "lam-mee"),
                tags=["MOST_ORDERED"],
                sort_order=3,
            ),
        ]

        # ── Category 2: Prawn Noodle ──
        prawn = CategorySpec(
            slug="prawn-noodle",
            name_en="Prawn Noodle",
            name_cn="虾面",
            display_name="🦐 Prawn Noodle 虾面",
            sort_order=2,
        )
        prawn.items = [
            MenuItemSpec(
                code="102", name_en="Tiger Prawn Noodle", name_cn="大头虾虾面",
                grab_name="🦐 Tiger Prawn Noodle 大头虾虾面",
                description="Whole tiger prawn in rich broth with pork, egg & bean sprouts. The prawn lover's choice!",
                category="prawn-noodle", price=29.90,
                photo_path=self._find_photo("102", "tiger-prawn-noodle"),
                tags=["POPULAR"],
                sort_order=1,
            ),
            MenuItemSpec(
                code="103", name_en="Udang Galah Prawn Noodle", name_cn="淡水大虾虾面",
                grab_name="🦞 Udang Galah Prawn Noodle 淡水大虾虾面",
                description="Premium freshwater prawn (udang galah) in signature broth. Big, fresh & impressive!",
                category="prawn-noodle", price=49.90,
                photo_path=self._find_photo("103", "udang-galah-prawn-noodle"),
                tags=["PREMIUM"],
                sort_order=2,
            ),
            MenuItemSpec(
                code="105", name_en="Prawn Noodle with Pork Ribs", name_cn="排骨虾面",
                grab_name="🍖 Prawn Noodle + Pork Ribs 排骨虾面",
                description="Best of both worlds — tender pork ribs in spicy prawn broth with fresh shrimps & egg",
                category="prawn-noodle", price=29.90,
                photo_path=self._find_photo("105", "prawn-noodle-pork-ribs"),
                sort_order=3,
            ),
            MenuItemSpec(
                code="107", name_en="MALA Dry Prawn Noodle", name_cn="麻辣干捞虾面",
                grab_name="🌶️ MALA Dry Prawn Noodle 麻辣干捞虾面",
                description="Numbing spicy prawn noodle tossed in Sichuan mala sauce. For spice lovers only! 🔥",
                category="prawn-noodle", price_small=11.50, price_large=13.50,
                photo_path=self._find_photo("107", "mala-dry-prawn-noodle"),
                tags=["SPICY", "NEW"],
                sort_order=4,
            ),
            MenuItemSpec(
                code="108", name_en="Seafood Deluxe Prawn Noodle (2 Pax)", name_cn="海鲜王虾面（2人份）",
                grab_name="👑 Seafood Deluxe for 2 海鲜王虾面",
                description="Tiger prawn, oyster, octopus, crab, show crab meat, pork, egg — the ultimate sharing bowl!",
                category="prawn-noodle", price=39.90,
                photo_path="",  # MISSING — needs shoot
                tags=["PREMIUM", "SHARING"],
                sort_order=5,
            ),
        ]

        # ── Category 3: Lam Mee & Rice ──
        lammee = CategorySpec(
            slug="lam-mee-rice",
            name_en="Lam Mee & Rice",
            name_cn="煨面 & 饭",
            display_name="🍚 Lam Mee & Rice 煨面与饭",
            sort_order=3,
        )
        lammee.items = [
            MenuItemSpec(
                code="201", name_en="Lam Mee Suah", name_cn="煨面线",
                grab_name="🍜 Lam Mee Suah 煨面线",
                description="Fine wheat noodles in prawn-egg drop broth with fresh shrimps, pork paste & veggie balls",
                category="lam-mee-rice", price=21.90,
                photo_path=self._find_photo("201", "lam-mee-suah"),
                sort_order=1,
            ),
            MenuItemSpec(
                code="205", name_en="Nyonya Curry Laksa", name_cn="娘惹咖喱叻沙",
                grab_name="🍛 Nyonya Curry Laksa 娘惹咖喱叻沙",
                description="Creamy coconut curry with prawns, tofu puffs, fish balls & keropok. Rich Peranakan flavour!",
                category="lam-mee-rice", price=13.90,
                photo_path=self._find_photo("205", "nyonya-curry-laksa"),
                tags=["NEW"],
                sort_order=2,
            ),
            MenuItemSpec(
                code="206", name_en="Chicken Chop Rice", name_cn="鸡扒饭",
                grab_name="🍗 Chicken Chop Rice 鸡扒饭",
                description="Crispy fried chicken chop with steamed rice. Choose your sauce: black pepper, Hainanese, or cheesy!",
                category="lam-mee-rice", price=13.90,
                photo_path="",  # MISSING
                tags=["NEW"],
                variations=[
                    {"name": "Sauce", "options": ["Black Pepper Sauce", "Hainanese Sauce", "Cheesy Sauce"]},
                ],
                sort_order=3,
            ),
        ]

        # ── Category 4: Soup Noodle ──
        soup = CategorySpec(
            slug="soup-noodle",
            name_en="Pork Paste Soup Noodle",
            name_cn="肉骨茶面",
            display_name="🥣 Soup Noodle 肉骨茶面",
            sort_order=4,
        )
        soup.items = [
            MenuItemSpec(
                code="300", name_en="Pork Paste Soup Noodle", name_cn="猪肉膏汤面",
                grab_name="🥣 Pork Paste Soup Noodle 猪肉膏汤面",
                description="Homemade pork paste in clear broth with veggie balls, fried beancurd & baby romaine",
                category="soup-noodle", price=21.90,
                photo_path="",  # MISSING
                sort_order=1,
            ),
            MenuItemSpec(
                code="305", name_en="Chicken Shrimp Wanton Hor Fun", name_cn="鸡丝鲜虾云吞河粉",
                grab_name="🥟 Chicken Shrimp Wanton Hor Fun 鸡丝鲜虾云吞河粉",
                description="Silky flat noodles in clear soup with shredded chicken, plump shrimp wantons & fresh greens",
                category="soup-noodle", price_small=10.90, price_large=12.90,
                photo_path=self._find_photo("305", "chicken-shrimp-wanton"),
                tags=["NEW"],
                sort_order=2,
            ),
            MenuItemSpec(
                code="307", name_en="MALA Dry Pork Paste Noodle", name_cn="麻辣干捞肉骨茶面",
                grab_name="🌶️ MALA Dry Pork Paste Noodle 麻辣干捞肉骨茶面",
                description="Numbing mala sauce with homemade pork paste, veggie balls & fried beancurd. Spicy & hearty!",
                category="soup-noodle", price_small=11.50, price_large=13.50,
                photo_path=self._find_photo("307", "mala-dry-pork-paste"),
                tags=["SPICY", "NEW"],
                sort_order=3,
            ),
        ]

        # ── Category 5: Snacks ──
        snacks = CategorySpec(
            slug="snacks",
            name_en="Snacks",
            name_cn="小吃",
            display_name="🥟 Snacks 小吃",
            sort_order=5,
        )
        snacks.items = [
            MenuItemSpec(
                code="500", name_en="Fried Beancurd with Fungus", name_cn="炸腐竹卷",
                grab_name="🧈 Fried Beancurd with Fungus 炸腐竹卷",
                description="Crispy deep-fried beancurd skin rolls stuffed with fungus. Crunchy outside, tender inside!",
                category="snacks", price=7.90,
                photo_path=self._find_photo("500", "fried-beancurd-fungus"),
                tags=["POPULAR"],
                sort_order=1,
            ),
            MenuItemSpec(
                code="501", name_en="Fried Chicken Popcorn", name_cn="炸鸡米花",
                grab_name="🍗 Fried Chicken Popcorn 炸鸡米花",
                description="Bite-sized crispy chicken popcorn — perfect snack or add-on to your noodle!",
                category="snacks", price=7.90,
                photo_path=self._find_photo("501", "snack-501"),
                sort_order=2,
            ),
            MenuItemSpec(
                code="502", name_en="Fried Beancurd", name_cn="炸豆腐",
                grab_name="🧈 Crispy Fried Beancurd 香脆炸豆腐",
                description="Light & crispy beancurd skin chips with fresh cucumber. Simple & addictive!",
                category="snacks", price=7.90,
                photo_path=self._find_photo("502", "fried-beancurd"),
                sort_order=3,
            ),
            MenuItemSpec(
                code="503", name_en="Golden Beancurd Prawn", name_cn="黄金虾枣",
                grab_name="🦐 Golden Beancurd Prawn 黄金虾枣",
                description="Golden fried prawn paste wrapped in beancurd skin. Crunchy, savoury & prawny!",
                category="snacks", price=7.90,
                photo_path=self._find_photo("503", "snack-503"),
                sort_order=4,
            ),
            MenuItemSpec(
                code="506", name_en="Fried Fish Ball", name_cn="炸鱼丸",
                grab_name="🐟 Fried Fish Ball 炸鱼丸",
                description="Bouncy fish balls deep fried until golden. Great with chilli sauce!",
                category="snacks", price=7.90,
                photo_path=self._find_photo("506", "snack-506"),
                sort_order=5,
            ),
        ]

        # ── Category 6: Desserts ──
        desserts = CategorySpec(
            slug="desserts",
            name_en="Desserts",
            name_cn="甜品",
            display_name="🍧 Desserts 甜品",
            sort_order=6,
        )
        desserts.items = [
            MenuItemSpec(
                code="800", name_en="Red Bean Soup", name_cn="红豆汤",
                grab_name="🫘 Red Bean Soup 红豆汤",
                description="Homemade warm red bean soup — the classic Chinese dessert to end your meal",
                category="desserts", price=5.90,
                photo_path=self._find_photo("800", "red-bean-soup"),
                sort_order=1,
            ),
        ]

        # ── Category 7: Beverages (Hot) ──
        hot_drinks = CategorySpec(
            slug="hot-beverages",
            name_en="Hot Beverages",
            name_cn="热饮",
            display_name="☕ Hot Beverages 热饮",
            sort_order=7,
        )
        hot_drinks.items = [
            self._drink_item("600", "White Coffee", "白咖啡", "☕", "Classic Ipoh white coffee — smooth, creamy & aromatic", 4.50),
            self._drink_item("601", "Kopi O", "咖啡乌", "☕", "Traditional black coffee with sugar. Strong local flavour!", 3.40),
            self._drink_item("613", "Nanyang Kopi", "南洋咖啡", "☕", "Rich Nanyang-style coffee brewed the old-school way", 6.50, tags=["MOST_LIKED"]),
            self._drink_item("614", "Nanyang Kopi C", "南洋咖啡C", "☕", "Nanyang coffee with evaporated milk. Smooth & creamy!", 6.50),
            self._drink_item("602", "Nescafe", "即溶咖啡", "☕", "Classic Nescafe with condensed milk", 5.50),
            self._drink_item("603", "Neslo", "Neslo", "☕", "Nescafe + Milo combo — best of both worlds!", 5.50),
            self._drink_item("604", "Teh O", "茶乌", "🍵", "Local black tea with sugar. Refreshing & classic!", 3.40),
            self._drink_item("615", "Nanyang Teh", "南洋茶", "🍵", "Premium Nanyang-style tea. Fragrant & rich!", 6.50),
            self._drink_item("616", "Nanyang Teh C", "南洋茶C", "🍵", "Nanyang tea with evaporated milk. Silky smooth!", 6.50),
            self._drink_item("617", "Cham O", "鸳鸯乌", "☕", "Coffee-tea mix (cham) without milk. Unique local blend!", 3.40),
            self._drink_item("618", "Cham", "鸳鸯", "☕", "Coffee + tea with condensed milk. The original Malaysian blend!", 6.50),
            self._drink_item("619", "Cham C", "鸳鸯C", "☕", "Coffee-tea mix with evaporated milk. Smooth version!", 6.50),
            self._drink_item("605", "Milo", "美禄", "🥤", "Hot Milo made with rich chocolate malt", 7.50),
        ]

        # ── Category 8: Cold Beverages ──
        cold_drinks = CategorySpec(
            slug="cold-beverages",
            name_en="Cold Beverages",
            name_cn="冷饮",
            display_name="🧊 Cold Beverages 冷饮",
            sort_order=8,
        )
        cold_drinks.items = [
            self._drink_item("606", "Coca-Cola", "可口可乐", "🥤", "Ice-cold Coca-Cola can with glass", 5.00),
            self._drink_item("607", "100 Plus", "100号", "🥤", "Isotonic 100 Plus — refreshing after a spicy meal!", 5.00),
            self._drink_item("608", "Sour Plum Juice", "酸梅汁", "🧃", "Homemade sour plum with lime — sweet, sour & cooling!", 9.50),
            self._drink_item("609", "Ambra Juice", "安布拉汁", "🧃", "Kedondong (ambra) juice with sour plum. Tangy & tropical!", 9.50),
            self._drink_item("610", "Herbal Tea", "凉茶", "🍵", "Homemade Chinese herbal tea — cooling & healthy!", 6.00),
            self._drink_item("611", "Barley", "薏米水", "🥤", "Homemade barley water — classic Chinese cooling drink", 6.00),
            self._drink_item("612", "Barley Lime", "薏米青柠", "🍋", "Barley water with fresh lime. Extra refreshing!", 7.00),
            self._drink_item("650", "Fresh Orange Juice", "鲜橙汁", "🍊", "Freshly squeezed orange juice — no added sugar!", 9.50),
            self._drink_item("651", "Fresh Apple Juice", "鲜苹果汁", "🍏", "Fresh apple juice — light, sweet & healthy!", 9.50),
            self._drink_item("652", "Glass Jelly", "仙草", "🍮", "Smooth grass jelly in sweet syrup. Classic dessert drink!", 5.00),
        ]

        # Assemble store
        store.categories = [bestsellers, prawn, lammee, soup, snacks, desserts, hot_drinks, cold_drinks]

        # Calculate stats
        all_items = []
        for cat in store.categories:
            all_items.extend(cat.items)
        store.total_items = len(all_items)
        store.items_with_photos = sum(1 for i in all_items if i.photo_path)

        # Score
        store.optimization_score = self._score(store, all_items)

        # Issues
        missing_photos = [i for i in all_items if not i.photo_path]
        if missing_photos:
            store.issues.append(f"{len(missing_photos)} items missing photos: {', '.join(i.code for i in missing_photos)}")
        duplicate_note = "200.JPG = 201.JPG (same photo for different items — need unique shot for Lam Mee Suah)"
        store.issues.append(duplicate_note)

        store.recommendations = [
            "Remove yellow background + logo overlay from all Grab thumbnails",
            "Reshoot drink photos on white background (current ones are dark restaurant shots)",
            "Add photos for items 108 (Seafood Deluxe), 206 (Chicken Chop), 300 (Pork Paste Soup)",
            "Create unique photo for 201 Lam Mee Suah (currently identical to 200 Lam Mee)",
            "Upload store banner (1350x750) using best prawn noodle hero shot",
            "Run 50% off promo for first-time customers during off-peak 2-5pm",
        ]

        return store

    def _find_photo(self, code: str, slug: str) -> str:
        """Find the best grab-800 photo for a given item code."""
        # Priority: direct code match, then heic convert, then variant
        patterns = [
            f"uncle-chua_{code}_{slug}_grab-800.jpg",
            f"uncle-chua_{code}_{slug}_heic_grab-800.jpg",
            f"uncle-chua_{code}_*_grab-800.jpg",
        ]
        for pattern in patterns:
            matches = list(self.photos_dir.glob(pattern))
            if matches:
                return str(matches[0])
        return ""

    def _drink_item(self, code, name_en, name_cn, emoji, desc, price, tags=None):
        """Helper to create a drink MenuItemSpec."""
        slug = DRINK_SLUGS.get(code, name_en.lower().replace(" ", "-"))
        return MenuItemSpec(
            code=code, name_en=name_en, name_cn=name_cn,
            grab_name=f"{emoji} {name_en} {name_cn}",
            description=desc,
            category="hot-beverages" if code < "606" else "cold-beverages",
            price=price,
            photo_path=self._find_photo(code, slug),
            tags=tags or [],
            sort_order=int(code) % 100,
        )

    def _score(self, store, all_items) -> int:
        """Calculate optimization score (0-100)."""
        score = 0

        # Photo coverage (40 pts)
        if store.total_items > 0:
            score += int((store.items_with_photos / store.total_items) * 40)

        # All items have descriptions (15 pts)
        with_desc = sum(1 for i in all_items if i.description and len(i.description) > 20)
        score += int((with_desc / max(len(all_items), 1)) * 15)

        # Bilingual names (15 pts)
        bilingual = sum(1 for i in all_items if i.name_cn)
        score += int((bilingual / max(len(all_items), 1)) * 15)

        # Emoji in names (10 pts)
        with_emoji = sum(1 for i in all_items if any(ord(c) > 0x1F600 for c in i.grab_name))
        score += int((with_emoji / max(len(all_items), 1)) * 10)

        # Category structure (10 pts)
        num_cats = len(store.categories)
        if 5 <= num_cats <= 8:
            score += 10
        elif 3 <= num_cats <= 10:
            score += 5

        # Store description (10 pts)
        if store.store_description and len(store.store_description) > 30:
            score += 5
        if any(ord(c) > 0x1F600 for c in store.store_description):
            score += 3
        if any('\u4e00' <= c <= '\u9fff' for c in store.store_description):
            score += 2

        return min(score, 100)

    # ── Export ────────────────────────────────────────────

    def export_manifest(self, store: StoreSpec, output_path: str) -> Path:
        """Export complete upload manifest as JSON.

        This manifest contains everything needed to:
        1. Update all menu items on Grab Merchant portal
        2. Upload all photos
        3. Restructure categories
        4. Update store info
        """
        manifest = {
            "version": "1.0",
            "merchant_id": store.merchant_id,
            "generated_by": "grab-listing-optimizer",
            "store": {
                "name": store.store_name,
                "name_optimized": store.store_name_optimized,
                "description": store.store_description,
                "cuisine_type": store.cuisine_type,
                "banner_photo": store.banner_photo,
            },
            "stats": {
                "total_items": store.total_items,
                "items_with_photos": store.items_with_photos,
                "photo_coverage": f"{store.items_with_photos}/{store.total_items} ({store.items_with_photos/max(store.total_items,1)*100:.0f}%)",
                "optimization_score": store.optimization_score,
                "categories": len(store.categories),
            },
            "categories": [],
            "upload_queue": [],  # Ordered list of what to do on merchant portal
            "issues": store.issues,
            "recommendations": store.recommendations,
        }

        for cat in store.categories:
            cat_data = {
                "slug": cat.slug,
                "display_name": cat.display_name,
                "sort_order": cat.sort_order,
                "items": [],
            }
            for item in cat.items:
                item_data = {
                    "code": item.code,
                    "grab_name": item.grab_name,
                    "description": item.description,
                    "price": item.price if item.price else None,
                    "price_small": item.price_small if item.price_small else None,
                    "price_large": item.price_large if item.price_large else None,
                    "photo_path": item.photo_path,
                    "has_photo": bool(item.photo_path),
                    "tags": item.tags,
                    "variations": item.variations,
                    "is_available": item.is_available,
                }
                cat_data["items"].append(item_data)

                # Build upload queue entry
                if item.photo_path:
                    manifest["upload_queue"].append({
                        "action": "upload_photo",
                        "item_name": item.grab_name,
                        "original_name": f"{item.code}. {item.name_en}",
                        "photo_path": item.photo_path,
                    })
                manifest["upload_queue"].append({
                    "action": "update_item",
                    "item_name": f"{item.code}. {item.name_en}",
                    "new_name": item.grab_name,
                    "new_desc": item.description,
                    "new_price": item.price or item.price_large or 0,
                })

            manifest["categories"].append(cat_data)

        out = Path(output_path)
        out.parent.mkdir(parents=True, exist_ok=True)
        with open(out, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)

        log.info(f"Manifest exported: {out} ({store.total_items} items, {len(manifest['upload_queue'])} actions)")
        return out


# Slug mapping for drinks
DRINK_SLUGS = {
    "600": "white-coffee", "601": "kopi-o", "602": "nescafe", "603": "neslo",
    "604": "teh-o", "605": "milo", "606": "coca-cola", "607": "100-plus",
    "608": "sour-plum-juice", "609": "ambra-juice", "610": "herbal-tea",
    "611": "barley", "612": "barley-lime", "613": "nanyang-kopi",
    "614": "nanyang-kopi-c", "615": "nanyang-teh", "616": "nanyang-teh-c",
    "617": "cham-o", "618": "cham", "619": "cham-c",
    "650": "fresh-orange-juice", "651": "fresh-apple-juice", "652": "glass-jelly",
}
