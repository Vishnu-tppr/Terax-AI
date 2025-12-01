# 🚨 Terax AI – AI‑Powered Personal Safety App 🔐📱

> 🛡️ A next‑gen AI safety app that protects you instantly using **voice triggers**, **gesture SOS**, **live GPS**, and **AI distress detection**.
>
> 🎤 Say a phrase → 📱 App activates → 🧠 AI records + alerts → 🚨 Help is notified.

---

## 📌 Table of Contents

* [✨ Features](#-features)
* [📸 Demo Screenshots](#-demo-screenshots)
* [🧠 How It Works](#-how-it-works)
* [🏗️ Architecture](#️-architecture)
* [📁 Project Structure](#-project-structure)
* [⚙️ Requirements](#️-requirements)
* [🚀 Getting Started](#-getting-started)
* [⚙️ Environment Setup](#️-environment-setup)
* [▶️ Run the App](#️-run-the-app)
* [🧪 Testing](#-testing)
* [📱 Build for Production](#-build-for-production)
* [🧩 Technologies Used](#-technologies-used)
* [👨🏻‍💻 Author](#-author)
* [📜 License](#-license)

---

## ✨ Features

* 🎤 **Voice Activation** – Triggers on phrases like “Help me”, “Save me”, or custom words.
* 👋 **Gesture SOS** – 3 shakes or 5 pocket taps to activate.
* ⏳ **Smart Countdown** – 10‑second auto‑trigger unless cancelled.
* 📍 **Live GPS Tracking** – Sends real‑time location to trusted contacts.
* 🎥 **Stealth Camera + Mic Recording** – Records silently and stores locally.
* 📴 **Fake Power‑Off Screen** – Looks off but continues recording.
* 🛑 **Anti‑Theft Mode** – Captures intruder photo after 3 wrong passwords.
* 🔐 **Auto‑Lock & Data Hide** – Secures sensitive apps instantly.
* 🧠 **AI Facial Distress Detection** – OpenCV‑based safety monitoring.
* 📱 **Multi‑Channel Alerts** – SMS, WhatsApp, calls via Twilio.
* 🗺️ **Safe Zone Alerts** – Notifies when user exits safe areas.
* 📶 **Offline‑First** – Core emergency tools work without internet.
* 🔒 **End‑to‑End Privacy** – AES encrypted, local‑first design.

---

## 📸 Demo Screenshots

<p align="center">
  <img src="assets/screens/screen1.png" width="300" />
  <img src="assets/screens/screen2.png" width="300" />
  <img src="assets/screens/screen3.png" width="300" />
</p>

*(Replace with your actual images)*

---

## 🧠 How It Works

### 1️⃣ Trigger Detection (Voice / Gesture / AI)

Terax listens for:

* Voice hotwords
* Shake patterns
* Facial distress via OpenCV

### 2️⃣ Instant Activation

Once triggered:

* Records video + audio silently
* Locks device and hides sensitive apps
* Starts live location broadcast

### 3️⃣ Alert Dispatch

Using the backend API (Node.js + Twilio):

* SMS / WhatsApp / Call alerts are sent
* Real‑time location tracking begins

### 4️⃣ Background Safety

* Fake shutdown animation
* Offline local protection
* Anti‑theft capture

---

## 📁 Project Structure
```
Terax-AI/
├── terax_ai_app/                 # Flutter Frontend
│   ├── lib/
│   │   ├── config/               # API and app configuration
│   │   ├── models/               # Data models with JSON serialization
│   │   ├── providers/            # State management (Provider pattern)
│   │   ├── screens/              # UI screens and pages
│   │   ├── services/             # Business logic and API services
│   │   ├── utils/                # Utilities and helpers
│   │   └── widgets/              # Reusable UI components
│   ├── assets/                   # Static assets (images, icons, fonts)
│   ├── test/                     # Unit and widget tests
│   └── pubspec.yaml              # Flutter dependencies
├── backend/                      # Node.js Backend
│   ├── models/                   # MongoDB schemas
│   ├── routes/                   # API endpoints
│   ├── middleware/               # Express middleware
│   ├── services/                 # Business logic
│   ├── utils/                    # Helper functions
│   ├── tests/                    # API tests
│   └── server.js                 # Main application file
├── .env.example                  # Environment template
├── .gitignore                    # Git ignore rules
└── README.md                     # This file
```

---

## ⚙️ Requirements

* Flutter SDK ≥ 3.4.4
* Node.js ≥ 18
* MongoDB
* Redis (optional)
* Twilio Account
* Google Maps API Key
* Git

---

## 🚀 Getting Started

### Clone Repo

```bash
git clone https://github.com/Vishnu-tppr/Terax-AI.git
cd Terax-AI
```

### Install Flutter Dependencies

```bash
cd terax_ai_app
flutter pub get
```

### Install Backend Dependencies

```bash
cd ../backend
npm install
```

---

## ⚙️ Environment Setup

Copy and update env:

```bash
cp ../.env.example .env
```

API keys needed:

```
TWILIO_ACCOUNT_SID
TWILIO_AUTH_TOKEN
GOOGLE_MAPS_API_KEY
JWT_SECRET
```

---

## ▶️ Run the App

### Flutter (Android/iOS)

```bash
flutter run
```

### Backend

```bash
npm run dev
```

---

## 🧪 Testing

### Flutter

```bash
flutter test
```

### Backend

```bash
npm test
```

---

## 📱 Build for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

### Backend Docker

```bash
docker build -t terax-backend .
docker run -p 3000:3000 terax-backend
```

---

## 🧩 Technologies Used

* Flutter / Dart
* Node.js / Express
* MongoDB / Mongoose
* OpenCV
* Twilio API
* Flutter Secure Storage
* JWT Authentication
* Redis (optional)

---

## 👨🏻‍💻 Author

Made with ❤️ by [**Vishnu**](https://www.linkedin.com/in/vishnu-v-31583b327/)

> "Stay safe, stay protected." 🔐⚡

---

## 📜 License

MIT License © 2025 Terax AI

---

## ⭐ Support This Project

If you like Terax AI, please **star ⭐ the repository** — it motivates further development!
