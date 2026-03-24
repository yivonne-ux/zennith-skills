"""Meta Graph API WRITE client — all mutations behind DRY_RUN gate."""

from typing import Any

import httpx
from loguru import logger

from app.core.config import settings
from app.core.exceptions import MetaAPIError, MetaDryRunError, MetaRateLimitError
from app.services.meta_api.client import MetaAPIClient

RATE_LIMIT_CODES = {4, 17, 32, 613}


class MetaAPIPublisher:
    """Write operations to Meta Graph API — ALL gated by META_API_DRY_RUN."""

    def __init__(self, access_token: str | None = None):
        self.base_url = settings.meta_base_url
        self.access_token = access_token or settings.meta_system_user_token
        self.dry_run = settings.meta_api_dry_run
        self._client: httpx.AsyncClient | None = None
        self._reader = MetaAPIClient(access_token=self.access_token)

    async def _get_client(self) -> httpx.AsyncClient:
        if self._client is None or self._client.is_closed:
            self._client = httpx.AsyncClient(timeout=60.0)
        return self._client

    async def close(self) -> None:
        if self._client and not self._client.is_closed:
            await self._client.aclose()
        await self._reader.close()

    def _check_dry_run(self, operation: str, payload: dict) -> dict | None:
        if not self.dry_run:
            return None
        logger.warning(
            "DRY_RUN: Would execute {op} with payload: {p}",
            op=operation,
            p=payload,
        )
        return {"dry_run": True, "operation": operation, "payload": payload}

    async def _post(self, path: str, data: dict[str, Any]) -> dict:
        await self._reader._rate_limit()
        client = await self._get_client()
        data["access_token"] = self.access_token
        url = f"{self.base_url}/{path}"
        logger.info("META POST {url}", url=url)
        resp = await client.post(url, data=data)
        result = resp.json()
        if "error" in result:
            err = result["error"]
            code = err.get("code", 0)
            if code in RATE_LIMIT_CODES:
                raise MetaRateLimitError(err["message"], error_code=code)
            raise MetaAPIError(err.get("message", "Unknown"), error_code=code)
        return result

    async def create_campaign(
        self,
        ad_account_id: str,
        name: str,
        objective: str,
        status: str = "PAUSED",
        daily_budget: int | None = None,
        special_ad_categories: list[str] | None = None,
    ) -> dict:
        payload = {
            "name": name,
            "objective": objective,
            "status": status,
            "special_ad_categories": special_ad_categories or [],
        }
        if daily_budget:
            payload["daily_budget"] = daily_budget * 100  # Meta uses cents
        dry = self._check_dry_run("create_campaign", payload)
        if dry:
            return dry
        return await self._post(f"act_{ad_account_id}/campaigns", payload)

    async def create_adset(
        self,
        ad_account_id: str,
        campaign_id: str,
        name: str,
        daily_budget: int,
        optimization_goal: str,
        billing_event: str = "IMPRESSIONS",
        targeting: dict | None = None,
        status: str = "PAUSED",
        promoted_object: dict | None = None,
    ) -> dict:
        payload = {
            "campaign_id": campaign_id,
            "name": name,
            "daily_budget": daily_budget * 100,
            "optimization_goal": optimization_goal,
            "billing_event": billing_event,
            "status": status,
        }
        if targeting:
            payload["targeting"] = str(targeting)
        if promoted_object:
            payload["promoted_object"] = str(promoted_object)
        dry = self._check_dry_run("create_adset", payload)
        if dry:
            return dry
        return await self._post(f"act_{ad_account_id}/adsets", payload)

    async def create_ad_creative_video(
        self,
        ad_account_id: str,
        name: str,
        page_id: str,
        video_id: str,
        primary_text: str,
        headline: str,
        cta_type: str = "WHATSAPP_MESSAGE",
        cta_link: str = "",
        thumbnail_url: str | None = None,
    ) -> dict:
        object_story_spec = {
            "page_id": page_id,
            "video_data": {
                "video_id": video_id,
                "message": primary_text,
                "title": headline,
                "call_to_action": {
                    "type": cta_type,
                    "value": {"link": cta_link},
                },
            },
        }
        if thumbnail_url:
            object_story_spec["video_data"]["image_url"] = thumbnail_url
        payload = {
            "name": name,
            "object_story_spec": str(object_story_spec),
            "degrees_of_freedom_spec": str({
                "creative_features_spec": {
                    "standard_enhancements": {"enroll_status": "OPT_OUT"}
                }
            }),
        }
        dry = self._check_dry_run("create_ad_creative_video", payload)
        if dry:
            return dry
        return await self._post(f"act_{ad_account_id}/adcreatives", payload)

    async def create_ad_creative_image(
        self,
        ad_account_id: str,
        name: str,
        page_id: str,
        image_hash: str,
        primary_text: str,
        headline: str,
        cta_type: str = "WHATSAPP_MESSAGE",
        cta_link: str = "",
    ) -> dict:
        object_story_spec = {
            "page_id": page_id,
            "link_data": {
                "image_hash": image_hash,
                "message": primary_text,
                "name": headline,
                "call_to_action": {
                    "type": cta_type,
                    "value": {"link": cta_link},
                },
            },
        }
        payload = {
            "name": name,
            "object_story_spec": str(object_story_spec),
            "degrees_of_freedom_spec": str({
                "creative_features_spec": {
                    "standard_enhancements": {"enroll_status": "OPT_OUT"}
                }
            }),
        }
        dry = self._check_dry_run("create_ad_creative_image", payload)
        if dry:
            return dry
        return await self._post(f"act_{ad_account_id}/adcreatives", payload)

    async def create_ad_creative_carousel(
        self,
        ad_account_id: str,
        name: str,
        page_id: str,
        cards: list[dict],
        primary_text: str,
    ) -> dict:
        object_story_spec = {
            "page_id": page_id,
            "link_data": {
                "message": primary_text,
                "child_attachments": cards,
            },
        }
        payload = {
            "name": name,
            "object_story_spec": str(object_story_spec),
        }
        dry = self._check_dry_run("create_ad_creative_carousel", payload)
        if dry:
            return dry
        return await self._post(f"act_{ad_account_id}/adcreatives", payload)

    async def create_ad(
        self,
        ad_account_id: str,
        name: str,
        adset_id: str,
        creative_id: str,
        status: str = "PAUSED",
    ) -> dict:
        payload = {
            "name": name,
            "adset_id": adset_id,
            "creative": str({"creative_id": creative_id}),
            "status": status,
        }
        dry = self._check_dry_run("create_ad", payload)
        if dry:
            return dry
        return await self._post(f"act_{ad_account_id}/ads", payload)

    async def set_ad_status(self, ad_id: str, status: str) -> dict:
        payload = {"status": status}
        dry = self._check_dry_run(f"set_ad_status({ad_id})", payload)
        if dry:
            return dry
        return await self._post(ad_id, payload)

    async def set_adset_status(self, adset_id: str, status: str) -> dict:
        payload = {"status": status}
        dry = self._check_dry_run(f"set_adset_status({adset_id})", payload)
        if dry:
            return dry
        return await self._post(adset_id, payload)

    async def set_campaign_status(self, campaign_id: str, status: str) -> dict:
        payload = {"status": status}
        dry = self._check_dry_run(f"set_campaign_status({campaign_id})", payload)
        if dry:
            return dry
        return await self._post(campaign_id, payload)

    async def update_adset_budget(
        self, adset_id: str, daily_budget: int
    ) -> dict:
        payload = {"daily_budget": daily_budget * 100}
        dry = self._check_dry_run(f"update_adset_budget({adset_id})", payload)
        if dry:
            return dry
        return await self._post(adset_id, payload)

    async def update_campaign_budget(
        self, campaign_id: str, daily_budget: int
    ) -> dict:
        payload = {"daily_budget": daily_budget * 100}
        dry = self._check_dry_run(f"update_campaign_budget({campaign_id})", payload)
        if dry:
            return dry
        return await self._post(campaign_id, payload)

    async def duplicate_campaign_for_scaling(
        self,
        campaign_id: str,
        new_name: str,
        daily_budget: int,
        status: str = "PAUSED",
    ) -> dict:
        payload = {
            "name": new_name,
            "daily_budget": daily_budget * 100,
            "status_option": status,
        }
        dry = self._check_dry_run(f"duplicate_campaign({campaign_id})", payload)
        if dry:
            return dry
        return await self._post(f"{campaign_id}/copies", payload)

    async def kill_ads_batch(self, ad_ids: list[str]) -> list[dict]:
        results = []
        for ad_id in ad_ids:
            result = await self.set_ad_status(ad_id, "PAUSED")
            results.append({"ad_id": ad_id, "result": result})
            logger.info("Killed ad {ad_id}", ad_id=ad_id)
        return results
