from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class ApiModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True, str_strip_whitespace=True)


class SignUpRequest(ApiModel):
    full_name: str = Field(alias="fullName", min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    phone_number: str | None = Field(default=None, alias="phoneNumber", max_length=32)
    preferences: dict[str, Any] = Field(default_factory=dict)


class SignInRequest(ApiModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class GoogleSignInRequest(ApiModel):
    id_token: str = Field(alias="idToken", min_length=1)
    access_token: str = Field(alias="accessToken", min_length=1)
    email: EmailStr | None = None
    full_name: str | None = Field(
        default=None,
        alias="fullName",
        min_length=2,
        max_length=120,
    )
    avatar_url: str | None = Field(
        default=None,
        alias="avatarUrl",
        max_length=500,
    )


class RefreshSessionRequest(ApiModel):
    access_token: str = Field(alias="accessToken", min_length=1)
    refresh_token: str = Field(alias="refreshToken", min_length=1)


class ResetPasswordRequest(ApiModel):
    email: EmailStr


class ChangePasswordRequest(ApiModel):
    current_password: str = Field(alias="currentPassword", min_length=6, max_length=128)
    new_password: str = Field(alias="newPassword", min_length=6, max_length=128)


class ProfileUpdateRequest(ApiModel):
    full_name: str | None = Field(default=None, alias="fullName", min_length=2, max_length=120)
    phone_number: str | None = Field(default=None, alias="phoneNumber", max_length=32)
    profile_image_url: str | None = Field(default=None, alias="profileImageUrl", max_length=500)
    preferences: dict[str, Any] | None = None


PriorityLiteral = Literal["one", "two", "three", "four", "five"]
RelationshipLiteral = Literal["emergency", "family", "friend"]
NotificationLiteral = Literal["sms", "call", "email", "push"]
TriggerLiteral = Literal["button", "voice", "gesture", "facial_distress", "safe_zone", "manual"]
StatusLiteral = Literal["active", "resolved", "failed"]


class ContactUpsertRequest(ApiModel):
    name: str = Field(min_length=1, max_length=120)
    phone_number: str = Field(alias="phoneNumber", min_length=4, max_length=32)
    email: EmailStr | None = None
    relationship: RelationshipLiteral = "emergency"
    priority: PriorityLiteral = "one"
    notification_methods: list[NotificationLiteral] = Field(
        alias="notificationMethods",
        default_factory=lambda: ["sms"],
    )
    is_primary: bool = Field(alias="isPrimary", default=False)
    is_active: bool = Field(alias="isActive", default=True)


class IncidentCreateRequest(ApiModel):
    trigger_type: TriggerLiteral = Field(alias="triggerType")
    status: StatusLiteral = "active"
    location: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    user_name: str | None = Field(default=None, alias="userName")
    emergency_contacts: list[str] | None = Field(default=None, alias="emergencyContacts")
    email_contacts: list[str] | None = Field(default=None, alias="emailContacts")
    recording_url: str | None = Field(default=None, alias="recordingUrl")
    ai_analysis: str | None = Field(default=None, alias="aiAnalysis")
    description: str | None = None
    triggered_at: str | None = Field(default=None, alias="triggeredAt")
    contact_ids: list[str] | None = Field(default=None, alias="contactIds")
    contacts_notified: int | None = Field(default=None, alias="contactsNotified", ge=0)
    resolved_at: str | None = Field(default=None, alias="resolvedAt")
    notes: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class LocationStreamRequest(ApiModel):
    latitude: float
    longitude: float
    accuracy: float | None = None
    altitude: float | None = None
    heading: float | None = None
    speed: float | None = None
    timestamp: str | None = None
    address: str | None = None
    source: str = "mobile_app"
