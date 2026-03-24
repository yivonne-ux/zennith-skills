"""Asset Pipeline — S3 download → Meta upload (resumable video protocol)."""

import asyncio
import io
import math
from typing import Any

import aioboto3
import httpx
from loguru import logger

from app.core.config import settings
from app.core.exceptions import AssetUploadError

CHUNK_SIZE = 10 * 1024 * 1024  # 10MB chunks for resumable upload
VIDEO_POLL_INTERVAL = 5  # seconds
VIDEO_POLL_MAX_ATTEMPTS = 60  # 5 minutes max wait


class AssetPipeline:
    """S3 ↔ Meta asset management with resumable video upload."""

    def __init__(self, access_token: str | None = None):
        self.access_token = access_token or settings.meta_system_user_token
        self.base_url = settings.meta_base_url
        self._http: httpx.AsyncClient | None = None

    async def _get_http(self) -> httpx.AsyncClient:
        if self._http is None or self._http.is_closed:
            self._http = httpx.AsyncClient(timeout=120.0)
        return self._http

    async def close(self) -> None:
        if self._http and not self._http.is_closed:
            await self._http.aclose()

    def _s3_session(self) -> aioboto3.Session:
        return aioboto3.Session(
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_region,
        )

    async def download_from_s3(self, bucket: str, key: str) -> bytes:
        """Download a file from S3 into memory."""
        session = self._s3_session()
        async with session.client("s3") as s3:
            try:
                response = await s3.get_object(Bucket=bucket, Key=key)
                data = await response["Body"].read()
                logger.info(
                    "Downloaded {key} from S3 ({size} bytes)",
                    key=key,
                    size=len(data),
                )
                return data
            except Exception as e:
                raise AssetUploadError(f"S3 download failed: {e}")

    async def list_s3_assets(
        self, bucket: str, prefix: str = ""
    ) -> list[dict[str, Any]]:
        """List objects in an S3 bucket/prefix."""
        session = self._s3_session()
        items: list[dict] = []
        async with session.client("s3") as s3:
            paginator = s3.get_paginator("list_objects_v2")
            async for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
                for obj in page.get("Contents", []):
                    items.append({
                        "key": obj["Key"],
                        "size": obj["Size"],
                        "last_modified": obj["LastModified"].isoformat(),
                    })
        return items

    async def generate_presigned_url(
        self, bucket: str, key: str, expires_in: int = 3600
    ) -> str:
        """Generate a presigned URL for temporary access."""
        session = self._s3_session()
        async with session.client("s3") as s3:
            url = await s3.generate_presigned_url(
                "get_object",
                Params={"Bucket": bucket, "Key": key},
                ExpiresIn=expires_in,
            )
            return url

    async def upload_image_to_meta(
        self, ad_account_id: str, image_data: bytes, filename: str
    ) -> str:
        """Upload image to Meta → returns image hash."""
        if settings.meta_api_dry_run:
            logger.warning("DRY_RUN: Would upload image {f}", f=filename)
            return "dry_run_hash"

        http = await self._get_http()
        url = f"{self.base_url}/act_{ad_account_id}/adimages"

        files = {"filename": (filename, io.BytesIO(image_data), "image/png")}
        data = {"access_token": self.access_token}

        resp = await http.post(url, data=data, files=files)
        result = resp.json()

        if "error" in result:
            raise AssetUploadError(f"Image upload failed: {result['error']}")

        images = result.get("images", {})
        for img_data in images.values():
            image_hash = img_data.get("hash")
            logger.info("Uploaded image {f} → hash={h}", f=filename, h=image_hash)
            return image_hash

        raise AssetUploadError("No image hash returned from Meta")

    async def upload_video_to_meta(
        self, ad_account_id: str, video_data: bytes, title: str
    ) -> str:
        """3-phase resumable video upload to Meta → returns video_id."""
        if settings.meta_api_dry_run:
            logger.warning("DRY_RUN: Would upload video {t}", t=title)
            return "dry_run_video_id"

        file_size = len(video_data)
        http = await self._get_http()

        # Phase 1: Start
        video_id = await self._video_upload_start(
            http, ad_account_id, file_size
        )

        # Phase 2: Transfer chunks
        await self._video_upload_transfer(
            http, video_id, video_data, file_size
        )

        # Phase 3: Finish and poll
        await self._video_upload_finish(http, video_id)
        await self._poll_video_ready(http, video_id)

        logger.info(
            "Video upload complete: {t} → {vid}",
            t=title,
            vid=video_id,
        )
        return video_id

    async def _video_upload_start(
        self, http: httpx.AsyncClient, ad_account_id: str, file_size: int
    ) -> str:
        url = f"{self.base_url}/act_{ad_account_id}/advideos"
        resp = await http.post(
            url,
            data={
                "access_token": self.access_token,
                "upload_phase": "start",
                "file_size": str(file_size),
            },
        )
        result = resp.json()
        if "error" in result:
            raise AssetUploadError(f"Video start failed: {result['error']}")

        video_id = result.get("video_id")
        if not video_id:
            raise AssetUploadError("No video_id returned from start phase")

        logger.debug("Video upload started: {vid}", vid=video_id)
        return video_id

    async def _video_upload_transfer(
        self,
        http: httpx.AsyncClient,
        video_id: str,
        video_data: bytes,
        file_size: int,
    ) -> None:
        num_chunks = math.ceil(file_size / CHUNK_SIZE)
        offset = 0

        for i in range(num_chunks):
            chunk = video_data[offset : offset + CHUNK_SIZE]
            url = f"{self.base_url}/{video_id}"

            files = {"video_file_chunk": (f"chunk_{i}", io.BytesIO(chunk))}
            data = {
                "access_token": self.access_token,
                "upload_phase": "transfer",
                "start_offset": str(offset),
            }

            resp = await http.post(url, data=data, files=files)
            result = resp.json()
            if "error" in result:
                raise AssetUploadError(
                    f"Video transfer chunk {i}/{num_chunks} failed: {result['error']}"
                )

            offset += len(chunk)
            logger.debug(
                "Video chunk {i}/{n} uploaded ({pct:.0f}%)",
                i=i + 1,
                n=num_chunks,
                pct=(offset / file_size) * 100,
            )

    async def _video_upload_finish(
        self, http: httpx.AsyncClient, video_id: str
    ) -> None:
        url = f"{self.base_url}/{video_id}"
        resp = await http.post(
            url,
            data={
                "access_token": self.access_token,
                "upload_phase": "finish",
            },
        )
        result = resp.json()
        if "error" in result:
            raise AssetUploadError(f"Video finish failed: {result['error']}")
        logger.debug("Video upload finish phase complete: {vid}", vid=video_id)

    async def _poll_video_ready(
        self, http: httpx.AsyncClient, video_id: str
    ) -> None:
        url = f"{self.base_url}/{video_id}"
        for attempt in range(VIDEO_POLL_MAX_ATTEMPTS):
            resp = await http.get(
                url,
                params={
                    "access_token": self.access_token,
                    "fields": "status",
                },
            )
            result = resp.json()
            status = result.get("status", {})
            video_status = status.get("video_status")

            if video_status == "ready":
                logger.info("Video {vid} is ready", vid=video_id)
                return
            elif video_status == "error":
                raise AssetUploadError(
                    f"Video processing failed: {status.get('processing_phase', {})}"
                )

            logger.debug(
                "Video {vid} status: {s}, polling... ({a}/{m})",
                vid=video_id,
                s=video_status,
                a=attempt + 1,
                m=VIDEO_POLL_MAX_ATTEMPTS,
            )
            await asyncio.sleep(VIDEO_POLL_INTERVAL)

        raise AssetUploadError(
            f"Video {video_id} not ready after {VIDEO_POLL_MAX_ATTEMPTS * VIDEO_POLL_INTERVAL}s"
        )

    async def upload_from_s3(
        self, ad_account_id: str, bucket: str, key: str, asset_type: str, name: str
    ) -> dict:
        """Download from S3 and upload to Meta. Returns video_id or image_hash."""
        data = await self.download_from_s3(bucket, key)

        if asset_type == "video":
            video_id = await self.upload_video_to_meta(ad_account_id, data, name)
            return {"video_id": video_id}
        else:
            filename = key.split("/")[-1]
            image_hash = await self.upload_image_to_meta(
                ad_account_id, data, filename
            )
            return {"image_hash": image_hash}
