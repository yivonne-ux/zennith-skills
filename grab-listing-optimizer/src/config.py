"""Configuration for GrabFood Listing Optimizer."""

import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# Paths
PROJECT_ROOT = Path(__file__).parent.parent
DATA_DIR = Path(os.getenv("DATA_DIR", PROJECT_ROOT / "data"))
SESSIONS_DIR = Path(os.getenv("SESSIONS_DIR", PROJECT_ROOT / "sessions"))
PHOTOS_DIR = DATA_DIR / "photos"
SCREENSHOTS_DIR = DATA_DIR / "screenshots"
REPORTS_DIR = DATA_DIR / "reports"
DB_PATH = DATA_DIR / "optimizer.db"

# Ensure dirs exist
for d in [DATA_DIR, SESSIONS_DIR, PHOTOS_DIR, SCREENSHOTS_DIR, REPORTS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

# Telegram
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")

# LLM
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")

# Image APIs
FOODSHOT_API_KEY = os.getenv("FOODSHOT_API_KEY", "")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

# Proxy
PROXY_URL = os.getenv("PROXY_URL", "")

# GrabFood URLs (verified via E2E testing 2026-03-23)
GRAB_MERCHANT_URL = "https://merchant.grab.com"
GRAB_MERCHANT_LOGIN = "https://weblogin.grab.com/merchant/login?service_id=MEXUSERS&redirect=https%3A%2F%2Fmerchant.grab.com%2Fportal"
GRAB_MERCHANT_DASHBOARD = f"{GRAB_MERCHANT_URL}/dashboard"
GRAB_MERCHANT_MENU = f"{GRAB_MERCHANT_URL}/food-menu"  # Needs store selected first; actual URL becomes /food/menu/{store_id}
GRAB_MERCHANT_PROMOS = f"{GRAB_MERCHANT_URL}/marketing"
GRAB_MERCHANT_REVIEWS = f"{GRAB_MERCHANT_URL}/feedback"
GRAB_MERCHANT_ANALYTICS = f"{GRAB_MERCHANT_URL}/insights"
GRAB_CONSUMER_URL = "https://food.grab.com/my/en"

# Browser settings
BROWSER_HEADLESS = True
BROWSER_SLOW_MO = 100  # ms between actions
ACTION_DELAY_MIN = 1.0  # seconds
ACTION_DELAY_MAX = 3.0  # seconds
MAX_RETRIES = 3
SCREENSHOT_ON_ERROR = True

# Photo specs (GrabFood requirements)
MENU_PHOTO_SIZE = (800, 800)
BANNER_PHOTO_SIZE = (1200, 400)
PHOTO_FORMAT = "JPEG"
PHOTO_QUALITY = 95
MAX_PHOTO_SIZE_MB = 6

# Exposure boost (Joel's step 3)
EXPOSURE_BOOST = 1.4  # multiply brightness by this factor
WARMTH_SHIFT = 15     # add warmth to red/yellow channels
