"""Campaign, AdSet, and Ad models — mirrors Meta hierarchy."""

import enum
import uuid

from sqlalchemy import Boolean, Enum, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class CampaignObjective(str, enum.Enum):
    OUTCOME_SALES = "OUTCOME_SALES"
    OUTCOME_ENGAGEMENT = "OUTCOME_ENGAGEMENT"
    OUTCOME_LEADS = "OUTCOME_LEADS"
    OUTCOME_AWARENESS = "OUTCOME_AWARENESS"
    OUTCOME_TRAFFIC = "OUTCOME_TRAFFIC"
    OUTCOME_APP_PROMOTION = "OUTCOME_APP_PROMOTION"


class EntityStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    PAUSED = "PAUSED"
    DELETED = "DELETED"
    ARCHIVED = "ARCHIVED"


class LearningPhase(str, enum.Enum):
    LEARNING = "LEARNING"
    LEARNING_LIMITED = "LEARNING_LIMITED"
    EXITED = "EXITED"


class Campaign(Base):
    __tablename__ = "campaigns"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    meta_campaign_id: Mapped[str | None] = mapped_column(String(50), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    objective: Mapped[CampaignObjective | None] = mapped_column(Enum(CampaignObjective))
    status: Mapped[EntityStatus] = mapped_column(Enum(EntityStatus), default=EntityStatus.PAUSED)
    is_advantage_plus: Mapped[bool] = mapped_column(Boolean, default=False)
    daily_budget: Mapped[float | None] = mapped_column(Numeric(10, 2))
    cbo_enabled: Mapped[bool] = mapped_column(Boolean, default=True)

    # Performance snapshots
    last_roas: Mapped[float | None] = mapped_column(Numeric(8, 4))
    last_cpa: Mapped[float | None] = mapped_column(Numeric(10, 2))
    last_audit_flag: Mapped[str | None] = mapped_column(String(20))

    # Relationships
    brand: Mapped["Brand"] = relationship(back_populates="campaigns")
    ad_sets: Mapped[list["AdSet"]] = relationship(back_populates="campaign", lazy="selectin")

    def __repr__(self) -> str:
        return f"<Campaign {self.name} ({self.meta_campaign_id})>"


class AdSet(Base):
    __tablename__ = "ad_sets"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    campaign_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("campaigns.id"), nullable=False, index=True
    )
    meta_adset_id: Mapped[str | None] = mapped_column(String(50), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[EntityStatus] = mapped_column(Enum(EntityStatus), default=EntityStatus.PAUSED)
    learning_phase: Mapped[LearningPhase | None] = mapped_column(Enum(LearningPhase))

    # Targeting
    targeting_config: Mapped[dict | None] = mapped_column(JSON)
    placement_type: Mapped[str | None] = mapped_column(String(50))
    daily_budget: Mapped[float | None] = mapped_column(Numeric(10, 2))

    # Performance snapshots
    last_roas: Mapped[float | None] = mapped_column(Numeric(8, 4))
    last_cpa: Mapped[float | None] = mapped_column(Numeric(10, 2))
    last_ctr: Mapped[float | None] = mapped_column(Numeric(8, 6))
    last_cpm: Mapped[float | None] = mapped_column(Numeric(10, 2))
    last_frequency: Mapped[float | None] = mapped_column(Numeric(6, 3))
    conversions_last_7d: Mapped[int | None] = mapped_column(Integer)
    last_audit_flag: Mapped[str | None] = mapped_column(String(20))

    # Relationships
    campaign: Mapped["Campaign"] = relationship(back_populates="ad_sets")
    ads: Mapped[list["Ad"]] = relationship(back_populates="ad_set", lazy="selectin")

    def __repr__(self) -> str:
        return f"<AdSet {self.name} ({self.meta_adset_id})>"


class Ad(Base):
    __tablename__ = "ads"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    ad_set_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("ad_sets.id"), nullable=False, index=True
    )
    meta_ad_id: Mapped[str | None] = mapped_column(String(50), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    status: Mapped[EntityStatus] = mapped_column(Enum(EntityStatus), default=EntityStatus.PAUSED)

    # Creative
    creative_id: Mapped[str | None] = mapped_column(String(50))
    creative_type: Mapped[str | None] = mapped_column(String(50))
    hook_type: Mapped[str | None] = mapped_column(String(100))
    angle_type: Mapped[str | None] = mapped_column(String(100))

    # Performance snapshots
    last_ctr: Mapped[float | None] = mapped_column(Numeric(8, 6))
    last_cpm: Mapped[float | None] = mapped_column(Numeric(10, 2))
    last_cpa: Mapped[float | None] = mapped_column(Numeric(10, 2))
    last_roas: Mapped[float | None] = mapped_column(Numeric(8, 4))
    last_frequency: Mapped[float | None] = mapped_column(Numeric(6, 3))
    hook_rate: Mapped[float | None] = mapped_column(Numeric(6, 4))
    hold_rate: Mapped[float | None] = mapped_column(Numeric(6, 4))
    fatigue_detected: Mapped[bool] = mapped_column(Boolean, default=False)
    kill_recommended: Mapped[bool] = mapped_column(Boolean, default=False)
    performance_history: Mapped[list | None] = mapped_column(JSON)

    # Relationships
    ad_set: Mapped["AdSet"] = relationship(back_populates="ads")

    def __repr__(self) -> str:
        return f"<Ad {self.name} ({self.meta_ad_id})>"
