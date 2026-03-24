"""Seed Mirra Eats brand data into Apex Meta database.

Run: cd apex-meta && python scripts/seed_mirra.py
Requires: PostgreSQL running, tables created (python scripts/init_db.py first)
"""

import asyncio
import sys
import uuid
from datetime import datetime, timezone
from decimal import Decimal

sys.path.insert(0, "backend")

from app.db.base import Base, engine, get_session
from app.db.models.brand import Brand
from app.db.models.campaign import Campaign, AdSet, Ad, CampaignObjective, EntityStatus
from app.db.models.asset import Asset, AssetType, AssetStatus, ApprovalStatus
from app.db.models.supporting import AuditLog, AuditSeverity


MIRRA_BRAND = {
    "name": "Mirra Eats",
    "slug": "mirra",
    "vertical": "food_delivery",
    "meta_ad_account_id": "830110298602617",
    "meta_pixel_id": None,
    "brand_dna": {
        "usp": "Diet bento — not convenient lunch bento. Low calorie, lose weight, drop a size.",
        "tone": "Girlboss, aspirational, NOT diet culture preachy",
        "price_point": "RM12-15 per bento",
        "positioning": "We're diet bento, not convenient lunch bento",
        "competitors": ["Dah Makan", "Yolo Foods", "The Rebellious Chickpea"],
        "platforms": ["Meta (FB/IG)", "WhatsApp (CTWA)"],
        "page_id": "318283048041590",
        "whatsapp": "60193838732",
        "copy_rules": {
            "never_lead_with": ["plant-based", "healthy", "nutritious", "balanced diet"],
            "always_lead_with": ["diet result", "lose weight", "drop a size", "low calorie"],
            "voice": "identity-first, viral/sendable, no exclamation marks",
            "forbidden": ["Before/after", "limited time", "don't miss out", "chicken/beef/meat"],
        },
        "visual_rules": {
            "palette": {
                "blush": "#F8BEC0",
                "dusty_rose": "#EBAAB9",
                "crimson": "#AC374B",
                "cream": "#FFF5EE",
            },
            "food_photos": "REAL only, NEVER AI-generated food",
            "format": "1080x1920 (9:16)",
            "logo": "Auto-color detection, smaller placement",
        },
    },
    "audience_personas": [
        {"name": "Office Girl", "age": "25-35", "interest": "weight loss, diet, fitness", "language": "EN"},
        {"name": "New Mum", "age": "28-40", "interest": "postpartum weight loss", "language": "EN"},
        {"name": "Diet Explorer", "age": "22-35", "interest": "calorie counting, bento", "language": "CN"},
        {"name": "KL Professional", "age": "25-40", "interest": "meal delivery, convenience", "language": "EN"},
    ],
    "target_countries": "MY",
    "roas_target": 3.0,
    "cpa_ceiling": 7.00,
    "monthly_budget": 36000,
    "onboarding_complete": True,
    "vector_namespace": "brand-mirra",
}

