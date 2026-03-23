# Real Auth Setup

Fill only the `CHANGE_ME` values in these two files:

1. `./backend-python/.env`
2. `./.env`

## Backend file

Open `./backend-python/.env` and replace:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

Then run the Supabase SQL in `./backend-python/supabase/schema.sql`.

Start the backend:

```powershell
cd backend-python
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Flutter file

Open `./.env` and replace:

- `GEMINI_API_KEY` only if you want real Gemini features
- `GOOGLE_WEB_CLIENT_ID` if you want native Google sign-in
- `GOOGLE_IOS_CLIENT_ID` for iOS/macOS Google sign-in

Usually you can leave `BACKEND_BASE_URL` as:

- `http://localhost:8000` for Windows/Desktop and iOS simulator
- `http://10.0.2.2:8000` for Android emulator
- `http://YOUR_COMPUTER_IP:8000` for a physical phone

Run Flutter:

```powershell
flutter pub get
flutter run
```

## What was wired for you

- Flutter now loads `./.env` at app startup.
- `BACKEND_BASE_URL` can come from `./.env` instead of only `--dart-define`.
- `./.env` is included as a Flutter asset so it works on-device.
- Ready-to-fill `.env` files were created for both the app and the Python backend.

## Google sign-in note

For the Google login button to work, you also need to:

1. Enable Google provider in Supabase Auth.
2. Create a Google OAuth Web client and put that client ID in `GOOGLE_WEB_CLIENT_ID`.
3. If building for iOS/macOS, also add the native iOS client ID to `GOOGLE_IOS_CLIENT_ID`.
