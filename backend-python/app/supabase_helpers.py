from __future__ import annotations

from datetime import datetime, timezone
from functools import lru_cache
from typing import Any

from supabase import Client, create_client
from supabase.client import ClientOptions

from app.config import get_settings


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def get_attr(source: Any, key: str, default: Any = None) -> Any:
    if source is None:
        return default
    if isinstance(source, dict):
        return source.get(key, default)
    return getattr(source, key, default)


def coerce_dict(value: Any) -> dict[str, Any]:
    if value is None:
        return {}
    if isinstance(value, dict):
        return value
    if hasattr(value, "model_dump"):
        return value.model_dump()
    if hasattr(value, "__dict__"):
        return {
            key: item
            for key, item in vars(value).items()
            if not key.startswith("_")
        }
    return {}


def extract_data(response: Any) -> Any:
    if response is None:
        return None
    if isinstance(response, dict):
        return response.get("data")
    return getattr(response, "data", None)


def extract_first(response: Any) -> dict[str, Any] | None:
    data = extract_data(response)
    if isinstance(data, list):
        return data[0] if data else None
    if isinstance(data, dict):
        return data
    return None


def create_public_client() -> Client:
    settings = get_settings()
    return create_client(
        settings.supabase_url,
        settings.supabase_anon_key,
        options=ClientOptions(auto_refresh_token=False, persist_session=False),
    )


@lru_cache(maxsize=1)
def get_admin_client() -> Client:
    settings = get_settings()
    return create_client(
        settings.supabase_url,
        settings.supabase_service_role_key,
        options=ClientOptions(auto_refresh_token=False, persist_session=False),
    )


def require_supabase_config() -> None:
    settings = get_settings()
    missing = []
    if not settings.supabase_url:
        missing.append("SUPABASE_URL")
    if not settings.supabase_anon_key:
        missing.append("SUPABASE_ANON_KEY")
    if not settings.supabase_service_role_key:
        missing.append("SUPABASE_SERVICE_ROLE_KEY")
    if missing:
        raise RuntimeError(f"Missing Supabase configuration: {', '.join(missing)}")


def fetch_profile(user_id: str) -> dict[str, Any] | None:
    response = (
        get_admin_client()
        .table("profiles")
        .select("*")
        .eq("id", user_id)
        .limit(1)
        .execute()
    )
    return extract_first(response)


def upsert_profile(
    *,
    user_id: str,
    email: str,
    full_name: str,
    phone_number: str | None = None,
    profile_image_url: str | None = None,
    preferences: dict[str, Any] | None = None,
    is_active: bool = True,
) -> dict[str, Any]:
    payload = {
        "id": user_id,
        "email": email,
        "full_name": full_name,
        "phone_number": phone_number,
        "profile_image_url": profile_image_url,
        "preferences": preferences or {},
        "is_active": is_active,
        "updated_at": utc_now_iso(),
    }
    response = get_admin_client().table("profiles").upsert(payload).execute()
    record = extract_first(response)
    return record or payload


def ensure_profile(user: Any) -> dict[str, Any]:
    user_id = get_attr(user, "id", "")
    email = get_attr(user, "email", "")
    metadata = coerce_dict(get_attr(user, "user_metadata", {}))
    existing = fetch_profile(user_id)
    if existing:
        return existing
    return upsert_profile(
        user_id=user_id,
        email=email,
        full_name=metadata.get("full_name") or email.split("@")[0] or "Terax User",
        phone_number=metadata.get("phone_number") or get_attr(user, "phone"),
        preferences={},
        is_active=True,
    )


def serialize_session(session: Any) -> dict[str, Any] | None:
    if session is None:
        return None
    return {
        "accessToken": get_attr(session, "access_token"),
        "refreshToken": get_attr(session, "refresh_token"),
        "expiresIn": get_attr(session, "expires_in"),
        "tokenType": get_attr(session, "token_type", "bearer"),
    }


def serialize_user(user: Any, profile: dict[str, Any] | None = None) -> dict[str, Any]:
    profile = profile or {}
    metadata = coerce_dict(get_attr(user, "user_metadata", {}))
    email = profile.get("email") or get_attr(user, "email") or ""
    created_at = profile.get("created_at") or get_attr(user, "created_at") or utc_now_iso()
    updated_at = profile.get("updated_at") or get_attr(user, "updated_at") or created_at
    full_name = profile.get("full_name") or metadata.get("full_name") or email.split("@")[0]

    return {
        "id": profile.get("id") or get_attr(user, "id"),
        "fullName": full_name,
        "email": email,
        "phoneNumber": profile.get("phone_number") or metadata.get("phone_number") or get_attr(user, "phone"),
        "createdAt": created_at,
        "updatedAt": updated_at,
        "isActive": profile.get("is_active", True),
        "profileImageUrl": profile.get("profile_image_url"),
        "preferences": profile.get("preferences") or {},
    }


def auth_response_payload(response: Any, *, requires_email_confirmation: bool = False) -> dict[str, Any]:
    user = get_attr(response, "user")
    session = get_attr(response, "session")
    profile = ensure_profile(user) if user is not None else None
    return {
        "user": serialize_user(user, profile) if user is not None else None,
        "session": serialize_session(session),
        "requiresEmailConfirmation": requires_email_confirmation,
    }


def healthcheck_supabase() -> tuple[bool, str]:
    try:
        require_supabase_config()
        get_admin_client().table("profiles").select("id").limit(1).execute()
        return True, "ok"
    except Exception as exc:
        return False, str(exc)
