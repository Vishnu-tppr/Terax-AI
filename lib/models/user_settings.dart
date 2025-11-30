import 'package:flutter/material.dart';

class UserSettings {
  final bool emergencySharing;
  final bool autoCallEmergencyServices;
  final bool soundAlerts;
  final bool pushNotifications;
  final bool locationTracking;
  final bool voiceActivation;
  final List<String> voiceTriggerPhrases;
  final int gestureSensitivity;
  final bool facialDistressDetection;
  final bool stealthMode;
  final bool emergencySiren;
  final int countdownTimer;
  final bool autoTriggerIfNotCancelled;
  final ThemeMode themeMode;
  final bool biometricAuthEnabled;
  final Map<String, dynamic> customSettings;

  UserSettings({
    this.emergencySharing = false,
    this.autoCallEmergencyServices = false,
    this.soundAlerts = false,
    this.pushNotifications = false,
    this.locationTracking = false,
    this.voiceActivation = false,
    this.voiceTriggerPhrases = const ['help me', 'save me', 'emergency'],
    this.gestureSensitivity = 5,
    this.facialDistressDetection = false,
    this.stealthMode = false,
    this.emergencySiren = false,
    this.countdownTimer = 10,
    this.autoTriggerIfNotCancelled = false,
    this.themeMode = ThemeMode.system,
    this.biometricAuthEnabled = false,
    this.customSettings = const {},
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      emergencySharing: json['emergencySharing'] ?? false,
      autoCallEmergencyServices: json['autoCallEmergencyServices'] ?? false,
      soundAlerts: json['soundAlerts'] ?? false,
      pushNotifications: json['pushNotifications'] ?? false,
      locationTracking: json['locationTracking'] ?? false,
      voiceActivation: json['voiceActivation'] ?? false,
      voiceTriggerPhrases: List<String>.from(
          json['voiceTriggerPhrases'] ?? ['help me', 'save me', 'emergency']),
      gestureSensitivity: json['gestureSensitivity'] ?? 5,
      facialDistressDetection: json['facialDistressDetection'] ?? false,
      stealthMode: json['stealthMode'] ?? false,
      emergencySiren: json['emergencySiren'] ?? false,
      countdownTimer: json['countdownTimer'] ?? 10,
      autoTriggerIfNotCancelled: json['autoTriggerIfNotCancelled'] ?? false,
      themeMode: _themeModeFromString(json['themeMode'] ?? 'system'),
      biometricAuthEnabled: json['biometricAuthEnabled'] ?? false,
      customSettings: json['customSettings'] ?? {},
    );
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'emergencySharing': emergencySharing,
      'autoCallEmergencyServices': autoCallEmergencyServices,
      'soundAlerts': soundAlerts,
      'pushNotifications': pushNotifications,
      'locationTracking': locationTracking,
      'voiceActivation': voiceActivation,
      'voiceTriggerPhrases': voiceTriggerPhrases,
      'gestureSensitivity': gestureSensitivity,
      'facialDistressDetection': facialDistressDetection,
      'stealthMode': stealthMode,
      'emergencySiren': emergencySiren,
      'countdownTimer': countdownTimer,
      'autoTriggerIfNotCancelled': autoTriggerIfNotCancelled,
      'themeMode': _themeModeToString(themeMode),
      'biometricAuthEnabled': biometricAuthEnabled,
      'customSettings': customSettings,
    };
  }

  UserSettings copyWith({
    bool? emergencySharing,
    bool? autoCallEmergencyServices,
    bool? soundAlerts,
    bool? pushNotifications,
    bool? locationTracking,
    bool? voiceActivation,
    List<String>? voiceTriggerPhrases,
    int? gestureSensitivity,
    bool? facialDistressDetection,
    bool? stealthMode,
    bool? emergencySiren,
    int? countdownTimer,
    bool? autoTriggerIfNotCancelled,
    ThemeMode? themeMode,
    bool? biometricAuthEnabled,
    Map<String, dynamic>? customSettings,
  }) {
    return UserSettings(
      emergencySharing: emergencySharing ?? this.emergencySharing,
      autoCallEmergencyServices:
          autoCallEmergencyServices ?? this.autoCallEmergencyServices,
      soundAlerts: soundAlerts ?? this.soundAlerts,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      locationTracking: locationTracking ?? this.locationTracking,
      voiceActivation: voiceActivation ?? this.voiceActivation,
      voiceTriggerPhrases: voiceTriggerPhrases ?? this.voiceTriggerPhrases,
      gestureSensitivity: gestureSensitivity ?? this.gestureSensitivity,
      facialDistressDetection:
          facialDistressDetection ?? this.facialDistressDetection,
      stealthMode: stealthMode ?? this.stealthMode,
      emergencySiren: emergencySiren ?? this.emergencySiren,
      countdownTimer: countdownTimer ?? this.countdownTimer,
      autoTriggerIfNotCancelled:
          autoTriggerIfNotCancelled ?? this.autoTriggerIfNotCancelled,
      themeMode: themeMode ?? this.themeMode,
      biometricAuthEnabled: biometricAuthEnabled ?? this.biometricAuthEnabled,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}
