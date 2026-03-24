"""Apex Meta — FastAPI application entrypoint."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

from app.core.config import settings
from app.core.logging import setup_logging
from app.db.base import engine
from app.schemas import HealthResponse


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup and shutdown events."""
    setup_logging()
    logger.info(
        "Apex Meta starting — env={env}, dry_run={dr}",
        env=settings.app_env,
        dr=settings.meta_api_dry_run,
    )
    yield
    await engine.dispose()
    logger.info("Apex Meta shutdown complete")


app = FastAPI(
    title="Apex Meta — God Mode Meta Ads Specialist",
    description="Autonomous Multi-Brand Meta Ads Intelligence Platform",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:80"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Register API routers ---
from app.api.v1.endpoints.brands import router as brands_router
from app.api.v1.endpoints.campaigns import router as campaigns_router
from app.api.v1.endpoints.audit import router as audit_router
from app.api.v1.endpoints.strategy import router as strategy_router
from app.api.v1.endpoints.research import router as research_router
from app.api.v1.endpoints.reports import router as reports_router
from app.api.v1.endpoints.deployment import router as deployment_router

app.include_router(brands_router, prefix="/api/v1")
app.include_router(campaigns_router, prefix="/api/v1")
app.include_router(audit_router, prefix="/api/v1")
app.include_router(strategy_router, prefix="/api/v1")
app.include_router(research_router, prefix="/api/v1")
app.include_router(reports_router, prefix="/api/v1")
app.include_router(deployment_router, prefix="/api/v1")


@app.get("/api/v1/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint."""
    db_status = "unknown"
    redis_status = "unknown"

    try:
        from sqlalchemy import text
        from app.db.base import async_session_factory
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
            db_status = "connected"
    except Exception as e:
        db_status = f"error: {e}"

    try:
        import redis as redis_lib
        r = redis_lib.from_url(settings.redis_url)
        r.ping()
        redis_status = "connected"
    except Exception as e:
        redis_status = f"error: {e}"

    return HealthResponse(
        status="healthy" if db_status == "connected" else "degraded",
        version="1.0.0",
        database=db_status,
        redis=redis_status,
    )
