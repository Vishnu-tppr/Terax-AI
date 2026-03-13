from __future__ import annotations

from datetime import datetime, timezone

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers.auth import router as auth_router
from app.routers.contacts import router as contacts_router
from app.routers.incidents import router as incidents_router
from app.routers.profile import router as profile_router
from app.supabase_helpers import healthcheck_supabase, require_supabase_config


settings = get_settings()
app = FastAPI(title=settings.app_name, version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup_check() -> None:
    require_supabase_config()


@app.get("/health")
def health() -> dict:
    supabase_ok, detail = healthcheck_supabase()
    return {
        "status": "healthy" if supabase_ok else "degraded",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "environment": settings.environment,
        "services": {
            "supabase": supabase_ok,
        },
        "detail": detail,
    }


app.include_router(auth_router)
app.include_router(profile_router)
app.include_router(contacts_router)
app.include_router(incidents_router)
