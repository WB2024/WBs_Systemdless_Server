"""
WB's Systemdless Server — FastAPI application entrypoint.

Mounts all routes and serves Jinja2 templates.
No systemd, no logind, no heavy framework.

Repository: https://github.com/WB2024/WBs_Systemdless_Server
"""
from __future__ import annotations

import logging
import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from app.routes import register_routes

# ---------------------------------------------------------------------------
# Load environment from .env file (must be present in the working directory)
# ---------------------------------------------------------------------------
load_dotenv()

# ---------------------------------------------------------------------------
# Logging — flat file, no journald
# ---------------------------------------------------------------------------
log_level = os.getenv("WBS_LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, log_level, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(
    title=os.getenv("WBS_APP_TITLE", "WB's Systemdless Server"),
    description="Headless NAS management UI — Devuan + OpenRC",
    version="0.1.0",
    # Disable OpenAPI/Swagger UI in production if desired
    docs_url="/api/docs" if os.getenv("WBS_DEBUG", "false").lower() == "true" else None,
    redoc_url=None,
)

# ---------------------------------------------------------------------------
# Templates
# ---------------------------------------------------------------------------
TEMPLATES_DIR = Path(__file__).parent / "templates"
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))

# ---------------------------------------------------------------------------
# Static files (served at /static/ — CSS, JS, images)
# ---------------------------------------------------------------------------
STATIC_DIR = Path(__file__).parent / "static"
if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# ---------------------------------------------------------------------------
# Register API routes from app/routes/
# ---------------------------------------------------------------------------
register_routes(app)

# ---------------------------------------------------------------------------
# Root route — serve the main dashboard template
# ---------------------------------------------------------------------------
@app.get("/", response_class=HTMLResponse)
async def index(request: Request) -> HTMLResponse:
    """Serve the main dashboard page."""
    return templates.TemplateResponse(
        "index.html",
        {
            "request": request,
            "title": os.getenv("WBS_APP_TITLE", "WB's Systemdless Server"),
            "pool_path": os.getenv("WBS_POOL_PATH", "/srv/pool"),
        },
    )

# ---------------------------------------------------------------------------
# Health check endpoint (used by reverse proxy and monitoring)
# ---------------------------------------------------------------------------
@app.get("/api/health")
async def health() -> dict[str, str]:
    """Basic health check — returns 200 if the app is running."""
    return {"status": "ok"}


logger.info("WB's Systemdless Server web UI started.")
