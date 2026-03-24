"""Custom exceptions for Apex Meta."""


class ApexMetaError(Exception):
    """Base exception for all Apex Meta errors."""

    def __init__(self, message: str, detail: str | None = None):
        self.message = message
        self.detail = detail
        super().__init__(self.message)


class MetaAPIError(ApexMetaError):
    """Meta Graph API returned an error."""

    def __init__(self, message: str, error_code: int | None = None, error_subcode: int | None = None):
        self.error_code = error_code
        self.error_subcode = error_subcode
        super().__init__(message, detail=f"code={error_code}, subcode={error_subcode}")


class MetaRateLimitError(MetaAPIError):
    """Meta API rate limit hit — should trigger backoff."""
    pass


class MetaDryRunError(ApexMetaError):
    """Attempted a write operation while META_API_DRY_RUN=true."""
    pass


class VectorStoreError(ApexMetaError):
    """Pinecone or embedding error."""
    pass


class DeploymentSafetyError(ApexMetaError):
    """Deployment safety gate blocked the operation."""

    def __init__(self, message: str, gate: str):
        self.gate = gate
        super().__init__(message, detail=f"gate={gate}")


class BrandNotFoundError(ApexMetaError):
    """Requested brand does not exist."""
    pass


class AssetUploadError(ApexMetaError):
    """S3 or Meta asset upload failed."""
    pass


class AuditError(ApexMetaError):
    """Forensic audit encountered an error."""
    pass


class ResearchError(ApexMetaError):
    """Midnight Scholar research pipeline error."""
    pass