# Active campaigns with LIVE 7-day data (as of 2026-03-23)
CAMPAIGNS = [
    {
        "meta_campaign_id": "120243085821340787",
        "name": "MIRRA-SALES-EN-MAR26",
        "objective": CampaignObjective.OUTCOME_SALES,
        "status": EntityStatus.ACTIVE,
        "daily_budget": 350,
        "cbo_enabled": True,
        "last_cpa": 1.49,
        "ad_sets": [
            {
                "meta_adset_id": "120243085921060787",
                "name": "EN-TOP-PERFORMERS",
                "status": EntityStatus.ACTIVE,
                "daily_budget": 350,
                "last_cpa": 1.49,
                "ads": [
                    {"meta_ad_id": "120243085940440787", "name": "SALES-MOFU-S19-Transformation-OfficeOutfit", "status": EntityStatus.ACTIVE, "last_cpa": 0.97, "creative_type": "static", "hook_type": "transformation", "angle_type": "transformation"},
                    {"meta_ad_id": "120243085941040787", "name": "SALES-BOFU-BX07-WhatsApp-WorthIt", "status": EntityStatus.ACTIVE, "last_cpa": 1.67, "creative_type": "static", "hook_type": "message_ui", "angle_type": "social_proof"},
                    {"meta_ad_id": "120243085942080787", "name": "SALES-BOFU-BX08-iMessage-FriendReco", "status": EntityStatus.ACTIVE, "last_cpa": 1.90, "creative_type": "static", "hook_type": "message_ui", "angle_type": "social_proof"},
                    {"meta_ad_id": "120243085943760787", "name": "SALES-MIX-EN-VID-Sales-BoomBoom", "status": EntityStatus.ACTIVE, "last_cpa": 1.99, "creative_type": "video", "hook_type": "sbb", "angle_type": "testimonial"},
                    {"meta_ad_id": "120243085945550787", "name": "SALES-MIX-EN-VID-OL-Foodie-WeightGoals", "status": EntityStatus.ACTIVE, "last_cpa": 2.29, "creative_type": "video", "hook_type": "lifestyle", "angle_type": "identity"},
                    {"meta_ad_id": "120243085941520787", "name": "SALES-MIX-EN-VID-ZiQian-V2", "status": EntityStatus.ACTIVE, "last_cpa": 2.53, "creative_type": "video", "hook_type": "kol", "angle_type": "testimonial"},
                    {"meta_ad_id": "120243085949180787", "name": "SALES-MIX-EN-VID-KOL-Chris-v2", "status": EntityStatus.ACTIVE, "last_cpa": 4.25, "creative_type": "video", "hook_type": "kol", "angle_type": "testimonial"},
                    {"meta_ad_id": "120243085954770787", "name": "SALES-MIX-EN-VID-M3A-NewMums", "status": EntityStatus.ACTIVE, "last_cpa": 0.17, "creative_type": "video", "hook_type": "persona", "angle_type": "identity"},
                    {"meta_ad_id": "120243085953910787", "name": "SALES-MIX-EN-VID-M3D-OfficeGirls", "status": EntityStatus.ACTIVE, "last_cpa": 2.02, "creative_type": "video", "hook_type": "persona", "angle_type": "identity"},
                    {"meta_ad_id": "120243085950090787", "name": "SALES-MOFU-F10-Grid-MonToFri", "status": EntityStatus.ACTIVE, "last_cpa": 1.52, "creative_type": "static", "hook_type": "food_grid", "angle_type": "variety"},
                    {"meta_ad_id": "120243085942740787", "name": "SALES-MIX-EN-VID-KOL-Sunny-V3", "status": EntityStatus.ACTIVE, "last_cpa": 6.67, "creative_type": "video", "hook_type": "kol", "angle_type": "testimonial"},
                    {"meta_ad_id": "120243085946150787", "name": "SALES-TOFU-S10-Checklist-QuitList", "status": EntityStatus.ACTIVE, "last_cpa": 10.86, "creative_type": "static", "hook_type": "checklist", "angle_type": "education"},
                    {"meta_ad_id": "120243085944680787", "name": "SALES-MIX-EN-VID-M3B-NewMums", "status": EntityStatus.ACTIVE, "last_cpa": 12.04, "creative_type": "video", "hook_type": "persona", "angle_type": "identity"},
                    {"meta_ad_id": "120243085947460787", "name": "SALES-TOFU-S15-Horoscope-LunchProphecy", "status": EntityStatus.ACTIVE, "last_cpa": None, "creative_type": "static", "hook_type": "horoscope", "angle_type": "entertainment"},
                    {"meta_ad_id": "120243085951970787", "name": "SALES-TOFU-S01-Notes-JeansDontFit", "status": EntityStatus.ACTIVE, "last_cpa": None, "creative_type": "static", "hook_type": "notes", "angle_type": "identity"},
                ],
            },
        ],
    },
    {
        "meta_campaign_id": "120235573169200787",
        "name": "Scalling-SUPER-WIN",
        "objective": CampaignObjective.OUTCOME_SALES,
        "status": EntityStatus.ACTIVE,
        "daily_budget": 190,
        "cbo_enabled": True,
        "last_cpa": 2.73,
        "ad_sets": [],
    },
    {
        "meta_campaign_id": "120242895523710787",
        "name": "MIRRA-RETARGET-EN-MAR26",
        "objective": CampaignObjective.OUTCOME_SALES,
        "status": EntityStatus.ACTIVE,
        "daily_budget": 50,
        "cbo_enabled": False,
        "last_cpa": 2.29,
        "ad_sets": [],
    },
    {
        "meta_campaign_id": "120242910542110787",
        "name": "MIRRA-RETARGET-CN-MAR26",
        "objective": CampaignObjective.OUTCOME_SALES,
        "status": EntityStatus.ACTIVE,
        "daily_budget": 35,
        "cbo_enabled": False,
        "last_cpa": 2.26,
        "ad_sets": [],
    },
]

