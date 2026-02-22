#!/usr/bin/env python3
"""
RAG-Anything ingestion script for GAIA CORP-OS.
Usage: python ingest.py <file_path> <kb_dir>
"""
import asyncio
import sys
import os

def main():
    if len(sys.argv) < 3:
        print("Usage: python ingest.py <file_path> <kb_dir>")
        sys.exit(1)

    file_path = sys.argv[1]
    kb_dir = sys.argv[2]

    if not os.path.exists(file_path):
        print(f"❌ File not found: {file_path}")
        sys.exit(1)

    os.makedirs(kb_dir, exist_ok=True)

    async def run():
        from raganything import RAGAnything
        rag = RAGAnything(working_dir=kb_dir)
        await rag.ainsert_file(file_path)
        print(f"✅ Ingested: {file_path} → {kb_dir}")

    asyncio.run(run())

if __name__ == "__main__":
    main()
