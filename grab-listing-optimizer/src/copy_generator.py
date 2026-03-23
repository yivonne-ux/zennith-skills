"""AI-powered menu copywriting — bilingual descriptions + emoji.

Generates optimized GrabFood menu copy:
- Bilingual names (English + Chinese)
- Emoji-prefixed for visual scanning
- Appetite-triggering descriptions (50-80 chars)
- Category structure with emoji headers
- Store description optimization
"""

import json
import logging
from typing import Optional
from openai import AsyncOpenAI

from src.config import OPENAI_API_KEY
from src.scraper import MenuItem

log = logging.getLogger("grab.copy")

client = AsyncOpenAI(api_key=OPENAI_API_KEY) if OPENAI_API_KEY else None

SYSTEM_PROMPT = """You are a GrabFood listing optimization expert specializing in Malaysian hawker food.
You write bilingual (English + Chinese) menu copy that maximizes orders on food delivery apps.

Rules:
- Every item name starts with a relevant food emoji
- Names are bilingual: English + Chinese (e.g., "🍜 Signature Prawn Noodle 招牌虾面")
- Descriptions are 50-80 characters, appetite-triggering, mention key ingredients
- Use warm, appetizing language (no generic "delicious" — be specific)
- Categories use emoji headers (e.g., "🍜 Noodles", "🍚 Rice", "🥟 Sides", "🧋 Drinks")
- Store descriptions: under 150 chars, include USP + cuisine type + relevant emoji
- Respect the original dish — don't change what it is, just make it sound irresistible
- For Chinese text, use Simplified Chinese (简体中文) unless the original is Traditional
- Keep pricing suggestions in RM, rounded to .50 or .90
"""


async def generate_menu_copy(
    items: list[dict],
    store_name: str = "",
    cuisine_type: str = "Chinese hawker",
) -> dict:
    """Generate optimized menu copy for all items.

    Args:
        items: List of {"name": str, "price": float, "description": str, "category": str}
        store_name: Current store name
        cuisine_type: Type of cuisine

    Returns:
        Dict with optimized store name, description, categories, and items
    """
    if not client:
        log.error("OpenAI API key not set")
        return {}

    items_text = "\n".join(
        f"- {i.get('name', 'Unknown')} | RM {i.get('price', 0):.2f} | "
        f"Category: {i.get('category', 'Uncategorized')} | "
        f"Description: {i.get('description', 'none')}"
        for i in items
    )

    prompt = f"""Optimize this GrabFood listing for maximum orders.

Store name: {store_name}
Cuisine type: {cuisine_type}

Current menu items:
{items_text}

Return a JSON object with:
{{
  "store_name": "optimized bilingual store name with emoji",
  "store_description": "under 150 chars, bilingual, with emoji, USP-focused",
  "categories": [
    {{
      "name": "emoji + category name",
      "items": [
        {{
          "original_name": "original item name for matching",
          "name": "🍜 Optimized Bilingual Name 优化名称",
          "description": "50-80 char appetite-triggering description",
          "price": 12.90,
          "tags": ["BESTSELLER"]
        }}
      ]
    }}
  ]
}}

Guidelines:
- Reorganize items into 5-8 clear categories
- Put best sellers in a "🔥 Best Sellers 招牌推荐" category at the top
- Add appropriate tags: BESTSELLER, SPICY, CHEF_PICK, NEW, POPULAR
- Suggest price adjustments if any are oddly rounded (keep within ±RM 1)
- Every item gets an emoji prefix and bilingual name
"""

    try:
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=4000,
        )
        result = json.loads(resp.choices[0].message.content)
        log.info(f"Generated copy: {len(result.get('categories', []))} categories")
        return result
    except Exception as e:
        log.error(f"Copy generation failed: {e}")
        return {}


async def generate_item_description(
    item_name: str,
    cuisine_type: str = "Chinese hawker",
    ingredients: str = "",
) -> dict:
    """Generate optimized copy for a single menu item.

    Returns:
        {"name": "emoji bilingual name", "description": "appetizing desc"}
    """
    if not client:
        return {"name": item_name, "description": ""}

    prompt = f"""Optimize this single GrabFood menu item:

Name: {item_name}
Cuisine: {cuisine_type}
Known ingredients: {ingredients or 'not specified'}

Return JSON:
{{
  "name": "🍜 Optimized Bilingual Name 优化中文名",
  "description": "50-80 char description that makes people hungry"
}}"""

    try:
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=500,
        )
        return json.loads(resp.choices[0].message.content)
    except Exception as e:
        log.error(f"Item description generation failed: {e}")
        return {"name": item_name, "description": ""}


async def generate_promo_strategy(
    store_name: str,
    avg_order_value: float = 15.0,
    current_rating: float = 4.0,
    monthly_orders: int = 100,
) -> dict:
    """Generate promotion strategy for a store.

    Returns:
        Dict with recommended promotions, timing, and expected ROI
    """
    if not client:
        return {}

    prompt = f"""Create a GrabFood promotion strategy for this store:

Store: {store_name}
Average order value: RM {avg_order_value:.2f}
Current rating: {current_rating}
Monthly orders: ~{monthly_orders}

Return JSON:
{{
  "promotions": [
    {{
      "type": "new_customer_discount | free_delivery | bundle_deal | off_peak",
      "name": "promo display name",
      "details": "specifics (% off, cap, conditions)",
      "timing": "when to run (days/hours)",
      "estimated_roi": "expected return multiple",
      "priority": "high | medium | low"
    }}
  ],
  "bundle_suggestions": [
    {{
      "name": "Bundle name with emoji",
      "items": ["item1", "item2"],
      "original_total": 25.80,
      "bundle_price": 22.90,
      "savings_display": "Save RM 2.90!"
    }}
  ],
  "review_strategy": "brief action plan for improving reviews"
}}"""

    try:
        resp = await client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            response_format={"type": "json_object"},
            temperature=0.7,
            max_tokens=2000,
        )
        return json.loads(resp.choices[0].message.content)
    except Exception as e:
        log.error(f"Promo strategy generation failed: {e}")
        return {}
