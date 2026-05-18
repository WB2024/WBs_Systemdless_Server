"""
app/routes/__init__.py

Route registration for WB's Systemdless Server web UI.
Import and include all APIRouter instances here.

Add new route modules by:
1. Creating app/routes/<module>.py with an APIRouter
2. Importing the router here
3. Calling app.include_router(router, prefix="/api/<module>")
"""
from __future__ import annotations

from fastapi import FastAPI


def register_routes(app: FastAPI) -> None:
    """Register all API routers with the FastAPI app."""

    # TODO: import and register route modules as they are created
    # Example:
    #   from app.routes.storage import router as storage_router
    #   app.include_router(storage_router, prefix="/api/storage", tags=["storage"])
    #
    #   from app.routes.services import router as services_router
    #   app.include_router(services_router, prefix="/api/services", tags=["services"])
    #
    #   from app.routes.system import router as system_router
    #   app.include_router(system_router, prefix="/api/system", tags=["system"])

    pass  # Remove this once real routes are registered
