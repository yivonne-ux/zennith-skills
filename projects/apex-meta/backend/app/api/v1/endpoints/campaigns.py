"""Campaign sync and listing endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from loguru import logger
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_db
from app.db.models.brand import Brand
from app.db.models.campaign import (
    Ad,
    AdSet,
    Campaign,
    CampaignObjective,
    EntityStatus,
    LearningPhase,
)
from app.schemas import CampaignResponse
from app.services.meta_api.client import MetaAPIClient

router = APIRouter(prefix="/campaigns", tags=["campaigns"])


@router.get("/{brand_id}", response_model=list[CampaignResponse])
async def list_campaigns(
    brand_id: uuid.UUID, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Campaign)
        .where(Campaign.brand_id == brand_id, Campaign.deleted_at.is_(None))
        .order_by(Campaign.name)
    )
    return result.scalars().all()


@router.post("/{brand_id}/sync")
async def sync_campaigns_from_meta(
    brand_id: uuid.UUID, db: AsyncSession = Depends(get_db)
):
    """Pull campaign structure from Meta and sync to local DB."""
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand or not brand.meta_ad_account_id:
        raise HTTPException(404, "Brand not found or no Meta account linked")

    client = MetaAPIClient(access_token=brand.meta_access_token)

    try:
        meta_campaigns = await client.get_campaigns(brand.meta_ad_account_id)
        synced = {"campaigns": 0, "ad_sets": 0, "ads": 0}

        for mc in meta_campaigns:
            campaign = await _upsert_campaign(db, brand.id, mc)
            synced["campaigns"] += 1

            meta_adsets = await client.get_ad_sets(
                brand.meta_ad_account_id, campaign_id=mc["id"]
            )
            for mas in meta_adsets:
                adset = await _upsert_adset(db, brand.id, campaign.id, mas)
                synced["ad_sets"] += 1

                meta_ads = await client.get_ads(
                    brand.meta_ad_account_id, adset_id=mas["id"]
                )
                for mad in meta_ads:
                    await _upsert_ad(db, brand.id, adset.id, mad)
                    synced["ads"] += 1

        await db.flush()
        logger.info(
            "Synced {c} campaigns, {s} ad sets, {a} ads for {brand}",
            c=synced["campaigns"],
            s=synced["ad_sets"],
            a=synced["ads"],
            brand=brand.slug,
        )
        return synced

    finally:
        await client.close()


async def _upsert_campaign(
    db: AsyncSession, brand_id: uuid.UUID, meta: dict
) -> Campaign:
    result = await db.execute(
        select(Campaign).where(Campaign.meta_campaign_id == meta["id"])
    )
    campaign = result.scalar_one_or_none()

    objective = None
    raw_obj = meta.get("objective", "")
    try:
        objective = CampaignObjective(raw_obj)
    except ValueError:
        pass

    if campaign:
        campaign.name = meta.get("name", campaign.name)
        campaign.status = _parse_status(meta.get("effective_status", "PAUSED"))
        campaign.objective = objective
        campaign.daily_budget = _cents_to_rm(meta.get("daily_budget"))
    else:
        campaign = Campaign(
            brand_id=brand_id,
            meta_campaign_id=meta["id"],
            name=meta.get("name", ""),
            objective=objective,
            status=_parse_status(meta.get("effective_status", "PAUSED")),
            daily_budget=_cents_to_rm(meta.get("daily_budget")),
        )
        db.add(campaign)

    await db.flush()
    return campaign


async def _upsert_adset(
    db: AsyncSession, brand_id: uuid.UUID, campaign_id: uuid.UUID, meta: dict
) -> AdSet:
    result = await db.execute(
        select(AdSet).where(AdSet.meta_adset_id == meta["id"])
    )
    adset = result.scalar_one_or_none()

    learning = None
    learning_info = meta.get("learning_phase_info", {})
    if learning_info:
        raw_lp = learning_info.get("status", "")
        try:
            learning = LearningPhase(raw_lp)
        except ValueError:
            pass

    if adset:
        adset.name = meta.get("name", adset.name)
        adset.status = _parse_status(meta.get("status", "PAUSED"))
        adset.daily_budget = _cents_to_rm(meta.get("daily_budget"))
        adset.learning_phase = learning
        adset.targeting_config = meta.get("targeting")
    else:
        adset = AdSet(
            brand_id=brand_id,
            campaign_id=campaign_id,
            meta_adset_id=meta["id"],
            name=meta.get("name", ""),
            status=_parse_status(meta.get("status", "PAUSED")),
            daily_budget=_cents_to_rm(meta.get("daily_budget")),
            learning_phase=learning,
            targeting_config=meta.get("targeting"),
        )
        db.add(adset)

    await db.flush()
    return adset


async def _upsert_ad(
    db: AsyncSession, brand_id: uuid.UUID, adset_id: uuid.UUID, meta: dict
) -> Ad:
    result = await db.execute(
        select(Ad).where(Ad.meta_ad_id == meta["id"])
    )
    ad = result.scalar_one_or_none()

    creative = meta.get("creative", {})

    if ad:
        ad.name = meta.get("name", ad.name)
        ad.status = _parse_status(meta.get("effective_status", "PAUSED"))
        ad.creative_id = creative.get("id")
    else:
        ad = Ad(
            brand_id=brand_id,
            ad_set_id=adset_id,
            meta_ad_id=meta["id"],
            name=meta.get("name", ""),
            status=_parse_status(meta.get("effective_status", "PAUSED")),
            creative_id=creative.get("id"),
        )
        db.add(ad)

    await db.flush()
    return ad


def _parse_status(raw: str) -> EntityStatus:
    try:
        return EntityStatus(raw)
    except ValueError:
        return EntityStatus.PAUSED


def _cents_to_rm(cents_str: str | None) -> float | None:
    if cents_str is None:
        return None
    try:
        return int(cents_str) / 100
    except (ValueError, TypeError):
        return None
