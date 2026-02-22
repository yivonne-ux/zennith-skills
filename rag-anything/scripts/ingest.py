#!/usr/bin/env python3
"""
RAG-Anything ingestion script — GAIA CORP-OS
Usage: python ingest.py <file_path> <kb_dir>
       python ingest.py - <kb_dir>   (read text from stdin)
Requires: OPENAI_API_KEY in environment.
Supports: .txt .md .csv .json (text), .pdf (via RAGAnything multimodal parser)
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


async def ingest(file_path: str, kb_dir: str):
    os.makedirs(kb_dir, exist_ok=True)
    ext = file_path.rsplit(".", 1)[-1].lower() if "." in file_path else ""

    if file_path == "-":
        text = sys.stdin.read()
    elif ext in ("txt", "md", "csv", "json"):
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read()
    elif ext == "pdf":
        # RAGAnything handles PDF with layout/table/image parsing
        from raganything import RAGAnything
        rag_any = RAGAnything(working_dir=kb_dir)
        await rag_any.ainsert_file(file_path)
        print(f"✅ PDF ingested via RAGAnything: {file_path} → {kb_dir}")
        return
    elif os.path.isfile(file_path):
        with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
            text = f.read()
    else:
        print(f"❌ File not found: {file_path}", file=sys.stderr); sys.exit(1)

    rag = build_rag(kb_dir)
    await rag.initialize_storages()
    await rag.ainsert(text)
    print(f"✅ Ingested ({len(text):,} chars) → {kb_dir}")


def main():
    if len(sys.argv) < 3:
        print("Usage: python ingest.py <file_path_or_-> <kb_dir>"); sys.exit(1)
    asyncio.run(ingest(sys.argv[1], sys.argv[2]))

if __name__ == "__main__":
    main()
