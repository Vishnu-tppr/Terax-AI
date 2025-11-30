import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:terax_ai_app/config/api_config.dart';

class AIService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static AIService? _instance;
  static AIService get instance {
    _instance ??= AIService._();
    return _instance!;
  }

  AIService._();

  /// Get API key securely
  Future<String?> _getApiKey() async {
    return await ApiConfig.getGeminiApiKey();
  }

  /// Analyze voice input for emergency keywords
  Future<EmergencyAnalysis> analyzeVoiceForEmergency(String voiceText) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
          'Gemini API key not configured. Please set it in Settings.');
    }

    try {
      final prompt = '''
Analyze this voice input for emergency situations. Respond with a JSON object containing:
- isEmergency (boolean): true if this indicates an emergency
- confidence (number 0-1): confidence level of emergency detection
- emergencyType (string): type of emergency if detected (medical, violence, accident, fire, etc.)
- urgencyLevel (string): low, medium, high, critical
- suggestedAction (string): recommended immediate action

Voice input: "$voiceText"

Respond only with valid JSON, no other text.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText =
            data['candidates'][0]['content']['parts'][0]['text'];

        // Clean up the response to extract JSON
        String cleanJson = generatedText.trim();
        if (cleanJson.startsWith('```json')) {
          cleanJson = cleanJson.substring(7);
        }
        if (cleanJson.endsWith('```')) {
          cleanJson = cleanJson.substring(0, cleanJson.length - 3);
        }

        final analysisData = jsonDecode(cleanJson);
        return EmergencyAnalysis.fromJson(analysisData);
      } else {
        throw Exception('Failed to analyze voice: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI analysis error: $e');
      }
      // Fallback analysis
      return _fallbackAnalysis(voiceText);
    }
  }

  /// Analyze text message for emergency context
  Future<String> generateEmergencyMessage({
    required String situation,
    required String location,
    required String userName,
  }) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return _generateFallbackMessage(situation, location, userName);
    }

    try {
      final prompt = '''
Generate a concise emergency message (max 160 characters for SMS) with these details:
- Person: $userName
- Situation: $situation
- Location: $location

The message should be clear, urgent, and include key information for emergency responders.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 50,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message =
            data['candidates'][0]['content']['parts'][0]['text'].trim();
        return message.length > 160
            ? message.substring(0, 157) + '...'
            : message;
      } else {
        return _generateFallbackMessage(situation, location, userName);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Message generation error: $e');
      }
      return _generateFallbackMessage(situation, location, userName);
    }
  }

  /// Fallback emergency analysis when AI is unavailable
  EmergencyAnalysis _fallbackAnalysis(String voiceText) {
    final lowerText = voiceText.toLowerCase();
    final emergencyKeywords = [
      'help',
      'emergency',
      'call 911',
      'police',
      'fire',
      'ambulance',
      'attack',
      'hurt',
      'pain',
      'bleeding',
      'accident',
      'danger',
      'save me',
      'help me',
      'call for help'
    ];

    bool isEmergency =
        emergencyKeywords.any((keyword) => lowerText.contains(keyword));
    double confidence = isEmergency ? 0.8 : 0.2;

    String emergencyType = 'unknown';
    if (lowerText.contains('medical') ||
        lowerText.contains('hurt') ||
        lowerText.contains('pain')) {
      emergencyType = 'medical';
    } else if (lowerText.contains('fire')) {
      emergencyType = 'fire';
    } else if (lowerText.contains('police') || lowerText.contains('attack')) {
      emergencyType = 'violence';
    }

    return EmergencyAnalysis(
      isEmergency: isEmergency,
      confidence: confidence,
      emergencyType: emergencyType,
      urgencyLevel: isEmergency ? 'high' : 'low',
      suggestedAction: isEmergency
          ? 'Contact emergency services immediately'
          : 'Monitor situation',
    );
  }

  String _generateFallbackMessage(
      String situation, String location, String userName) {
    return 'EMERGENCY: $userName needs help. Situation: $situation. Location: $location. Please respond immediately.';
  }
}

class EmergencyAnalysis {
  final bool isEmergency;
  final double confidence;
  final String emergencyType;
  final String urgencyLevel;
  final String suggestedAction;

  EmergencyAnalysis({
    required this.isEmergency,
    required this.confidence,
    required this.emergencyType,
    required this.urgencyLevel,
    required this.suggestedAction,
  });

  factory EmergencyAnalysis.fromJson(Map<String, dynamic> json) {
    return EmergencyAnalysis(
      isEmergency: json['isEmergency'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      emergencyType: json['emergencyType'] ?? 'unknown',
      urgencyLevel: json['urgencyLevel'] ?? 'low',
      suggestedAction: json['suggestedAction'] ?? 'Monitor situation',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEmergency': isEmergency,
      'confidence': confidence,
      'emergencyType': emergencyType,
      'urgencyLevel': urgencyLevel,
      'suggestedAction': suggestedAction,
    };
  }
}
