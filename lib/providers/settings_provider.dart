import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';

class SettingsProvider extends ChangeNotifier {
  UserSettings _settings = UserSettings();
  bool _isLoading = false;
  String? _error;

  UserSettings get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('user_settings');

      if (settingsJson != null) {
        try {
          final Map<String, dynamic> settingsMap =
              jsonDecode(settingsJson) as Map<String, dynamic>;
          _settings = UserSettings.fromJson(settingsMap);
        } catch (e) {
          // Use default settings if parsing fails
          if (kDebugMode) {
            print('Failed to parse saved settings: $e');
          }
        }
      }
    } catch (e) {
      _setError('Failed to load settings: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_settings', jsonEncode(_settings.toJson()));
    } catch (e) {
      _setError('Failed to save settings: $e');
    }
  }

  Future<void> updateEmergencySharing(bool value) async {
    _settings = _settings.copyWith(emergencySharing: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateAutoCallEmergencyServices(bool value) async {
    _settings = _settings.copyWith(autoCallEmergencyServices: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateSoundAlerts(bool value) async {
    _settings = _settings.copyWith(soundAlerts: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updatePushNotifications(bool value) async {
    _settings = _settings.copyWith(pushNotifications: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateLocationTracking(bool value) async {
    _settings = _settings.copyWith(locationTracking: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateVoiceActivation(bool value) async {
    _settings = _settings.copyWith(voiceActivation: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateVoiceTriggerPhrases(List<String> phrases) async {
    _settings = _settings.copyWith(voiceTriggerPhrases: phrases);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateGestureSensitivity(int sensitivity) async {
    if (sensitivity >= 1 && sensitivity <= 10) {
      _settings = _settings.copyWith(gestureSensitivity: sensitivity);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateFacialDistressDetection(bool value) async {
    _settings = _settings.copyWith(facialDistressDetection: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateStealthMode(bool value) async {
    _settings = _settings.copyWith(stealthMode: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateEmergencySiren(bool value) async {
    _settings = _settings.copyWith(emergencySiren: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateCountdownTimer(int seconds) async {
    if (seconds >= 5 && seconds <= 60) {
      _settings = _settings.copyWith(countdownTimer: seconds);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> updateAutoTriggerIfNotCancelled(bool value) async {
    _settings = _settings.copyWith(autoTriggerIfNotCancelled: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateBiometricAuth(bool value) async {
    _settings = _settings.copyWith(biometricAuthEnabled: value);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> updateSettings(UserSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> addVoiceTriggerPhrase(String phrase) async {
    if (phrase.isNotEmpty && !_settings.voiceTriggerPhrases.contains(phrase)) {
      final newPhrases = List<String>.from(_settings.voiceTriggerPhrases)
        ..add(phrase);
      _settings = _settings.copyWith(voiceTriggerPhrases: newPhrases);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> removeVoiceTriggerPhrase(String phrase) async {
    if (_settings.voiceTriggerPhrases.length > 1) {
      final newPhrases = List<String>.from(_settings.voiceTriggerPhrases)
        ..remove(phrase);
      _settings = _settings.copyWith(voiceTriggerPhrases: newPhrases);
      await _saveSettings();
      notifyListeners();
    }
  }

  Future<void> resetToDefaults() async {
    _settings = UserSettings();
    await _saveSettings();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
