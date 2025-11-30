import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealLocationService {
  static RealLocationService? _instance;
  static RealLocationService get instance {
    _instance ??= RealLocationService._();
    return _instance!;
  }

  RealLocationService._();

  Position? _currentPosition;
  String? _currentAddress;
  StreamSubscription<Position>? _positionStream;
  final StreamController<LocationUpdate> _locationController =
      StreamController<LocationUpdate>.broadcast();

  // Real-time streaming and backend integration
  final Dio _dio = Dio();
  Timer? _streamingTimer;
  bool _isStreamingToBackend = false;
  bool _isBackgroundTrackingEnabled = false;
  String? _backendUrl;
  String? _apiKey;

  // Location sharing
  final List<String> _sharedWithContacts = [];
  Timer? _locationShareTimer;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  Stream<LocationUpdate> get locationStream => _locationController.stream;

  /// Initialize location services
  Future<LocationResult> initialize() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult(
          success: false,
          message:
              'Location services are disabled. Please enable them in settings.',
          position: null,
          address: null,
        );
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationResult(
            success: false,
            message: 'Location permission denied',
            position: null,
            address: null,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationResult(
          success: false,
          message:
              'Location permissions are permanently denied. Please enable them in app settings.',
          position: null,
          address: null,
        );
      }

      // Get current location
      final result = await getCurrentLocation();
      if (result.success) {
        // Start background tracking
        await startLocationTracking();
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Location service initialization error: $e');
      }
      return LocationResult(
        success: false,
        message: 'Failed to initialize location services: $e',
        position: null,
        address: null,
      );
    }
  }

  /// Get current location
  Future<LocationResult> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentPosition = position;

      // Get address from coordinates
      String? address = await _getAddressFromPosition(position);
      _currentAddress = address;

      // Notify listeners
      _locationController.add(LocationUpdate(
        position: position,
        address: address,
        timestamp: DateTime.now(),
      ));

      return LocationResult(
        success: true,
        message: 'Location retrieved successfully',
        position: position,
        address: address,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Get current location error: $e');
      }
      return LocationResult(
        success: false,
        message: 'Failed to get current location: $e',
        position: null,
        address: null,
      );
    }
  }

  /// Start continuous location tracking
  Future<void> startLocationTracking() async {
    try {
      // Stop existing stream if any
      await stopLocationTracking();

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          _currentPosition = position;

          // Get address (but don't wait for it to avoid blocking)
          _getAddressFromPosition(position).then((address) {
            _currentAddress = address;

            // Notify listeners
            _locationController.add(LocationUpdate(
              position: position,
              address: address,
              timestamp: DateTime.now(),
            ));
          });
        },
        onError: (error) {
          if (kDebugMode) {
            print('Location tracking error: $error');
          }
        },
      );

      if (kDebugMode) {
        print('Location tracking started');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Start location tracking error: $e');
      }
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;

    // Stop streaming to backend
    await stopLocationStreaming();

    if (kDebugMode) {
      print('Location tracking stopped');
    }
  }

  /// Initialize backend connection for location streaming
  Future<void> initializeBackend({
    required String backendUrl,
    required String apiKey,
  }) async {
    _backendUrl = backendUrl;
    _apiKey = apiKey;

    _dio.options.baseUrl = backendUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    if (kDebugMode) {
      print('Location service backend initialized: $backendUrl');
    }
  }

  /// Start streaming location to backend
  Future<void> startLocationStreaming({
    Duration interval = const Duration(seconds: 30),
  }) async {
    if (_backendUrl == null || _apiKey == null) {
      throw Exception(
          'Backend not initialized. Call initializeBackend() first.');
    }

    if (_isStreamingToBackend) {
      if (kDebugMode) {
        print('Location streaming already active');
      }
      return;
    }

    _isStreamingToBackend = true;

    _streamingTimer = Timer.periodic(interval, (timer) async {
      if (_currentPosition != null) {
        await _sendLocationToBackend(_currentPosition!);
      }
    });

    if (kDebugMode) {
      print(
          'Location streaming to backend started (interval: ${interval.inSeconds}s)');
    }
  }

  /// Stop streaming location to backend
  Future<void> stopLocationStreaming() async {
    _streamingTimer?.cancel();
    _streamingTimer = null;
    _isStreamingToBackend = false;

    if (kDebugMode) {
      print('Location streaming to backend stopped');
    }
  }

  /// Send current location to backend
  Future<void> _sendLocationToBackend(Position position) async {
    if (_backendUrl == null || _apiKey == null) return;

    try {
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'heading': position.heading,
        'speed': position.speed,
        'timestamp': DateTime.now().toIso8601String(),
        'address': _currentAddress,
      };

      await _dio.post(
        '/v1/emergency/location-stream',
        data: locationData,
      );

      if (kDebugMode) {
        print(
            'Location sent to backend: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending location to backend: $e');
      }
    }
  }

  /// Get address from coordinates
  Future<String?> _getAddressFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Geocoding error: $e');
      }
    }

    // Fallback to coordinates if geocoding fails
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Get formatted location string for emergency messages
  String getEmergencyLocationString() {
    if (_currentPosition == null) {
      return 'Location unavailable';
    }

    String locationString = '';

    if (_currentAddress != null && _currentAddress!.isNotEmpty) {
      locationString = _currentAddress!;
    } else {
      locationString = 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
          'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}';
    }

    // Add accuracy info
    locationString += ' (±${_currentPosition!.accuracy.toStringAsFixed(0)}m)';

    return locationString;
  }

  /// Get Google Maps URL for current location
  String? getGoogleMapsUrl() {
    if (_currentPosition == null) return null;

    return 'https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
  }

  /// Calculate distance between two positions
  double calculateDistance(Position pos1, Position pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }

  /// Check if location permissions are granted
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permissions
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Start location sharing with contacts
  Future<void> startLocationSharing({
    required List<String> contacts,
    Duration interval = const Duration(minutes: 5),
    String? customMessage,
  }) async {
    _sharedWithContacts.clear();
    _sharedWithContacts.addAll(contacts);

    // Stop existing sharing timer
    _locationShareTimer?.cancel();

    // Start sharing timer
    _locationShareTimer = Timer.periodic(interval, (timer) async {
      if (_currentPosition != null && _sharedWithContacts.isNotEmpty) {
        await _shareLocationWithContacts(customMessage);
      }
    });

    // Send initial location immediately
    if (_currentPosition != null) {
      await _shareLocationWithContacts(customMessage);
    }

    if (kDebugMode) {
      print('Location sharing started with ${contacts.length} contacts');
    }
  }

  /// Stop location sharing
  Future<void> stopLocationSharing() async {
    _locationShareTimer?.cancel();
    _locationShareTimer = null;
    _sharedWithContacts.clear();

    if (kDebugMode) {
      print('Location sharing stopped');
    }
  }

  /// Share current location with contacts via SMS
  Future<void> _shareLocationWithContacts(String? customMessage) async {
    if (_currentPosition == null || _backendUrl == null || _apiKey == null) {
      return;
    }

    try {
      final shareData = {
        'recipients': _sharedWithContacts,
        'lat': _currentPosition!.latitude,
        'lon': _currentPosition!.longitude,
        'custom_message': customMessage,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _dio.post(
        '/v1/emergency/share-location',
        data: shareData,
      );

      if (kDebugMode) {
        print('Location shared with ${_sharedWithContacts.length} contacts');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing location: $e');
      }
    }
  }

  /// Enable background location tracking
  Future<void> enableBackgroundTracking() async {
    try {
      // Check for background location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.always) {
          throw Exception('Background location permission required');
        }
      }

      // Initialize workmanager for background tasks
      await Workmanager().initialize(
        callbackDispatcher,
      );

      // Register background location task
      await Workmanager().registerPeriodicTask(
        'background_location_task',
        'backgroundLocationTask',
        frequency: const Duration(minutes: 15), // Minimum allowed by Android
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );

      _isBackgroundTrackingEnabled = true;

      // Save settings
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_tracking_enabled', true);
      await prefs.setString('backend_url', _backendUrl ?? '');
      await prefs.setString('api_key', _apiKey ?? '');

      if (kDebugMode) {
        print('Background location tracking enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error enabling background tracking: $e');
      }
      rethrow;
    }
  }

  /// Disable background location tracking
  Future<void> disableBackgroundTracking() async {
    try {
      await Workmanager().cancelByUniqueName('background_location_task');
      _isBackgroundTrackingEnabled = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('background_tracking_enabled', false);

      if (kDebugMode) {
        print('Background location tracking disabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error disabling background tracking: $e');
      }
    }
  }

  /// Get location sharing status
  bool get isLocationSharing => _locationShareTimer?.isActive ?? false;

  /// Get streaming status
  bool get isStreamingToBackend => _isStreamingToBackend;

  /// Get background tracking status
  bool get isBackgroundTrackingEnabled => _isBackgroundTrackingEnabled;

  /// Get shared contacts
  List<String> get sharedWithContacts => List.unmodifiable(_sharedWithContacts);

  /// Calculate distance between two positions
  static double getDistanceBetween(Position pos1, Position pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }

  /// Format coordinates for display
  static String formatCoordinates(Position position) {
    return '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
    stopLocationStreaming();
    stopLocationSharing();
    _locationController.close();
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'backgroundLocationTask') {
      try {
        // Get current location
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        // Get stored backend configuration
        final prefs = await SharedPreferences.getInstance();
        final backendUrl = prefs.getString('backend_url');
        final apiKey = prefs.getString('api_key');

        if (backendUrl != null && apiKey != null) {
          // Send location to backend
          final dio = Dio();
          dio.options.baseUrl = backendUrl;
          dio.options.headers = {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
          };

          final locationData = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'accuracy': position.accuracy,
            'timestamp': DateTime.now().toIso8601String(),
            'source': 'background_task',
          };

          await dio.post('/v1/emergency/location-stream', data: locationData);

          if (kDebugMode) {
            print(
                'Background location sent: ${position.latitude}, ${position.longitude}');
          }
        }

        return Future.value(true);
      } catch (e) {
        if (kDebugMode) {
          print('Background location task error: $e');
        }
        return Future.value(false);
      }
    }
    return Future.value(false);
  });
}

class LocationResult {
  final bool success;
  final String message;
  final Position? position;
  final String? address;

  LocationResult({
    required this.success,
    required this.message,
    required this.position,
    required this.address,
  });

  @override
  String toString() {
    return 'LocationResult(success: $success, message: $message, position: $position, address: $address)';
  }
}

class LocationUpdate {
  final Position position;
  final String? address;
  final DateTime timestamp;

  LocationUpdate({
    required this.position,
    required this.address,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LocationUpdate(position: ${position.latitude}, ${position.longitude}, address: $address, timestamp: $timestamp)';
  }
}