# Sales attribution data (March 17-23, 2026)
SALES_ATTRIBUTION = [
    {"ad_id": "120243085941520787", "ad_name": "SALES-MIX-EN-VID-ZiQian-V2", "campaign": "SALES-EN", "sales": 2, "revenue": 560.50},
    {"ad_id": "120237108120450787", "ad_name": "SBB-Chi-Warm-V3 (Copy 2)", "campaign": "SCALLING-CN-SBB", "sales": 2, "revenue": 1032.50},
    {"ad_id": "120242861107730787", "ad_name": "CN17-FreeDelivery-KLAreas", "campaign": "TEST-CN", "sales": 2, "revenue": 560.50},
    {"ad_id": "120238821800600787", "ad_name": "BOFU-12.12-Animation", "campaign": "Retargeting-EN", "sales": 1, "revenue": 794.00},
    {"ad_id": "120242861076080787", "ad_name": "BX07-WhatsApp-WorthIt", "campaign": "TEST-EN", "sales": 1, "revenue": 898.00},
    {"ad_id": "120238867812300787", "ad_name": "KOL-Chris-v2", "campaign": "CBO-EN", "sales": 1, "revenue": 433.00},
    {"ad_id": "120242868849920787", "ad_name": "ZiQian-V2 (MIX)", "campaign": "TEST-EN", "sales": 1, "revenue": 433.00},
    {"ad_id": "120242009992650787", "ad_name": "MOFU Byebye CNY Weight", "campaign": "CBO-EN", "sales": 1, "revenue": 127.50},
    {"ad_id": "120240116040420787", "ad_name": "KOL-Chris-v2 (SCALLING)", "campaign": "SCALLING", "sales": 1, "revenue": 238.50},
    {"ad_id": "120242906548010787", "ad_name": "SBB-Chi-Warm-V3 (CN MIX)", "campaign": "TEST-CN", "sales": 1, "revenue": 433.00},
    {"ad_id": "120242545185690787", "ad_name": "MOFU Drop 2kg weight", "campaign": "CBO-EN", "sales": 1, "revenue": 433.00},
]

# Format performance rankings (3-month forensic data)
FORMAT_RANKINGS = [
    {"format": "Transformation", "cpa": 4.8, "rank": 1},
    {"format": "Video (SBB)", "cpa": 5.7, "rank": 2},
    {"format": "Carousel", "cpa": 6.0, "rank": 3},
    {"format": "Message UI (iMessage/WA)", "cpa": 6.1, "rank": 4},
    {"format": "Food Grid", "cpa": 9.4, "rank": 5},
    {"format": "Screenshot UI", "cpa": 12.1, "rank": 6},
]

