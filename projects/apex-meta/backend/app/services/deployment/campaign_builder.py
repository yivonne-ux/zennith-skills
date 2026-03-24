"""Campaign Builder — end-to-end 3-tier Meta campaign construction.

Takes CampaignSpec → builds campaign + ad sets + ads via Meta API.
"""

from dataclasses import dataclass, field
from typing import Any

from loguru import logger

from app.services.deployment.asset_pipeline import AssetPipeline
from app.services.meta_api.publisher import MetaAPIPublisher
from app.services.memory.vector_store import VectorStore, brand_namespace


@dataclass
class AdSpec:
    name: str
    asset_type: str  # "video" or "image"
    s3_bucket: str | None = None
    s3_key: str | None = None
    meta_video_id: str | None = None
    meta_image_hash: str | None = None
    primary_text: str = ""
    headline: str = ""
    cta_type: str = "WHATSAPP_MESSAGE"
    cta_link: str = ""


@dataclass
class AdSetSpec:
    name: str
    daily_budget: int
    optimization_goal: str = "CONVERSATIONS"
    billing_event: str = "IMPRESSIONS"
    targeting: dict | None = None
    promoted_object: dict | None = None
    ads: list[AdSpec] = field(default_factory=list)


@dataclass
class CampaignSpec:
    name: str
    objective: str = "OUTCOME_SALES"
    daily_budget: int | None = None
    cbo_enabled: bool = True
    status: str = "PAUSED"
    ad_account_id: str = ""
    page_id: str = ""
    brand_slug: str = ""
    auto_activate: bool = False
    ad_sets: list[AdSetSpec] = field(default_factory=list)


class CampaignBuilder:
    """Build complete campaign hierarchy from a CampaignSpec."""

    def __init__(self, access_token: str | None = None):
        self.publisher = MetaAPIPublisher(access_token=access_token)
        self.asset_pipeline = AssetPipeline(access_token=access_token)
        self.vector_store = VectorStore()

    async def close(self) -> None:
        await self.publisher.close()
        await self.asset_pipeline.close()

    async def build(self, spec: CampaignSpec) -> dict:
        """Execute full campaign build from spec."""
        logger.info("Building campaign '{name}'", name=spec.name)
        result = {"campaign": None, "ad_sets": [], "ads": [], "errors": []}

        try:
            campaign_result = await self._create_campaign(spec)
            campaign_id = campaign_result.get("id", campaign_result.get("dry_run", "dry_run"))
            result["campaign"] = campaign_result

            for adset_spec in spec.ad_sets:
                adset_result = await self._create_adset(
                    spec, campaign_id, adset_spec
                )
                adset_id = adset_result.get("id", "dry_run")
                result["ad_sets"].append(adset_result)

                for ad_spec in adset_spec.ads:
                    try:
                        ad_result = await self._create_ad(
                            spec, adset_id, ad_spec
                        )
                        result["ads"].append(ad_result)
                    except Exception as e:
                        error = f"Ad '{ad_spec.name}' failed: {e}"
                        result["errors"].append(error)
                        logger.error(error)

            if spec.auto_activate and not self.publisher.dry_run:
                await self.publisher.set_campaign_status(campaign_id, "ACTIVE")
                logger.info("Campaign {cid} activated", cid=campaign_id)

            await self._embed_deployment(spec, result)

            logger.info(
                "Campaign build complete: {n_sets} ad sets, {n_ads} ads, {n_err} errors",
                n_sets=len(result["ad_sets"]),
                n_ads=len(result["ads"]),
                n_err=len(result["errors"]),
            )

        except Exception as e:
            result["errors"].append(f"Campaign build failed: {e}")
            logger.error("Campaign build failed: {e}", e=e)
        finally:
            await self.close()

        return result

    async def _create_campaign(self, spec: CampaignSpec) -> dict:
        return await self.publisher.create_campaign(
            ad_account_id=spec.ad_account_id,
            name=spec.name,
            objective=spec.objective,
            status=spec.status,
            daily_budget=spec.daily_budget if spec.cbo_enabled else None,
        )

    async def _create_adset(
        self, spec: CampaignSpec, campaign_id: str, adset_spec: AdSetSpec
    ) -> dict:
        return await self.publisher.create_adset(
            ad_account_id=spec.ad_account_id,
            campaign_id=campaign_id,
            name=adset_spec.name,
            daily_budget=adset_spec.daily_budget,
            optimization_goal=adset_spec.optimization_goal,
            billing_event=adset_spec.billing_event,
            targeting=adset_spec.targeting,
            promoted_object=adset_spec.promoted_object,
        )

    async def _create_ad(
        self, spec: CampaignSpec, adset_id: str, ad_spec: AdSpec
    ) -> dict:
        await self._resolve_asset(spec.ad_account_id, ad_spec)

        if ad_spec.asset_type == "video" and ad_spec.meta_video_id:
            creative_result = await self.publisher.create_ad_creative_video(
                ad_account_id=spec.ad_account_id,
                name=f"creative-{ad_spec.name}",
                page_id=spec.page_id,
                video_id=ad_spec.meta_video_id,
                primary_text=ad_spec.primary_text,
                headline=ad_spec.headline,
                cta_type=ad_spec.cta_type,
                cta_link=ad_spec.cta_link,
            )
        elif ad_spec.meta_image_hash:
            creative_result = await self.publisher.create_ad_creative_image(
                ad_account_id=spec.ad_account_id,
                name=f"creative-{ad_spec.name}",
                page_id=spec.page_id,
                image_hash=ad_spec.meta_image_hash,
                primary_text=ad_spec.primary_text,
                headline=ad_spec.headline,
                cta_type=ad_spec.cta_type,
                cta_link=ad_spec.cta_link,
            )
        else:
            raise ValueError(f"Ad '{ad_spec.name}' has no resolved asset")

        creative_id = creative_result.get("id", "dry_run")

        return await self.publisher.create_ad(
            ad_account_id=spec.ad_account_id,
            name=ad_spec.name,
            adset_id=adset_id,
            creative_id=creative_id,
            status=spec.status,
        )

    async def _resolve_asset(
        self, ad_account_id: str, ad_spec: AdSpec
    ) -> None:
        """Ensure ad has a meta_video_id or meta_image_hash. Upload if needed."""
        if ad_spec.meta_video_id or ad_spec.meta_image_hash:
            return

        if not ad_spec.s3_bucket or not ad_spec.s3_key:
            raise ValueError(
                f"Ad '{ad_spec.name}' has no Meta ID and no S3 location"
            )

        result = await self.asset_pipeline.upload_from_s3(
            ad_account_id=ad_account_id,
            bucket=ad_spec.s3_bucket,
            key=ad_spec.s3_key,
            asset_type=ad_spec.asset_type,
            name=ad_spec.name,
        )

        if "video_id" in result:
            ad_spec.meta_video_id = result["video_id"]
        elif "image_hash" in result:
            ad_spec.meta_image_hash = result["image_hash"]

    async def _embed_deployment(
        self, spec: CampaignSpec, result: dict
    ) -> None:
        """Record deployment in vector memory."""
        if not spec.brand_slug:
            return

        summary = (
            f"Deployed campaign '{spec.name}': "
            f"{len(result['ad_sets'])} ad sets, {len(result['ads'])} ads. "
            f"Objective: {spec.objective}, CBO: {spec.cbo_enabled}"
        )

        try:
            await self.vector_store.store_brand_learning(
                brand_slug=spec.brand_slug,
                content=summary,
                learning_type="deployment",
            )
        except Exception as e:
            logger.warning("Failed to embed deployment: {e}", e=e)
