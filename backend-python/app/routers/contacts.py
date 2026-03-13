from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import AuthenticatedUser, get_current_user
from app.schemas import ContactUpsertRequest
from app.supabase_helpers import extract_data, extract_first, get_admin_client, utc_now_iso


router = APIRouter(prefix="/v1/contacts", tags=["contacts"])


PRIORITY_TO_LEVEL = {
    "one": 1,
    "two": 2,
    "three": 3,
    "four": 4,
    "five": 5,
}

LEVEL_TO_PRIORITY = {value: key for key, value in PRIORITY_TO_LEVEL.items()}


def serialize_contact(row: dict) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "phoneNumber": row["phone_number"],
        "email": row.get("email"),
        "relationship": row["relationship"],
        "priority": LEVEL_TO_PRIORITY.get(row["priority"], "one"),
        "notificationMethods": row.get("notification_methods") or ["sms"],
        "isPrimary": row.get("is_primary", False),
        "createdAt": row["created_at"],
        "updatedAt": row["updated_at"],
        "isActive": row.get("is_active", True),
    }


def clear_primary_contacts(user_id: str, current_id: str | None = None) -> None:
    query = (
        get_admin_client()
        .table("emergency_contacts")
        .update({"is_primary": False, "updated_at": utc_now_iso()})
        .eq("user_id", user_id)
        .eq("is_primary", True)
    )
    if current_id:
        query = query.neq("id", current_id)
    query.execute()


@router.get("")
def list_contacts(current_user: AuthenticatedUser = Depends(get_current_user)) -> dict:
    response = (
        get_admin_client()
        .table("emergency_contacts")
        .select("*")
        .eq("user_id", current_user.user_id)
        .order("priority")
        .order("created_at")
        .execute()
    )
    rows = extract_data(response) or []
    return {"contacts": [serialize_contact(row) for row in rows]}


@router.post("", status_code=status.HTTP_201_CREATED)
def create_contact(
    payload: ContactUpsertRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> dict:
    if payload.is_primary:
        clear_primary_contacts(current_user.user_id)

    response = (
        get_admin_client()
        .table("emergency_contacts")
        .insert(
            {
                "user_id": current_user.user_id,
                "name": payload.name,
                "phone_number": payload.phone_number,
                "email": payload.email,
                "relationship": payload.relationship,
                "priority": PRIORITY_TO_LEVEL[payload.priority],
                "notification_methods": payload.notification_methods,
                "is_primary": payload.is_primary,
                "is_active": payload.is_active,
            }
        )
        .execute()
    )
    row = extract_first(response)
    if row is None:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Failed to create contact.")
    return {"contact": serialize_contact(row)}


@router.put("/{contact_id}")
def update_contact(
    contact_id: str,
    payload: ContactUpsertRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> dict:
    if payload.is_primary:
        clear_primary_contacts(current_user.user_id, current_id=contact_id)

    response = (
        get_admin_client()
        .table("emergency_contacts")
        .update(
            {
                "name": payload.name,
                "phone_number": payload.phone_number,
                "email": payload.email,
                "relationship": payload.relationship,
                "priority": PRIORITY_TO_LEVEL[payload.priority],
                "notification_methods": payload.notification_methods,
                "is_primary": payload.is_primary,
                "is_active": payload.is_active,
                "updated_at": utc_now_iso(),
            }
        )
        .eq("id", contact_id)
        .eq("user_id", current_user.user_id)
        .execute()
    )
    row = extract_first(response)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contact not found.")
    return {"contact": serialize_contact(row)}


@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contact(
    contact_id: str,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> None:
    (
        get_admin_client()
        .table("emergency_contacts")
        .delete()
        .eq("id", contact_id)
        .eq("user_id", current_user.user_id)
        .execute()
    )
