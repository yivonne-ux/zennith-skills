"""Brand model — multi-tenant root entity."""

import uuid
from sqlalchemy import Boolean, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Brand(Base):
    __tablename__ = "brands"

    name: Mapped[str] = mapped_column(String(255), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, nullable=False, index=True)
    vertical: Mapped[str | None] = mapped_column(String(100))

    # Meta integration
    meta_ad_account_id: Mapped[str | None] = mapped_column(String(50))
    meta_access_token: Mapped[str | None] = mapped_column(Text)
    meta_pixel_id: Mapped[str | None] = mapped_column(String(50))

    # Brand DNA
    brand_dna: Mapped[dict | None] = mapped_column(JSON)
    audience_personas: Mapped[list | None] = mapped_column(JSON)
    target_countries: Mapped[str | None] = mapped_column(String(255), default="MY")

    # Performance targets
    roas_target: Mapped[float] = mapped_column(Numeric(10, 2), default=3.0)
    cpa_ceiling: Mapped[float | None] = mapped_column(Numeric(10, 2))
    ctr_floor: Mapped[float] = mapped_column(Numeric(5, 4), default=0.01)
    frequency_ceiling: Mapped[float] = mapped_column(Numeric(4, 2), default=3.5)
    monthly_budget: Mapped[float | None] = mapped_column(Numeric(12, 2))

    # Status
    onboarding_complete: Mapped[bool] = mapped_column(Boolean, default=False)
    vector_namespace: Mapped[str | None] = mapped_column(String(100))
    seasonality_config: Mapped[dict | None] = mapped_column(JSON)

    # Relationships
    campaigns: Mapped[list["Campaign"]] = relationship(back_populates="brand", lazy="selectin")
    assets: Mapped[list["Asset"]] = relationship(back_populates="brand", lazy="selectin")

    def __repr__(self) -> str:
        return f"<Brand {self.slug} ({self.meta_ad_account_id})>"
