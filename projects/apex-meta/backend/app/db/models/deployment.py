"""Deployment job and campaign template models."""

import enum
import uuid

from sqlalchemy import Boolean, Enum, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class JobType(str, enum.Enum):
    KILL_AD = "kill_ad"
    PAUSE_ADSET = "pause_adset"
    PAUSE_CAMPAIGN = "pause_campaign"
    SCALE_BUDGET = "scale_budget"
    LAUNCH_CAMPAIGN = "launch_campaign"
    LAUNCH_ADSET = "launch_adset"
    LAUNCH_AD = "launch_ad"
    UPLOAD_ASSET = "upload_asset"
    CREATE_CREATIVE = "create_creative"
    DUPLICATE_CAMPAIGN = "duplicate_campaign"
    UPDATE_TARGETING = "update_targeting"


class JobStatus(str, enum.Enum):
    PENDING_APPROVAL = "pending_approval"
    APPROVED = "approved"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    REJECTED = "rejected"
    ROLLED_BACK = "rolled_back"


class DeploymentJob(Base):
    __tablename__ = "deployment_jobs"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    audit_log_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("audit_logs.id"), nullable=True
    )

    job_type: Mapped[JobType] = mapped_column(Enum(JobType), nullable=False)
    status: Mapped[JobStatus] = mapped_column(Enum(JobStatus), default=JobStatus.PENDING_APPROVAL)
    priority: Mapped[int] = mapped_column(Integer, default=3)

    entity_type: Mapped[str | None] = mapped_column(String(50))
    meta_entity_id: Mapped[str | None] = mapped_column(String(50))

    request_payload: Mapped[dict | None] = mapped_column(JSON)
    response_payload: Mapped[dict | None] = mapped_column(JSON)

    ai_rationale: Mapped[str | None] = mapped_column(Text)
    ai_confidence: Mapped[float | None] = mapped_column(Numeric(4, 3))

    is_reversible: Mapped[bool] = mapped_column(Boolean, default=True)
    rollback_job_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), nullable=True
    )

    def __repr__(self) -> str:
        return f"<DeploymentJob {self.job_type.value} ({self.status.value})>"


class CampaignTemplate(Base):
    __tablename__ = "campaign_templates"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)

    campaign_config: Mapped[dict | None] = mapped_column(JSON)
    adset_config: Mapped[dict | None] = mapped_column(JSON)
    ad_config: Mapped[dict | None] = mapped_column(JSON)
    copy_variants: Mapped[list | None] = mapped_column(JSON)

    def __repr__(self) -> str:
        return f"<CampaignTemplate {self.name}>"
