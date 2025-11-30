import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shake/shake.dart';

class GestureDetectionService {
  static GestureDetectionService? _instance;
  static GestureDetectionService get instance {
    _instance ??= GestureDetectionService._();
    return _instance!;
  }

  GestureDetectionService._();

  // Shake detection
  ShakeDetector? _shakeDetector;
  bool _isShakeDetectionEnabled = false;
  double _shakeThreshold = 12.0;
  int _shakeCount = 0;
  Timer? _shakeResetTimer;

  // Tap detection
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isTapDetectionEnabled = false;
  double _tapSensitivity = 0.8;
  int _tapCount = 0;
  Timer? _tapResetTimer;
  final List<double> _accelerometerHistory = [];
  static const int _historyLength = 10;

  // Gesture callbacks
  Function()? _onEmergencyGestureDetected;
  Function(String)? _onGestureDetected;

  // Stream controllers
  final StreamController<GestureEvent> _gestureController =
      StreamController<GestureEvent>.broadcast();

  Stream<GestureEvent> get gestureStream => _gestureController.stream;

  /// Initialize gesture detection
  Future<bool> initialize() async {
    try {
      if (kDebugMode) {
        print('Initializing gesture detection service');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing gesture detection: $e');
      }
      return false;
    }
  }

  /// Set emergency gesture callback
  void setEmergencyCallback(Function() callback) {
    _onEmergencyGestureDetected = callback;
  }

  /// Set general gesture callback
  void setGestureCallback(Function(String) callback) {
    _onGestureDetected = callback;
  }

  /// Start shake detection
  Future<void> startShakeDetection({double threshold = 12.0}) async {
    if (_isShakeDetectionEnabled) return;

    try {
      _shakeThreshold = threshold;
      _shakeDetector = ShakeDetector.autoStart(
        onPhoneShake: (ShakeEvent event) => _onShakeDetected(),
        minimumShakeCount: 1,
        shakeSlopTimeMS: 500,
        shakeCountResetTime: 3000,
        shakeThresholdGravity: threshold,
      );

      _isShakeDetectionEnabled = true;
      if (kDebugMode) {
        print('Shake detection started with threshold: $threshold');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting shake detection: $e');
      }
    }
  }

  /// Stop shake detection
  void stopShakeDetection() {
    if (!_isShakeDetectionEnabled) return;

    try {
      _shakeDetector?.stopListening();
      _shakeDetector = null;
      _isShakeDetectionEnabled = false;
      _shakeCount = 0;
      _shakeResetTimer?.cancel();

      if (kDebugMode) {
        print('Shake detection stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping shake detection: $e');
      }
    }
  }

  /// Start tap detection
  Future<void> startTapDetection({double sensitivity = 0.8}) async {
    if (_isTapDetectionEnabled) return;

    try {
      _tapSensitivity = sensitivity;
      _accelerometerSubscription =
          accelerometerEventStream().listen(_onAccelerometerEvent);
      _isTapDetectionEnabled = true;

      if (kDebugMode) {
        print('Tap detection started with sensitivity: $sensitivity');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting tap detection: $e');
      }
    }
  }

  /// Stop tap detection
  void stopTapDetection() {
    if (!_isTapDetectionEnabled) return;

    try {
      _accelerometerSubscription?.cancel();
      _accelerometerSubscription = null;
      _isTapDetectionEnabled = false;
      _tapCount = 0;
      _tapResetTimer?.cancel();
      _accelerometerHistory.clear();

      if (kDebugMode) {
        print('Tap detection stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping tap detection: $e');
      }
    }
  }

  /// Handle shake detection
  void _onShakeDetected() {
    _shakeCount++;

    if (kDebugMode) {
      print('Shake detected! Count: $_shakeCount');
    }

    // Reset timer for shake count
    _shakeResetTimer?.cancel();
    _shakeResetTimer = Timer(const Duration(seconds: 5), () {
      _shakeCount = 0;
    });

    // Trigger emergency after 3 shakes
    if (_shakeCount >= 3) {
      _triggerEmergencyGesture('shake', 'Triple shake detected');
      _shakeCount = 0;
    } else {
      _gestureController.add(GestureEvent(
        type: 'shake',
        count: _shakeCount,
        isEmergency: false,
        message: 'Shake detected ($_shakeCount/3)',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Handle accelerometer events for tap detection
  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate magnitude of acceleration
    double magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // Add to history
    _accelerometerHistory.add(magnitude);
    if (_accelerometerHistory.length > _historyLength) {
      _accelerometerHistory.removeAt(0);
    }

    // Detect sudden changes (taps)
    if (_accelerometerHistory.length >= 3) {
      double current = _accelerometerHistory.last;
      double previous = _accelerometerHistory[_accelerometerHistory.length - 2];
      double diff = (current - previous).abs();

      // Threshold based on sensitivity (higher sensitivity = lower threshold)
      double threshold = 15.0 - (_tapSensitivity * 10.0);

      if (diff > threshold) {
        _onTapDetected();
      }
    }
  }

  /// Handle tap detection
  void _onTapDetected() {
    _tapCount++;

    if (kDebugMode) {
      print('Tap detected! Count: $_tapCount');
    }

    // Reset timer for tap count
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 3), () {
      _tapCount = 0;
    });

    // Trigger emergency after 5 taps
    if (_tapCount >= 5) {
      _triggerEmergencyGesture('tap', 'Five taps detected');
      _tapCount = 0;
    } else {
      _gestureController.add(GestureEvent(
        type: 'tap',
        count: _tapCount,
        isEmergency: false,
        message: 'Tap detected ($_tapCount/5)',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Trigger emergency gesture
  void _triggerEmergencyGesture(String gestureType, String message) {
    if (kDebugMode) {
      print('EMERGENCY GESTURE DETECTED: $gestureType - $message');
    }

    _gestureController.add(GestureEvent(
      type: gestureType,
      count: gestureType == 'shake' ? 3 : 5,
      isEmergency: true,
      message: message,
      timestamp: DateTime.now(),
    ));

    // Trigger callbacks
    _onEmergencyGestureDetected?.call();
    _onGestureDetected?.call('$gestureType emergency');
  }

  /// Update shake threshold
  void updateShakeThreshold(double threshold) {
    _shakeThreshold = threshold;
    if (_isShakeDetectionEnabled) {
      stopShakeDetection();
      startShakeDetection(threshold: threshold);
    }
  }

  /// Update tap sensitivity
  void updateTapSensitivity(double sensitivity) {
    _tapSensitivity = sensitivity;
    // No need to restart tap detection, just update the sensitivity
  }

  /// Check if gesture detection is active
  bool get isShakeDetectionActive => _isShakeDetectionEnabled;
  bool get isTapDetectionActive => _isTapDetectionEnabled;

  /// Get current settings
  double get shakeThreshold => _shakeThreshold;
  double get tapSensitivity => _tapSensitivity;

  /// Dispose resources
  void dispose() {
    stopShakeDetection();
    stopTapDetection();
    _gestureController.close();
  }
}

class GestureEvent {
  final String type;
  final int count;
  final bool isEmergency;
  final String message;
  final DateTime timestamp;

  GestureEvent({
    required this.type,
    required this.count,
    required this.isEmergency,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'GestureEvent(type: $type, count: $count, emergency: $isEmergency, message: $message)';
  }
}
