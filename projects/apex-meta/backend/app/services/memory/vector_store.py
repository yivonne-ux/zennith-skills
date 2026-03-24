"""Pinecone RAG interface — embed, store, retrieve context for LLM reasoning."""

import hashlib
import uuid
from typing import Any

from loguru import logger
from openai import AsyncOpenAI
from pinecone import Pinecone

from app.core.config import settings
from app.core.exceptions import VectorStoreError

# Namespace constants
NS_RESEARCH = "research-daily"
NS_WORLD_CLASS = "world-class-cases"
NS_META_PLATFORM = "meta-platform"
NS_CREATIVE_LIBRARY = "creative-library"
NS_CAMPAIGN_PATTERNS = "campaign-patterns"


def brand_namespace(slug: str) -> str:
    return f"brand-{slug}"


class VectorStore:
    """OpenAI embeddings + Pinecone vector storage for RAG."""

    def __init__(self):
        self._openai = AsyncOpenAI(api_key=settings.openai_api_key)
        self._pc = Pinecone(api_key=settings.pinecone_api_key)
        self._index = self._pc.Index(settings.pinecone_index_name)
        self._model = settings.openai_embedding_model
        self._dims = settings.openai_embedding_dims

    async def embed(self, text: str) -> list[float]:
        """Generate embedding vector for text."""
        try:
            resp = await self._openai.embeddings.create(
                model=self._model,
                input=text,
                dimensions=self._dims,
            )
            return resp.data[0].embedding
        except Exception as e:
            raise VectorStoreError(f"Embedding failed: {e}")

    def _vector_id(self, content: str, namespace: str) -> str:
        """Deterministic vector ID from content hash + namespace."""
        h = hashlib.sha256(f"{namespace}:{content[:500]}".encode()).hexdigest()[:16]
        return f"{namespace}-{h}"

    async def store(
        self,
        content: str,
        namespace: str,
        metadata: dict[str, Any] | None = None,
        vector_id: str | None = None,
    ) -> str:
        """Embed content and upsert into Pinecone."""
        vec = await self.embed(content)
        vid = vector_id or self._vector_id(content, namespace)
        meta = metadata or {}
        meta["content"] = content[:2000]  # Pinecone metadata limit

        self._index.upsert(
            vectors=[{"id": vid, "values": vec, "metadata": meta}],
            namespace=namespace,
        )
        logger.info(
            "Stored vector {vid} in namespace {ns}",
            vid=vid,
            ns=namespace,
        )
        return vid

    async def retrieve_context(
        self,
        query: str,
        namespace: str,
        top_k: int | None = None,
        min_score: float | None = None,
    ) -> list[dict]:
        """Query Pinecone for similar vectors."""
        top_k = top_k or settings.rag_top_k
        min_score = min_score or settings.rag_similarity_threshold
        vec = await self.embed(query)

        results = self._index.query(
            vector=vec,
            namespace=namespace,
            top_k=top_k,
            include_metadata=True,
        )

        chunks = []
        for match in results.get("matches", []):
            if match["score"] >= min_score:
                chunks.append({
                    "id": match["id"],
                    "score": match["score"],
                    "content": match.get("metadata", {}).get("content", ""),
                    "metadata": match.get("metadata", {}),
                })

        logger.debug(
            "Retrieved {n} chunks from {ns} (query: {q:.80}...)",
            n=len(chunks),
            ns=namespace,
            q=query,
        )
        return chunks[:settings.rag_max_context_chunks]

    async def retrieve_multi_namespace(
        self,
        query: str,
        namespaces: list[str],
        top_k_per_namespace: int = 5,
    ) -> list[dict]:
        """Query multiple namespaces and merge results by score."""
        all_chunks: list[dict] = []
        for ns in namespaces:
            chunks = await self.retrieve_context(
                query, ns, top_k=top_k_per_namespace
            )
            for c in chunks:
                c["namespace"] = ns
            all_chunks.extend(chunks)

        all_chunks.sort(key=lambda x: x["score"], reverse=True)
        return all_chunks[:settings.rag_max_context_chunks]

    async def delete_vector(self, vector_id: str, namespace: str) -> None:
        """Delete a specific vector."""
        self._index.delete(ids=[vector_id], namespace=namespace)
        logger.info("Deleted vector {vid} from {ns}", vid=vector_id, ns=namespace)

    def format_context_for_llm(self, chunks: list[dict]) -> str:
        """Format retrieved chunks into a context string for LLM prompts."""
        if not chunks:
            return "No relevant context found in memory."

        parts = []
        for i, chunk in enumerate(chunks, 1):
            ns = chunk.get("namespace", "unknown")
            score = chunk.get("score", 0)
            content = chunk.get("content", "")
            parts.append(
                f"[Source {i} | {ns} | relevance: {score:.2f}]\n{content}"
            )

        return "\n\n---\n\n".join(parts)

    async def store_brand_learning(
        self, brand_slug: str, content: str, learning_type: str
    ) -> str:
        """Store a brand-specific learning into its namespace."""
        return await self.store(
            content=content,
            namespace=brand_namespace(brand_slug),
            metadata={"type": learning_type, "brand": brand_slug},
        )

    async def store_research(self, content: str, source: str, content_type: str) -> str:
        """Store a research finding into the daily research namespace."""
        return await self.store(
            content=content,
            namespace=NS_RESEARCH,
            metadata={"source": source, "content_type": content_type},
        )
