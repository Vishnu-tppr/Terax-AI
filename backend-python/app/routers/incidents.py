from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.dependencies import AuthenticatedUser, get_current_user
from app.schemas import IncidentCreateRequest, LocationStreamRequest
from app.supabase_helpers import extract_data, extract_first, get_admin_client, utc_now_iso


router = APIRouter(prefix="/v1/emergency", tags=["emergency"])


def serialize_incident(row: dict) -> dict:
    return {
        "id": row["id"],
        "timestamp": row["created_at"],
        "triggerType": row["trigger_type"],
        "status": row["status"],
        "location": row.get("location"),
        "latitude": row.get("latitude"),
        "longitude": row.get("longitude"),
        "userName": row.get("user_name"),
        "emergencyContacts": row.get("emergency_contacts"),
        "emailContacts": row.get("email_contacts"),
        "recordingUrl": row.get("recording_url"),
        "aiAnalysis": row.get("ai_analysis"),
        "description": row.get("description"),
        "triggeredAt": row.get("triggered_at"),
        "contactIds": row.get("contact_ids"),
        "contactsNotified": row.get("contacts_notified"),
        "resolvedAt": row.get("resolved_at"),
        "notes": row.get("notes"),
    }


@router.get("/incidents")
def list_incidents(
    limit: int = Query(default=50, ge=1, le=200),
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> dict:
    response = (
        get_admin_client()
        .table("emergency_incidents")
        .select("*")
        .eq("user_id", current_user.user_id)
        .order("created_at", desc=True)
        .limit(limit)
        .execute()
    )
    rows = extract_data(response) or []
    return {"incidents": [serialize_incident(row) for row in rows]}


@router.post("/incidents", status_code=status.HTTP_201_CREATED)
def create_incident(
    payload: IncidentCreateRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> dict:
    response = (
        get_admin_client()
        .table("emergency_incidents")
        .insert(
            {
                "user_id": current_user.user_id,
                "trigger_type": payload.trigger_type,
                "status": payload.status,
                "location": payload.location,
                "latitude": payload.latitude,
                "longitude": payload.longitude,
                "user_name": payload.user_name,
                "emergency_contacts": payload.emergency_contacts,
                "email_contacts": payload.email_contacts,
                "recording_url": payload.recording_url,
                "ai_analysis": payload.ai_analysis,
                "description": payload.description,
                "triggered_at": payload.triggered_at,
                "contact_ids": payload.contact_ids,
                "contacts_notified": payload.contacts_notified,
                "resolved_at": payload.resolved_at,
                "notes": payload.notes,
                "metadata": payload.metadata,
            }
        )
        .execute()
    )
    row = extract_first(response)
    if row is None:
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Failed to create incident.")
    return {"incident": serialize_incident(row)}


@router.post("/location-stream", status_code=status.HTTP_202_ACCEPTED)
def stream_location(
    payload: LocationStreamRequest,
    current_user: AuthenticatedUser = Depends(get_current_user),
) -> dict:
    (
        get_admin_client()
        .table("location_events")
        .insert(
            {
                "user_id": current_user.user_id,
                "latitude": payload.latitude,
                "longitude": payload.longitude,
                "accuracy": payload.accuracy,
                "altitude": payload.altitude,
                "heading": payload.heading,
                "speed": payload.speed,
                "address": payload.address,
                "source": payload.source,
                "captured_at": payload.timestamp or utc_now_iso(),
            }
        )
        .execute()
    )
    return {"success": True}
