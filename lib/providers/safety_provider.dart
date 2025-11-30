
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SafetyProvider extends ChangeNotifier {
  bool _isEmergencyActive = false;
  bool _isSilentMode = false;
  bool _isAutoTriggerEnabled = true;
  int _autoTriggerDelay = 30; // seconds
  bool _isLoading = false;
  String? _lastError;

  // Constants for validation
  static const int minAutoTriggerDelay = 5;
  static const int maxAutoTriggerDelay = 300; // 5 minutes max
  static const String _silentModeKey = 'silent_mode';
  static const String _autoTriggerEnabledKey = 'auto_trigger_enabled';
  static const String _autoTriggerDelayKey = 'auto_trigger_delay';

  bool get isEmergencyActive => _isEmergencyActive;

  // Getters for settings
  bool get isSilentMode => _isSilentMode;
  bool get isAutoTriggerEnabled => _isAutoTriggerEnabled;
  int get autoTriggerDelay => _autoTriggerDelay;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  // Constructor
  SafetyProvider() {
    _initializeSettings();
  }

  // Initialize settings with proper error handling
  Future<void> _initializeSettings() async {
    _setLoading(true);
    try {
      await _loadSettings();
      _clearError();
    } catch (e) {
      _setError('Failed to load safety settings: $e');
      if (kDebugMode) {
        print('Error initializing safety settings: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isSilentMode = prefs.getBool(_silentModeKey) ?? false;
      _isAutoTriggerEnabled = prefs.getBool(_autoTriggerEnabledKey) ?? true;
      
      // Validate auto-trigger delay with bounds checking
      final savedDelay = prefs.getInt(_autoTriggerDelayKey) ?? 30;
      _autoTriggerDelay = _validateAutoTriggerDelay(savedDelay);
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading safety settings: $e');
      }
      rethrow;
    }
  }

  // Save settings to SharedPreferences with error handling
  Future<bool> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final results = await Future.wait([
        prefs.setBool(_silentModeKey, _isSilentMode),
        prefs.setBool(_autoTriggerEnabledKey, _isAutoTriggerEnabled),
        prefs.setInt(_autoTriggerDelayKey, _autoTriggerDelay),
      ]);
      
      // Check if all save operations succeeded
      final allSucceeded = results.every((result) => result);
      
      if (allSucceeded) {
        _clearError();
      } else {
        _setError('Some settings failed to save');
      }
      
      return allSucceeded;
    } catch (e) {
      _setError('Failed to save settings: $e');
      if (kDebugMode) {
        print('Error saving safety settings: $e');
      }
      return false;
    }
  }

  // Validate auto-trigger delay value
  int _validateAutoTriggerDelay(int delay) {
    if (delay < minAutoTriggerDelay) {
      if (kDebugMode) {
        print('Auto-trigger delay too low, setting to minimum: $minAutoTriggerDelay');
      }
      return minAutoTriggerDelay;
    }
    if (delay > maxAutoTriggerDelay) {
      if (kDebugMode) {
        print('Auto-trigger delay too high, setting to maximum: $maxAutoTriggerDelay');
      }
      return maxAutoTriggerDelay;
    }
    return delay;
  }

  // Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Set error state
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  // Clear error state
  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  // Toggle silent mode with async save
  Future<bool> toggleSilentMode() async {
    if (_isLoading) return false;
    
    _setLoading(true);
    try {
      _isSilentMode = !_isSilentMode;
      notifyListeners();
      
      final success = await _saveSettings();
      if (!success) {
        // Revert on save failure
        _isSilentMode = !_isSilentMode;
        notifyListeners();
      }
      return success;
    } catch (e) {
      // Revert on error
      _isSilentMode = !_isSilentMode;
      _setError('Failed to toggle silent mode: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle auto-trigger with async save
  Future<bool> toggleAutoTrigger() async {
    if (_isLoading) return false;
    
    _setLoading(true);
    try {
      _isAutoTriggerEnabled = !_isAutoTriggerEnabled;
      notifyListeners();
      
      final success = await _saveSettings();
      if (!success) {
        // Revert on save failure
        _isAutoTriggerEnabled = !_isAutoTriggerEnabled;
        notifyListeners();
      }
      return success;
    } catch (e) {
      // Revert on error
      _isAutoTriggerEnabled = !_isAutoTriggerEnabled;
      _setError('Failed to toggle auto-trigger: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set auto-trigger delay with validation and async save
  Future<bool> setAutoTriggerDelay(int delay) async {
    if (_isLoading) return false;
    
    final validatedDelay = _validateAutoTriggerDelay(delay);
    
    if (_autoTriggerDelay == validatedDelay) {
      return true; // No change needed
    }
    
    _setLoading(true);
    try {
      final oldDelay = _autoTriggerDelay;
      _autoTriggerDelay = validatedDelay;
      notifyListeners();
      
      final success = await _saveSettings();
      if (!success) {
        // Revert on save failure
        _autoTriggerDelay = oldDelay;
        notifyListeners();
      }
      return success;
    } catch (e) {
      // Revert on error
      _setError('Failed to set auto-trigger delay: $e');
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reload settings from storage
  Future<bool> reloadSettings() async {
    if (_isLoading) return false;
    
    _setLoading(true);
    try {
      await _loadSettings();
      _clearError();
      return true;
    } catch (e) {
      _setError('Failed to reload settings: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset settings to defaults
  Future<bool> resetToDefaults() async {
    if (_isLoading) return false;
    
    _setLoading(true);
    try {
      _isSilentMode = false;
      _isAutoTriggerEnabled = true;
      _autoTriggerDelay = 30;
      notifyListeners();
      
      final success = await _saveSettings();
      if (success) {
        _clearError();
      }
      return success;
    } catch (e) {
      _setError('Failed to reset settings: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get validation constraints for UI
  Map<String, int> get autoTriggerDelayConstraints => {
    'min': minAutoTriggerDelay,
    'max': maxAutoTriggerDelay,
  };

  void activateEmergency() {
    _isEmergencyActive = true;
    notifyListeners();
  }

  void cancelEmergency() {
    _isEmergencyActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