# Pending creatives
PENDING_CREATIVES = [
    {"name": "diet-v2-01", "asset_type": "image", "angle_type": "transformation", "status": "pending"},
    {"name": "diet-v2-02", "asset_type": "image", "angle_type": "transformation", "status": "pending"},
    {"name": "diet-v2-03", "asset_type": "image", "angle_type": "transformation", "status": "pending"},
    {"name": "diet-v2-04", "asset_type": "image", "angle_type": "transformation", "status": "pending"},
    {"name": "diet-v2-05", "asset_type": "image", "angle_type": "transformation", "status": "pending"},
    {"name": "diet-v2-06", "asset_type": "image", "angle_type": "identity", "status": "pending"},
    {"name": "diet-v2-07", "asset_type": "image", "angle_type": "identity", "status": "pending"},
    {"name": "diet-v2-08", "asset_type": "image", "angle_type": "lifestyle", "status": "pending"},
    {"name": "diet-v2-09", "asset_type": "image", "angle_type": "lifestyle", "status": "pending"},
    {"name": "diet-v2-10", "asset_type": "image", "angle_type": "social_proof", "status": "pending"},
    {"name": "diet-v2-11", "asset_type": "image", "angle_type": "social_proof", "status": "pending"},
    {"name": "SBB-EN-01", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-EN-02", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-EN-03", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-CN-01", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-CN-02", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-CN-03", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-CN-04", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-CN-05", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-CN-06", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-CN-07", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
    {"name": "SBB-CN-08", "asset_type": "video", "angle_type": "sbb", "status": "pending"},
]


async def seed():
    print("=" * 50)
    print("SEEDING MIRRA EATS DATA")
    print("=" * 50)

    async with get_session() as session:
        # 1. Create brand
        brand = Brand(**MIRRA_BRAND)
        session.add(brand)
        await session.flush()
        print(f"\n[OK] Brand created: {brand.name} (ID: {brand.id})")

        # 2. Create campaigns + ad sets + ads
        for c_data in CAMPAIGNS:
            ad_sets_data = c_data.pop("ad_sets")
            campaign = Campaign(brand_id=brand.id, **c_data)
            session.add(campaign)
            await session.flush()
            print(f"[OK] Campaign: {campaign.name}")

            for as_data in ad_sets_data:
                ads_data = as_data.pop("ads")
                adset = AdSet(brand_id=brand.id, campaign_id=campaign.id, **as_data)
                session.add(adset)
                await session.flush()
                print(f"  [OK] Ad Set: {adset.name}")

                for ad_data in ads_data:
                    ad = Ad(brand_id=brand.id, ad_set_id=adset.id, **ad_data)
                    session.add(ad)
                    print(f"    [OK] Ad: {ad.name} (CPA: RM{ad.last_cpa or 'N/A'})")
                await session.flush()

        # 3. Create pending assets
        for asset_data in PENDING_CREATIVES:
            asset = Asset(
                brand_id=brand.id,
                name=asset_data["name"],
                asset_type=AssetType(asset_data["asset_type"]),
                angle_type=asset_data["angle_type"],
                status=AssetStatus.PENDING,
                approval_status=ApprovalStatus.PENDING_REVIEW,
            )
            session.add(asset)
        await session.flush()
        print(f"\n[OK] {len(PENDING_CREATIVES)} pending assets registered")

        # 4. Create initial audit log with current state
        audit = AuditLog(
            brand_id=brand.id,
            audit_type="seed_initial_state",
            severity=AuditSeverity.INFO,
            metrics_snapshot={
                "date": "2026-03-23",
                "total_daily_spend": 694.96,
                "total_7d_spend": 1808.73,
                "total_7d_convos": 963,
                "avg_cpa_7d": 1.88,
                "sales_attribution": {
                    "total_attributed_sales_march": 13,
                    "total_attributed_revenue_march": 5621.50,
                    "attribution_rate": 0.084,
                    "top_selling_ad": "SBB-Chi-Warm-V3 (3 sales, RM1465.50)",
                },
                "daily_revenue_trend": {
                    "mar_8": 9171, "mar_12": 5892, "mar_16": 6100,
                    "mar_20": 4933, "mar_22": 534, "mar_23": 926,
                },
                "format_rankings": FORMAT_RANKINGS,
                "budget_cap": 1200,
                "actual_daily_spend": 258,
            },
            flags_raised=[
                {"severity": "RED", "message": "Daily revenue dropped 90% (RM9,171 → RM926) over 15 days"},
                {"severity": "RED", "message": "SUPER WIN spending RM190/day with RM2.73/convo but NO sales attribution"},
                {"severity": "ORANGE", "message": "Only 8.4% of orders have ad ID attribution — blind optimization"},
                {"severity": "YELLOW", "message": "31 new creatives pending deployment — no Entity ID diversity refresh"},
            ],
            root_cause_analysis=(
                "Sales decline driven by: (1) TEST campaigns paused on Mar 21 reducing reach, "
                "(2) SUPER WIN consuming budget on non-converting ads, "
                "(3) Best performers (S19, BX07, BX08) were paused until recently, "
                "(4) No new creative deployment since Mar 21 — audience fatigue risk. "
                "SALES-EN is actually performing excellently at RM1.49/convo but needs more "
                "budget and creative diversity to scale. Revenue crash may also reflect "
                "seasonal/market factors beyond ad performance."
            ),
        )
        session.add(audit)
        await session.flush()
        print(f"[OK] Initial audit log created")

    print(f"\n{'=' * 50}")
    print("SEED COMPLETE")
    print(f"{'=' * 50}")
    print(f"\nBrand ID: {brand.id}")
    print(f"Use this ID for all API calls: /api/v1/brands/{brand.id}")
    print(f"\nNext: python scripts/test_connections.py")


if __name__ == "__main__":
    asyncio.run(seed())
