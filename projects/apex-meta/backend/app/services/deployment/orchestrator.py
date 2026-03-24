"""Deployment Orchestrator — closed-loop audit → execution with safety gates."""

import uuid
from typing import Any

from loguru import logger
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.exceptions import DeploymentSafetyError
from app.db.models.deployment import DeploymentJob, JobStatus, JobType
from app.services.meta_api.publisher import MetaAPIPublisher
from app.services.memory.vector_store import VectorStore, brand_namespace


class DeploymentOrchestrator:
    """Ingest audit actions → apply safety gates → execute deployments."""

    def __init__(self, db: AsyncSession, access_token: str | None = None):
        self.db = db
        self.publisher = MetaAPIPublisher(access_token=access_token)
        self.vector_store = VectorStore()

    async def close(self) -> None:
        await self.publisher.close()

    async def ingest_audit_actions(
        self, brand_id: uuid.UUID, audit_log_id: uuid.UUID, proposed_actions: list[dict]
    ) -> list[DeploymentJob]:
        """Create DeploymentJobs from audit proposed_actions with safety gates."""
        jobs: list[DeploymentJob] = []

        for action in proposed_actions:
            job_type = self._parse_job_type(action.get("action_type", ""))
            if not job_type:
                logger.warning(
                    "Unknown action type: {t}", t=action.get("action_type")
                )
                continue

            status = self._apply_safety_gate(job_type, action)

            job = DeploymentJob(
                brand_id=brand_id,
                audit_log_id=audit_log_id,
                job_type=job_type,
                status=status,
                priority=action.get("priority", 3),
                entity_type=action.get("entity_type", "ad"),
                meta_entity_id=action.get("entity_id"),
                request_payload=action,
                ai_rationale=action.get("rationale"),
                ai_confidence=action.get("confidence"),
                is_reversible=job_type in (
                    JobType.KILL_AD,
                    JobType.PAUSE_ADSET,
                    JobType.PAUSE_CAMPAIGN,
                    JobType.SCALE_BUDGET,
                ),
            )
            self.db.add(job)
            jobs.append(job)

        await self.db.flush()
        logger.info(
            "Ingested {n} deployment jobs ({approved} auto-approved)",
            n=len(jobs),
            approved=len([j for j in jobs if j.status == JobStatus.APPROVED]),
        )
        return jobs

    def _parse_job_type(self, action_type: str) -> JobType | None:
        mapping = {
            "kill_ad": JobType.KILL_AD,
            "pause_adset": JobType.PAUSE_ADSET,
            "pause_campaign": JobType.PAUSE_CAMPAIGN,
            "scale_budget": JobType.SCALE_BUDGET,
            "launch_campaign": JobType.LAUNCH_CAMPAIGN,
            "launch_adset": JobType.LAUNCH_ADSET,
            "launch_ad": JobType.LAUNCH_AD,
            "upload_asset": JobType.UPLOAD_ASSET,
            "duplicate_campaign": JobType.DUPLICATE_CAMPAIGN,
        }
        return mapping.get(action_type)

    def _apply_safety_gate(self, job_type: JobType, action: dict) -> JobStatus:
        """Determine if job needs human approval or can auto-execute."""
        confidence = action.get("confidence", 0)

        if confidence < 0.70:
            logger.info(
                "Safety gate: low confidence ({c:.2f}) requires approval",
                c=confidence,
            )
            return JobStatus.PENDING_APPROVAL

        if job_type == JobType.KILL_AD and settings.deployment_kill_requires_approval:
            return JobStatus.PENDING_APPROVAL

        if job_type in (
            JobType.LAUNCH_CAMPAIGN, JobType.LAUNCH_ADSET, JobType.LAUNCH_AD
        ) and settings.deployment_new_campaign_requires_approval:
            return JobStatus.PENDING_APPROVAL

        if job_type == JobType.SCALE_BUDGET:
            pct = action.get("request_payload", {}).get("budget_increase_pct", 100)
            if pct > settings.deployment_max_daily_spend_increase_pct:
                return JobStatus.PENDING_APPROVAL
            if settings.deployment_scale_requires_approval:
                return JobStatus.PENDING_APPROVAL
            return JobStatus.APPROVED

        if settings.deployment_auto_execute:
            return JobStatus.APPROVED

        return JobStatus.PENDING_APPROVAL

    async def execute_approved_jobs(self, brand_id: uuid.UUID | None = None) -> list[dict]:
        """Execute all approved deployment jobs."""
        query = select(DeploymentJob).where(
            DeploymentJob.status == JobStatus.APPROVED
        )
        if brand_id:
            query = query.where(DeploymentJob.brand_id == brand_id)
        query = query.order_by(DeploymentJob.priority)

        result = await self.db.execute(query)
        jobs = result.scalars().all()

        execution_results: list[dict] = []
        for job in jobs:
            exec_result = await self._execute_job(job)
            execution_results.append(exec_result)

        return execution_results

    async def _execute_job(self, job: DeploymentJob) -> dict:
        """Execute a single deployment job."""
        job.status = JobStatus.RUNNING
        await self.db.flush()

        try:
            result = await self._dispatch_handler(job)
            job.status = JobStatus.COMPLETED
            job.response_payload = result
            logger.info(
                "Job {jid} completed: {jtype} on {eid}",
                jid=job.id,
                jtype=job.job_type.value,
                eid=job.meta_entity_id,
            )
            return {"job_id": str(job.id), "status": "completed", "result": result}

        except Exception as e:
            job.status = JobStatus.FAILED
            job.response_payload = {"error": str(e)}
            logger.error(
                "Job {jid} failed: {e}", jid=job.id, e=e
            )
            return {"job_id": str(job.id), "status": "failed", "error": str(e)}
        finally:
            await self.db.flush()

    async def _dispatch_handler(self, job: DeploymentJob) -> dict:
        """Route job to appropriate handler."""
        entity_id = job.meta_entity_id
        if not entity_id:
            raise ValueError("Job has no meta_entity_id")

        handlers = {
            JobType.KILL_AD: lambda: self.publisher.set_ad_status(entity_id, "PAUSED"),
            JobType.PAUSE_ADSET: lambda: self.publisher.set_adset_status(entity_id, "PAUSED"),
            JobType.PAUSE_CAMPAIGN: lambda: self.publisher.set_campaign_status(entity_id, "PAUSED"),
            JobType.LAUNCH_AD: lambda: self.publisher.set_ad_status(entity_id, "ACTIVE"),
            JobType.LAUNCH_ADSET: lambda: self.publisher.set_adset_status(entity_id, "ACTIVE"),
            JobType.LAUNCH_CAMPAIGN: lambda: self.publisher.set_campaign_status(entity_id, "ACTIVE"),
            JobType.SCALE_BUDGET: lambda: self._handle_scale(job),
            JobType.DUPLICATE_CAMPAIGN: lambda: self._handle_duplicate(job),
        }

        handler = handlers.get(job.job_type)
        if not handler:
            raise ValueError(f"No handler for job type: {job.job_type}")

        return await handler()

    async def _handle_scale(self, job: DeploymentJob) -> dict:
        """Scale budget with cap enforcement."""
        payload = job.request_payload or {}
        new_budget = payload.get("new_budget")
        if not new_budget:
            raise ValueError("Scale job missing new_budget in payload")

        max_increase = settings.deployment_max_daily_spend_increase_pct
        current_budget = payload.get("current_budget", 0)
        if current_budget > 0:
            pct_increase = ((new_budget - current_budget) / current_budget) * 100
            if pct_increase > max_increase:
                capped = int(current_budget * (1 + max_increase / 100))
                logger.warning(
                    "Budget capped: {new} → {capped} (max {pct}% increase)",
                    new=new_budget,
                    capped=capped,
                    pct=max_increase,
                )
                new_budget = capped

        entity_type = job.entity_type or "adset"
        if entity_type == "campaign":
            return await self.publisher.update_campaign_budget(
                job.meta_entity_id, new_budget
            )
        return await self.publisher.update_adset_budget(
            job.meta_entity_id, new_budget
        )

    async def _handle_duplicate(self, job: DeploymentJob) -> dict:
        """Duplicate a campaign for scaling."""
        payload = job.request_payload or {}
        return await self.publisher.duplicate_campaign_for_scaling(
            campaign_id=job.meta_entity_id,
            new_name=payload.get("new_name", f"SCALE-{job.meta_entity_id}"),
            daily_budget=payload.get("daily_budget", 100),
        )

    async def approve_job(self, job_id: uuid.UUID) -> DeploymentJob:
        """Human approves a pending job."""
        result = await self.db.execute(
            select(DeploymentJob).where(DeploymentJob.id == job_id)
        )
        job = result.scalar_one_or_none()
        if not job:
            raise ValueError(f"Job {job_id} not found")
        if job.status != JobStatus.PENDING_APPROVAL:
            raise ValueError(f"Job {job_id} is {job.status.value}, not pending")
        job.status = JobStatus.APPROVED
        await self.db.flush()
        logger.info("Job {jid} approved", jid=job_id)
        return job

    async def reject_job(self, job_id: uuid.UUID, reason: str = "") -> DeploymentJob:
        """Human rejects a pending job."""
        result = await self.db.execute(
            select(DeploymentJob).where(DeploymentJob.id == job_id)
        )
        job = result.scalar_one_or_none()
        if not job:
            raise ValueError(f"Job {job_id} not found")
        job.status = JobStatus.REJECTED
        job.response_payload = {"rejection_reason": reason}
        await self.db.flush()
        logger.info("Job {jid} rejected: {r}", jid=job_id, r=reason)
        return job

    async def rollback_job(self, job_id: uuid.UUID) -> DeploymentJob | None:
        """Rollback a completed job if reversible."""
        result = await self.db.execute(
            select(DeploymentJob).where(DeploymentJob.id == job_id)
        )
        job = result.scalar_one_or_none()
        if not job:
            raise ValueError(f"Job {job_id} not found")
        if not job.is_reversible:
            raise DeploymentSafetyError("Job is not reversible", gate="rollback")

        rollback_type = self._get_rollback_type(job.job_type)
        if not rollback_type:
            raise DeploymentSafetyError(
                f"No rollback handler for {job.job_type.value}", gate="rollback"
            )

        rollback_job = DeploymentJob(
            brand_id=job.brand_id,
            job_type=rollback_type,
            status=JobStatus.APPROVED,
            priority=1,
            entity_type=job.entity_type,
            meta_entity_id=job.meta_entity_id,
            request_payload={"rollback_of": str(job.id)},
            ai_rationale=f"Rollback of job {job.id}",
            is_reversible=False,
            rollback_job_id=job.id,
        )
        self.db.add(rollback_job)
        job.status = JobStatus.ROLLED_BACK
        await self.db.flush()

        await self._execute_job(rollback_job)
        return rollback_job

    def _get_rollback_type(self, job_type: JobType) -> JobType | None:
        rollbacks = {
            JobType.KILL_AD: JobType.LAUNCH_AD,
            JobType.PAUSE_ADSET: JobType.LAUNCH_ADSET,
            JobType.PAUSE_CAMPAIGN: JobType.LAUNCH_CAMPAIGN,
            JobType.LAUNCH_AD: JobType.KILL_AD,
            JobType.LAUNCH_ADSET: JobType.PAUSE_ADSET,
            JobType.LAUNCH_CAMPAIGN: JobType.PAUSE_CAMPAIGN,
        }
        return rollbacks.get(job_type)
