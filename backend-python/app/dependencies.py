from __future__ import annotations

from dataclasses import dataclass
from typing import Annotated, Any

import httpx
from fastapi import Header, HTTPException, status

from app.config import get_settings


@dataclass(frozen=True)
class AuthenticatedUser:
    token: str
    raw_user: dict[str, Any]

    @property
    def user_id(self) -> str:
        return str(self.raw_user.get("id", ""))

    @property
    def email(self) -> str:
        return str(self.raw_user.get("email", ""))

    @property
    def user_metadata(self) -> dict[str, Any]:
        value = self.raw_user.get("user_metadata")
        return value if isinstance(value, dict) else {}


def _extract_bearer_token(authorization: str | None) -> str:
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header is required.",
        )
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authorization header must use Bearer token format.",
        )
    return token.strip()


def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
) -> AuthenticatedUser:
    token = _extract_bearer_token(authorization)
    settings = get_settings()

    try:
        response = httpx.get(
            f"{settings.supabase_url}/auth/v1/user",
            headers={
                "apikey": settings.supabase_anon_key,
                "Authorization": f"Bearer {token}",
            },
            timeout=10.0,
        )
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Supabase auth lookup failed: {exc}",
        ) from exc

    if response.status_code == status.HTTP_200_OK:
        return AuthenticatedUser(token=token, raw_user=response.json())

    if response.status_code in (status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Supabase session is invalid or expired.",
        )

    raise HTTPException(
        status_code=status.HTTP_502_BAD_GATEWAY,
        detail=f"Unexpected Supabase auth response: {response.text}",
    )
