"""Initialize database — create all tables."""

import asyncio
import sys
sys.path.insert(0, "backend")

from app.db.base import Base, engine
from app.db.models import *  # noqa: F403 — ensures all models are registered


async def init():
    print("Creating all tables...")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("Done. All tables created.")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(init())
