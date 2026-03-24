"""Forensic Audit Engine — 6-hour automated campaign analysis.

Pull live Meta insights → compute metrics → apply threshold rules →
query Vector DB for context → LLM forensic reasoning → structured report.
"""

import json
import uuid
from datetime import datetime, timezone
from typing import Any

import anthropic
from loguru import logger
from scipy import stats

from app.core.config import settings
from app.core.exceptions import AuditError
from app.services.meta_api.client import MetaAPIClient
from app.services.memory.vector_store import (
    VectorStore,
    NS_CAMPAIGN_PATTERNS,
    NS_META_PLATFORM,
    brand_namespace,
)


class AuditFlag:
    """Single audit flag with severity and metadata."""

    def __init__(
        self,
        severity: str,
        entity_type: str,
        entity_id: str,
        entity_name: str,
        metric: str,
        value: float,
        threshold: float,
        message: str,
    ):
        self.severity = severity
        self.entity_type = entity_type
        self.entity_id = entity_id
        self.entity_name = entity_name
        self.metric = metric
        self.value = value
        self.threshold = threshold
        self.message = message

    def to_dict(self) -> dict:
        return {
            "severity": self.severity,
            "entity_type": self.entity_type,
            "entity_id": self.entity_id,
            "entity_name": self.entity_name,
            "metric": self.metric,
            "value": self.value,
            "threshold": self.threshold,
            "message": self.message,
        }


