import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:terax_ai_app/services/ai_service.dart';

class RealVoiceService {
  static RealVoiceService? _instance;
  static RealVoiceService get instance {
    _instance ??= RealVoiceService._();
    return _instance!;
  }

  RealVoiceService._();

  late stt.SpeechToText _speech;
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  double _confidence = 0.0;

  final StreamController<VoiceDetectionResult> _voiceController =
      StreamController<VoiceDetectionResult>.broadcast();

  // Default emergency trigger phrases
  final List<String> _defaultTriggerPhrases = [
    'help me',
    'emergency',
    'save me',
    'call 911',
    'i need help',
    'help please',
    'someone help',
    'call for help',
  ];

  // Custom trigger phrases from user settings
  List<String> _customTriggerPhrases = [];

  // Combined trigger phrases (default + custom)
  List<String> get _allTriggerPhrases =>
      [..._defaultTriggerPhrases, ..._customTriggerPhrases];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  double get confidence => _confidence;
  List<String> get triggerPhrases => List.from(_allTriggerPhrases);
  Stream<VoiceDetectionResult> get voiceStream => _voiceController.stream;

  /// Initialize speech recognition
  Future<VoiceInitResult> initialize() async {
    try {
      _speech = stt.SpeechToText();

      // Check microphone permission
      final permission = await Permission.microphone.request();
      if (permission != PermissionStatus.granted) {
        return VoiceInitResult(
          success: false,
          message: 'Microphone permission denied',
        );
      }

      // Initialize speech recognition
      bool available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: kDebugMode,
      );

      if (available) {
        _isInitialized = true;
        return VoiceInitResult(
          success: true,
          message: 'Voice detection ready',
        );
      } else {
        return VoiceInitResult(
          success: false,
          message: 'Speech recognition not available on this device',
        );
      }
    } catch (e) {
      return VoiceInitResult(
        success: false,
        message: 'Failed to initialize voice detection: $e',
      );
    }
  }

  /// Start listening for voice commands
  Future<bool> startListening() async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (!initResult.success) {
        return false;
      }
    }

    try {
      if (_speech.isAvailable && !_isListening) {
        await _speech.listen(
          onResult: _onSpeechResult,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          localeId: 'en_US',
          onSoundLevelChange: _onSoundLevelChange,
          listenOptions: stt.SpeechListenOptions(
            cancelOnError: false,
            partialResults: true,
            listenMode: stt.ListenMode.confirmation,
          ),
        );

        _isListening = true;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_isListening) {
        await _speech.stop();
        _isListening = false;
      }
    } catch (e) {
      //
    }
  }

  /// Update custom trigger phrases
  void updateCustomTriggerPhrases(List<String> phrases) {
    _customTriggerPhrases = phrases.map((p) => p.toLowerCase().trim()).toList();
  }

  /// Add a custom trigger phrase
  void addCustomTriggerPhrase(String phrase) {
    final cleanPhrase = phrase.toLowerCase().trim();
    if (cleanPhrase.isNotEmpty &&
        !_customTriggerPhrases.contains(cleanPhrase)) {
      _customTriggerPhrases.add(cleanPhrase);
    }
  }

  /// Remove a custom trigger phrase
  void removeCustomTriggerPhrase(String phrase) {
    final cleanPhrase = phrase.toLowerCase().trim();
    _customTriggerPhrases.remove(cleanPhrase);
  }

  /// Get all custom trigger phrases
  List<String> get customTriggerPhrases => List.from(_customTriggerPhrases);

  /// Get default trigger phrases
  List<String> get defaultTriggerPhrases => List.from(_defaultTriggerPhrases);

  /// Check if text contains emergency trigger
  Future<VoiceDetectionResult> analyzeVoiceInput(String text) async {
    final lowerText = text.toLowerCase();

    // Check for basic trigger phrases first
    bool hasBasicTrigger = _allTriggerPhrases
        .any((phrase) => lowerText.contains(phrase.toLowerCase()));

    if (hasBasicTrigger) {
      // Use AI for more sophisticated analysis
      try {
        final aiAnalysis =
            await AIService.instance.analyzeVoiceForEmergency(text);

        return VoiceDetectionResult(
          isEmergency: aiAnalysis.isEmergency,
          confidence: aiAnalysis.confidence,
          detectedText: text,
          emergencyType: aiAnalysis.emergencyType,
          urgencyLevel: aiAnalysis.urgencyLevel,
          suggestedAction: aiAnalysis.suggestedAction,
          triggerPhrase: _findMatchingTrigger(lowerText),
          timestamp: DateTime.now(),
        );
      } catch (e) {
        // Fallback to basic detection
        return VoiceDetectionResult(
          isEmergency: true,
          confidence: 0.8,
          detectedText: text,
          emergencyType: 'unknown',
          urgencyLevel: 'high',
          suggestedAction: 'Contact emergency services',
          triggerPhrase: _findMatchingTrigger(lowerText),
          timestamp: DateTime.now(),
        );
      }
    } else {
      // No basic trigger found, but still check with AI for context
      try {
        final aiAnalysis =
            await AIService.instance.analyzeVoiceForEmergency(text);

        return VoiceDetectionResult(
          isEmergency: aiAnalysis.isEmergency,
          confidence: aiAnalysis.confidence,
          detectedText: text,
          emergencyType: aiAnalysis.emergencyType,
          urgencyLevel: aiAnalysis.urgencyLevel,
          suggestedAction: aiAnalysis.suggestedAction,
          triggerPhrase: null,
          timestamp: DateTime.now(),
        );
      } catch (e) {
        // No AI and no basic trigger
        return VoiceDetectionResult(
          isEmergency: false,
          confidence: 0.1,
          detectedText: text,
          emergencyType: 'none',
          urgencyLevel: 'low',
          suggestedAction: 'Continue monitoring',
          triggerPhrase: null,
          timestamp: DateTime.now(),
        );
      }
    }
  }

  /// Find which trigger phrase was matched
  String? _findMatchingTrigger(String lowerText) {
    for (String phrase in _allTriggerPhrases) {
      if (lowerText.contains(phrase.toLowerCase())) {
        return phrase;
      }
    }
    return null;
  }

  /// Speech recognition result callback
  void _onSpeechResult(dynamic result) async {
    _lastWords = result.recognizedWords;
    _confidence = result.confidence;

    // Analyze the speech for emergency triggers
    if (result.recognizedWords.isNotEmpty) {
      final analysis = await analyzeVoiceInput(result.recognizedWords);
      _voiceController.add(analysis);

      // If emergency detected and confidence is high enough, trigger emergency
      if (analysis.isEmergency && analysis.confidence > 0.7) {
        //
      }
    }
  }

  /// Speech status callback
  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
    }
  }

  /// Speech error callback
  void _onSpeechError(dynamic error) {
    _isListening = false;
  }

  /// Sound level change callback
  void _onSoundLevelChange(double level) {
    // Can be used for visual feedback
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  /// Dispose resources
  void dispose() {
    stopListening();
    _voiceController.close();
  }
}

class VoiceInitResult {
  final bool success;
  final String message;

  VoiceInitResult({
    required this.success,
    required this.message,
  });
}

class VoiceDetectionResult {
  final bool isEmergency;
  final double confidence;
  final String detectedText;
  final String emergencyType;
  final String urgencyLevel;
  final String suggestedAction;
  final String? triggerPhrase;
  final DateTime timestamp;

  VoiceDetectionResult({
    required this.isEmergency,
    required this.confidence,
    required this.detectedText,
    required this.emergencyType,
    required this.urgencyLevel,
    required this.suggestedAction,
    required this.triggerPhrase,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'VoiceDetectionResult(isEmergency: $isEmergency, confidence: $confidence, text: $detectedText, trigger: $triggerPhrase)';
  }
}