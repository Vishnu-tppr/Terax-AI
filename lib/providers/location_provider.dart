import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';

class LocationProvider extends ChangeNotifier {
  bool _isLocationEnabled = false;
  bool _isLocationPermissionGranted = false;
  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentAddress;
  bool _isTrackingEnabled = false;
  bool _isLoadingLocation = false;
  StreamSubscription<Position>? _positionStream;

  // Getters
  bool get isLocationEnabled => _isLocationEnabled;
  bool get isLocationPermissionGranted => _isLocationPermissionGranted;
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String? get currentAddress => _currentAddress;
  bool get isTrackingEnabled => _isTrackingEnabled;
  bool get isLoadingLocation => _isLoadingLocation;

  LocationProvider() {
    _loadLocationSettings();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadLocationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLocationEnabled = prefs.getBool('location_enabled') ?? false;
      _isTrackingEnabled = prefs.getBool('location_tracking') ?? false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading location settings: $e');
      }
    }
  }

  Future<void> _saveLocationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('location_enabled', _isLocationEnabled);
      await prefs.setBool('location_tracking', _isTrackingEnabled);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving location settings: $e');
      }
    }
  }

  void toggleLocation() {
    _isLocationEnabled = !_isLocationEnabled;
    _saveLocationSettings();
    notifyListeners();
  }

  void setLocationPermissionGranted(bool granted) {
    _isLocationPermissionGranted = granted;
    notifyListeners();
  }

  void updateCurrentLocation(double latitude, double longitude) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    notifyListeners();
  }

  void updateCurrentAddress(String address) {
    _currentAddress = address;
    notifyListeners();
  }

  void toggleTracking() {
    _isTrackingEnabled = !_isTrackingEnabled;

    if (_isTrackingEnabled && _isLocationPermissionGranted) {
      _startLocationTracking();
    } else {
      _stopLocationTracking();
    }

    _saveLocationSettings();
    notifyListeners();
  }

  void clearLocation() {
    _currentLatitude = null;
    _currentLongitude = null;
    _currentAddress = null;
    notifyListeners();
  }

  bool get hasValidLocation =>
      _currentLatitude != null &&
      _currentLongitude != null &&
      _isLocationEnabled &&
      _isLocationPermissionGranted;

  // Convenience getter for location status
  bool get hasLocation => hasValidLocation;

  String get locationStatus {
    if (!_isLocationEnabled) return 'Disabled';
    if (!_isLocationPermissionGranted) return 'Permission Required';
    if (!hasValidLocation) return 'No Location';
    return 'Active';
  }

  // Check current location permission status
  Future<void> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      _isLocationPermissionGranted = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _isLocationEnabled = serviceEnabled && _isLocationPermissionGranted;

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permission: $e');
      }
    }
  }

  // Request location permission
  Future<void> requestLocationPermission() async {
    try {
      _isLoadingLocation = true;
      notifyListeners();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print('Location services are disabled');
        }
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Check current permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('Location permissions are denied');
          }
          _isLoadingLocation = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print('Location permissions are permanently denied');
        }
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      // Permission granted, update status and get current location
      _isLocationPermissionGranted = true;
      _isLocationEnabled = true;
      await getCurrentLocation();

      // Start tracking if enabled
      if (_isTrackingEnabled) {
        _startLocationTracking();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error requesting location permission: $e');
      }
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Get current location
  Future<void> getCurrentLocation() async {
    try {
      if (!_isLocationPermissionGranted) {
        await requestLocationPermission();
        return;
      }

      _isLoadingLocation = true;
      notifyListeners();

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  // Get address from coordinates
  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentAddress =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting address: $e');
      }
      _currentAddress = 'Unknown location';
    }
  }

  // Start location tracking
  void _startLocationTracking() {
    if (!_isLocationPermissionGranted || _positionStream != null) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _getAddressFromCoordinates(position.latitude, position.longitude);
        notifyListeners();
      },
      onError: (error) {
        if (kDebugMode) {
          print('Location tracking error: $error');
        }
      },
    );
  }

  // Stop location tracking
  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