class ForensicAuditEngine:
    """Automated forensic audit engine — runs every 6 hours per brand."""

    def __init__(self, brand_slug: str, ad_account_id: str, access_token: str | None = None):
        self.brand_slug = brand_slug
        self.ad_account_id = ad_account_id
        self.meta_client = MetaAPIClient(access_token=access_token)
        self.vector_store = VectorStore()
        self.flags: list[AuditFlag] = []

    async def run(
        self,
        roas_target: float | None = None,
        cpa_ceiling: float | None = None,
    ) -> dict:
        """Execute full forensic audit."""
        logger.info("Starting forensic audit for {brand}", brand=self.brand_slug)
        roas_target = roas_target or settings.default_roas_target
        cpa_ceiling_mult = settings.default_cpa_ceiling_multiplier

        try:
            campaign_data = await self._pull_campaign_data()
            adset_data = await self._pull_adset_data()
            ad_data = await self._pull_ad_data()

            self._audit_campaigns(campaign_data, roas_target)
            self._audit_adsets(adset_data, roas_target)
            self._audit_ads(ad_data, roas_target, cpa_ceiling)
            scale_ops = self._find_scale_opportunities(ad_data, roas_target)

            rag_context = await self._get_rag_context()
            report = await self._llm_forensic_reasoning(rag_context, scale_ops)
            report["flags"] = [f.to_dict() for f in self.flags]
            report["metrics_snapshot"] = self._build_snapshot(
                campaign_data, adset_data, ad_data
            )

            await self._embed_findings(report)
            logger.info(
                "Audit complete for {brand}: {n} flags",
                brand=self.brand_slug,
                n=len(self.flags),
            )
            return report

        except Exception as e:
            raise AuditError(f"Forensic audit failed: {e}")
        finally:
            await self.meta_client.close()

    async def _pull_campaign_data(self) -> list[dict]:
        campaigns = await self.meta_client.get_campaigns(self.ad_account_id)
        insights = await self.meta_client.get_campaign_insights(
            f"act_{self.ad_account_id}", level="campaign", date_preset="last_7d"
        )
        return self._merge_entity_insights(campaigns, insights, "campaign_id")

    async def _pull_adset_data(self) -> list[dict]:
        adsets = await self.meta_client.get_ad_sets(self.ad_account_id)
        insights = await self.meta_client.get_campaign_insights(
            f"act_{self.ad_account_id}", level="adset", date_preset="last_7d"
        )
        return self._merge_entity_insights(adsets, insights, "adset_id")

    async def _pull_ad_data(self) -> list[dict]:
        ads = await self.meta_client.get_ads(self.ad_account_id)
        insights = await self.meta_client.get_campaign_insights(
            f"act_{self.ad_account_id}", level="ad", date_preset="last_7d"
        )
        return self._merge_entity_insights(ads, insights, "ad_id")

    def _merge_entity_insights(
        self, entities: list[dict], insights: list[dict], id_field: str
    ) -> list[dict]:
        insight_map = {i.get(id_field): i for i in insights}
        for entity in entities:
            eid = entity.get("id")
            if eid and eid in insight_map:
                entity["insights"] = insight_map[eid]
        return entities

    def _parse_metric(self, insights: dict, key: str, default: float = 0.0) -> float:
        val = insights.get(key, default)
        try:
            return float(val)
        except (TypeError, ValueError):
            return default

    def _parse_conversions(self, insights: dict) -> int:
        actions = insights.get("actions", [])
        for action in actions:
            if action.get("action_type") in (
                "onsite_conversion.messaging_conversation_started_7d",
                "offsite_conversion.fb_pixel_purchase",
                "onsite_conversion.lead_grouped",
            ):
                return int(action.get("value", 0))
        return 0

    def _parse_conv_value(self, insights: dict) -> float:
        values = insights.get("action_values", [])
        for val in values:
            if val.get("action_type") == "offsite_conversion.fb_pixel_purchase":
                return float(val.get("value", 0))
        return 0.0

    def _compute_cpa(self, spend: float, conversions: int) -> float | None:
        if conversions == 0:
            return None
        return spend / conversions

    def _compute_roas(self, revenue: float, spend: float) -> float | None:
        if spend == 0:
            return None
        return revenue / spend

    def _compute_hook_rate(self, insights: dict) -> float | None:
        impressions = self._parse_metric(insights, "impressions")
        views_3s = 0
        for action in insights.get("video_30_sec_watched_actions", []):
            views_3s += int(action.get("value", 0))
        if impressions == 0:
            return None
        return views_3s / impressions

    def _compute_hold_rate(self, insights: dict) -> float | None:
        views_3s = sum(
            int(a.get("value", 0))
            for a in insights.get("video_30_sec_watched_actions", [])
        )
        thruplays = sum(
            int(a.get("value", 0))
            for a in insights.get("video_thruplay_watched_actions", [])
        )
        if views_3s == 0:
            return None
        return thruplays / views_3s

    def _audit_campaigns(self, campaigns: list[dict], roas_target: float) -> None:
        for c in campaigns:
            if c.get("effective_status") != "ACTIVE":
                continue
            ins = c.get("insights", {})
            spend = self._parse_metric(ins, "spend")
            conversions = self._parse_conversions(ins)
            cpa = self._compute_cpa(spend, conversions)
            if cpa and cpa > roas_target * 5:
                self.flags.append(AuditFlag(
                    severity="RED",
                    entity_type="campaign",
                    entity_id=c["id"],
                    entity_name=c.get("name", ""),
                    metric="cpa",
                    value=cpa,
                    threshold=roas_target * 5,
                    message=f"Campaign CPA RM{cpa:.2f} exceeds threshold",
                ))

    def _audit_adsets(self, adsets: list[dict], roas_target: float) -> None:
        for a in adsets:
            if a.get("status") != "ACTIVE":
                continue
            ins = a.get("insights", {})
            frequency = self._parse_metric(ins, "frequency")
            if frequency > settings.default_frequency_ceiling:
                self.flags.append(AuditFlag(
                    severity="ORANGE",
                    entity_type="adset",
                    entity_id=a["id"],
                    entity_name=a.get("name", ""),
                    metric="frequency",
                    value=frequency,
                    threshold=settings.default_frequency_ceiling,
                    message=f"Ad set frequency {frequency:.1f} indicates audience fatigue",
                ))
            learning = a.get("learning_phase_info", {})
            if learning.get("status") == "LEARNING_LIMITED":
                self.flags.append(AuditFlag(
                    severity="ORANGE",
                    entity_type="adset",
                    entity_id=a["id"],
                    entity_name=a.get("name", ""),
                    metric="learning_phase",
                    value=0,
                    threshold=0,
                    message="Ad set stuck in LEARNING_LIMITED — not enough conversions",
                ))

    def _audit_ads(
        self, ads: list[dict], roas_target: float, cpa_ceiling: float | None
    ) -> None:
        for ad in ads:
            if ad.get("effective_status") != "ACTIVE":
                continue
            ins = ad.get("insights", {})
            spend = self._parse_metric(ins, "spend")
            impressions = self._parse_metric(ins, "impressions")
            ctr = self._parse_metric(ins, "ctr")
            conversions = self._parse_conversions(ins)
            cpa = self._compute_cpa(spend, conversions)

            if cpa and cpa_ceiling and cpa > cpa_ceiling * 1.5:
                self.flags.append(AuditFlag(
                    severity="RED",
                    entity_type="ad",
                    entity_id=ad["id"],
                    entity_name=ad.get("name", ""),
                    metric="cpa",
                    value=cpa,
                    threshold=cpa_ceiling * 1.5,
                    message=f"Ad CPA RM{cpa:.2f} is 1.5x above ceiling",
                ))

            if spend > (cpa_ceiling or 15) * 3 and conversions == 0:
                self.flags.append(AuditFlag(
                    severity="RED",
                    entity_type="ad",
                    entity_id=ad["id"],
                    entity_name=ad.get("name", ""),
                    metric="zero_conversions",
                    value=spend,
                    threshold=(cpa_ceiling or 15) * 3,
                    message=f"Ad spent RM{spend:.2f} with ZERO conversions",
                ))

            if impressions > 1000 and ctr < 0.005:
                self.flags.append(AuditFlag(
                    severity="RED",
                    entity_type="ad",
                    entity_id=ad["id"],
                    entity_name=ad.get("name", ""),
                    metric="ctr",
                    value=ctr,
                    threshold=0.005,
                    message=f"Ad CTR {ctr:.4f} critically low after {impressions:.0f} impressions",
                ))
            elif impressions > 1000 and ctr < 0.01:
                self.flags.append(AuditFlag(
                    severity="ORANGE",
                    entity_type="ad",
                    entity_id=ad["id"],
                    entity_name=ad.get("name", ""),
                    metric="ctr",
                    value=ctr,
                    threshold=0.01,
                    message=f"Ad CTR {ctr:.4f} below floor",
                ))

            hook_rate = self._compute_hook_rate(ins)
            if hook_rate is not None and hook_rate < settings.default_hook_rate_floor:
                self.flags.append(AuditFlag(
                    severity="YELLOW",
                    entity_type="ad",
                    entity_id=ad["id"],
                    entity_name=ad.get("name", ""),
                    metric="hook_rate",
                    value=hook_rate,
                    threshold=settings.default_hook_rate_floor,
                    message=f"Video hook rate {hook_rate:.1%} below {settings.default_hook_rate_floor:.0%}",
                ))

    def _find_scale_opportunities(
        self, ads: list[dict], roas_target: float
    ) -> list[dict]:
        opportunities = []
        for ad in ads:
            if ad.get("effective_status") != "ACTIVE":
                continue
            ins = ad.get("insights", {})
            spend = self._parse_metric(ins, "spend")
            frequency = self._parse_metric(ins, "frequency")
            conversions = self._parse_conversions(ins)
            revenue = self._parse_conv_value(ins)
            roas = self._compute_roas(revenue, spend)

            if (
                roas
                and roas > roas_target * 1.2
                and frequency < 2.5
                and conversions >= 10
            ):
                opportunities.append({
                    "entity_id": ad["id"],
                    "entity_name": ad.get("name", ""),
                    "roas": roas,
                    "conversions": conversions,
                    "frequency": frequency,
                })
        return opportunities

    def _build_snapshot(
        self,
        campaigns: list[dict],
        adsets: list[dict],
        ads: list[dict],
    ) -> dict:
        total_spend = sum(
            self._parse_metric(c.get("insights", {}), "spend")
            for c in campaigns
        )
        total_conversions = sum(
            self._parse_conversions(c.get("insights", {}))
            for c in campaigns
        )
        return {
            "total_campaigns": len(campaigns),
            "total_adsets": len(adsets),
            "total_ads": len(ads),
            "total_spend_7d": total_spend,
            "total_conversions_7d": total_conversions,
            "avg_cpa": total_spend / total_conversions if total_conversions else None,
            "flags_red": len([f for f in self.flags if f.severity == "RED"]),
            "flags_orange": len([f for f in self.flags if f.severity == "ORANGE"]),
            "flags_yellow": len([f for f in self.flags if f.severity == "YELLOW"]),
            "timestamp": datetime.now(timezone.utc).isoformat(),
        }

    async def _get_rag_context(self) -> str:
        query = f"forensic audit findings for {self.brand_slug} campaign performance"
        chunks = await self.vector_store.retrieve_multi_namespace(
            query=query,
            namespaces=[
                brand_namespace(self.brand_slug),
                NS_CAMPAIGN_PATTERNS,
                NS_META_PLATFORM,
            ],
        )
        return self.vector_store.format_context_for_llm(chunks)

    async def _llm_forensic_reasoning(
        self, rag_context: str, scale_ops: list[dict]
    ) -> dict:
        if not settings.anthropic_api_key:
            return self._fallback_report(scale_ops)

        client = anthropic.AsyncAnthropic(api_key=settings.anthropic_api_key)
        flags_text = "\n".join(
            f"[{f.severity}] {f.entity_type} '{f.entity_name}' — {f.message}"
            for f in self.flags
        )
        scale_text = "\n".join(
            f"SCALE: '{s['entity_name']}' ROAS={s['roas']:.2f}, {s['conversions']} conversions"
            for s in scale_ops
        )

        prompt = f"""You are a forensic Meta Ads auditor. Analyze these findings and provide structured recommendations.

## Flags Raised
{flags_text or "No flags raised."}

## Scale Opportunities
{scale_text or "No scale opportunities found."}

## Historical Context (from vector memory)
{rag_context}

Provide your analysis as JSON with these fields:
- "root_cause_analysis": string (2-3 sentences explaining WHY performance is this way)
- "proposed_actions": array of objects, each with:
  - "priority": 1-5 (1=most urgent)
  - "action_type": "kill_ad" | "pause_adset" | "scale_budget" | "pause_campaign" | "launch_ad"
  - "entity_id": string
  - "entity_name": string
  - "rationale": string
  - "expected_impact": string
  - "confidence": float 0-1
  - "requires_human_approval": boolean
- "compounding_insight": string (what should be remembered for future audits)

Return ONLY the JSON object."""

        try:
            response = await client.messages.create(
                model=settings.anthropic_model,
                max_tokens=4096,
                messages=[{"role": "user", "content": prompt}],
            )
            text = response.content[0].text.strip()
            start = text.find("{")
            end = text.rfind("}") + 1
            if start >= 0 and end > start:
                report = json.loads(text[start:end])
                report["llm_tokens_used"] = response.usage.input_tokens + response.usage.output_tokens
                return report
        except Exception as e:
            logger.error("LLM forensic reasoning failed: {e}", e=e)

        return self._fallback_report(scale_ops)

    def _fallback_report(self, scale_ops: list[dict]) -> dict:
        actions = []
        for f in self.flags:
            if f.severity == "RED" and f.entity_type == "ad":
                actions.append({
                    "priority": 1,
                    "action_type": "kill_ad",
                    "entity_id": f.entity_id,
                    "entity_name": f.entity_name,
                    "rationale": f.message,
                    "expected_impact": "Stop budget waste",
                    "confidence": 0.85,
                    "requires_human_approval": True,
                })
        for s in scale_ops:
            actions.append({
                "priority": 3,
                "action_type": "scale_budget",
                "entity_id": s["entity_id"],
                "entity_name": s["entity_name"],
                "rationale": f"ROAS {s['roas']:.2f}x, {s['conversions']} conversions, frequency {s['frequency']:.1f}",
                "expected_impact": "Increase revenue from proven winner",
                "confidence": 0.75,
                "requires_human_approval": False,
            })
        return {
            "root_cause_analysis": "Automated analysis — LLM unavailable",
            "proposed_actions": actions,
            "compounding_insight": f"Audit found {len(self.flags)} flags, {len(scale_ops)} scale opportunities",
            "llm_tokens_used": 0,
        }

    async def _embed_findings(self, report: dict) -> None:
        insight = report.get("compounding_insight", "")
        if insight:
            await self.vector_store.store_brand_learning(
                brand_slug=self.brand_slug,
                content=f"Forensic audit {datetime.now(timezone.utc).isoformat()}: {insight}",
                learning_type="audit_finding",
            )

    @staticmethod
    def ab_test_significance(
        control_conversions: int,
        control_impressions: int,
        variant_conversions: int,
        variant_impressions: int,
    ) -> dict:
        """Z-test for conversion rate significance."""
        if control_impressions == 0 or variant_impressions == 0:
            return {"significant": False, "p_value": 1.0, "confidence": 0.0}

        p_c = control_conversions / control_impressions
        p_v = variant_conversions / variant_impressions
        p_pool = (control_conversions + variant_conversions) / (
            control_impressions + variant_impressions
        )

        if p_pool == 0 or p_pool == 1:
            return {"significant": False, "p_value": 1.0, "confidence": 0.0}

        se = (p_pool * (1 - p_pool) * (1 / control_impressions + 1 / variant_impressions)) ** 0.5
        if se == 0:
            return {"significant": False, "p_value": 1.0, "confidence": 0.0}

        z = (p_v - p_c) / se
        p_value = 2 * (1 - stats.norm.cdf(abs(z)))
        confidence = 1 - p_value

        return {
            "significant": confidence >= settings.ab_test_confidence_threshold,
            "p_value": round(p_value, 4),
            "confidence": round(confidence, 4),
            "z_score": round(z, 4),
            "control_rate": round(p_c, 6),
            "variant_rate": round(p_v, 6),
            "winner": "variant" if p_v > p_c and confidence >= settings.ab_test_confidence_threshold else "control" if p_c > p_v and confidence >= settings.ab_test_confidence_threshold else "inconclusive",
        }
