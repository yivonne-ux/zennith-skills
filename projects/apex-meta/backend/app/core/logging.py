"""Structured loguru logging configuration."""

import sys
from loguru import logger

from app.core.config import settings


def setup_logging() -> None:
    """Configure loguru with structured JSON logging for production."""
    logger.remove()

    log_format = (
        "<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | "
        "<level>{level: <8}</level> | "
        "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> | "
        "<level>{message}</level>"
    )

    if settings.is_production:
        logger.add(
            sys.stdout,
            format=log_format,
            level="INFO",
            serialize=True,
            backtrace=False,
            diagnose=False,
        )
        logger.add(
            "logs/apex-meta.log",
            rotation="100 MB",
            retention="30 days",
            compression="gz",
            format=log_format,
            level="INFO",
            serialize=True,
        )
    else:
        logger.add(
            sys.stdout,
            format=log_format,
            level="DEBUG",
            colorize=True,
            backtrace=True,
            diagnose=True,
        )

    logger.info(
        "Logging initialized",
        env=settings.app_env,
        debug=settings.debug,
    )
