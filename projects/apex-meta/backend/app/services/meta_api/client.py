"""Meta Graph API READ client — async httpx with retry and rate limiting."""

import asyncio
from typing import Any

import httpx
from loguru import logger
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from app.core.config import settings
from app.core.exceptions import MetaAPIError, MetaRateLimitError

RATE_LIMIT_CODES = {4, 17, 32, 613}
REQUEST_DELAY = 0.5


class MetaAPIClient:
    """Async read-only Meta Graph API client."""

    def __init__(self, access_token: str | None = None):
        self.base_url = settings.meta_base_url
        self.access_token = access_token or settings.meta_system_user_token
        self._client: httpx.AsyncClient | None = None
        self._last_request_time: float = 0

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=30.0)
        return self._client

    async def close(self) -> None:
        if self._client and not self._client.is_closed:
            await self._client.aclose()

    async def _rate_limit(self) -> None:
        now = asyncio.get_event_loop().time()
        elapsed = now - self._last_request_time
        if elapsed < REQUEST_DELAY:
            await asyncio.sleep(REQUEST_DELAY - elapsed)
        self._last_request_time = asyncio.get_event_loop().time()

    def _check_error(self, data: dict) -> None:
        if "error" not in data:
            return
        err = data["error"]
        code = err.get("code", 0)
        subcode = err.get("error_subcode", 0)
        msg = err.get("message", "Unknown Meta API error")
        if code in RATE_LIMIT_CODES:
            raise MetaRateLimitError(msg, error_code=code, error_subcode=subcode)
        raise MetaAPIError(msg, error_code=code, error_subcode=subcode)

    @retry(
        retry=retry_if_exception_type(MetaRateLimitError),
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=2, min=5, max=120),
    )
    async def _get(self, path: str, params: dict[str, Any] | None = None) -> dict:
        await self._rate_limit()
        client = await self._get_client()
        all_params = {"access_token": self.access_token}
        if params:
            all_params.update(params)
        url = f"{self.base_url}/{path}"
        logger.debug("META GET {url}", url=url)
        resp = await client.get(url, params=all_params)
        data = resp.json()
        self._check_error(data)
        return data

    async def get_campaigns(
        self, ad_account_id: str, fields: str | None = None
    ) -> list[dict]:
        default_fields = "id,name,objective,status,daily_budget,lifetime_budget,configured_status,effective_status"
        result = await self._get(
            f"act_{ad_account_id}/campaigns",
            {"fields": fields or default_fields, "limit": 500},
        )
        return result.get("data", [])

    async def get_ad_sets(
        self, ad_account_id: str, campaign_id: str | None = None, fields: str | None = None
    ) -> list[dict]:
        default_fields = "id,name,status,daily_budget,targeting,optimization_goal,bid_strategy,learning_phase_info"
        path = (
            f"{campaign_id}/adsets" if campaign_id
            else f"act_{ad_account_id}/adsets"
        )
        result = await self._get(
            path, {"fields": fields or default_fields, "limit": 500}
        )
        return result.get("data", [])

    async def get_ads(
        self, ad_account_id: str, adset_id: str | None = None, fields: str | None = None
    ) -> list[dict]:
        default_fields = "id,name,status,creative{id,name,thumbnail_url},configured_status,effective_status"
        path = (
            f"{adset_id}/ads" if adset_id
            else f"act_{ad_account_id}/ads"
        )
        result = await self._get(
            path, {"fields": fields or default_fields, "limit": 500}
        )
        return result.get("data", [])

    async def get_campaign_insights(
        self,
        entity_id: str,
        level: str = "campaign",
        date_preset: str = "last_7d",
        fields: str | None = None,
        breakdowns: str | None = None,
    ) -> list[dict]:
        default_fields = (
            "campaign_id,campaign_name,adset_id,adset_name,ad_id,ad_name,"
            "spend,impressions,clicks,ctr,cpm,frequency,"
            "actions,action_values,cost_per_action_type,"
            "video_30_sec_watched_actions,video_p25_watched_actions,"
            "video_p50_watched_actions,video_p75_watched_actions,"
            "video_p100_watched_actions,"
            "video_thruplay_watched_actions"
        )
        params: dict[str, Any] = {
            "fields": fields or default_fields,
            "date_preset": date_preset,
            "level": level,
            "limit": 500,
        }
        if breakdowns:
            params["breakdowns"] = breakdowns
        result = await self._get(f"{entity_id}/insights", params)
        return result.get("data", [])

    async def get_ad_insights(
        self, ad_id: str, date_preset: str = "last_7d", fields: str | None = None
    ) -> list[dict]:
        return await self.get_campaign_insights(
            entity_id=ad_id, level="ad", date_preset=date_preset, fields=fields
        )

    async def get_account_quality(self, ad_account_id: str) -> dict:
        return await self._get(
            f"act_{ad_account_id}",
            {"fields": "account_status,disable_reason,funding_source_details"},
        )

    async def verify_pixel(self, pixel_id: str) -> dict:
        return await self._get(pixel_id, {"fields": "id,name,last_fired_time,is_created_by_app"})

    async def get_custom_audiences(self, ad_account_id: str) -> list[dict]:
        result = await self._get(
            f"act_{ad_account_id}/customaudiences",
            {"fields": "id,name,subtype,approximate_count_lower_bound,approximate_count_upper_bound"},
        )
        return result.get("data", [])

    async def get_ad_creatives(self, ad_account_id: str, fields: str | None = None) -> list[dict]:
        default_fields = "id,name,status,object_story_spec,thumbnail_url"
        result = await self._get(
            f"act_{ad_account_id}/adcreatives",
            {"fields": fields or default_fields, "limit": 500},
        )
        return result.get("data", [])

    async def get_entity_by_id(self, entity_id: str, fields: str = "name,status") -> dict:
        return await self._get(entity_id, {"fields": fields})

    async def paginate_all(self, path: str, params: dict[str, Any]) -> list[dict]:
        """Follow pagination cursors to get all results."""
        all_data: list[dict] = []
        params["access_token"] = self.access_token
        client = await self._get_client()
        url = f"{self.base_url}/{path}"

        while url:
            await self._rate_limit()
            resp = await client.get(url, params=params if url.startswith("http") is False else None)
            data = resp.json()
            self._check_error(data)
            all_data.extend(data.get("data", []))
            url = data.get("paging", {}).get("next")
            params = {}  # Next URL has params embedded

        return all_data
