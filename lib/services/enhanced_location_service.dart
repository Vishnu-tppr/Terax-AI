import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final String? address;
  final Map<String, dynamic>? metadata;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
    this.address,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp.toIso8601String(),
    'accuracy': accuracy,
    'address': address,
    'metadata': metadata,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    latitude: json['latitude'],
    longitude: json['longitude'],
    timestamp: DateTime.parse(json['timestamp']),
    accuracy: json['accuracy'],
    address: json['address'],
    metadata: json['metadata'],
  );
}

class EnhancedLocationService {
  static EnhancedLocationService? _instance;
  static EnhancedLocationService get instance {
    _instance ??= EnhancedLocationService._();
    return _instance!;
  }

  EnhancedLocationService._();

  Position? _lastKnownPosition;
  String? _currentAddress;
  DateTime? _lastLocationUpdate;
  StreamSubscription<Position>? _positionStream;
  final List<LocationData> _locationHistory = [];
  bool _isTracking = false;

  // Getters
  Position? get lastKnownPosition => _lastKnownPosition;
  String? get currentAddress => _currentAddress;
  DateTime? get lastLocationUpdate => _lastLocationUpdate;
  bool get isTracking => _isTracking;
  List<LocationData> get locationHistory => List.unmodifiable(_locationHistory);

  /// Initialize location service
  Future<bool> initialize() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled');
        }
        return false;
      }

      final permission = await _checkPermissions();
      if (!permission) {
        if (kDebugMode) {
          print('Location permissions denied');
        }
        return false;
      }

      // Get initial location
      await getCurrentLocation();
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing location service: $e');
      }
      return false;
    }
  }

  /// Check and request location permissions
  Future<bool> _checkPermissions() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Open app settings
        await Geolocator.openAppSettings();
        return false;
      }

      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permissions: $e');
      }
      return false;
    }
  }

  /// Get current location with high accuracy
  Future<Position?> getCurrentLocation({
    bool highAccuracy = true,
    Duration? timeout,
  }) async {
    try {
      if (!await _checkPermissions()) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
          timeLimit: timeout ?? const Duration(seconds: 30),
        ),
      );

      _lastKnownPosition = position;
      _lastLocationUpdate = DateTime.now();
      
      // Update address
      await _updateCurrentAddress(position);
      
      // Store location history
      _locationHistory.add(LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        address: _currentAddress,
      ));
      
      // Keep only last 100 locations
      if (_locationHistory.length > 100) {
        _locationHistory.removeAt(0);
      }
      
      return position;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
      return null;
    }
  }

  /// Update current address from position
  Future<void> _updateCurrentAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        _currentAddress = _formatAddress(placemark);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting address: $e');
      }
    }
  }

  /// Format address from placemark
  String _formatAddress(Placemark placemark) {
    final parts = <String>[];
    
    if (placemark.street?.isNotEmpty == true) {
      parts.add(placemark.street!);
    }
    if (placemark.locality?.isNotEmpty == true) {
      parts.add(placemark.locality!);
    }
    if (placemark.administrativeArea?.isNotEmpty == true) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country?.isNotEmpty == true) {
      parts.add(placemark.country!);
    }
    
    return parts.join(', ');
  }

  /// Start continuous location tracking
  Future<bool> startTracking({
    Duration interval = const Duration(seconds: 30),
    double distanceFilter = 10.0,
  }) async {
    try {
      if (_isTracking) {
        return true;
      }

      if (!await _checkPermissions()) {
        return false;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _lastKnownPosition = position;
          _lastLocationUpdate = DateTime.now();
          _updateCurrentAddress(position);
          
          // Add to history
          _locationHistory.add(LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            accuracy: position.accuracy,
            address: _currentAddress,
          ));
          
          // Keep only last 100 locations
          if (_locationHistory.length > 100) {
            _locationHistory.removeAt(0);
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Location tracking error: $error');
          }
        },
      );

      _isTracking = true;
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting location tracking: $e');
      }
      return false;
    }
  }

  /// Stop location tracking
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
  }

  /// Get distance between two points in meters
  double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Get Google Maps URL for current location
  String? getGoogleMapsUrl() {
    if (_lastKnownPosition == null) return null;
    
    return 'https://maps.google.com/?q=${_lastKnownPosition!.latitude},${_lastKnownPosition!.longitude}';
  }

  /// Get location sharing message
  String getLocationSharingMessage({String? customMessage}) {
    if (_lastKnownPosition == null) {
      return 'Location not available';
    }

    final message = customMessage ?? 'Here is my current location:';
    final mapsUrl = getGoogleMapsUrl()!;
    final address = _currentAddress ?? 'Address not available';
    
    return '$message\n\n📍 $address\n🗺️ $mapsUrl\n\n⏰ Shared at ${DateTime.now().toString()}';
  }

  /// Check if location is accurate enough
  bool isLocationAccurate({double maxAccuracyMeters = 50.0}) {
    if (_lastKnownPosition == null) return false;
    return _lastKnownPosition!.accuracy <= maxAccuracyMeters;
  }

  /// Get location age in minutes
  int? getLocationAgeMinutes() {
    if (_lastLocationUpdate == null) return null;
    return DateTime.now().difference(_lastLocationUpdate!).inMinutes;
  }

  /// Check if location is recent
  bool isLocationRecent({Duration maxAge = const Duration(minutes: 5)}) {
    if (_lastLocationUpdate == null) return false;
    return DateTime.now().difference(_lastLocationUpdate!) <= maxAge;
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
    _locationHistory.clear();
  }
}
