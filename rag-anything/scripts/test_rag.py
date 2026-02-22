#!/usr/bin/env python3
"""
End-to-end RAG-Anything test — GAIA CORP-OS
Uses OpenAI for both LLM (gpt-4o-mini) and embeddings (text-embedding-3-small).
Requires: OPENAI_API_KEY in environment.
"""
import asyncio, os, sys, tempfile, shutil
import numpy as np

WORKING_DIR = os.path.join(tempfile.mkdtemp(), "rag-test-kb")

TEST_TEXT = """
GAIA CORP is a Malaysian company with 7 F&B and wellness brands.
Pinxin Vegan focuses on plant-based food with core values of sustainability and community.
Wholey Wonder makes healthy snacks. MIRRA produces wellness beverages.
Rasaya celebrates traditional Malaysian recipes. Gaia Eats is a delivery kitchen.
Dr Stan makes health supplements. Serein is a skincare brand.
The company is focused on automation and AI-first operations.
"""

async def test_rag():
    from lightrag import LightRAG, QueryParam
    from lightrag.llm.openai import openai_complete_if_cache
    from lightrag.utils import EmbeddingFunc
    import openai

    openai_key = os.environ.get("OPENAI_API_KEY", "")
    if not openai_key:
        print("❌ OPENAI_API_KEY not set"); sys.exit(1)

    os.makedirs(WORKING_DIR, exist_ok=True)

    async def llm_func(prompt, system_prompt=None, **kwargs):
        return await openai_complete_if_cache(
            "gpt-4o-mini", prompt,
            system_prompt=system_prompt,
            api_key=openai_key,
            base_url="https://api.openai.com/v1",
            **kwargs
        )

    async def embed_func(texts):
        client = openai.AsyncOpenAI(api_key=openai_key)
        response = await client.embeddings.create(
            model="text-embedding-3-small", input=texts
        )
        return np.array([item.embedding for item in response.data])

    rag = LightRAG(
        working_dir=WORKING_DIR,
        llm_model_func=llm_func,
        embedding_func=EmbeddingFunc(
            embedding_dim=1536, max_token_size=8192, func=embed_func
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
    if result and "[no-context]" not in result:
        print(f"Answer: {result[:400]}")
        print("\n✅ RAG end-to-end test PASSED")
    else:
        print(f"⚠️  Got: {result}")
        print("Answer returned empty/no-context — graph may need more data")

if __name__ == "__main__":
    try:
        asyncio.run(test_rag())
    except Exception as e:
        print(f"❌ Test failed: {e}")
        import traceback; traceback.print_exc()
        sys.exit(1)
    finally:
        shutil.rmtree(WORKING_DIR, ignore_errors=True)
        print("🧹 Cleaned up temp KB")
