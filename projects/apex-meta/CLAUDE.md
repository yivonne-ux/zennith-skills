# APEX META — GOD MODE META ADS SPECIALIST
## Master Project Context & Coding Standards

## SYSTEM IDENTITY
Project: Apex Meta — Autonomous Multi-Brand Meta Ads Intelligence Platform
Mission: Build a production-grade, self-learning, autonomous Meta Ads AI that compounds its intelligence daily, executes forensic audits every 6 hours, and delivers world-class ad strategy for any brand, product, audience, or location.

## TECH STACK (LOCKED)

Backend: Python 3.11+, FastAPI (async), LangChain + LangGraph (agent workflows)
LLM: Anthropic Claude API (claude-sonnet-4-20250514 as primary)
Embeddings: OpenAI text-embedding-3-large (3072 dims)
Vector DB: Pinecone (production) / ChromaDB (local dev)
Relational DB: PostgreSQL 15 via SQLAlchemy 2.0 async + Alembic migrations
Cache/Queue: Redis 7 + Celery + Celery Beat
HTTP Client: httpx async
Frontend: Next.js 14 App Router, TypeScript, Tailwind CSS, Recharts
Infrastructure: Docker + Docker Compose + Nginx
External APIs: Meta Graph API v21.0, Anthropic, OpenAI, Pinecone, Serper, YouTube Data API, AWS S3

## CODING STANDARDS
- Python: Type hints on all functions, Pydantic models for all data shapes, async/await throughout, specific exceptions never bare except, loguru structured logging on every service action, max 50 lines per function
- All monetary values: NUMERIC(10,2) never float
- All timestamps: UTC TIMESTAMPTZ
- Soft deletes only: deleted_at column, never hard DELETE
- Every table: id (UUID), created_at, updated_at, deleted_at
- Meta IDs: VARCHAR (they are strings not integers)
- NEVER commit .env or hardcode API keys
- NEVER skip embedding a strategy conclusion — memory is sacred
- ALWAYS check Vector DB history before generating any new strategy
- ALWAYS log the reasoning chain that led to kill/scale decisions
- META_API_DRY_RUN must be checked before every write operation
