"""Research endpoints — trigger Midnight Scholar, check status."""

from fastapi import APIRouter
from loguru import logger

from app.core.celery_app import run_midnight_scholar
from app.schemas import ResearchStatusResponse, ResearchTriggerResponse

router = APIRouter(prefix="/research", tags=["research"])


@router.post("/trigger", response_model=ResearchTriggerResponse)
async def trigger_research():
    """Manually trigger the Midnight Scholar research pipeline."""
    task = run_midnight_scholar.delay()
    logger.info("Research pipeline triggered: {tid}", tid=task.id)
    return ResearchTriggerResponse(task_id=task.id, status="started")


@router.get("/status/{task_id}", response_model=ResearchStatusResponse)
async def get_research_status(task_id: str):
    """Check status of a research task."""
    from celery.result import AsyncResult
    from app.core.celery_app import celery_app

    result = AsyncResult(task_id, app=celery_app)
    response = ResearchStatusResponse(
        task_id=task_id,
        status=result.status,
    )
    if result.ready():
        response.result = result.result
    return response
