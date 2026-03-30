---
name: Google Drive Desktop Access
description: User has Google Drive Desktop mounted — access GDrive files directly via local filesystem, never ask to download
type: feedback
---

Google Drive is mounted locally via Google Drive Desktop. Access files directly from the filesystem — never ask the user to download or share files manually.

**Why:** User got frustrated repeating this. They use GDrive Desktop for all brand assets.

**How to apply:** When user shares a GDrive link, find the corresponding local path on the filesystem (typically under `/Users/yi-vonnehooi/Library/CloudStorage/GoogleDrive-*/My Drive/` or similar). Search for it if needed.
