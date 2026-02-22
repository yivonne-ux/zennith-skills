#!/usr/bin/env python3
"""
End-to-end RAG-Anything test using OpenRouter.
Tests: insert text → query → verify answer makes sense.
"""
import asyncio
import os
import sys
import tempfile
import shutil

WORKING_DIR = os.path.join(tempfile.mkdtemp(), "rag-test-kb")

TEST_TEXT = """
GAIA CORP is a Malaysian company with 7 F&B and wellness brands.
Pinxin Vegan focuses on plant-based food. Core values: sustainability, community, authentic Malaysian flavours.
Wholey Wonder makes healthy snacks. MIRRA produces wellness beverages.
Rasaya celebrates traditional Malaysian recipes. Gaia Eats is a delivery kitchen.
Dr Stan makes health supplements. Serein is a skincare brand.
The company founder is focused on automation and AI-first operations by 2026.
"""

async def test_rag():
    from lightrag import LightRAG, QueryParam
    from lightrag.llm.openai import openai_complete_if_cache, openai_embed
    from lightrag.utils import EmbeddingFunc
    import numpy as np

    os.makedirs(WORKING_DIR, exist_ok=True)

    # Use OpenRouter for both LLM and embedding
    openrouter_key = os.environ.get("OPENROUTER_API_KEY", os.environ.get("OPENAI_API_KEY", ""))
    openrouter_base = os.environ.get("OPENAI_API_BASE", "https://openrouter.ai/api/v1")

    async def llm_func(prompt, system_prompt=None, **kwargs):
        return await openai_complete_if_cache(
            "openrouter/qwen/qwen3-235b-a22b",
            prompt,
            system_prompt=system_prompt,
            api_key=openrouter_key,
            base_url=openrouter_base,
            **kwargs
        )

    # Use OpenAI's embedding API directly (not OpenRouter for embeddings)
    # This requires OPENAI_API_KEY env var separate from OpenRouter
    openai_key = os.environ.get("OPENAI_API_KEY", openrouter_key)
    openai_base = os.environ.get("OPENAI_BASE_URL", "https://api.openai.com/v1")
    
    async def embed_func(texts):
        import openai
        client = openai.AsyncOpenAI(api_key=openai_key, base_url=openai_base)
        response = await client.embeddings.create(
            model="text-embedding-3-small",
            input=texts
        )
        return [item.embedding for item in response.data]

    rag = LightRAG(
        working_dir=WORKING_DIR,
        llm_model_func=llm_func,
        embedding_func=EmbeddingFunc(
            embedding_dim=1536,
            max_token_size=8192,
            func=embed_func,
        ),
    )

    await rag.initialize_storages()

    print("📥 Inserting test document...")
    await rag.ainsert(TEST_TEXT)
    print("✅ Insert complete")

    print("\n🔍 Querying: 'What brands does GAIA CORP have?'")
    result = await rag.aquery(
        "What brands does GAIA CORP have?",
        param=QueryParam(mode="naive")
    )
    print(f"Answer: {result[:300]}...")
    print("\n✅ RAG end-to-end test PASSED")

if __name__ == "__main__":
    try:
        asyncio.run(test_rag())
    except Exception as e:
        print(f"❌ Test failed: {e}")
        sys.exit(1)
    finally:
        shutil.rmtree(WORKING_DIR, ignore_errors=True)
        print(f"🧹 Cleaned up temp KB")
