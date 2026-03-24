# Apex Meta — API Documentation

Base URL: `http://localhost:8000/api/v1`

---

## Health

### GET /health
```json
// Response 200
{
  "status": "healthy",
  "version": "1.0.0",
  "database": "connected",
  "redis": "connected"
}
```

---

## Brands

### POST /brands/
Create a new brand and seed its vector namespace.
```json
// Request
{
  "name": "Mirra Eats",
  "slug": "mirra",
  "vertical": "food_delivery",
  "meta_ad_account_id": "830110298602617",
  "meta_access_token": "EAAHIW2s...",
  "meta_pixel_id": "123456789",
  "brand_dna": {
    "usp": "Diet bento, not convenient lunch",
    "tone": "girlboss, aspirational",
    "price_point": "RM12-15 per bento"
  },
  "audience_personas": [
    {"name": "Office Girl", "age": "25-35", "interest": "weight loss"}
  ],
  "target_countries": "MY",
  "roas_target": 3.0,
  "cpa_ceiling": 7.00,
  "monthly_budget": 36000
}

// Response 201
{
  "id": "uuid",
  "name": "Mirra Eats",
  "slug": "mirra",
  "vertical": "food_delivery",
  "meta_ad_account_id": "830110298602617",
  "roas_target": 3.0,
  "onboarding_complete": false,
  "created_at": "2026-03-23T..."
}
```

### GET /brands/
```json
// Response 200
[{"id": "uuid", "name": "Mirra Eats", "slug": "mirra", ...}]
```

### GET /brands/{brand_id}
### PATCH /brands/{brand_id}
### DELETE /brands/{brand_id} (soft delete)

### POST /brands/{brand_id}/memory/query
Query the brand's vector memory.
```json
// Request
{
  "query": "What creative formats perform best?",
  "namespaces": ["brand-mirra", "creative-library"],
  "top_k": 5
}

// Response 200
{
  "chunks": [
    {"id": "vec-123", "score": 0.89, "content": "Transformation format RM4.8/WA..."}
  ],
  "formatted_context": "[Source 1 | brand-mirra | relevance: 0.89]\n..."
}
```

---

## Campaigns

### GET /campaigns/{brand_id}
List all campaigns for a brand.

### POST /campaigns/{brand_id}/sync
Pull campaign structure from Meta Graph API into local DB.
```json
// Response 200
{
  "campaigns": 4,
  "ad_sets": 12,
  "ads": 45
}
```

---

## Audit

### POST /audit/{brand_id}/trigger
Manually trigger a forensic audit.
```json
// Request (optional)
{
  "roas_target": 3.0,
  "cpa_ceiling": 7.00
}

// Response 200
{
  "id": "uuid",
  "audit_type": "manual_trigger",
  "severity": "critical",
  "metrics_snapshot": {
    "total_spend_7d": 1808,
    "total_conversions_7d": 266,
    "avg_cpa": 6.80
  },
  "flags_raised": [
    {
      "severity": "RED",
      "entity_type": "ad",
      "entity_name": "KOL-Sunny-V3",
      "metric": "cpa",
      "value": 20.02,
      "message": "Ad CPA RM20.02 is 1.5x above ceiling"
    }
  ],
  "root_cause_analysis": "Budget concentrated on 3 high-CPA video ads...",
  "proposed_actions": [
    {
      "priority": 1,
      "action_type": "kill_ad",
      "entity_id": "120243085921060787",
      "entity_name": "KOL-Sunny-V3",
      "rationale": "RM20.02/convo, zero sales attribution",
      "confidence": 0.92,
      "requires_human_approval": true
    }
  ]
}
```

### GET /audit/{brand_id}/history?limit=20
### GET /audit/{brand_id}/latest

### POST /audit/{brand_id}/actions/{audit_id}/approve
Approve audit actions and create deployment jobs.
```json
// Request (optional — approve specific actions by index)
[0, 1, 3]

// Response 200
{
  "jobs_created": 3,
  "auto_approved": 1,
  "pending_approval": 2
}
```

---

## Strategy

### POST /strategy/{brand_id}/generate
Generate RAG-powered campaign strategy.
```json
// Request
{
  "session_type": "full_strategy",
  "custom_query": "How should we structure campaigns for RM1200/day budget?",
  "include_research": true
}

// Response 200
{
  "id": "uuid",
  "session_type": "full_strategy",
  "strategy_proposal": "Based on your brand's performance history...",
  "action_plan": [
    {
      "priority": 1,
      "type": "restructure",
      "description": "Consolidate to 3 campaigns: WINNERS-EN, WINNERS-CN, RETARGET",
      "expected_impact": "Reduce CPA by 20-30%"
    }
  ],
  "llm_tokens_used": 3500
}
```

