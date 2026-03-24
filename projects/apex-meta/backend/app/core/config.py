"""Pydantic Settings — reads .env, provides typed config to all services."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # App
    app_env: str = "development"
    secret_key: str = "change-me"
    debug: bool = False

    # PostgreSQL
    database_url: str = "postgresql+asyncpg://apex:apex_secret@localhost:5432/apex_meta"

    # Redis / Celery
    redis_url: str = "redis://localhost:6379/0"
    celery_broker_url: str = "redis://localhost:6379/1"
    celery_result_backend: str = "redis://localhost:6379/2"

    # Anthropic
    anthropic_api_key: str = ""
    anthropic_model: str = "claude-sonnet-4-20250514"

    # OpenAI (embeddings)
    openai_api_key: str = ""
    openai_embedding_model: str = "text-embedding-3-large"
    openai_embedding_dims: int = 3072

    # Pinecone
    pinecone_api_key: str = ""
    pinecone_index_name: str = "apex-meta"
    pinecone_index_dims: int = 3072

    # Meta
    meta_app_id: str = ""
    meta_app_secret: str = ""
    meta_graph_api_version: str = "v21.0"
    meta_system_user_token: str = ""
    meta_api_dry_run: bool = True

    # Serper
    serper_api_key: str = ""

    # YouTube
    youtube_api_key: str = ""

    # AWS S3
    aws_access_key_id: str = ""
    aws_secret_access_key: str = ""
    aws_region: str = "ap-southeast-1"
    s3_bucket_creatives: str = "apex-meta-creatives"

    # Deployment safety gates
    deployment_auto_execute: bool = False
    deployment_max_daily_spend_increase_pct: int = 20
    deployment_kill_requires_approval: bool = True
    deployment_new_campaign_requires_approval: bool = True
    deployment_scale_requires_approval: bool = False

    # Default thresholds
    default_roas_target: float = 3.0
    default_cpa_ceiling_multiplier: float = 1.5
    default_ctr_floor: float = 0.01
    default_frequency_ceiling: float = 3.5
    default_hook_rate_floor: float = 0.20
    ab_test_confidence_threshold: float = 0.80

    # RAG
    rag_top_k: int = 10
    rag_similarity_threshold: float = 0.75
    rag_max_context_chunks: int = 5

    @property
    def meta_base_url(self) -> str:
        return f"https://graph.facebook.com/{self.meta_graph_api_version}"

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"


settings = Settings()
