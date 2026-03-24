"""Audit endpoints — trigger, history, approve actions."""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from loguru import logger
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_db
from app.db.models.brand import Brand
from app.db.models.supporting import AuditLog, AuditSeverity
from app.schemas import AuditResponse, AuditTriggerRequest
from app.services.audit.forensic_engine import ForensicAuditEngine
from app.services.deployment.orchestrator import DeploymentOrchestrator

router = APIRouter(prefix="/audit", tags=["audit"])


@router.post("/{brand_id}/trigger", response_model=AuditResponse)
async def trigger_audit(
    brand_id: uuid.UUID,
    data: AuditTriggerRequest | None = None,
    db: AsyncSession = Depends(get_db),
):
    """Manually trigger a forensic audit for a brand."""
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand or not brand.meta_ad_account_id:
        raise HTTPException(404, "Brand not found or no Meta account linked")

    engine = ForensicAuditEngine(
        brand_slug=brand.slug,
        ad_account_id=brand.meta_ad_account_id,
        access_token=brand.meta_access_token,
    )

    roas = data.roas_target if data else None
    cpa = data.cpa_ceiling if data else None
    report = await engine.run(roas_target=roas or brand.roas_target, cpa_ceiling=cpa or brand.cpa_ceiling)

    flags = report.get("flags", [])
    max_severity = AuditSeverity.INFO
    if any(f["severity"] == "RED" for f in flags):
        max_severity = AuditSeverity.CRITICAL
    elif any(f["severity"] == "ORANGE" for f in flags):
        max_severity = AuditSeverity.HIGH

    audit_log = AuditLog(
        brand_id=brand_id,
        audit_type="manual_trigger",
        severity=max_severity,
        metrics_snapshot=report.get("metrics_snapshot"),
        flags_raised=flags,
        root_cause_analysis=report.get("root_cause_analysis"),
        proposed_actions=report.get("proposed_actions"),
        rag_context_used=report.get("rag_context_used"),
        llm_tokens_used=report.get("llm_tokens_used"),
    )
    db.add(audit_log)
    await db.flush()

    logger.info(
        "Manual audit for {brand}: {sev}, {n} flags",
        brand=brand.slug,
        sev=max_severity.value,
        n=len(flags),
    )
    return audit_log


@router.get("/{brand_id}/history", response_model=list[AuditResponse])
async def get_audit_history(
    brand_id: uuid.UUID,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(AuditLog)
        .where(AuditLog.brand_id == brand_id)
        .order_by(AuditLog.created_at.desc())
        .limit(limit)
    )
    return result.scalars().all()


@router.get("/{brand_id}/latest", response_model=AuditResponse)
async def get_latest_audit(
    brand_id: uuid.UUID, db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(AuditLog)
        .where(AuditLog.brand_id == brand_id)
        .order_by(AuditLog.created_at.desc())
        .limit(1)
    )
    audit = result.scalar_one_or_none()
    if not audit:
        raise HTTPException(404, "No audits found for this brand")
    return audit


@router.post("/{brand_id}/actions/{audit_id}/approve")
async def approve_audit_actions(
    brand_id: uuid.UUID,
    audit_id: uuid.UUID,
    action_indices: list[int] | None = None,
    db: AsyncSession = Depends(get_db),
):
    """Approve audit proposed actions and create deployment jobs."""
    result = await db.execute(
        select(AuditLog).where(
            AuditLog.id == audit_id, AuditLog.brand_id == brand_id
        )
    )
    audit = result.scalar_one_or_none()
    if not audit:
        raise HTTPException(404, "Audit not found")

    actions = audit.proposed_actions or []
    if action_indices:
        actions = [actions[i] for i in action_indices if i < len(actions)]

    orchestrator = DeploymentOrchestrator(db)
    jobs = await orchestrator.ingest_audit_actions(brand_id, audit_id, actions)
    await orchestrator.close()

    audit.actions_taken = [
        {"job_id": str(j.id), "type": j.job_type.value, "status": j.status.value}
        for j in jobs
    ]
    await db.flush()

    return {
        "jobs_created": len(jobs),
        "auto_approved": len([j for j in jobs if j.status.value == "approved"]),
        "pending_approval": len([j for j in jobs if j.status.value == "pending_approval"]),
    }
