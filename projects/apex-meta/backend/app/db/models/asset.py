"""Creative asset lifecycle model — S3 → Meta upload tracking."""

import enum
import uuid

from sqlalchemy import Boolean, Enum, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class AssetType(str, enum.Enum):
    VIDEO = "video"
    IMAGE = "image"


class AssetStatus(str, enum.Enum):
    PENDING = "pending"
    UPLOADING = "uploading"
    PROCESSING = "processing"
    READY = "ready"
    FAILED = "failed"
    ARCHIVED = "archived"


class ApprovalStatus(str, enum.Enum):
    PENDING_REVIEW = "pending_review"
    APPROVED = "approved"
    REJECTED = "rejected"


class Asset(Base):
    __tablename__ = "assets"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    asset_type: Mapped[AssetType] = mapped_column(Enum(AssetType), nullable=False)
    status: Mapped[AssetStatus] = mapped_column(Enum(AssetStatus), default=AssetStatus.PENDING)
    approval_status: Mapped[ApprovalStatus] = mapped_column(
        Enum(ApprovalStatus), default=ApprovalStatus.PENDING_REVIEW
    )

    # S3 location
    s3_bucket: Mapped[str | None] = mapped_column(String(255))
    s3_key: Mapped[str | None] = mapped_column(String(1024))

    # Meta IDs (populated after upload)
    meta_video_id: Mapped[str | None] = mapped_column(String(50))
    meta_image_hash: Mapped[str | None] = mapped_column(String(100))
    meta_creative_id: Mapped[str | None] = mapped_column(String(50))

    # File metadata
    file_size_bytes: Mapped[int | None] = mapped_column(Integer)
    duration_seconds: Mapped[float | None] = mapped_column(Numeric(8, 2))
    width_px: Mapped[int | None] = mapped_column(Integer)
    height_px: Mapped[int | None] = mapped_column(Integer)
    aspect_ratio: Mapped[str | None] = mapped_column(String(10))

    # Creative metadata
    angle_type: Mapped[str | None] = mapped_column(String(100))
    hook_text: Mapped[str | None] = mapped_column(Text)

    # Performance (populated from audit)
    avg_hook_rate: Mapped[float | None] = mapped_column(Numeric(6, 4))
    avg_cpa: Mapped[float | None] = mapped_column(Numeric(10, 2))
    best_roas: Mapped[float | None] = mapped_column(Numeric(8, 4))
    is_winner: Mapped[bool] = mapped_column(Boolean, default=False)
    fatigue_detected: Mapped[bool] = mapped_column(Boolean, default=False)

    # Relationships
    brand: Mapped["Brand"] = relationship(back_populates="assets")

    def __repr__(self) -> str:
        return f"<Asset {self.name} ({self.asset_type.value})>"
