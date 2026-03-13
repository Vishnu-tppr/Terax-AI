from __future__ import annotations

import os
from dataclasses import dataclass
from functools import lru_cache

from dotenv import load_dotenv


load_dotenv()


def _split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


@dataclass(frozen=True)
class Settings:
    app_name: str
    environment: str
    host: str
    port: int
    allowed_origins: list[str]
    supabase_url: str
    supabase_anon_key: str
    supabase_service_role_key: str
    password_reset_redirect: str | None


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings(
        app_name=os.getenv("APP_NAME", "Terax AI Supabase Backend"),
        environment=os.getenv("ENVIRONMENT", "development"),
        host=os.getenv("HOST", "0.0.0.0"),
        port=int(os.getenv("PORT", "8000")),
        allowed_origins=_split_csv(
            os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:8000")
        ),
        supabase_url=os.getenv("SUPABASE_URL", "").strip(),
        supabase_anon_key=os.getenv("SUPABASE_ANON_KEY", "").strip(),
        supabase_service_role_key=os.getenv("SUPABASE_SERVICE_ROLE_KEY", "").strip(),
        password_reset_redirect=os.getenv("SUPABASE_PASSWORD_RESET_REDIRECT", "").strip() or None,
    )
