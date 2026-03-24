"""Test all external service connections."""

import asyncio
import sys
sys.path.insert(0, "backend")

from app.core.config import settings


async def test_database():
    """Test PostgreSQL connection."""
    print("\n--- PostgreSQL ---")
    try:
        from app.db.base import engine
        from sqlalchemy import text
        async with engine.connect() as conn:
            result = await conn.execute(text("SELECT version()"))
            version = result.scalar()
            print(f"  Connected: {version[:60]}...")
        await engine.dispose()
        return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False


async def test_redis():
    """Test Redis connection."""
    print("\n--- Redis ---")
    try:
        import redis
        r = redis.from_url(settings.redis_url)
        r.ping()
        print(f"  Connected: {settings.redis_url}")
        return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False


async def test_meta_api():
    """Test Meta Graph API token."""
    print("\n--- Meta Graph API ---")
    if not settings.meta_system_user_token:
        print("  SKIPPED: No token configured")
        return False
    try:
        from app.services.meta_api.client import MetaAPIClient
        client = MetaAPIClient()
        result = await client._get("me", {"fields": "id,name"})
        await client.close()
        print(f"  Connected: {result.get('name', 'OK')} (ID: {result.get('id')})")
        return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False


async def test_anthropic():
    """Test Anthropic API key."""
    print("\n--- Anthropic ---")
    if not settings.anthropic_api_key:
        print("  SKIPPED: No API key configured")
        return False
    try:
        import anthropic
        client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
        response = await client.messages.create(
            model=settings.anthropic_model,
            max_tokens=10,
            messages=[{"role": "user", "content": "Say OK"}],
        )
        print(f"  Connected: Model {settings.anthropic_model}, response: {response.content[0].text}")
        return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False


async def test_openai():
    """Test OpenAI API key (embeddings)."""
    print("\n--- OpenAI (Embeddings) ---")
    if not settings.openai_api_key:
        print("  SKIPPED: No API key configured")
        return False
    try:
        from openai import AsyncOpenAI
        client = AsyncOpenAI(api_key=settings.openai_api_key)
        resp = await client.embeddings.create(
            model=settings.openai_embedding_model,
            input="test",
            dimensions=settings.openai_embedding_dims,
        )
        print(f"  Connected: {len(resp.data[0].embedding)} dims")
        return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False


async def test_pinecone():
    """Test Pinecone connection."""
    print("\n--- Pinecone ---")
    if not settings.pinecone_api_key:
        print("  SKIPPED: No API key configured")
        return False
    try:
        from pinecone import Pinecone
        pc = Pinecone(api_key=settings.pinecone_api_key)
        index = pc.Index(settings.pinecone_index_name)
        stats = index.describe_index_stats()
        print(f"  Connected: {stats.get('total_vector_count', 0)} vectors")
        return True
    except Exception as e:
        print(f"  FAILED: {e}")
        return False


async def main():
    print("=" * 50)
    print("APEX META — Connection Test")
    print("=" * 50)

    results = {}
    results["PostgreSQL"] = await test_database()
    results["Redis"] = await test_redis()
    results["Meta API"] = await test_meta_api()
    results["Anthropic"] = await test_anthropic()
    results["OpenAI"] = await test_openai()
    results["Pinecone"] = await test_pinecone()

    print("\n" + "=" * 50)
    print("SUMMARY")
    print("=" * 50)
    for name, ok in results.items():
        status = "PASS" if ok else "FAIL/SKIP"
        print(f"  {name}: {status}")

    required = ["PostgreSQL", "Redis"]
    if all(results.get(r) for r in required):
        print("\nCore services OK. Ready to start.")
    else:
        print("\nCore services missing. Run: docker compose up -d postgres redis")


if __name__ == "__main__":
    asyncio.run(main())
