"""Deployment endpoints — assets, campaign launch, jobs, rollback."""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from loguru import logger
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_db
from app.db.models.asset import ApprovalStatus, Asset, AssetStatus, AssetType
from app.db.models.brand import Brand
from app.db.models.deployment import DeploymentJob, JobStatus
from app.db.models.supporting import AuditLog
from app.schemas import (
    AssetRegisterRequest,
    AssetResponse,
    CampaignLaunchRequest,
    DeploymentJobResponse,
    JobDecisionRequest,
)
from app.services.deployment.asset_pipeline import AssetPipeline
from app.services.deployment.campaign_builder import (
    AdSetSpec,
    AdSpec,
    CampaignBuilder,
    CampaignSpec,
)
from app.services.deployment.orchestrator import DeploymentOrchestrator

router = APIRouter(prefix="/deployment", tags=["deployment"])


# --- Assets ---

@router.get("/{brand_id}/assets", response_model=list[AssetResponse])
async def list_assets(
    brand_id: uuid.UUID,
    status: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    query = select(Asset).where(
        Asset.brand_id == brand_id, Asset.deleted_at.is_(None)
    )
    if status:
        query = query.where(Asset.status == AssetStatus(status))
    query = query.order_by(Asset.created_at.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.post("/{brand_id}/assets/register", response_model=AssetResponse, status_code=201)
async def register_asset(
    brand_id: uuid.UUID,
    data: AssetRegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    """Register a creative asset (S3 or already-uploaded to Meta)."""
    asset = Asset(
        brand_id=brand_id,
        name=data.name,
        asset_type=AssetType(data.asset_type),
        s3_bucket=data.s3_bucket,
        s3_key=data.s3_key,
        meta_video_id=data.meta_video_id,
        meta_image_hash=data.meta_image_hash,
        angle_type=data.angle_type,
        hook_text=data.hook_text,
        width_px=data.width_px,
        height_px=data.height_px,
        status=AssetStatus.READY if (data.meta_video_id or data.meta_image_hash) else AssetStatus.PENDING,
    )
    db.add(asset)
    await db.flush()
    return asset


@router.post("/{brand_id}/assets/{asset_id}/upload")
async def upload_asset_to_meta(
    brand_id: uuid.UUID,
    asset_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Trigger S3 → Meta upload for a registered asset."""
    from app.core.celery_app import upload_asset_to_meta as upload_task

    result = await db.execute(select(Asset).where(Asset.id == asset_id))
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(404, "Asset not found")
    if not asset.s3_bucket or not asset.s3_key:
        raise HTTPException(400, "Asset has no S3 location")

    task = upload_task.delay(str(asset_id), str(brand_id))
    return {"task_id": task.id, "status": "upload_queued"}


@router.patch("/{brand_id}/assets/{asset_id}/approve", response_model=AssetResponse)
async def approve_asset(
    brand_id: uuid.UUID,
    asset_id: uuid.UUID,
    approved: bool = True,
    db: AsyncSession = Depends(get_db),
):
    """Human approval gate for creative assets."""
    result = await db.execute(select(Asset).where(Asset.id == asset_id))
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(404, "Asset not found")

    asset.approval_status = ApprovalStatus.APPROVED if approved else ApprovalStatus.REJECTED
    await db.flush()
    return asset


@router.get("/{brand_id}/assets/s3/browse")
async def browse_s3(
    brand_id: uuid.UUID,
    prefix: str = "",
    db: AsyncSession = Depends(get_db),
):
    """Browse S3 bucket for available assets."""
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(404, "Brand not found")

    pipeline = AssetPipeline(access_token=brand.meta_access_token)
    try:
        items = await pipeline.list_s3_assets(
            bucket=brand.slug or "apex-meta-creatives",
            prefix=prefix,
        )
        return {"items": items}
    finally:
        await pipeline.close()


# --- Campaign Launch ---

@router.post("/{brand_id}/campaigns/launch")
async def launch_campaign(
    brand_id: uuid.UUID,
    data: CampaignLaunchRequest,
    db: AsyncSession = Depends(get_db),
):
    """Build and launch a full campaign from spec."""
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand or not brand.meta_ad_account_id:
        raise HTTPException(404, "Brand not found or no Meta account")

    ad_sets = []
    for as_data in data.ad_sets:
        ads = []
        for ad_data in as_data.get("ads", []):
            ads.append(AdSpec(**ad_data))
        ad_sets.append(AdSetSpec(
            name=as_data["name"],
            daily_budget=as_data.get("daily_budget", 50),
            optimization_goal=as_data.get("optimization_goal", "CONVERSATIONS"),
            targeting=as_data.get("targeting"),
            promoted_object=as_data.get("promoted_object"),
            ads=ads,
        ))

    spec = CampaignSpec(
        name=data.name,
        objective=data.objective,
        daily_budget=data.daily_budget,
        cbo_enabled=data.cbo_enabled,
        ad_account_id=brand.meta_ad_account_id,
        page_id=data.page_id,
        brand_slug=brand.slug,
        auto_activate=data.auto_activate,
        ad_sets=ad_sets,
    )

    builder = CampaignBuilder(access_token=brand.meta_access_token)
    build_result = await builder.build(spec)

    return build_result


# --- Audit → Deployment ---

@router.post("/{brand_id}/execute-audit/{audit_id}")
async def execute_audit_actions(
    brand_id: uuid.UUID,
    audit_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Create deployment jobs from an audit's proposed actions."""
    result = await db.execute(
        select(AuditLog).where(
            AuditLog.id == audit_id, AuditLog.brand_id == brand_id
        )
    )
    audit = result.scalar_one_or_none()
    if not audit:
        raise HTTPException(404, "Audit not found")

    orchestrator = DeploymentOrchestrator(db)
    jobs = await orchestrator.ingest_audit_actions(
        brand_id, audit_id, audit.proposed_actions or []
    )
    await orchestrator.close()

    return {
        "jobs_created": len(jobs),
        "jobs": [
            {"id": str(j.id), "type": j.job_type.value, "status": j.status.value}
            for j in jobs
        ],
    }


# --- Jobs ---

@router.get("/{brand_id}/jobs", response_model=list[DeploymentJobResponse])
async def list_jobs(
    brand_id: uuid.UUID,
    status: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    query = select(DeploymentJob).where(DeploymentJob.brand_id == brand_id)
    if status:
        query = query.where(DeploymentJob.status == JobStatus(status))
    query = query.order_by(DeploymentJob.priority, DeploymentJob.created_at.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.post("/{brand_id}/jobs/{job_id}/decision")
async def job_decision(
    brand_id: uuid.UUID,
    job_id: uuid.UUID,
    data: JobDecisionRequest,
    db: AsyncSession = Depends(get_db),
):
    """Approve or reject a pending deployment job."""
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(404, "Brand not found")

    orchestrator = DeploymentOrchestrator(db, access_token=brand.meta_access_token)

    try:
        if data.decision == "approve":
            job = await orchestrator.approve_job(job_id)
            exec_result = await orchestrator._execute_job(job)
            return {"status": "executed", "result": exec_result}
        elif data.decision == "reject":
            job = await orchestrator.reject_job(job_id, data.reason or "")
            return {"status": "rejected", "job_id": str(job.id)}
        else:
            raise HTTPException(400, "Decision must be 'approve' or 'reject'")
    except ValueError as e:
        raise HTTPException(404, str(e))
    finally:
        await orchestrator.close()


@router.post("/{brand_id}/jobs/{job_id}/rollback")
async def rollback_job(
    brand_id: uuid.UUID,
    job_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
):
    """Rollback a completed deployment job."""
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(404, "Brand not found")

    orchestrator = DeploymentOrchestrator(db, access_token=brand.meta_access_token)
    try:
        rollback = await orchestrator.rollback_job(job_id)
        return {"status": "rolled_back", "rollback_job_id": str(rollback.id)}
    except Exception as e:
        raise HTTPException(400, str(e))
    finally:
        await orchestrator.close()
