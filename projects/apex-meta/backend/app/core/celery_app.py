"""Celery configuration with beat schedules for automated tasks."""

import asyncio
from celery import Celery
from celery.schedules import crontab

from app.core.config import settings

celery_app = Celery(
    "apex_meta",
    broker=settings.celery_broker_url,
    backend=settings.celery_result_backend,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_routes={
        "app.core.celery_app.run_midnight_scholar": {"queue": "research"},
        "app.core.celery_app.run_forensic_audit_all_brands": {"queue": "audit"},
        "app.core.celery_app.run_forensic_audit_brand": {"queue": "audit"},
        "app.core.celery_app.execute_approved_deployment_jobs": {"queue": "deployment"},
        "app.core.celery_app.upload_asset_to_meta": {"queue": "deployment"},
    },
    beat_schedule={
        "midnight-scholar-daily": {
            "task": "app.core.celery_app.run_midnight_scholar",
            "schedule": crontab(hour=0, minute=0),
        },
        "forensic-audit-all-brands": {
            "task": "app.core.celery_app.run_forensic_audit_all_brands",
            "schedule": crontab(minute=0, hour="*/6"),
        },
        "auto-execute-approved-jobs": {
            "task": "app.core.celery_app.execute_approved_deployment_jobs",
            "schedule": crontab(minute="*/15"),
        },
    },
)


def run_async(coro):
    """Helper to run async code in sync Celery task."""
    loop = asyncio.new_event_loop()
    try:
        return loop.run_until_complete(coro)
    finally:
        loop.close()


@celery_app.task(name="app.core.celery_app.run_midnight_scholar")
def run_midnight_scholar():
    """Nightly research pipeline."""
    from app.services.research.midnight_scholar import MidnightScholarPipeline

    pipeline = MidnightScholarPipeline()
    return run_async(pipeline.run())


@celery_app.task(name="app.core.celery_app.run_forensic_audit_all_brands")
def run_forensic_audit_all_brands():
    """Dispatch forensic audit for every active brand."""
    from app.db.base import get_session
    from app.db.models.brand import Brand
    from sqlalchemy import select

    async def _dispatch():
        async with get_session() as session:
            result = await session.execute(
                select(Brand).where(
                    Brand.meta_ad_account_id.isnot(None),
                    Brand.deleted_at.is_(None),
                )
            )
            brands = result.scalars().all()
            for brand in brands:
                run_forensic_audit_brand.delay(
                    str(brand.id),
                    brand.slug,
                    brand.meta_ad_account_id,
                    brand.meta_access_token,
                )
            return {"dispatched": len(brands)}

    return run_async(_dispatch())


@celery_app.task(name="app.core.celery_app.run_forensic_audit_brand")
def run_forensic_audit_brand(
    brand_id: str, brand_slug: str, ad_account_id: str, access_token: str | None = None
):
    """Run forensic audit for a single brand."""
    import uuid
    from app.db.base import get_session
    from app.db.models.supporting import AuditLog, AuditSeverity
    from app.services.audit.forensic_engine import ForensicAuditEngine

    async def _audit():
        engine = ForensicAuditEngine(brand_slug, ad_account_id, access_token)
        report = await engine.run()

        async with get_session() as session:
            max_severity = AuditSeverity.INFO
            flags = report.get("flags", [])
            if any(f["severity"] == "RED" for f in flags):
                max_severity = AuditSeverity.CRITICAL
            elif any(f["severity"] == "ORANGE" for f in flags):
                max_severity = AuditSeverity.HIGH

            audit_log = AuditLog(
                brand_id=uuid.UUID(brand_id),
                audit_type="forensic_6h",
                severity=max_severity,
                metrics_snapshot=report.get("metrics_snapshot"),
                flags_raised=flags,
                root_cause_analysis=report.get("root_cause_analysis"),
                proposed_actions=report.get("proposed_actions"),
                rag_context_used=report.get("rag_context_used"),
                llm_tokens_used=report.get("llm_tokens_used"),
            )
            session.add(audit_log)

        return report

    return run_async(_audit())


@celery_app.task(name="app.core.celery_app.execute_approved_deployment_jobs")
def execute_approved_deployment_jobs():
    """Sweep and execute all approved deployment jobs."""
    from app.db.base import get_session
    from app.services.deployment.orchestrator import DeploymentOrchestrator

    async def _execute():
        async with get_session() as session:
            orchestrator = DeploymentOrchestrator(session)
            results = await orchestrator.execute_approved_jobs()
            await orchestrator.close()
            return {"executed": len(results), "results": results}

    return run_async(_execute())


@celery_app.task(name="app.core.celery_app.upload_asset_to_meta")
def upload_asset_to_meta(asset_id: str, brand_id: str):
    """Upload a single asset from S3 to Meta."""
    import uuid
    from app.db.base import get_session
    from app.db.models.asset import Asset, AssetStatus
    from app.services.deployment.asset_pipeline import AssetPipeline
    from sqlalchemy import select

    async def _upload():
        async with get_session() as session:
            result = await session.execute(
                select(Asset).where(Asset.id == uuid.UUID(asset_id))
            )
            asset = result.scalar_one_or_none()
            if not asset:
                return {"error": f"Asset {asset_id} not found"}

            from app.db.models.brand import Brand
            brand_result = await session.execute(
                select(Brand).where(Brand.id == uuid.UUID(brand_id))
            )
            brand = brand_result.scalar_one_or_none()
            if not brand:
                return {"error": f"Brand {brand_id} not found"}

            asset.status = AssetStatus.UPLOADING

            pipeline = AssetPipeline(access_token=brand.meta_access_token)
            try:
                upload_result = await pipeline.upload_from_s3(
                    ad_account_id=brand.meta_ad_account_id,
                    bucket=asset.s3_bucket,
                    key=asset.s3_key,
                    asset_type=asset.asset_type.value,
                    name=asset.name,
                )
                if "video_id" in upload_result:
                    asset.meta_video_id = upload_result["video_id"]
                elif "image_hash" in upload_result:
                    asset.meta_image_hash = upload_result["image_hash"]
                asset.status = AssetStatus.READY
                return upload_result
            except Exception as e:
                asset.status = AssetStatus.FAILED
                return {"error": str(e)}
            finally:
                await pipeline.close()

    return run_async(_upload())
