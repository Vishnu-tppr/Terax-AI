import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricAuthService {
  static BiometricAuthService? _instance;
  static BiometricAuthService get instance {
    _instance ??= BiometricAuthService._(LocalAuthentication(), const FlutterSecureStorage());
    return _instance!;
  }

  BiometricAuthService._(this._localAuth, this._secureStorage);

  LocalAuthentication _localAuth;
  FlutterSecureStorage _secureStorage;
  bool _isInitialized = false;
  List<BiometricType> _availableBiometrics = [];

  /// Test-only setters for dependency injection
  @visibleForTesting
  set auth(LocalAuthentication localAuth) {
    _localAuth = localAuth;
  }

  @visibleForTesting
  set storage(FlutterSecureStorage secureStorage) {
    _secureStorage = secureStorage;
  }

  static const String _pinHashKey = 'biometric_pin_hash';
  static const String _pinSaltKey = 'biometric_pin_salt';
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Initialize biometric authentication
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Check if device supports biometrics
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        if (kDebugMode) {
          print('Biometric authentication not available on this device');
        }
        return false;
      }

      // Get available biometric types
      _availableBiometrics = await _localAuth.getAvailableBiometrics();

      _isInitialized = true;
      if (kDebugMode) {
        print('Biometric auth initialized. Available: $_availableBiometrics');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing biometric auth: $e');
      }
      return false;
    }
  }

  /// Check if biometric authentication is available
  Future<BiometricAvailability> checkAvailability() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (!canCheckBiometrics || !isDeviceSupported) {
        return BiometricAvailability(
          isAvailable: false,
          reason: 'Device does not support biometric authentication',
          availableTypes: [],
        );
      }

      if (availableBiometrics.isEmpty) {
        return BiometricAvailability(
          isAvailable: false,
          reason: 'No biometric methods enrolled on device',
          availableTypes: [],
        );
      }

      return BiometricAvailability(
        isAvailable: true,
        reason: 'Biometric authentication available',
        availableTypes: availableBiometrics,
      );
    } catch (e) {
      return BiometricAvailability(
        isAvailable: false,
        reason: 'Error checking biometric availability: $e',
        availableTypes: [],
      );
    }
  }

  /// Authenticate using biometrics
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    BiometricAuthType preferredType = BiometricAuthType.any,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return BiometricAuthResult(
          isAuthenticated: false,
          error: 'Biometric authentication not available',
          errorType: BiometricErrorType.notAvailable,
        );
      }
    }

    try {
      // Configure authentication options
      final authOptions = AuthenticationOptions(
        useErrorDialogs: useErrorDialogs,
        stickyAuth: stickyAuth,
        biometricOnly: preferredType != BiometricAuthType.any,
      );

      // Platform-specific options
      final androidOptions = AndroidAuthMessages(
        signInTitle: 'Biometric Authentication',
        biometricHint: reason,
        biometricNotRecognized: 'Biometric not recognized, try again',
        biometricRequiredTitle: 'Biometric Required',
        biometricSuccess: 'Authentication successful',
        cancelButton: 'Cancel',
        deviceCredentialsRequiredTitle: 'Device Credentials Required',
        deviceCredentialsSetupDescription: 'Please set up device credentials',
        goToSettingsButton: 'Go to Settings',
        goToSettingsDescription: 'Please set up biometric authentication',
      );

      final iosOptions = IOSAuthMessages(
        cancelButton: 'Cancel',
        goToSettingsButton: 'Go to Settings',
        goToSettingsDescription: 'Please set up biometric authentication',
        lockOut: 'Biometric authentication is locked out',
      );

      // Perform authentication
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: [androidOptions, iosOptions],
        options: authOptions,
      );

      if (isAuthenticated) {
        if (kDebugMode) {
          print('Biometric authentication successful');
        }
        return BiometricAuthResult(
          isAuthenticated: true,
          authenticatedBiometric: _getAuthenticatedBiometric(),
        );
      } else {
        return BiometricAuthResult(
          isAuthenticated: false,
          error: 'Authentication cancelled or failed',
          errorType: BiometricErrorType.userCancel,
        );
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Biometric authentication error: ${e.code} - ${e.message}');
      }

      final errorType = _mapPlatformExceptionToErrorType(e.code);
      return BiometricAuthResult(
        isAuthenticated: false,
        error: e.message ?? 'Unknown biometric error',
        errorType: errorType,
        platformError: e,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected biometric error: $e');
      }
      return BiometricAuthResult(
        isAuthenticated: false,
        error: 'Unexpected error during authentication',
        errorType: BiometricErrorType.unknown,
      );
    }
  }

  /// Quick fingerprint authentication for emergency features
  Future<bool> quickFingerprintAuth({String? reason}) async {
    final result = await authenticate(
      reason: reason ?? 'Verify your identity for emergency access',
      useErrorDialogs: false,
      stickyAuth: false,
      preferredType: BiometricAuthType.fingerprint,
    );
    return result.isAuthenticated;
  }

  /// Emergency bypass authentication (for critical situations)
  Future<BiometricAuthResult> emergencyAuthentication() async {
    return await authenticate(
      reason: 'EMERGENCY: Verify identity to access safety features',
      useErrorDialogs: true,
      stickyAuth: true,
      preferredType: BiometricAuthType.any,
    );
  }

  /// Silent authentication attempt (no UI)
  Future<bool> silentAuthentication() async {
    try {
      final result = await authenticate(
        reason: 'Silent authentication',
        useErrorDialogs: false,
        stickyAuth: false,
      );
      return result.isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  List<BiometricType> get availableBiometrics => _availableBiometrics;

  /// Check if specific biometric type is available
  bool hasBiometricType(BiometricType type) {
    return _availableBiometrics.contains(type);
  }

  /// Check if fingerprint is available
  bool get hasFingerprint => hasBiometricType(BiometricType.fingerprint);

  /// Check if face recognition is available
  bool get hasFaceRecognition => hasBiometricType(BiometricType.face);

  /// Check if iris recognition is available
  bool get hasIrisRecognition => hasBiometricType(BiometricType.iris);

  /// Get user-friendly biometric type names
  List<String> get availableBiometricNames {
    return _availableBiometrics.map((type) {
      switch (type) {
        case BiometricType.fingerprint:
          return 'Fingerprint';
        case BiometricType.face:
          return 'Face Recognition';
        case BiometricType.iris:
          return 'Iris Recognition';
        case BiometricType.strong:
          return 'Strong Biometric';
        case BiometricType.weak:
          return 'Weak Biometric';
      }
    }).toList();
  }

  /// Get the most likely authenticated biometric type
  BiometricType? _getAuthenticatedBiometric() {
    if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return BiometricType.iris;
    }
    return _availableBiometrics.isNotEmpty ? _availableBiometrics.first : null;
  }

  /// Map platform exception codes to error types
  BiometricErrorType _mapPlatformExceptionToErrorType(String code) {
    switch (code) {
      case 'NotAvailable':
      case 'NotEnrolled':
        return BiometricErrorType.notAvailable;
      case 'UserCancel':
        return BiometricErrorType.userCancel;
      case 'UserFallback':
        return BiometricErrorType.userFallback;
      case 'SystemCancel':
        return BiometricErrorType.systemCancel;
      case 'InvalidContext':
        return BiometricErrorType.invalidContext;
      case 'NotInteractive':
        return BiometricErrorType.notInteractive;
      case 'LockOut':
      case 'PermanentlyLockedOut':
        return BiometricErrorType.lockedOut;
      case 'BiometricOnlyNotSupported':
        return BiometricErrorType.biometricOnlyNotSupported;
      default:
        return BiometricErrorType.unknown;
    }
  }

  /// Stop any ongoing authentication
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping authentication: $e');
      }
    }
  }

  /// Check if biometric authentication is initialized
  bool get isInitialized => _isInitialized;

  // PIN Fallback Methods

  /// Check if biometric authentication is enabled in settings
  Future<bool> isBiometricEnabled() async {
    try {
      final String? enabled =
          await _secureStorage.read(key: _biometricEnabledKey);
      return enabled == 'true';
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric enabled status: $e');
      }
      return false;
    }
  }

  /// Enable or disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error setting biometric enabled status: $e');
      }
    }
  }

  /// Set up a PIN for fallback authentication
  Future<bool> setupPin(String pin) async {
    try {
      if (pin.length < 4 || pin.length > 6) {
        return false;
      }

      // Generate a random salt
      final List<int> saltBytes = List.generate(
          32, (i) => DateTime.now().millisecondsSinceEpoch.hashCode + i);
      final String salt = base64Encode(saltBytes);

      // Hash the PIN with salt
      final String hashedPin = _hashPin(pin, salt);

      // Store the hashed PIN and salt securely
      await _secureStorage.write(key: _pinHashKey, value: hashedPin);
      await _secureStorage.write(key: _pinSaltKey, value: salt);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up PIN: $e');
      }
      return false;
    }
  }

  /// Verify PIN for fallback authentication
  Future<BiometricAuthResult> verifyPin(String pin) async {
    try {
      final String? storedHash = await _secureStorage.read(key: _pinHashKey);
      final String? salt = await _secureStorage.read(key: _pinSaltKey);

      if (storedHash == null || salt == null) {
        return BiometricAuthResult(
          isAuthenticated: false,
          error: 'PIN not set up',
          errorType: BiometricErrorType.notAvailable,
        );
      }

      final String hashedPin = _hashPin(pin, salt);

      if (hashedPin == storedHash) {
        return BiometricAuthResult(
          isAuthenticated: true,
          authenticatedBiometric: null, // PIN authentication
        );
      } else {
        return BiometricAuthResult(
          isAuthenticated: false,
          error: 'Incorrect PIN',
          errorType: BiometricErrorType.pinIncorrect,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying PIN: $e');
      }
      return BiometricAuthResult(
        isAuthenticated: false,
        error: 'Error verifying PIN',
        errorType: BiometricErrorType.unknown,
      );
    }
  }

  /// Check if PIN is set up
  Future<bool> isPinSetup() async {
    try {
      final String? storedHash = await _secureStorage.read(key: _pinHashKey);
      return storedHash != null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking PIN setup: $e');
      }
      return false;
    }
  }

  /// Remove PIN (for security reset)
  Future<void> removePin() async {
    try {
      await _secureStorage.delete(key: _pinHashKey);
      await _secureStorage.delete(key: _pinSaltKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error removing PIN: $e');
      }
    }
  }

  /// Hash PIN with salt using SHA-256
  String _hashPin(String pin, String salt) {
    final List<int> bytes = utf8.encode(pin + salt);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Clear all biometric data (for logout/reset)
  Future<void> clearAllData() async {
    try {
      await _secureStorage.delete(key: _pinHashKey);
      await _secureStorage.delete(key: _pinSaltKey);
      await _secureStorage.delete(key: _biometricEnabledKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing biometric data: $e');
      }
    }
  }

  /// Authenticate with fallback to PIN
  Future<BiometricAuthResult> authenticateWithFallback({
    String reason = 'Please authenticate to access secure features',
    bool allowPinFallback = true,
  }) async {
    // First try biometric authentication
    final biometricResult = await authenticate(reason: reason);

    if (biometricResult.isAuthenticated) {
      return biometricResult;
    }

    // If biometric fails and PIN fallback is allowed, check if PIN is available
    if (allowPinFallback && await isPinSetup()) {
      return BiometricAuthResult(
        isAuthenticated: false,
        error: 'PIN authentication required',
        errorType: BiometricErrorType.userFallback,
      );
    }

    return biometricResult;
  }

  /// Dispose of resources
  void dispose() {
    _isInitialized = false;
    _availableBiometrics.clear();
  }

  /// Check if biometric authentication is available (like checkAvailability but returns bool)
  Future<bool> isBiometricAvailable() async {
    try {
      final availability = await checkAvailability();
      return availability.isAvailable;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric availability: $e');
      }
      return false;
    }
  }

  /// Get result message for different authentication results
  static String getResultMessage(BiometricAuthResult result) {
    if (result.isAuthenticated) {
      return 'Authentication successful';
    }

    switch (result.errorType) {
      case BiometricErrorType.notAvailable:
        return 'Biometric authentication not available';
      case BiometricErrorType.lockedOut:
        return 'Biometric authentication is locked out';
      case BiometricErrorType.userCancel:
        return 'Authentication cancelled';
      case BiometricErrorType.userFallback:
        return 'PIN authentication required';
      case BiometricErrorType.failed:
        return 'Authentication failed';
      case BiometricErrorType.pinIncorrect:
        return 'Incorrect PIN';
      default:
        return 'Unknown authentication error';
    }
  }
}

