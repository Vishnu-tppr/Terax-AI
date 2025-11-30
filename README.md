# 🚨 Terax AI - Personal Safety App

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-4EA94B?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com)
[![Twilio](https://img.shields.io/badge/Twilio-F22F46?style=for-the-badge&logo=twilio&logoColor=white)](https://www.twilio.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

> **Terax AI** is a cutting-edge, privacy-focused personal safety mobile application that provides instant emergency response through voice commands, gesture recognition, and AI-powered facial distress detection. Built with Flutter for cross-platform compatibility and backed by a robust Node.js API.

## 📋 Table of Contents

- [✨ Features](#-features)
- [🛠️ Tech Stack](#️-tech-stack)
- [🚀 Quick Start](#-quick-start)
- [📱 Installation](#-installation)
- [⚙️ Configuration](#️-configuration)
- [📁 Project Structure](#-project-structure)
- [🧪 Testing](#-testing)
- [🚀 Deployment](#-deployment)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [📞 Support](#-support)

## ✨ Features

### 🚨 Emergency Response System
- **⚡ Sub-second Emergency Response** - Optimized emergency button with haptic feedback
- **🎤 Voice Activation** - Customizable trigger phrases ("help me", "save me", "emergency")
- **👋 Gesture Recognition** - Motion-based emergency triggers with configurable sensitivity
- **🤖 AI Facial Detection** - Advanced distress detection using computer vision (infrastructure ready)

### 📍 Location & Communication
- **📍 Real-time GPS Tracking** - Precise location sharing with permission handling
- **👥 Emergency Contacts** - Priority-based notification system with multiple channels
- **📱 Multi-channel Alerts** - SMS, Phone calls, Email, and Push notifications via Twilio
- **🔇 Stealth Mode** - Silent operation with background monitoring

### 📊 Activity Tracking & Analytics
- **📈 Incident History** - Complete emergency incident logs with timestamps
- **🔍 Status Filtering** - Active, Resolved, and Failed incidents tracking
- **📊 Real-time Updates** - Live incident status monitoring and analytics
- **📋 Activity Logging** - Comprehensive user activity monitoring

### ⚙️ Advanced Settings & Customization
- **🔐 Security Features** - Biometric authentication and secure storage
- **🎨 Theme Customization** - Dark/light mode with custom color schemes
- **🔊 Voice Commands** - Customizable emergency phrases and voice settings
- **📳 Haptic Feedback** - Configurable vibration patterns
- **🔔 Notification Preferences** - Granular control over all notifications

### 🔒 Privacy & Security
- **🔐 End-to-end Encryption** - AES-256 encryption for sensitive data
- **📱 Local Storage First** - All data stored locally by default
- **🔑 Secure Authentication** - JWT-based authentication system
- **🛡️ Permission Management** - Granular control over device permissions

## 🛠️ Tech Stack

### Frontend (Flutter)
```yaml
- Flutter SDK: ^3.4.4
- State Management: Provider
- Navigation: Go Router
- Local Storage: Shared Preferences, SQLite
- Networking: Dio, HTTP
- Location: Geolocator, Geocoding
- Media: Camera, Audio Players, Speech-to-Text
- Security: Flutter Secure Storage, Local Auth
- UI: Flutter SVG, Lottie, Shimmer
```

### Backend (Node.js)
```json
- Runtime: Node.js >=18.0.0
- Framework: Express.js
- Database: MongoDB with Mongoose
- Caching: Redis
- Authentication: JWT, bcrypt
- SMS/Communication: Twilio API
- Security: Helmet, Rate Limiting
- Logging: Winston
```

### DevOps & Tools
```yaml
- Version Control: Git
- CI/CD: GitHub Actions
- Testing: Flutter Test, Jest
- Linting: Flutter Lints, ESLint
- Package Management: Pub, npm
```

## 🚀 Quick Start

### Prerequisites
- **Flutter SDK** (3.4.4 or higher)
- **Node.js** (18.0.0 or higher)
- **MongoDB** (local or cloud instance)
- **Redis** (for caching)
- **Android Studio** / **VS Code** / **Xcode**
- **Git**

### One-Command Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/Vishnu-tppr/Terax-AI.git
cd Terax-AI

# Setup Flutter app
cd terax_ai_app
flutter pub get

# Setup backend
cd ../backend
npm install

# Copy environment files
cp ../.env.example ../.env
# Edit .env with your API keys
```

## 📱 Installation

### Flutter App Setup

1. **Clone and Navigate:**
   ```bash
   git clone https://github.com/Vishnu-tppr/Terax-AI.git
   cd Terax-AI/terax_ai_app
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate Code (for JSON serialization):**
   ```bash
   flutter pub run build_runner build
   ```

4. **Run the App:**
   ```bash
   # For Android
   flutter run

   # For iOS (macOS only)
   flutter run --flavor development

   # For Web
   flutter run -d chrome
   ```

### Backend API Setup

1. **Navigate to Backend:**
   ```bash
   cd ../backend
   ```

2. **Install Dependencies:**
   ```bash
   npm install
   ```

3. **Environment Setup:**
   ```bash
   cp ../.env.example .env
   # Edit .env with your configuration
   ```

4. **Start Development Server:**
   ```bash
   npm run dev
   ```

5. **API will be available at:** `http://localhost:3000`

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Backend Configuration
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/terax_ai
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRE=7d

# Twilio Configuration
TWILIO_ACCOUNT_SID=your-twilio-account-sid
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_PHONE_NUMBER=+1234567890

# Google Maps API
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# OpenAI API (for AI features)
OPENAI_API_KEY=your-openai-api-key

# App Configuration
APP_NAME=Terax AI
APP_VERSION=1.0.0
```

### Flutter Configuration

Update `lib/config/api_config.dart` with your backend URL:

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // iOS simulator
}
```

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

## 🧪 Testing

### Flutter App Testing

```bash
cd terax_ai_app

# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Run tests with coverage
flutter test --coverage
```

### Backend Testing

```bash
cd backend

# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

## 🚀 Deployment

### Mobile App Deployment

#### Android
```bash
# Build APK
flutter build apk --release

# Build App Bundle (recommended)
flutter build appbundle --release
```

#### iOS
```bash
# Build for iOS
flutter build ios --release

# Archive for App Store
flutter build ipa --release
```

### Backend Deployment

#### Using Docker
```bash
cd backend

# Build Docker image
docker build -t terax-ai-backend .

# Run container
docker run -p 3000:3000 terax-ai-backend
```

#### Using Railway/Render/Heroku
```bash
# Install Railway CLI
npm install -g @railway/cli

# Deploy
railway login
railway link
railway up
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. **Fork the repository**
2. **Create a feature branch:**
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **Commit your changes:**
   ```bash
   git commit -m 'Add amazing feature'
   ```
4. **Push to the branch:**
   ```bash
   git push origin feature/amazing-feature
   ```
5. **Open a Pull Request**

### Development Guidelines

- Follow the existing code style
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass
- Use meaningful commit messages

### Code Style

```bash
# Flutter linting
flutter analyze

# Backend linting
npm run lint

# Fix linting issues
npm run lint:fix
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

### Getting Help

- 📧 **Email:** vishnu.tppr@gmail.com
- 🐛 **Issues:** [GitHub Issues](https://github.com/Vishnu-tppr/Terax-AI/issues)
- 📖 **Documentation:** [Wiki](https://github.com/Vishnu-tppr/Terax-AI/wiki)
- 💬 **Discussions:** [GitHub Discussions](https://github.com/Vishnu-tppr/Terax-AI/discussions)

### Security

If you discover a security vulnerability, please email vishnu.tppr@gmail.com instead of creating a public issue.

---

<div align="center">

**Made with ❤️ by the Terax AI Team**

⭐ Star us on GitHub if you find this project helpful!


</div>

---

**⚠️ Important Note:** This is a safety application. In production deployments, ensure compliance with local emergency services regulations and implement proper security measures.
