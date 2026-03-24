"""Strategy generation endpoints — RAG-powered campaign strategy."""

import json
import uuid

import anthropic
from fastapi import APIRouter, Depends, HTTPException
from loguru import logger
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.base import get_db
from app.db.models.brand import Brand
from app.db.models.supporting import StrategySession
from app.schemas import StrategyRequest, StrategyResponse
from app.services.memory.vector_store import (
    NS_CAMPAIGN_PATTERNS,
    NS_META_PLATFORM,
    NS_RESEARCH,
    VectorStore,
    brand_namespace,
)

router = APIRouter(prefix="/strategy", tags=["strategy"])


@router.post("/{brand_id}/generate", response_model=StrategyResponse)
async def generate_strategy(
    brand_id: uuid.UUID,
    data: StrategyRequest,
    db: AsyncSession = Depends(get_db),
):
    """Generate RAG-powered strategy for a brand."""
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(404, "Brand not found")

    vs = VectorStore()
    query = data.custom_query or f"Meta Ads strategy for {brand.name} ({brand.vertical})"

    namespaces = [brand_namespace(brand.slug), NS_CAMPAIGN_PATTERNS]
    if data.include_research:
        namespaces.extend([NS_RESEARCH, NS_META_PLATFORM])

    chunks = await vs.retrieve_multi_namespace(
        query=query, namespaces=namespaces
    )
    context = vs.format_context_for_llm(chunks)

    brand_info = json.dumps(brand.brand_dna or {}, indent=2)
    personas = json.dumps(brand.audience_personas or [], indent=2)

    prompt = f"""You are Apex Meta, a world-class Meta Ads strategist. Generate a comprehensive campaign strategy.

## Brand
Name: {brand.name}
Vertical: {brand.vertical}
ROAS Target: {brand.roas_target}x
CPA Ceiling: RM{brand.cpa_ceiling or 'not set'}
Monthly Budget: RM{brand.monthly_budget or 'not set'}
Countries: {brand.target_countries}

## Brand DNA
{brand_info}

## Audience Personas
{personas}

## Context from Memory (past learnings, research, patterns)
{context}

## Session Type: {data.session_type}

Generate:
1. **Strategy Proposal**: 3-5 paragraphs covering campaign structure, creative strategy, audience strategy, budget allocation, and testing plan
2. **Action Plan**: JSON array of specific actions with priority, type, description, expected_impact

Return as JSON with:
- "strategy_proposal": string
- "action_plan": array of {{"priority": int, "type": string, "description": string, "expected_impact": string}}
- "key_insights_used": array of strings (which memory chunks influenced the strategy)

Return ONLY the JSON object."""

    try:
        client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
        response = await client.messages.create(
            model=settings.anthropic_model,
            max_tokens=4096,
            messages=[{"role": "user", "content": prompt}],
        )
        text = response.content[0].text.strip()
        start = text.find("{")
        end = text.rfind("}") + 1
        result_json = json.loads(text[start:end]) if start >= 0 else {}
        tokens = response.usage.input_tokens + response.usage.output_tokens
    except Exception as e:
        logger.error("Strategy generation failed: {e}", e=e)
        result_json = {
            "strategy_proposal": f"Strategy generation failed: {e}",
            "action_plan": [],
        }
        tokens = 0

    session = StrategySession(
        brand_id=brand_id,
        session_type=data.session_type,
        rag_query=query,
        rag_context_chunks=[c.get("id") for c in chunks],
        strategy_proposal=result_json.get("strategy_proposal"),
        action_plan=result_json.get("action_plan"),
        llm_tokens_used=tokens,
    )
    db.add(session)
    await db.flush()

    # Embed the strategy conclusion into brand memory
    if result_json.get("strategy_proposal"):
        try:
            await vs.store_brand_learning(
                brand_slug=brand.slug,
                content=f"Strategy session ({data.session_type}): {result_json['strategy_proposal'][:1000]}",
                learning_type="strategy_conclusion",
            )
        except Exception as e:
            logger.warning("Failed to embed strategy: {e}", e=e)

    return session


@router.get("/{brand_id}/sessions", response_model=list[StrategyResponse])
async def list_strategy_sessions(
    brand_id: uuid.UUID,
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(StrategySession)
        .where(StrategySession.brand_id == brand_id)
        .order_by(StrategySession.created_at.desc())
        .limit(limit)
    )
    return result.scalars().all()
