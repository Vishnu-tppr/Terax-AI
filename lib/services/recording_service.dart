import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

class RecordingService {
  static RecordingService? _instance;
  static RecordingService get instance {
    _instance ??= RecordingService._();
    return _instance!;
  }

  RecordingService._();

  // Camera recording
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isVideoRecording = false;
  String? _currentVideoPath;

  // Audio recording
  FlutterSoundRecorder? _audioRecorder;
  bool _isAudioRecording = false;
  String? _currentAudioPath;

  // Recording state
  bool _isInitialized = false;
  bool _isRecordingActive = false;
  DateTime? _recordingStartTime;

  // Stream controllers
  final StreamController<RecordingEvent> _recordingController =
      StreamController<RecordingEvent>.broadcast();

  Stream<RecordingEvent> get recordingStream => _recordingController.stream;

  /// Initialize recording service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request permissions
      final cameraPermission = await Permission.camera.request();
      final microphonePermission = await Permission.microphone.request();
      final storagePermission = await Permission.storage.request();

      if (cameraPermission != PermissionStatus.granted ||
          microphonePermission != PermissionStatus.granted ||
          storagePermission != PermissionStatus.granted) {
        if (kDebugMode) {
          print('Recording permissions not granted');
        }
        return false;
      }

      // Initialize cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (kDebugMode) {
          print('No cameras available');
        }
        return false;
      }

      // Initialize audio recorder
      _audioRecorder = FlutterSoundRecorder();
      await _audioRecorder!.openRecorder();

      _isInitialized = true;
      if (kDebugMode) {
        print('Recording service initialized successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing recording service: $e');
      }
      return false;
    }
  }

  /// Start emergency recording (both video and audio)
  Future<bool> startEmergencyRecording({bool silent = true}) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    if (_isRecordingActive) {
      if (kDebugMode) {
        print('Recording already active');
      }
      return true;
    }

    try {
      _recordingStartTime = DateTime.now();
      _isRecordingActive = true;

      // Start video recording
      final videoStarted = await _startVideoRecording(silent: silent);
      
      // Start audio recording
      final audioStarted = await _startAudioRecording(silent: silent);

      if (videoStarted || audioStarted) {
        _recordingController.add(RecordingEvent(
          type: RecordingEventType.started,
          message: 'Emergency recording started',
          videoPath: _currentVideoPath,
          audioPath: _currentAudioPath,
          timestamp: _recordingStartTime!,
        ));

        if (kDebugMode) {
          print('Emergency recording started - Video: $videoStarted, Audio: $audioStarted');
        }
        return true;
      } else {
        _isRecordingActive = false;
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting emergency recording: $e');
      }
      _isRecordingActive = false;
      return false;
    }
  }

  /// Start video recording
  Future<bool> _startVideoRecording({bool silent = true}) async {
    if (_isVideoRecording || _cameras == null || _cameras!.isEmpty) {
      return false;
    }

    try {
      // Use back camera for stealth recording
      final camera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false, // Audio handled separately
      );

      await _cameraController!.initialize();

      // Create video file path
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/emergency_videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentVideoPath = '${videoDir.path}/emergency_video_$timestamp.mp4';

      // Start recording
      await _cameraController!.startVideoRecording();
      _isVideoRecording = true;

      if (kDebugMode) {
        print('Video recording started: $_currentVideoPath');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting video recording: $e');
      }
      return false;
    }
  }

  /// Start audio recording
  Future<bool> _startAudioRecording({bool silent = true}) async {
    if (_isAudioRecording || _audioRecorder == null) {
      return false;
    }

    try {
      // Create audio file path
      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/emergency_audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentAudioPath = '${audioDir.path}/emergency_audio_$timestamp.aac';

      // Start recording
      await _audioRecorder!.startRecorder(
        toFile: _currentAudioPath,
        codec: Codec.aacADTS,
      );
      _isAudioRecording = true;

      if (kDebugMode) {
        print('Audio recording started: $_currentAudioPath');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting audio recording: $e');
      }
      return false;
    }
  }

  /// Stop emergency recording
  Future<RecordingResult?> stopEmergencyRecording() async {
    if (!_isRecordingActive) {
      return null;
    }

    try {
      String? finalVideoPath;
      String? finalAudioPath;
      Duration? recordingDuration;

      if (_recordingStartTime != null) {
        recordingDuration = DateTime.now().difference(_recordingStartTime!);
      }

      // Stop video recording
      if (_isVideoRecording && _cameraController != null) {
        final videoFile = await _cameraController!.stopVideoRecording();
        finalVideoPath = videoFile.path;
        _isVideoRecording = false;
        await _cameraController!.dispose();
        _cameraController = null;
      }

      // Stop audio recording
      if (_isAudioRecording && _audioRecorder != null) {
        await _audioRecorder!.stopRecorder();
        finalAudioPath = _currentAudioPath;
        _isAudioRecording = false;
      }

      _isRecordingActive = false;
      _currentVideoPath = null;
      _currentAudioPath = null;

      final result = RecordingResult(
        videoPath: finalVideoPath,
        audioPath: finalAudioPath,
        duration: recordingDuration,
        startTime: _recordingStartTime!,
        endTime: DateTime.now(),
      );

      _recordingController.add(RecordingEvent(
        type: RecordingEventType.stopped,
        message: 'Emergency recording stopped',
        videoPath: finalVideoPath,
        audioPath: finalAudioPath,
        timestamp: DateTime.now(),
      ));

      if (kDebugMode) {
        print('Emergency recording stopped - Video: $finalVideoPath, Audio: $finalAudioPath');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping emergency recording: $e');
      }
      return null;
    }
  }

  /// Check if recording is active
  bool get isRecording => _isRecordingActive;
  bool get isVideoRecording => _isVideoRecording;
  bool get isAudioRecording => _isAudioRecording;

  /// Get recording duration
  Duration? get recordingDuration {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Get all emergency recordings
  Future<List<RecordingResult>> getEmergencyRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/emergency_videos');
      final audioDir = Directory('${directory.path}/emergency_audio');

      final recordings = <RecordingResult>[];

      // Get video files
      if (await videoDir.exists()) {
        final videoFiles = videoDir.listSync()
            .where((file) => file.path.endsWith('.mp4'))
            .cast<File>();

        for (final videoFile in videoFiles) {
          final stat = await videoFile.stat();
          recordings.add(RecordingResult(
            videoPath: videoFile.path,
            audioPath: null,
            duration: null,
            startTime: stat.modified,
            endTime: stat.modified,
          ));
        }
      }

      // Get audio files
      if (await audioDir.exists()) {
        final audioFiles = audioDir.listSync()
            .where((file) => file.path.endsWith('.aac'))
            .cast<File>();

        for (final audioFile in audioFiles) {
          final stat = await audioFile.stat();
          recordings.add(RecordingResult(
            videoPath: null,
            audioPath: audioFile.path,
            duration: null,
            startTime: stat.modified,
            endTime: stat.modified,
          ));
        }
      }

      recordings.sort((a, b) => b.startTime.compareTo(a.startTime));
      return recordings;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting emergency recordings: $e');
      }
      return [];
    }
  }

  /// Delete recording
  Future<bool> deleteRecording(RecordingResult recording) async {
    try {
      bool deleted = false;

      if (recording.videoPath != null) {
        final videoFile = File(recording.videoPath!);
        if (await videoFile.exists()) {
          await videoFile.delete();
          deleted = true;
        }
      }

      if (recording.audioPath != null) {
        final audioFile = File(recording.audioPath!);
        if (await audioFile.exists()) {
          await audioFile.delete();
          deleted = true;
        }
      }

      return deleted;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting recording: $e');
      }
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _cameraController?.dispose();
    _audioRecorder?.closeRecorder();
    _recordingController.close();
  }
}

enum RecordingEventType {
  started,
  stopped,
  error,
}

class RecordingEvent {
  final RecordingEventType type;
  final String message;
  final String? videoPath;
  final String? audioPath;
  final DateTime timestamp;

  RecordingEvent({
    required this.type,
    required this.message,
    this.videoPath,
    this.audioPath,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'RecordingEvent(type: $type, message: $message, video: $videoPath, audio: $audioPath)';
  }
}

class RecordingResult {
  final String? videoPath;
  final String? audioPath;
  final Duration? duration;
  final DateTime startTime;
  final DateTime endTime;

  RecordingResult({
    this.videoPath,
    this.audioPath,
    this.duration,
    required this.startTime,
    required this.endTime,
  });

  bool get hasVideo => videoPath != null;
  bool get hasAudio => audioPath != null;
  
  String get displayName {
    final timestamp = startTime.toString().substring(0, 19);
    if (hasVideo && hasAudio) {
      return 'Video + Audio - $timestamp';
    } else if (hasVideo) {
      return 'Video - $timestamp';
    } else if (hasAudio) {
      return 'Audio - $timestamp';
    } else {
      return 'Recording - $timestamp';
    }
  }
}
