from __future__ import annotations

from fastapi import APIRouter, Depends

from app.dependencies import AuthenticatedUser, get_current_user
from app.schemas import ProfileUpdateRequest
from app.supabase_helpers import ensure_profile, serialize_user, upsert_profile


router = APIRouter(prefix="/v1/profile", tags=["profile"])


@router.get("")
def get_profile(current_user: AuthenticatedUser = Depends(get_current_user)) -> dict:
    profile = ensure_profile(current_user.raw_user)
    return {"user": serialize_user(current_user.raw_user, profile)}


@router.patch("")
def update_profile(
    payload: ProfileUpdateRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> dict:
    existing = ensure_profile(current_user.raw_user)
    updated_profile = upsert_profile(
        user_id=current_user.user_id,
        email=current_user.email,
        full_name=payload.full_name or existing.get("full_name") or current_user.email.split("@")[0],
        phone_number=payload.phone_number if payload.phone_number is not None else existing.get("phone_number"),
        profile_image_url=(
            payload.profile_image_url
            if payload.profile_image_url is not None
            else existing.get("profile_image_url")
        ),
        preferences=payload.preferences if payload.preferences is not None else existing.get("preferences") or {},
        is_active=existing.get("is_active", True),
    )
    return {"user": serialize_user(current_user.raw_user, updated_profile)}
