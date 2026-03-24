"""Pydantic schemas for request/response validation."""

import uuid
from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field


# --- Brand ---
class BrandCreate(BaseModel):
    name: str
    slug: str
    vertical: str | None = None
    meta_ad_account_id: str | None = None
    meta_access_token: str | None = None
    meta_pixel_id: str | None = None
    brand_dna: dict | None = None
    audience_personas: list | None = None
    target_countries: str = "MY"
    roas_target: float = 3.0
    cpa_ceiling: float | None = None
    monthly_budget: float | None = None


class BrandUpdate(BaseModel):
    name: str | None = None
    meta_ad_account_id: str | None = None
    meta_access_token: str | None = None
    meta_pixel_id: str | None = None
    brand_dna: dict | None = None
    audience_personas: list | None = None
    roas_target: float | None = None
    cpa_ceiling: float | None = None
    monthly_budget: float | None = None
    onboarding_complete: bool | None = None


class BrandResponse(BaseModel):
    id: uuid.UUID
    name: str
    slug: str
    vertical: str | None
    meta_ad_account_id: str | None
    meta_pixel_id: str | None
    roas_target: float
    cpa_ceiling: float | None
    monthly_budget: float | None
    onboarding_complete: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class MemoryQueryRequest(BaseModel):
    query: str
    namespaces: list[str] | None = None
    top_k: int = 5


class MemoryQueryResponse(BaseModel):
    chunks: list[dict]
    formatted_context: str


# --- Campaign ---
class CampaignResponse(BaseModel):
    id: uuid.UUID
    meta_campaign_id: str | None
    name: str
    objective: str | None
    status: str
    daily_budget: float | None
    cbo_enabled: bool
    last_roas: float | None
    last_cpa: float | None
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Audit ---
class AuditTriggerRequest(BaseModel):
    roas_target: float | None = None
    cpa_ceiling: float | None = None


class AuditResponse(BaseModel):
    id: uuid.UUID
    audit_type: str
    severity: str
    metrics_snapshot: dict | None
    flags_raised: list | None
    root_cause_analysis: str | None
    proposed_actions: list | None
    llm_tokens_used: int | None
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Strategy ---
class StrategyRequest(BaseModel):
    session_type: str = "full_strategy"
    custom_query: str | None = None
    include_research: bool = True


class StrategyResponse(BaseModel):
    id: uuid.UUID
    session_type: str
    strategy_proposal: str | None
    action_plan: list | None
    llm_tokens_used: int | None
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Research ---
class ResearchTriggerResponse(BaseModel):
    task_id: str
    status: str = "started"


class ResearchStatusResponse(BaseModel):
    task_id: str
    status: str
    result: dict | None = None


# --- Deployment ---
class AssetRegisterRequest(BaseModel):
    name: str
    asset_type: str
    s3_bucket: str | None = None
    s3_key: str | None = None
    meta_video_id: str | None = None
    meta_image_hash: str | None = None
    angle_type: str | None = None
    hook_text: str | None = None
    width_px: int | None = None
    height_px: int | None = None


class AssetResponse(BaseModel):
    id: uuid.UUID
    name: str
    asset_type: str
    status: str
    approval_status: str
    meta_video_id: str | None
    meta_image_hash: str | None
    s3_key: str | None
    is_winner: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class CampaignLaunchRequest(BaseModel):
    name: str
    objective: str = "OUTCOME_SALES"
    daily_budget: int | None = None
    cbo_enabled: bool = True
    page_id: str
    auto_activate: bool = False
    ad_sets: list[dict] = Field(default_factory=list)


class JobDecisionRequest(BaseModel):
    decision: str
    reason: str | None = None


class DeploymentJobResponse(BaseModel):
    id: uuid.UUID
    job_type: str
    status: str
    priority: int
    entity_type: str | None
    meta_entity_id: str | None
    ai_rationale: str | None
    ai_confidence: float | None
    is_reversible: bool
    created_at: datetime

    model_config = {"from_attributes": True}


# --- Reports ---
class WeeklyReportResponse(BaseModel):
    brand_id: uuid.UUID
    period: str
    total_spend: float | None
    total_conversions: int | None
    avg_cpa: float | None
    avg_roas: float | None
    top_performers: list[dict]
    flags_summary: dict
    recommendations: list[str]


# --- Health ---
class HealthResponse(BaseModel):
    status: str = "healthy"
    version: str = "1.0.0"
    database: str = "unknown"
    redis: str = "unknown"
