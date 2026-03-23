from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.config import get_settings
from app.dependencies import AuthenticatedUser, get_current_user
from app.schemas import (
    ChangePasswordRequest,
    GoogleSignInRequest,
    RefreshSessionRequest,
    ResetPasswordRequest,
    SignInRequest,
    SignUpRequest,
)
from app.supabase_helpers import (
    auth_response_payload,
    coerce_dict,
    create_public_client,
    ensure_profile,
    get_attr,
    require_supabase_config,
    serialize_user,
    upsert_profile,
)


router = APIRouter(prefix="/v1/auth", tags=["auth"])


@router.post("/sign-up", status_code=status.HTTP_201_CREATED)
def sign_up(payload: SignUpRequest) -> dict:
    require_supabase_config()
    client = create_public_client()

    try:
        response = client.auth.sign_up(
            {
                "email": payload.email,
                "password": payload.password,
                "options": {
                    "data": {
                        "full_name": payload.full_name,
                        "phone_number": payload.phone_number,
                    }
                },
            }
        )
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    user = get_attr(response, "user")
    if user is not None:
        profile = upsert_profile(
            user_id=get_attr(user, "id"),
            email=payload.email,
            full_name=payload.full_name,
            phone_number=payload.phone_number,
            preferences=payload.preferences,
            is_active=True,
        )
    else:
        profile = None

    result = auth_response_payload(
        response,
        requires_email_confirmation=get_attr(response, "session") is None,
    )
    if user is not None and profile is not None:
        result["user"] = serialize_user(user, profile)
    return result


@router.post("/sign-in")
def sign_in(payload: SignInRequest) -> dict:
    require_supabase_config()
    client = create_public_client()

    try:
        response = client.auth.sign_in_with_password(
            {
                "email": payload.email,
                "password": payload.password,
            }
        )
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    return auth_response_payload(response)


@router.post("/sign-in/google")
def sign_in_with_google(payload: GoogleSignInRequest) -> dict:
    require_supabase_config()
    client = create_public_client()

    try:
        response = client.auth.sign_in_with_id_token(
            {
                "provider": "google",
                "token": payload.id_token,
                "access_token": payload.access_token,
            }
        )
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    user = get_attr(response, "user")
    profile = None
    if user is not None:
        metadata = coerce_dict(get_attr(user, "user_metadata", {}))
        profile = upsert_profile(
            user_id=get_attr(user, "id"),
            email=payload.email or get_attr(user, "email") or "",
            full_name=(
                payload.full_name
                or metadata.get("full_name")
                or metadata.get("name")
                or get_attr(user, "email", "Terax User").split("@")[0]
            ),
            phone_number=metadata.get("phone_number") or get_attr(user, "phone"),
            profile_image_url=payload.avatar_url or metadata.get("avatar_url") or metadata.get("picture"),
            preferences={},
            is_active=True,
        )

    result = auth_response_payload(response)
    if user is not None and profile is not None:
        result["user"] = serialize_user(user, profile)
    return result


@router.post("/refresh")
def refresh_session(payload: RefreshSessionRequest) -> dict:
    require_supabase_config()
    client = create_public_client()

    try:
        response = client.auth.set_session(payload.access_token, payload.refresh_token)
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    return auth_response_payload(response)


@router.get("/me")
def get_me(current_user: AuthenticatedUser = Depends(get_current_user)) -> dict:
    require_supabase_config()
    profile = ensure_profile(current_user.raw_user)
    return {"user": serialize_user(current_user.raw_user, profile)}


@router.post("/reset-password")
def reset_password(payload: ResetPasswordRequest) -> dict:
    require_supabase_config()
    client = create_public_client()
    settings = get_settings()

    try:
        client.auth.reset_password_for_email(
            payload.email,
            {"redirect_to": settings.password_reset_redirect}
            if settings.password_reset_redirect
            else {},
        )
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    return {"success": True}


@router.post("/change-password")
def change_password(
    payload: ChangePasswordRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> dict:
    require_supabase_config()
    client = create_public_client()

    try:
        client.auth.sign_in_with_password(
            {
                "email": current_user.email,
                "password": payload.current_password,
            }
        )
        client.auth.update_user({"password": payload.new_password})
    except Exception as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    return {"success": True}