### GET /strategy/{brand_id}/sessions?limit=10

---

## Research

### POST /research/trigger
Manually trigger Midnight Scholar pipeline.
```json
// Response 200
{"task_id": "celery-task-id", "status": "started"}
```

### GET /research/status/{task_id}
```json
// Response 200
{
  "task_id": "celery-task-id",
  "status": "SUCCESS",
  "result": {"web": 18, "youtube": 9, "rss": 9, "embedded": 12}
}
```

---

## Reports

### GET /reports/{brand_id}/weekly
```json
// Response 200
{
  "brand_id": "uuid",
  "period": "2026-03-16 to 2026-03-23",
  "total_spend": 1808.50,
  "total_conversions": 266,
  "avg_cpa": 6.80,
  "top_performers": [
    {"ad_name": "S19-Transformation", "spend": 234, "conversions": 66, "cpa": 3.55}
  ],
  "flags_summary": {"red": 4, "orange": 7, "yellow": 3},
  "recommendations": ["Average CPA exceeds ceiling. Review underperformers."]
}
```

---

## Deployment

### GET /deployment/{brand_id}/assets?status=ready
List creative assets.

### POST /deployment/{brand_id}/assets/register
Register a new creative asset.
```json
// Request
{
  "name": "S19-Transformation-OfficeOutfit",
  "asset_type": "image",
  "s3_bucket": "apex-meta-creatives",
  "s3_key": "mirra/statics/S19.png",
  "angle_type": "transformation",
  "hook_text": "she dropped a size"
}

// Response 201
{"id": "uuid", "name": "S19-Transformation-OfficeOutfit", "status": "pending", ...}
```

### POST /deployment/{brand_id}/assets/{asset_id}/upload
Trigger S3 → Meta upload.
```json
// Response 200
{"task_id": "celery-task-id", "status": "upload_queued"}
```

### PATCH /deployment/{brand_id}/assets/{asset_id}/approve?approved=true
Human approval gate for creative.

### GET /deployment/{brand_id}/assets/s3/browse?prefix=mirra/
Browse S3 bucket.

### POST /deployment/{brand_id}/campaigns/launch
Build and launch a full campaign.
```json
// Request
{
  "name": "MIRRA-WINNERS-EN-MAR26",
  "objective": "OUTCOME_SALES",
  "daily_budget": 400,
  "cbo_enabled": true,
  "page_id": "318283048041590",
  "auto_activate": false,
  "ad_sets": [
    {
      "name": "EN-TOP-PERFORMERS",
      "daily_budget": 400,
      "optimization_goal": "CONVERSATIONS",
      "targeting": {"geo_locations": {"countries": ["MY"]}},
      "ads": [
        {
          "name": "S19-Transformation",
          "asset_type": "image",
          "meta_image_hash": "abc123",
          "primary_text": "she dropped a size. kept every lunch.",
          "headline": "Under 500kcal bento"
        }
      ]
    }
  ]
}

// Response 200
{
  "campaign": {"id": "120243..."},
  "ad_sets": [{"id": "120243..."}],
  "ads": [{"id": "120243..."}],
  "errors": []
}
```

### POST /deployment/{brand_id}/execute-audit/{audit_id}
Create deployment jobs from audit actions.

### GET /deployment/{brand_id}/jobs?status=pending_approval
List deployment jobs.

### POST /deployment/{brand_id}/jobs/{job_id}/decision
Approve or reject a job.
```json
// Request
{"decision": "approve", "reason": null}

// Response 200
{"status": "executed", "result": {"id": "120243..."}}
```

### POST /deployment/{brand_id}/jobs/{job_id}/rollback
Rollback a completed job.
```json
// Response 200
{"status": "rolled_back", "rollback_job_id": "uuid"}
```

---

## Authentication
Currently no auth middleware. For production, add JWT or API key auth to all endpoints.

## Rate Limiting
Meta API calls are rate-limited at 0.5s between requests with exponential backoff on codes 4, 17, 32, 613.

## Dry Run Mode
Set `META_API_DRY_RUN=true` in .env to prevent all Meta write operations. All mutations will be logged but not executed.
