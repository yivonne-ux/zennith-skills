"""Midnight Scholar — nightly 00:00 UTC research pipeline.

Scrapes web, YouTube, RSS feeds → extracts insights via Claude → embeds into Pinecone.
"""

import asyncio
import json
from datetime import datetime, timezone
from typing import Any

import feedparser
import httpx
from loguru import logger

from app.core.config import settings
from app.core.exceptions import ResearchError
from app.services.memory.vector_store import VectorStore, NS_RESEARCH, NS_META_PLATFORM

SERPER_URL = "https://google.serper.dev/search"
YT_SEARCH_URL = "https://www.googleapis.com/youtube/v3/search"
YT_CAPTION_URL = "https://www.googleapis.com/youtube/v3/captions"

RSS_FEEDS = [
    "https://www.jonloomer.com/feed/",
    "https://adespresso.com/blog/feed/",
    "https://about.fb.com/news/feed/",
]

SEARCH_QUERIES = [
    "Meta Ads algorithm update {year}",
    "Facebook Ads scaling strategy case study {year}",
    "Meta Advantage+ creative optimization {year}",
    "WhatsApp click-to-message ads best practices {year}",
    "Meta Andromeda ad delivery system",
    "Meta Ads creative testing framework",
]


class MidnightScholarPipeline:
    """Nightly research pipeline that compounds platform intelligence."""

    def __init__(self):
        self.vector_store = VectorStore()
        self._http: httpx.AsyncClient | None = None
        self.year = datetime.now(timezone.utc).year

    async def _get_http(self) -> httpx.AsyncClient:
        if self._http is None or self._http.is_closed:
            self._http = httpx.AsyncClient(timeout=30.0)
        return self._http

    async def close(self) -> None:
        if self._http and not self._http.is_closed:
            await self._http.aclose()

    async def run(self) -> dict:
        """Execute full research pipeline."""
        logger.info("Midnight Scholar starting...")
        results = {"web": [], "youtube": [], "rss": [], "embedded": 0, "errors": []}

        try:
            web_task = self._search_web()
            rss_task = self._scrape_rss()
            yt_task = self._search_youtube()

            web_results, rss_results, yt_results = await asyncio.gather(
                web_task, rss_task, yt_task, return_exceptions=True
            )

            if isinstance(web_results, list):
                results["web"] = web_results
            elif isinstance(web_results, Exception):
                results["errors"].append(f"Web: {web_results}")

            if isinstance(rss_results, list):
                results["rss"] = rss_results
            elif isinstance(rss_results, Exception):
                results["errors"].append(f"RSS: {rss_results}")

            if isinstance(yt_results, list):
                results["youtube"] = yt_results
            elif isinstance(yt_results, Exception):
                results["errors"].append(f"YouTube: {yt_results}")

            all_content = results["web"] + results["rss"] + results["youtube"]
            if all_content:
                insights = await self._extract_insights(all_content)
                embedded = await self._embed_insights(insights)
                results["embedded"] = embedded

            logger.info(
                "Midnight Scholar complete: {w} web, {r} rss, {y} yt, {e} embedded",
                w=len(results["web"]),
                r=len(results["rss"]),
                y=len(results["youtube"]),
                e=results["embedded"],
            )
        except Exception as e:
            results["errors"].append(str(e))
            logger.error("Midnight Scholar failed: {e}", e=e)
        finally:
            await self.close()

        return results

    async def _search_web(self) -> list[dict]:
        """Search web via Serper API."""
        if not settings.serper_api_key:
            logger.warning("Serper API key not set, skipping web search")
            return []

        http = await self._get_http()
        all_results: list[dict] = []

        for query_template in SEARCH_QUERIES:
            query = query_template.format(year=self.year)
            try:
                resp = await http.post(
                    SERPER_URL,
                    json={"q": query, "num": 3},
                    headers={"X-API-KEY": settings.serper_api_key},
                )
                data = resp.json()
                for item in data.get("organic", [])[:3]:
                    all_results.append({
                        "source": "web",
                        "title": item.get("title", ""),
                        "url": item.get("link", ""),
                        "snippet": item.get("snippet", ""),
                        "query": query,
                    })
            except Exception as e:
                logger.warning("Web search failed for '{q}': {e}", q=query, e=e)

        return all_results

    async def _search_youtube(self) -> list[dict]:
        """Search YouTube for recent Meta Ads content."""
        if not settings.youtube_api_key:
            logger.warning("YouTube API key not set, skipping")
            return []

        http = await self._get_http()
        results: list[dict] = []
        queries = [
            "Meta Ads strategy 2026",
            "Facebook Ads scaling",
            "WhatsApp ads optimization",
        ]

        for query in queries:
            try:
                resp = await http.get(
                    YT_SEARCH_URL,
                    params={
                        "part": "snippet",
                        "q": query,
                        "maxResults": 3,
                        "type": "video",
                        "order": "date",
                        "key": settings.youtube_api_key,
                    },
                )
                data = resp.json()
                for item in data.get("items", []):
                    snippet = item.get("snippet", {})
                    video_id = item.get("id", {}).get("videoId", "")
                    transcript = await self._get_transcript(video_id)
                    results.append({
                        "source": "youtube",
                        "title": snippet.get("title", ""),
                        "url": f"https://www.youtube.com/watch?v={video_id}",
                        "snippet": transcript[:5000] if transcript else snippet.get("description", ""),
                        "query": query,
                    })
            except Exception as e:
                logger.warning("YouTube search failed for '{q}': {e}", q=query, e=e)

        return results

    async def _get_transcript(self, video_id: str) -> str | None:
        """Attempt to get YouTube transcript."""
        try:
            from youtube_transcript_api import YouTubeTranscriptApi
            transcript_list = YouTubeTranscriptApi.get_transcript(video_id)
            return " ".join(t["text"] for t in transcript_list)
        except Exception:
            return None

    async def _scrape_rss(self) -> list[dict]:
        """Parse RSS feeds for latest articles."""
        results: list[dict] = []
        for feed_url in RSS_FEEDS:
            try:
                feed = feedparser.parse(feed_url)
                for entry in feed.entries[:3]:
                    results.append({
                        "source": "rss",
                        "title": entry.get("title", ""),
                        "url": entry.get("link", ""),
                        "snippet": entry.get("summary", "")[:2000],
                        "query": feed_url,
                    })
            except Exception as e:
                logger.warning("RSS parse failed for {url}: {e}", url=feed_url, e=e)
        return results

    async def _extract_insights(self, content_items: list[dict]) -> list[dict]:
        """Use Claude to extract actionable insights from raw content."""
        import anthropic

        if not settings.anthropic_api_key:
            logger.warning("Anthropic API key not set, skipping insight extraction")
            return []

        client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
        batch_text = "\n\n---\n\n".join(
            f"[{item['source']}] {item['title']}\nURL: {item['url']}\n{item['snippet']}"
            for item in content_items[:15]
        )

        prompt = f"""Analyze these Meta/Facebook Ads research sources and extract actionable insights.

{batch_text}

Return a JSON array where each object has:
- "insight": string (the actionable takeaway)
- "evidence": string (what supports this)
- "content_type": "algorithm_update" | "scaling_strategy" | "creative_testing" | "audience_targeting" | "platform_change" | "case_study"
- "applicable_verticals": array of strings (e.g., ["ecommerce", "food_delivery", "all"])
- "confidence": float 0-1
- "performance_impact": "high" | "medium" | "low"

Only include insights that are:
1. Actionable (can change campaign strategy)
2. Specific (not generic marketing advice)
3. Evidence-backed (has data or expert source)

Return ONLY the JSON array, no other text."""

        try:
            response = await client.messages.create(
                model=settings.anthropic_model,
                max_tokens=4096,
                messages=[{"role": "user", "content": prompt}],
            )
            text = response.content[0].text.strip()
            if text.startswith("["):
                return json.loads(text)
            start = text.find("[")
            end = text.rfind("]") + 1
            if start >= 0 and end > start:
                return json.loads(text[start:end])
            return []
        except Exception as e:
            logger.error("Insight extraction failed: {e}", e=e)
            return []

    async def _embed_insights(self, insights: list[dict]) -> int:
        """Embed extracted insights into Pinecone."""
        count = 0
        for insight in insights:
            content = f"{insight['insight']}\n\nEvidence: {insight.get('evidence', '')}"
            content_type = insight.get("content_type", "general")
            namespace = NS_META_PLATFORM if content_type == "platform_change" else NS_RESEARCH

            try:
                await self.vector_store.store(
                    content=content,
                    namespace=namespace,
                    metadata={
                        "content_type": content_type,
                        "confidence": insight.get("confidence", 0.5),
                        "verticals": insight.get("applicable_verticals", []),
                        "impact": insight.get("performance_impact", "medium"),
                        "date": datetime.now(timezone.utc).isoformat(),
                    },
                )
                count += 1
            except Exception as e:
                logger.warning("Failed to embed insight: {e}", e=e)

        return count
