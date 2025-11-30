import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

enum ApiKeyType {
  backend,
  googleMaps,
  twilio,
  firebase,
  gemini,
  openai,
}

class ApiKeyConfig {
  final String key;
  final String? description;
  final DateTime? expiresAt;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  ApiKeyConfig({
    required this.key,
    this.description,
    this.expiresAt,
    this.isActive = true,
    this.metadata,
  });

  factory ApiKeyConfig.fromJson(Map<String, dynamic> json) {
    return ApiKeyConfig(
      key: json['key'],
      description: json['description'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      isActive: json['is_active'] ?? true,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'description': description,
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
      'metadata': metadata,
    };
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isValid => isActive && !isExpired;
}

class ApiKeyService {
  static ApiKeyService? _instance;
  static ApiKeyService get instance {
    _instance ??= ApiKeyService._();
    return _instance!;
  }

  ApiKeyService._();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  final Map<ApiKeyType, ApiKeyConfig> _apiKeys = {};
  bool _isInitialized = false;

  /// Initialize API key service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");

      // Load API keys from secure storage
      await _loadApiKeysFromStorage();

      // Load API keys from environment (development only)
      if (kDebugMode) {
        await _loadApiKeysFromEnvironment();
      }

      _isInitialized = true;
    } catch (e) {
      //
    }
  }

  /// Load API keys from secure storage
  Future<void> _loadApiKeysFromStorage() async {
    try {
      for (final keyType in ApiKeyType.values) {
        final keyName = _getStorageKeyName(keyType);
        final storedData = await _secureStorage.read(key: keyName);
        
        if (storedData != null) {
          final config = ApiKeyConfig.fromJson(jsonDecode(storedData));
          if (config.isValid) {
            _apiKeys[keyType] = config;
          }
        }
      }
    } catch (e) {
      //
    }
  }

  /// Load API keys from environment (development only)
  Future<void> _loadApiKeysFromEnvironment() async {
    final envMappings = {
      ApiKeyType.backend: 'CLIENT_API_KEY',
      ApiKeyType.googleMaps: 'GOOGLE_MAPS_API_KEY',
      ApiKeyType.twilio: 'TWILIO_ACCOUNT_SID', // Note: Twilio should be backend-only
      ApiKeyType.firebase: 'FIREBASE_API_KEY',
      ApiKeyType.gemini: 'GEMINI_API_KEY',
      ApiKeyType.openai: 'OPENAI_API_KEY',
    };

    for (final entry in envMappings.entries) {
      final envValue = dotenv.env[entry.value];
      if (envValue != null && envValue.isNotEmpty) {
        _apiKeys[entry.key] = ApiKeyConfig(
          key: envValue,
          description: 'Loaded from environment (${entry.value})',
          isActive: true,
        );
      }
    }
  }

  /// Store API key securely
  Future<void> storeApiKey(
    ApiKeyType type,
    String key, {
    String? description,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) async {
    final config = ApiKeyConfig(
      key: key,
      description: description,
      expiresAt: expiresAt,
      metadata: metadata,
    );

    // Store in memory
    _apiKeys[type] = config;

    // Store in secure storage
    try {
      final keyName = _getStorageKeyName(type);
      await _secureStorage.write(
        key: keyName,
        value: jsonEncode(config.toJson()),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Get API key
  String? getApiKey(ApiKeyType type) {
    final config = _apiKeys[type];
    return config?.isValid == true ? config!.key : null;
  }

  /// Get API key configuration
  ApiKeyConfig? getApiKeyConfig(ApiKeyType type) {
    return _apiKeys[type];
  }

  /// Check if API key exists and is valid
  bool hasValidApiKey(ApiKeyType type) {
    final config = _apiKeys[type];
    return config?.isValid == true;
  }

  /// Remove API key
  Future<void> removeApiKey(ApiKeyType type) async {
    _apiKeys.remove(type);

    try {
      final keyName = _getStorageKeyName(type);
      await _secureStorage.delete(key: keyName);
    } catch (e) {
      //
    }
  }

  /// Validate API key with backend
  Future<bool> validateApiKey(ApiKeyType type) async {
    final key = getApiKey(type);
    if (key == null) return false;

    try {
      switch (type) {
        case ApiKeyType.backend:
          return await _validateBackendApiKey(key);
        case ApiKeyType.googleMaps:
          return await _validateGoogleMapsApiKey(key);
        default:
          // For other types, assume valid if exists
          return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Validate backend API key
  Future<bool> _validateBackendApiKey(String key) async {
    try {
      final backendUrl = dotenv.env['BACKEND_BASE_URL'];
      if (backendUrl == null) return false;

      final dio = Dio();
      final response = await dio.get(
        '$backendUrl/health',
        options: Options(
          headers: {'x-api-key': key},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Validate Google Maps API key
  Future<bool> _validateGoogleMapsApiKey(String key) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://maps.googleapis.com/maps/api/geocode/json',
        queryParameters: {
          'address': 'New York',
          'key': key,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      return response.statusCode == 200 && 
             response.data['status'] != 'REQUEST_DENIED';
    } catch (e) {
      return false;
    }
  }

  /// Get all stored API key types
  List<ApiKeyType> getStoredApiKeyTypes() {
    return _apiKeys.keys.where((type) => _apiKeys[type]?.isValid == true).toList();
  }

  /// Clear all API keys
  Future<void> clearAllApiKeys() async {
    for (final type in ApiKeyType.values) {
      await removeApiKey(type);
    }
    _apiKeys.clear();
  }

  /// Get storage key name for API key type
  String _getStorageKeyName(ApiKeyType type) {
    return 'api_key_${type.toString().split('.').last}';
  }

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Get API key status summary
  Map<String, dynamic> getApiKeyStatus() {
    final status = <String, dynamic>{};
    
    for (final type in ApiKeyType.values) {
      final config = _apiKeys[type];
      status[type.toString().split('.').last] = {
        'exists': config != null,
        'valid': config?.isValid ?? false,
        'expired': config?.isExpired ?? false,
        'description': config?.description,
        'expires_at': config?.expiresAt?.toIso8601String(),
      };
    }
    
    return status;
  }

  /// Refresh expired API keys (placeholder for future implementation)
  Future<void> refreshExpiredApiKeys() async {
    final expiredKeys = _apiKeys.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    if (expiredKeys.isNotEmpty) {
      // Future enhancement: Implement automatic refresh logic if supported by the API provider
      // This would require specific implementation for each API provider (Google, OpenAI, etc.)
      // For now, expired keys will need to be manually updated by the user
      if (kDebugMode) {
        print('Found ${expiredKeys.length} expired API keys that need manual refresh');
      }
    }
  }
}