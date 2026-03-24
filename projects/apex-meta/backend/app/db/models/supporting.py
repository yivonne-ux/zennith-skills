"""Supporting models: AuditLog, ABTest, Creative, ResearchDigest, StrategySession."""

import enum
import uuid

from sqlalchemy import Boolean, Enum, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.dialects.postgresql import JSON, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AuditSeverity(str, enum.Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"


class ABTestStatus(str, enum.Enum):
    RUNNING = "running"
    CONCLUDED = "concluded"
    CANCELLED = "cancelled"


class AuditLog(Base):
    __tablename__ = "audit_logs"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    audit_type: Mapped[str] = mapped_column(String(50), nullable=False)
    severity: Mapped[AuditSeverity] = mapped_column(Enum(AuditSeverity), default=AuditSeverity.INFO)

    metrics_snapshot: Mapped[dict | None] = mapped_column(JSON)
    flags_raised: Mapped[list | None] = mapped_column(JSON)
    root_cause_analysis: Mapped[str | None] = mapped_column(Text)
    proposed_actions: Mapped[list | None] = mapped_column(JSON)
    actions_taken: Mapped[list | None] = mapped_column(JSON)
    rag_context_used: Mapped[list | None] = mapped_column(JSON)
    llm_tokens_used: Mapped[int | None] = mapped_column(Integer)

    def __repr__(self) -> str:
        return f"<AuditLog {self.audit_type} ({self.severity.value})>"


class ABTest(Base):
    __tablename__ = "ab_tests"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    test_variable: Mapped[str] = mapped_column(String(255), nullable=False)
    hypothesis: Mapped[str | None] = mapped_column(Text)

    control_entity_id: Mapped[str | None] = mapped_column(String(50))
    variant_entity_id: Mapped[str | None] = mapped_column(String(50))
    primary_metric: Mapped[str] = mapped_column(String(50), default="cpa")

    status: Mapped[ABTestStatus] = mapped_column(Enum(ABTestStatus), default=ABTestStatus.RUNNING)
    winner_entity_id: Mapped[str | None] = mapped_column(String(50))
    confidence_level: Mapped[float | None] = mapped_column(Numeric(5, 4))
    statistical_method: Mapped[str] = mapped_column(String(50), default="z_test")
    conclusion: Mapped[str | None] = mapped_column(Text)

    def __repr__(self) -> str:
        return f"<ABTest {self.test_variable} ({self.status.value})>"


class ResearchDigest(Base):
    __tablename__ = "research_digests"

    source_type: Mapped[str] = mapped_column(String(50), nullable=False)
    source_url: Mapped[str | None] = mapped_column(String(2048))
    source_title: Mapped[str | None] = mapped_column(String(500))

    raw_content: Mapped[str | None] = mapped_column(Text)
    ai_summary: Mapped[str | None] = mapped_column(Text)
    key_insights: Mapped[list | None] = mapped_column(JSON)
    platform_changes: Mapped[list | None] = mapped_column(JSON)

    content_type: Mapped[str | None] = mapped_column(String(50))
    confidence_score: Mapped[float | None] = mapped_column(Numeric(4, 3))
    applicable_verticals: Mapped[list | None] = mapped_column(JSON)
    embedded: Mapped[bool] = mapped_column(Boolean, default=False)

    def __repr__(self) -> str:
        return f"<ResearchDigest {self.source_type}: {self.source_title}>"


class StrategySession(Base):
    __tablename__ = "strategy_sessions"

    brand_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("brands.id"), nullable=False, index=True
    )
    session_type: Mapped[str] = mapped_column(String(50), nullable=False)

    rag_query: Mapped[str | None] = mapped_column(Text)
    rag_context_chunks: Mapped[list | None] = mapped_column(JSON)
    agents_invoked: Mapped[list | None] = mapped_column(JSON)

    strategy_proposal: Mapped[str | None] = mapped_column(Text)
    action_plan: Mapped[list | None] = mapped_column(JSON)
    approved_by_human: Mapped[bool | None] = mapped_column(Boolean)
    llm_tokens_used: Mapped[int | None] = mapped_column(Integer)

    def __repr__(self) -> str:
        return f"<StrategySession {self.session_type}>"
