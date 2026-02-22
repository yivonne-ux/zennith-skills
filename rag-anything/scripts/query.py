#!/usr/bin/env python3
"""
RAG-Anything query script — GAIA CORP-OS
Usage: python query.py '<question>' <kb_dir> [mode: naive|local|global|hybrid]
Requires: OPENAI_API_KEY in environment.
"""
import asyncio, os, sys
import numpy as np


def build_rag(kb_dir: str):
    from lightrag import LightRAG
    from lightrag.llm.openai import openai_complete_if_cache
    from lightrag.utils import EmbeddingFunc
    import openai

    key = os.environ.get("OPENAI_API_KEY", "")
    if not key:
        print("❌ OPENAI_API_KEY not set", file=sys.stderr); sys.exit(1)

    async def llm_func(prompt, system_prompt=None, **kwargs):
        return await openai_complete_if_cache(
            "gpt-4o-mini", prompt,
            system_prompt=system_prompt,
            api_key=key,
            base_url="https://api.openai.com/v1",
            **kwargs
        )

    async def embed_func(texts):
        client = openai.AsyncOpenAI(api_key=key)
        r = await client.embeddings.create(model="text-embedding-3-small", input=texts)
        return np.array([i.embedding for i in r.data])

    return LightRAG(
        working_dir=kb_dir,
        llm_model_func=llm_func,
        embedding_func=EmbeddingFunc(embedding_dim=1536, max_token_size=8192, func=embed_func),
    )


async def run_query(question: str, kb_dir: str, mode: str = "hybrid"):
    from lightrag import QueryParam

    if not os.path.exists(kb_dir):
        print(f"❌ KB not found: {kb_dir}", file=sys.stderr)
        print("   Run ingest.py first.", file=sys.stderr); sys.exit(1)

    rag = build_rag(kb_dir)
    await rag.initialize_storages()
    result = await rag.aquery(question, param=QueryParam(mode=mode))
    print(result)


def main():
    if len(sys.argv) < 3:
        print("Usage: python query.py '<question>' <kb_dir> [mode]")
        print("Modes: naive | local | global | hybrid (default)"); sys.exit(1)
    mode = sys.argv[3] if len(sys.argv) > 3 else "hybrid"
    asyncio.run(run_query(sys.argv[1], sys.argv[2], mode))

if __name__ == "__main__":
    main()
