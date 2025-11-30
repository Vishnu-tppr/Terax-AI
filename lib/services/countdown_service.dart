import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

class CountdownService {
  static CountdownService? _instance;
  static CountdownService get instance {
    _instance ??= CountdownService._();
    return _instance!;
  }

  CountdownService._();

  Timer? _countdownTimer;
  bool _isCountdownActive = false;
  int _remainingSeconds = 0;
  int _totalSeconds = 10;

  // Callbacks
  Function()? _onCountdownComplete;
  Function()? _onCountdownCancelled;
  Function(int)? _onCountdownTick;

  // Stream controller for countdown updates
  final StreamController<CountdownEvent> _countdownController =
      StreamController<CountdownEvent>.broadcast();

  Stream<CountdownEvent> get countdownStream => _countdownController.stream;

  /// Check if countdown is currently active
  bool get isActive => _isCountdownActive;

  /// Get remaining seconds
  int get remainingSeconds => _remainingSeconds;

  /// Get total countdown duration
  int get totalSeconds => _totalSeconds;

  /// Set countdown duration
  void setCountdownDuration(int seconds) {
    if (!_isCountdownActive) {
      _totalSeconds = seconds;
    }
  }

  /// Set callbacks
  void setCallbacks({
    Function()? onComplete,
    Function()? onCancelled,
    Function(int)? onTick,
  }) {
    _onCountdownComplete = onComplete;
    _onCountdownCancelled = onCancelled;
    _onCountdownTick = onTick;
  }

  /// Start countdown
  Future<void> startCountdown({int? duration}) async {
    if (_isCountdownActive) {
      if (kDebugMode) {
        print('Countdown already active');
      }
      return;
    }

    _totalSeconds = duration ?? _totalSeconds;
    _remainingSeconds = _totalSeconds;
    _isCountdownActive = true;

    if (kDebugMode) {
      print('Starting countdown: $_totalSeconds seconds');
    }

    // Send initial countdown event
    _countdownController.add(CountdownEvent(
      type: CountdownEventType.started,
      remainingSeconds: _remainingSeconds,
      totalSeconds: _totalSeconds,
      message: 'Emergency countdown started',
    ));

    // Vibrate to indicate countdown start
    _vibrate();

    // Start the countdown timer
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;

      if (kDebugMode) {
        print('Countdown: $_remainingSeconds seconds remaining');
      }

      // Send tick event
      _countdownController.add(CountdownEvent(
        type: CountdownEventType.tick,
        remainingSeconds: _remainingSeconds,
        totalSeconds: _totalSeconds,
        message: '$_remainingSeconds seconds remaining',
      ));

      // Call tick callback
      _onCountdownTick?.call(_remainingSeconds);

      // Vibrate on each tick for the last 3 seconds
      if (_remainingSeconds <= 3 && _remainingSeconds > 0) {
        _vibrate();
      }

      // Check if countdown is complete
      if (_remainingSeconds <= 0) {
        _completeCountdown();
      }
    });
  }

  /// Cancel countdown
  void cancelCountdown() {
    if (!_isCountdownActive) {
      return;
    }

    if (kDebugMode) {
      print('Countdown cancelled');
    }

    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isCountdownActive = false;

    // Send cancelled event
    _countdownController.add(CountdownEvent(
      type: CountdownEventType.cancelled,
      remainingSeconds: _remainingSeconds,
      totalSeconds: _totalSeconds,
      message: 'Emergency countdown cancelled',
    ));

    // Call cancelled callback
    _onCountdownCancelled?.call();

    // Double vibrate to indicate cancellation
    _vibrate();
    Future.delayed(const Duration(milliseconds: 200), () => _vibrate());
  }

  /// Complete countdown
  void _completeCountdown() {
    if (kDebugMode) {
      print('Countdown completed - triggering emergency');
    }

    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isCountdownActive = false;

    // Send completed event
    _countdownController.add(CountdownEvent(
      type: CountdownEventType.completed,
      remainingSeconds: 0,
      totalSeconds: _totalSeconds,
      message: 'Emergency countdown completed - activating emergency mode',
    ));

    // Call completion callback
    _onCountdownComplete?.call();

    // Strong vibration pattern to indicate emergency activation
    _emergencyVibration();
  }

  /// Vibrate device
  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 200);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Vibration error: $e');
      }
    }
  }

  /// Emergency vibration pattern
  Future<void> _emergencyVibration() async {
    try {
      if (await Vibration.hasVibrator()) {
        // Pattern: vibrate 500ms, pause 200ms, vibrate 500ms, pause 200ms, vibrate 500ms
        Vibration.vibrate(
          pattern: [0, 500, 200, 500, 200, 500],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Emergency vibration error: $e');
      }
    }
  }

  /// Add extra time to countdown (for testing or emergency situations)
  void addTime(int seconds) {
    if (_isCountdownActive) {
      _remainingSeconds += seconds;
      _totalSeconds += seconds;

      _countdownController.add(CountdownEvent(
        type: CountdownEventType.timeAdded,
        remainingSeconds: _remainingSeconds,
        totalSeconds: _totalSeconds,
        message: '$seconds seconds added to countdown',
      ));

      if (kDebugMode) {
        print('Added $seconds seconds to countdown. New total: $_remainingSeconds');
      }
    }
  }

  /// Get countdown progress (0.0 to 1.0)
  double get progress {
    if (_totalSeconds == 0) return 0.0;
    return (_totalSeconds - _remainingSeconds) / _totalSeconds;
  }

  /// Get countdown progress percentage (0 to 100)
  int get progressPercentage {
    return (progress * 100).round();
  }

  /// Dispose resources
  void dispose() {
    _countdownTimer?.cancel();
    _countdownController.close();
  }
}

enum CountdownEventType {
  started,
  tick,
  completed,
  cancelled,
  timeAdded,
}

class CountdownEvent {
  final CountdownEventType type;
  final int remainingSeconds;
  final int totalSeconds;
  final String message;
  final DateTime timestamp;

  CountdownEvent({
    required this.type,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.message,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'CountdownEvent(type: $type, remaining: $remainingSeconds, total: $totalSeconds, message: $message)';
  }
}
