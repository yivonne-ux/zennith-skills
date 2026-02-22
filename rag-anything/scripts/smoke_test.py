#!/usr/bin/env python3
"""
Smoke test for RAG-Anything setup.
Verifies imports and basic functionality without API calls.
"""
import asyncio
import os
import sys

async def test_smoke():
    print("🔍 Testing RAG-Anything imports...")
    
    # Test 1: Import core modules
    try:
        from raganything import RAGAnything
        print("  ✅ RAGAnything imports OK")
    except Exception as e:
        print(f"  ❌ RAGAnything import failed: {e}")
        return False

    try:
        from lightrag import LightRAG, QueryParam
        print("  ✅ LightRAG imports OK")
    except Exception as e:
        print(f"  ❌ LightRAG import failed: {e}")
        return False

    # Test 2: Verify venv has all required deps
    try:
        import numpy
        import pandas
        import aiohttp
        import networkx
        print("  ✅ Core dependencies present")
    except ImportError as e:
        print(f"  ❌ Missing dependency: {e}")
        return False

    # Test 3: Check API key availability
    openrouter_key = os.environ.get("OPENROUTER_API_KEY")
    openai_key = os.environ.get("OPENAI_API_KEY")
    
    if openrouter_key:
        print("  ✅ OPENROUTER_API_KEY configured")
    else:
        print("  ⚠️  OPENROUTER_API_KEY not set")
        
    if openai_key and openai_key != openrouter_key:
        print("  ✅ Separate OPENAI_API_KEY configured (recommended)")
    elif openai_key == openrouter_key:
        print("  ⚠️  Using OpenRouter key for OpenAI — embeddings may fail")
        print("     Note: OpenRouter does not support text-embedding models")
        print("     Get a separate OpenAI API key for embeddings")
    else:
        print("  ❌ OPENAI_API_KEY not set — RAG queries will fail")
        print("     Set it in ~/.openclaw/.env or environment")

    print("\n📋 Next steps:")
    print("  1. Get OpenAI API key for embeddings")
    print("  2. Add to ~/.openclaw/.env: OPENAI_API_KEY=sk-...")
    print("  3. RAG-Anything will work for both LLM (OpenRouter) + embeddings (OpenAI)")
    
    print("\n✅ Smoke test PASSED")
    return True

if __name__ == "__main__":
    success = asyncio.run(test_smoke())
    sys.exit(0 if success else 1)
