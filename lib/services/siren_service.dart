import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';

class SirenService {
  static SirenService? _instance;
  static SirenService get instance {
    _instance ??= SirenService._();
    return _instance!;
  }

  SirenService._();

  AudioPlayer? _audioPlayer;
  Timer? _sirenTimer;
  Timer? _vibrationTimer;
  bool _isSirenActive = false;
  bool _isInitialized = false;
  
  // Siren patterns
  SirenPattern _currentPattern = SirenPattern.emergency;
  double _volume = 1.0;
  
  // Stream controller for siren events
  final StreamController<SirenEvent> _sirenController =
      StreamController<SirenEvent>.broadcast();

  Stream<SirenEvent> get sirenStream => _sirenController.stream;

  /// Initialize siren service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _audioPlayer = AudioPlayer();
      _isInitialized = true;
      
      if (kDebugMode) {
        print('Siren service initialized');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing siren service: $e');
      }
      return false;
    }
  }

  /// Start emergency siren
  Future<bool> startEmergencySiren({
    SirenPattern pattern = SirenPattern.emergency,
    double volume = 1.0,
    bool withVibration = true,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isSirenActive) {
      if (kDebugMode) {
        print('Siren already active');
      }
      return true;
    }

    try {
      _currentPattern = pattern;
      _volume = volume.clamp(0.0, 1.0);
      _isSirenActive = true;

      // Start audio siren
      await _startAudioSiren();
      
      // Start vibration pattern if enabled
      if (withVibration) {
        await _startVibrationPattern();
      }

      _sirenController.add(SirenEvent(
        type: SirenEventType.started,
        pattern: _currentPattern,
        message: 'Emergency siren activated',
        timestamp: DateTime.now(),
      ));

      if (kDebugMode) {
        print('Emergency siren started with pattern: $_currentPattern');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting emergency siren: $e');
      }
      _isSirenActive = false;
      return false;
    }
  }

  /// Start audio siren with pattern
  Future<void> _startAudioSiren() async {
    if (_audioPlayer == null) return;

    try {
      // Generate siren sound based on pattern
      switch (_currentPattern) {
        case SirenPattern.emergency:
          await _playEmergencySiren();
          break;
        case SirenPattern.police:
          await _playPoliceSiren();
          break;
        case SirenPattern.ambulance:
          await _playAmbulanceSiren();
          break;
        case SirenPattern.fire:
          await _playFireSiren();
          break;
        case SirenPattern.alarm:
          await _playAlarmSiren();
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error playing audio siren: $e');
      }
    }
  }

  /// Play emergency siren pattern
  Future<void> _playEmergencySiren() async {
    // Create a repeating high-pitched emergency sound
    _sirenTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }

      try {
        // Generate high-pitched beep sound
        await _playTone(frequency: 1000 + (timer.tick % 10) * 100, duration: 100);
      } catch (e) {
        if (kDebugMode) {
          print('Error in emergency siren: $e');
        }
      }
    });
  }

  /// Play police siren pattern
  Future<void> _playPoliceSiren() async {
    // Alternating high-low pattern
    _sirenTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }

      try {
        final isHigh = timer.tick % 2 == 0;
        await _playTone(frequency: isHigh ? 1200 : 800, duration: 500);
      } catch (e) {
        if (kDebugMode) {
          print('Error in police siren: $e');
        }
      }
    });
  }

  /// Play ambulance siren pattern
  Future<void> _playAmbulanceSiren() async {
    // Rising and falling pattern
    _sirenTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }

      try {
        final cycle = timer.tick % 40;
        final frequency = 800 + (sin(cycle * pi / 20) * 400).abs();
        await _playTone(frequency: frequency.toInt(), duration: 50);
      } catch (e) {
        if (kDebugMode) {
          print('Error in ambulance siren: $e');
        }
      }
    });
  }

  /// Play fire siren pattern
  Future<void> _playFireSiren() async {
    // Continuous high-pitched sound
    _sirenTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }

      try {
        await _playTone(frequency: 1500, duration: 200);
      } catch (e) {
        if (kDebugMode) {
          print('Error in fire siren: $e');
        }
      }
    });
  }

  /// Play alarm siren pattern
  Future<void> _playAlarmSiren() async {
    // Rapid beeping pattern
    _sirenTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }

      try {
        await _playTone(frequency: 1000, duration: 150);
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (e) {
        if (kDebugMode) {
          print('Error in alarm siren: $e');
        }
      }
    });
  }

  /// Play a tone with specified frequency and duration
  Future<void> _playTone({required int frequency, required int duration}) async {
    try {
      // Use system sound for now (can be replaced with generated audio)
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      if (kDebugMode) {
        print('Error playing tone: $e');
      }
    }
  }

  /// Start vibration pattern
  Future<void> _startVibrationPattern() async {
    if (!await Vibration.hasVibrator()) return;

    try {
      switch (_currentPattern) {
        case SirenPattern.emergency:
          _startEmergencyVibration();
          break;
        case SirenPattern.police:
          _startPoliceVibration();
          break;
        case SirenPattern.ambulance:
          _startAmbulanceVibration();
          break;
        case SirenPattern.fire:
          _startFireVibration();
          break;
        case SirenPattern.alarm:
          _startAlarmVibration();
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting vibration: $e');
      }
    }
  }

  /// Emergency vibration pattern
  void _startEmergencyVibration() {
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }
      Vibration.vibrate(duration: 100);
    });
  }

  /// Police vibration pattern
  void _startPoliceVibration() {
    _vibrationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }
      // Long-short-long pattern
      Vibration.vibrate(pattern: [0, 500, 200, 200, 200, 500]);
    });
  }

  /// Ambulance vibration pattern
  void _startAmbulanceVibration() {
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }
      Vibration.vibrate(duration: 400);
    });
  }

  /// Fire vibration pattern
  void _startFireVibration() {
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }
      Vibration.vibrate(duration: 150);
    });
  }

  /// Alarm vibration pattern
  void _startAlarmVibration() {
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (!_isSirenActive) {
        timer.cancel();
        return;
      }
      // Triple short vibrations
      Vibration.vibrate(pattern: [0, 100, 100, 100, 100, 100]);
    });
  }

  /// Stop siren
  Future<void> stopSiren() async {
    if (!_isSirenActive) return;

    try {
      _isSirenActive = false;
      
      // Stop timers
      _sirenTimer?.cancel();
      _vibrationTimer?.cancel();
      
      // Stop audio
      await _audioPlayer?.stop();
      
      // Stop vibration
      await Vibration.cancel();

      _sirenController.add(SirenEvent(
        type: SirenEventType.stopped,
        pattern: _currentPattern,
        message: 'Emergency siren stopped',
        timestamp: DateTime.now(),
      ));

      if (kDebugMode) {
        print('Emergency siren stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping siren: $e');
      }
    }
  }

  /// Check if siren is active
  bool get isActive => _isSirenActive;

  /// Get current pattern
  SirenPattern get currentPattern => _currentPattern;

  /// Set volume
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _audioPlayer?.setVolume(_volume);
  }

  /// Get volume
  double get volume => _volume;

  /// Dispose resources
  void dispose() {
    stopSiren();
    _audioPlayer?.dispose();
    _sirenController.close();
  }
}

enum SirenPattern {
  emergency,
  police,
  ambulance,
  fire,
  alarm,
}

enum SirenEventType {
  started,
  stopped,
  error,
}

class SirenEvent {
  final SirenEventType type;
  final SirenPattern pattern;
  final String message;
  final DateTime timestamp;

  SirenEvent({
    required this.type,
    required this.pattern,
    required this.message,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'SirenEvent(type: $type, pattern: $pattern, message: $message)';
  }
}
