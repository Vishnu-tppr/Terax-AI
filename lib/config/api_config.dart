import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

class ApiConfig {
  static const String _geminiApiKeyKey = 'gemini_api_key_secure';
  static String? _cachedApiKey;

  /// Initialize API configuration with API key (non-blocking)
  static Future<void> initializeWithApiKey() async {
    try {
      // Try to load existing key from preferences
      final prefs = await SharedPreferences.getInstance();
      _cachedApiKey = prefs.getString(_geminiApiKeyKey);

      // If no API key is found, try to load from environment
      if (_cachedApiKey == null) {
        const defaultKey = String.fromEnvironment('GEMINI_API_KEY');
        if (defaultKey.isNotEmpty) { // Only set if not empty
          await setGeminiApiKey(defaultKey);
        }
      }

      if (kDebugMode) {
        print('API key loaded from storage successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading API key from storage: $e');
        print('NOTE: App will continue with limited AI features');
      }
      // Don't rethrow - allow app to continue without API key
    }
  }

  /// Set the Gemini API key securely
  static Future<void> setGeminiApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_geminiApiKeyKey, apiKey);
      _cachedApiKey = apiKey;

      if (kDebugMode) {
        print('Gemini API key saved securely');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving API key: $e');
      }
      throw Exception('Failed to save API key securely');
    }
  }

  /// Get the Gemini API key
  static Future<String?> getGeminiApiKey() async {
    if (_cachedApiKey != null) {
      return _cachedApiKey;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedApiKey = prefs.getString(_geminiApiKeyKey);
      return _cachedApiKey;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving API key: $e');
      }
      return null;
    }
  }

  /// Check if API key is configured
  static Future<bool> hasGeminiApiKey() async {
    final apiKey = await getGeminiApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Remove the API key (for logout/reset)
  static Future<void> clearGeminiApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_geminiApiKeyKey);
      _cachedApiKey = null;

      if (kDebugMode) {
        print('Gemini API key cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing API key: $e');
      }
    }
  }

  /// Validate API key format (basic validation)
  static bool isValidApiKeyFormat(String apiKey) {
    // Gemini API keys typically start with 'AIza' and are 39 characters long
    return apiKey.isNotEmpty &&
        apiKey.length >= 30 &&
        apiKey.startsWith('AIza');
  }

  /// Get masked API key for display (shows only first 8 and last 4 characters)
  static String getMaskedApiKey(String apiKey) {
    if (apiKey.length < 12) return '***';

    final start = apiKey.substring(0, 8);
    final end = apiKey.substring(apiKey.length - 4);
    final middle = '*' * (apiKey.length - 12);

    return '$start$middle$end';
  }
}

/// Environment configuration for different build modes
class EnvironmentConfig {
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool isDebug = !isProduction;

  /// API endpoints
  static const String geminiApiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration emergencyTimeout = Duration(seconds: 10);

  /// Rate limiting
  static const int maxApiCallsPerMinute = 60;
  static const int maxEmergencyCallsPerHour = 10;

  /// Security settings
  static const bool enableApiKeyValidation = true;
  static const bool enableRequestLogging = isDebug;
  static const bool enableErrorReporting = isProduction;
}

/// API key status for UI feedback
enum ApiKeyStatus {
  notSet,
  invalid,
  valid,
  expired,
  rateLimited,
}

class ApiKeyManager {
  static ApiKeyStatus _currentStatus = ApiKeyStatus.notSet;

  /// Get current API key status
  static ApiKeyStatus get currentStatus => _currentStatus;

  /// Validate API key with actual API call (with timeout)
  static Future<ApiKeyStatus> validateApiKey([String? apiKey]) async {
    try {
      final keyToValidate = apiKey ?? await ApiConfig.getGeminiApiKey();

      if (keyToValidate == null || keyToValidate.isEmpty) {
        _currentStatus = ApiKeyStatus.notSet;
        return _currentStatus;
      }

      if (!ApiConfig.isValidApiKeyFormat(keyToValidate)) {
        _currentStatus = ApiKeyStatus.invalid;
        return _currentStatus;
      }

      // Make actual API call to validate with timeout
      final validationUrl = Uri.parse('${EnvironmentConfig.geminiApiBaseUrl}/models?key=$keyToValidate');
      final response = await http.get(validationUrl).timeout(EnvironmentConfig.apiTimeout);

      if (response.statusCode == 200) {
        _currentStatus = ApiKeyStatus.valid;
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        // 400 Bad Request or 403 Forbidden often indicates an invalid API key
        _currentStatus = ApiKeyStatus.invalid;
      } else if (response.statusCode == 429) {
        // 429 Too Many Requests indicates rate limiting
        _currentStatus = ApiKeyStatus.rateLimited;
      } else {
        // Other errors might also indicate an invalid key or temporary issues
        _currentStatus = ApiKeyStatus.invalid;
      }

      return _currentStatus;
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('API key validation timeout: $e');
        print('NOTE: Treating as network issue - validation deferred');
      }
      _currentStatus = ApiKeyStatus.notSet; // Default to not set to avoid blocking
      return _currentStatus;
    } catch (e) {
      if (kDebugMode) {
        print('API key validation error: $e');
        print('NOTE: Treating as network issue - validation deferred');
      }
      _currentStatus = ApiKeyStatus.notSet; // Default to not set to avoid blocking
      return _currentStatus;
    }
  }

  /// Get status message for UI
  static String getStatusMessage(ApiKeyStatus status) {
    switch (status) {
      case ApiKeyStatus.notSet:
        return 'API key not configured';
      case ApiKeyStatus.invalid:
        return 'Invalid API key format';
      case ApiKeyStatus.valid:
        return 'API key is valid';
      case ApiKeyStatus.expired:
        return 'API key has expired';
      case ApiKeyStatus.rateLimited:
        return 'API rate limit exceeded';
    }
  }

  /// Get status color for UI
  static String getStatusColor(ApiKeyStatus status) {
    switch (status) {
      case ApiKeyStatus.notSet:
        return '#FFA500'; // Orange
      case ApiKeyStatus.invalid:
        return '#FF0000'; // Red
      case ApiKeyStatus.valid:
        return '#00FF00'; // Green
      case ApiKeyStatus.expired:
        return '#FF0000'; // Red
      case ApiKeyStatus.rateLimited:
        return '#FFA500'; // Orange
    }
  }
}
