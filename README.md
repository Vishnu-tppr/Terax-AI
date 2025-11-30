# Terax AI - Personal Safety App

A privacy-focused personal safety app providing instant emergency response via voice, gesture, and AI-powered facial distress detection.

## Features

### 🚨 Emergency Response
- **Sub-second Emergency Response** - Optimized emergency button with immediate feedback
- **Voice Activation** - Configurable trigger phrases ("help me", "save me", "emergency")
- **Gesture Recognition** - Motion-based emergency triggers
- **AI Safety Features** - Facial distress detection toggle (infrastructure ready)

### 📍 Location & Communication
- **Location Sharing** - GPS integration with permission handling
- **Emergency Contacts** - Priority-based notification system
- **Multi-channel Alerts** - SMS, Call, Email, and Push notifications
- **Stealth Mode** - Silent operation capabilities

### 📊 Activity Tracking
- **Incident History** - Complete emergency incident logs
- **Status Filtering** - Active, Resolved, and Failed incidents
- **Real-time Updates** - Live incident status tracking

### ⚙️ Settings & Customization
- **Safety Preferences** - Comprehensive safety feature toggles
- **Voice Triggers** - Customizable emergency phrases
- **Gesture Sensitivity** - Configurable 1-10 scale for motion detection
- **Privacy Controls** - All settings user-controlled, secure data handling

## Screenshots

The app includes the following main screens:
- **Safety Dashboard** - Emergency button with pulse animation and status indicators
- **Emergency Contacts** - Full CRUD with priority levels and notification methods
- **Activity History** - Incident tracking with filtering and detailed logs
- **Settings** - All safety features, voice triggers, and preferences

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd terax_ai_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Demo Account
For testing purposes, use:
- **Email**: demo@terax.ai
- **Password**: any password

## Architecture

### State Management
- **Provider Pattern** - For state management across the app
- **Service Layer** - Emergency service, authentication, and data management
- **Repository Pattern** - Data access and business logic separation

### Key Components
- **Models** - User, EmergencyContact, EmergencyIncident, UserSettings
- **Providers** - AuthProvider, ContactsProvider, SettingsProvider, IncidentsProvider
- **Services** - AuthService, EmergencyService
- **Screens** - Authentication, Safety, Contacts, Activity, Settings

### Security Features
- **AES-256 Encryption** - For sensitive data
- **Secure Authentication** - Token-based user sessions
- **Permission Handling** - Location, camera, and microphone permissions
- **Privacy-First Design** - All data stays on device by default

## Future Enhancements

### Phase 2 Features
- **Real Voice Detection** - Integration with Google ML Kit
- **Camera Recording** - Emergency video/audio capture
- **SMS Integration** - Direct emergency contact messaging
- **WhatsApp Integration** - Business API integration
- **Cloud Backup** - Zero-knowledge encrypted backups

### Advanced AI Features
- **Facial Distress Detection** - OpenCV-based emotion recognition
- **Gesture Recognition** - Advanced motion pattern detection
- **Behavioral Analysis** - Learning user patterns for better detection

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions, please contact the development team or create an issue in the repository.

---

**Note**: This is a demo application. In production, implement proper security measures, API integrations, and emergency service compliance.
