import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceProvider extends ChangeNotifier {
  bool _isVoiceEnabled = false;
  bool _isListening = false;
  List<String> _triggerPhrases = ['help me', 'save me', 'emergency'];
  double _sensitivity = 0.8;
  bool _isBackgroundListening = false;

  late SpeechToText _speechToText;
  bool _speechEnabled = false;
  String _lastWords = '';
  Function(String)? _onTriggerDetected;

  // Getters
  bool get isVoiceEnabled => _isVoiceEnabled;
  bool get isListening => _isListening;
  List<String> get triggerPhrases => List.unmodifiable(_triggerPhrases);
  double get sensitivity => _sensitivity;
  bool get isBackgroundListening => _isBackgroundListening;
  bool get speechEnabled => _speechEnabled;
  String get lastWords => _lastWords;

  VoiceProvider() {
    _speechToText = SpeechToText();
    _initSpeech();
    _loadVoiceSettings();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (status) {
        if (kDebugMode) {
          print('Speech status: $status');
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Speech error: $error');
        }
      },
    );
    notifyListeners();
  }

  void setTriggerCallback(Function(String) callback) {
    _onTriggerDetected = callback;
  }

  Future<void> _loadVoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isVoiceEnabled = prefs.getBool('voice_enabled') ?? false;
      _sensitivity = prefs.getDouble('voice_sensitivity') ?? 0.8;
      _isBackgroundListening = prefs.getBool('background_listening') ?? false;

      final phrases = prefs.getStringList('trigger_phrases');
      if (phrases != null && phrases.isNotEmpty) {
        _triggerPhrases = phrases;
      }

      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading voice settings: $e');
      }
    }
  }

  Future<void> _saveVoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('voice_enabled', _isVoiceEnabled);
      await prefs.setDouble('voice_sensitivity', _sensitivity);
      await prefs.setBool('background_listening', _isBackgroundListening);
      await prefs.setStringList('trigger_phrases', _triggerPhrases);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving voice settings: $e');
      }
    }
  }

  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    if (_isVoiceEnabled) {
      _startListening();
    } else {
      _stopListening();
    }
    _saveVoiceSettings();
    notifyListeners();
  }

  // Alias for toggleVoice to match the safety screen usage
  void toggleVoiceActivation() {
    toggleVoice();
  }

  void _startListening() async {
    if (!_isVoiceEnabled || !_speechEnabled) return;

    // Request microphone permission
    final permission = await Permission.microphone.request();
    if (permission != PermissionStatus.granted) {
      if (kDebugMode) {
        print('Microphone permission denied');
      }
      return;
    }

    _isListening = true;
    notifyListeners();

    if (kDebugMode) {
      print('Voice detection started');
    }

    await _speechToText.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords.toLowerCase();

        // Check if any trigger phrase is detected
        for (String phrase in _triggerPhrases) {
          if (_lastWords.contains(phrase)) {
            if (kDebugMode) {
              print('Trigger phrase detected: $phrase');
            }
            _onTriggerDetected?.call(phrase);
            break;
          }
        }

        notifyListeners();
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      onSoundLevelChange: (level) {
        // Handle sound level changes if needed
      },
    );
  }

  void _stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    _isListening = false;
    notifyListeners();

    if (kDebugMode) {
      print('Voice detection stopped');
    }
  }

  void setSensitivity(double value) {
    _sensitivity = value.clamp(0.0, 1.0);
    _saveVoiceSettings();
    notifyListeners();
  }

  void toggleBackgroundListening() {
    _isBackgroundListening = !_isBackgroundListening;
    _saveVoiceSettings();
    notifyListeners();
  }

  void addTriggerPhrase(String phrase) {
    if (phrase.isNotEmpty && !_triggerPhrases.contains(phrase.toLowerCase())) {
      _triggerPhrases.add(phrase.toLowerCase());
      _saveVoiceSettings();
      notifyListeners();
    }
  }

  void removeTriggerPhrase(String phrase) {
    if (_triggerPhrases.remove(phrase.toLowerCase())) {
      _saveVoiceSettings();
      notifyListeners();
    }
  }

  void updateTriggerPhrases(List<String> phrases) {
    _triggerPhrases = phrases.map((e) => e.toLowerCase()).toList();
    _saveVoiceSettings();
    notifyListeners();
  }

  bool isTriggerPhrase(String phrase) {
    return _triggerPhrases.contains(phrase.toLowerCase());
  }

  void resetToDefaults() {
    _triggerPhrases = ['help me', 'save me', 'emergency'];
    _sensitivity = 0.8;
    _isBackgroundListening = false;
    _saveVoiceSettings();
    notifyListeners();
  }
}