// Data classes
class BiometricAvailability {
  final bool isAvailable;
  final String reason;
  final List<BiometricType> availableTypes;

  BiometricAvailability({
    required this.isAvailable,
    required this.reason,
    required this.availableTypes,
  });
}

class BiometricAuthResult {
  final bool isAuthenticated;
  final String? error;
  final BiometricErrorType? errorType;
  final BiometricType? authenticatedBiometric;
  final PlatformException? platformError;

  BiometricAuthResult({
    required this.isAuthenticated,
    this.error,
    this.errorType,
    this.authenticatedBiometric,
    this.platformError,
  });

  bool get isSuccess => isAuthenticated;
  bool get isError => !isAuthenticated;

  // Static constants for common results
  static BiometricAuthResult get success => BiometricAuthResult(
    isAuthenticated: true,
  );

  static BiometricAuthResult get failed => BiometricAuthResult(
    isAuthenticated: false,
    error: 'Biometric authentication failed',
    errorType: BiometricErrorType.failed,
  );

  static BiometricAuthResult get notAvailable => BiometricAuthResult(
    isAuthenticated: false,
    error: 'Biometric authentication not available',
    errorType: BiometricErrorType.notAvailable,
  );

  static BiometricAuthResult get cancelled => BiometricAuthResult(
    isAuthenticated: false,
    error: 'Authentication cancelled',
    errorType: BiometricErrorType.userCancel,
  );

  static BiometricAuthResult get pinIncorrect => BiometricAuthResult(
    isAuthenticated: false,
    error: 'Incorrect PIN',
    errorType: BiometricErrorType.pinIncorrect,
  );
}

enum BiometricAuthType {
  any,
  fingerprint,
  face,
  iris,
}

enum BiometricErrorType {
  notAvailable,
  userCancel,
  userFallback,
  systemCancel,
  invalidContext,
  notInteractive,
  lockedOut,
  biometricOnlyNotSupported,
  failed,
  pinIncorrect,
  unknown,
}