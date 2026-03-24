"""Reports endpoints — weekly performance summaries."""

import uuid
from datetime import datetime, timezone, timedelta

from fastapi import APIRouter, Depends, HTTPException
from loguru import logger
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_db
from app.db.models.brand import Brand
from app.db.models.supporting import AuditLog
from app.schemas import WeeklyReportResponse
from app.services.meta_api.client import MetaAPIClient

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("/{brand_id}/weekly", response_model=WeeklyReportResponse)
async def get_weekly_report(
    brand_id: uuid.UUID, db: AsyncSession = Depends(get_db)
):
    """Generate weekly performance report from Meta + audit data."""
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand or not brand.meta_ad_account_id:
        raise HTTPException(404, "Brand not found or no Meta account linked")

    client = MetaAPIClient(access_token=brand.meta_access_token)

    try:
        insights = await client.get_campaign_insights(
            f"act_{brand.meta_ad_account_id}",
            level="ad",
            date_preset="last_7d",
        )
    finally:
        await client.close()

    total_spend = 0.0
    total_conversions = 0
    ad_performance: list[dict] = []

    for row in insights:
        spend = float(row.get("spend", 0))
        total_spend += spend
        convos = 0
        for action in row.get("actions", []):
            if "conversation" in action.get("action_type", ""):
                convos += int(action.get("value", 0))
        total_conversions += convos
        cpa = spend / convos if convos > 0 else None
        ad_performance.append({
            "ad_name": row.get("ad_name", ""),
            "ad_id": row.get("ad_id", ""),
            "spend": spend,
            "conversions": convos,
            "cpa": round(cpa, 2) if cpa else None,
            "ctr": float(row.get("ctr", 0)),
        })

    ad_performance.sort(key=lambda x: x.get("cpa") or 9999)
    top_performers = ad_performance[:10]

    # Get audit flags summary
    audit_result = await db.execute(
        select(AuditLog)
        .where(AuditLog.brand_id == brand_id)
        .order_by(AuditLog.created_at.desc())
        .limit(7)
    )
    audits = audit_result.scalars().all()
    flags_summary = {"red": 0, "orange": 0, "yellow": 0}
    for audit in audits:
        for flag in audit.flags_raised or []:
            severity = flag.get("severity", "").lower()
            if severity in flags_summary:
                flags_summary[severity] += 1

    recommendations: list[str] = []
    avg_cpa = total_spend / total_conversions if total_conversions else None
    if avg_cpa and brand.cpa_ceiling and avg_cpa > brand.cpa_ceiling:
        recommendations.append(
            f"Average CPA (RM{avg_cpa:.2f}) exceeds ceiling (RM{brand.cpa_ceiling:.2f}). Review underperformers."
        )
    if flags_summary["red"] > 0:
        recommendations.append(
            f"{flags_summary['red']} critical flags in the past week. Check audit history."
        )

    now = datetime.now(timezone.utc)
    period = f"{(now - timedelta(days=7)).strftime('%Y-%m-%d')} to {now.strftime('%Y-%m-%d')}"

    return WeeklyReportResponse(
        brand_id=brand_id,
        period=period,
        total_spend=round(total_spend, 2),
        total_conversions=total_conversions,
        avg_cpa=round(avg_cpa, 2) if avg_cpa else None,
        avg_roas=None,
        top_performers=top_performers,
        flags_summary=flags_summary,
        recommendations=recommendations,
    )
