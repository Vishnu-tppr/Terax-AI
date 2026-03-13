# Terax AI Python Backend

FastAPI backend for the Terax AI Flutter app using Supabase for authentication and app data.

## What it provides

- Supabase email/password authentication
- User profile storage in `profiles`
- Emergency contact storage in `emergency_contacts`
- Incident storage in `emergency_incidents`
- Location event storage in `location_events`
- Backend-managed access to Supabase service-role credentials

## 1. Install

```bash
cd backend-python
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## 2. Configure Supabase

1. Create a Supabase project.
2. In Supabase SQL Editor, run `supabase/schema.sql`.
3. Copy `.env.example` to `.env` and fill in:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`

Keep the service-role key only in this backend. Do not put it in Flutter.

If you want password reset links to open your app directly, configure a mobile deep link such as `teraxai://reset-password`.

## 3. Run

```bash
cd backend-python
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://localhost:8000/health
```

## 4. Flutter app configuration

Pass the backend URL into Flutter:

```bash
flutter run --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000
```

Use `http://localhost:8000` for desktop or iOS simulator. Use your machine IP for a physical device.

This backend is for a mobile app. You do not need a website to use it.

- Android emulator: `http://10.0.2.2:8000`
- iOS simulator: `http://localhost:8000`
- Physical device: `http://<your-computer-ip>:8000`
- Password reset redirect: use an app deep link like `teraxai://reset-password`

## Main endpoints

- `POST /v1/auth/sign-up`
- `POST /v1/auth/sign-in`
- `POST /v1/auth/refresh`
- `GET /v1/auth/me`
- `POST /v1/auth/reset-password`
- `POST /v1/auth/change-password`
- `GET /v1/profile`
- `PATCH /v1/profile`
- `GET /v1/contacts`
- `POST /v1/contacts`
- `PUT /v1/contacts/{contact_id}`
- `DELETE /v1/contacts/{contact_id}`
- `GET /v1/emergency/incidents`
- `POST /v1/emergency/incidents`
- `POST /v1/emergency/location-stream`
