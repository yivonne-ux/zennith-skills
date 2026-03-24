"""Brand CRUD endpoints."""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from loguru import logger
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.base import get_db
from app.db.models.brand import Brand
from app.schemas import (
    BrandCreate,
    BrandResponse,
    BrandUpdate,
    MemoryQueryRequest,
    MemoryQueryResponse,
)
from app.services.memory.vector_store import VectorStore, brand_namespace

router = APIRouter(prefix="/brands", tags=["brands"])


@router.post("/", response_model=BrandResponse, status_code=201)
async def create_brand(
    data: BrandCreate, db: AsyncSession = Depends(get_db)
):
    """Create a new brand and seed its vector namespace."""
    existing = await db.execute(
        select(Brand).where(Brand.slug == data.slug)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(400, f"Brand with slug '{data.slug}' already exists")

    brand = Brand(
        **data.model_dump(),
        vector_namespace=brand_namespace(data.slug),
    )
    db.add(brand)
    await db.flush()

    if data.brand_dna:
        try:
            vs = VectorStore()
            dna_text = f"Brand: {data.name}. DNA: {data.brand_dna}"
            await vs.store_brand_learning(data.slug, dna_text, "brand_dna")
            logger.info("Seeded vector namespace for {slug}", slug=data.slug)
        except Exception as e:
            logger.warning("Vector seeding failed: {e}", e=e)

    return brand


@router.get("/", response_model=list[BrandResponse])
async def list_brands(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Brand).where(Brand.deleted_at.is_(None)).order_by(Brand.name)
    )
    return result.scalars().all()


@router.get("/{brand_id}", response_model=BrandResponse)
async def get_brand(brand_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(404, "Brand not found")
    return brand


@router.patch("/{brand_id}", response_model=BrandResponse)
async def update_brand(
    brand_id: uuid.UUID,
    data: BrandUpdate,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(404, "Brand not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(brand, field, value)

    await db.flush()
    return brand


@router.delete("/{brand_id}", status_code=204)
async def delete_brand(brand_id: uuid.UUID, db: AsyncSession = Depends(get_db)):
    from datetime import datetime, timezone

    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(404, "Brand not found")

    brand.deleted_at = datetime.now(timezone.utc)
    await db.flush()


@router.post("/{brand_id}/memory/query", response_model=MemoryQueryResponse)
async def query_brand_memory(
    brand_id: uuid.UUID,
    data: MemoryQueryRequest,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Brand).where(Brand.id == brand_id))
    brand = result.scalar_one_or_none()
    if not brand:
        raise HTTPException(404, "Brand not found")

    vs = VectorStore()
    namespaces = data.namespaces or [brand_namespace(brand.slug)]
    chunks = await vs.retrieve_multi_namespace(
        query=data.query,
        namespaces=namespaces,
        top_k_per_namespace=data.top_k,
    )
    formatted = vs.format_context_for_llm(chunks)

    return MemoryQueryResponse(chunks=chunks, formatted_context=formatted)
