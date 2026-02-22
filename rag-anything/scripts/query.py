#!/usr/bin/env python3
"""
RAG-Anything query script for GAIA CORP-OS.
Usage: python query.py '<question>' <kb_dir> [mode: naive|local|global|hybrid]
"""
import asyncio
import sys
import os

def main():
    if len(sys.argv) < 3:
        print("Usage: python query.py '<question>' <kb_dir> [mode]")
        print("Modes: naive | local | global | hybrid (default)")
        sys.exit(1)

    question = sys.argv[1]
    kb_dir = sys.argv[2]
    mode = sys.argv[3] if len(sys.argv) > 3 else "hybrid"

    if not os.path.exists(kb_dir):
        print(f"❌ KB directory not found: {kb_dir}")
        print("Tip: Ingest documents first with ingest.py")
        sys.exit(1)

    async def run():
        from lightrag import LightRAG, QueryParam
        rag = LightRAG(working_dir=kb_dir)
        result = await rag.aquery(question, param=QueryParam(mode=mode))
        print(result)

    asyncio.run(run())

if __name__ == "__main__":
    main()
