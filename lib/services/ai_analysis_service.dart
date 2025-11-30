import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:terax_ai_app/config/api_config.dart';
import 'package:terax_ai_app/services/real_location_service.dart';

class AIAnalysisService {
  static AIAnalysisService? _instance;
  static AIAnalysisService get instance {
    _instance ??= AIAnalysisService._();
    return _instance!;
  }

  AIAnalysisService._();

  /// Analyze text for emergency keywords and urgency
  Future<EmergencyAnalysis> analyzeEmergencyText(String text) async {
    try {
      final apiKey = await ApiConfig.getGeminiApiKey();
      if (apiKey == null) {
        return EmergencyAnalysis(
          isEmergency: _containsEmergencyKeywords(text),
          urgencyLevel: UrgencyLevel.medium,
          confidence: 0.5,
          suggestedActions: ['Contact emergency services'],
          analysis: 'Basic keyword analysis (no AI)',
        );
      }

      final prompt = '''
Analyze this text for emergency situation indicators:
"$text"

Respond with JSON format:
{
  "isEmergency": boolean,
  "urgencyLevel": "low|medium|high|critical",
  "confidence": 0.0-1.0,
  "suggestedActions": ["action1", "action2"],
  "analysis": "brief explanation",
  "keywords": ["detected", "keywords"]
}

Consider:
- Explicit emergency words (help, emergency, danger, attack, etc.)
- Emotional indicators (panic, fear, distress)
- Situation context (location, time, circumstances)
- Urgency level based on language intensity
''';

      final response = await _callGeminiAPI(prompt, apiKey);
      return _parseEmergencyAnalysis(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in AI emergency analysis: $e');
      }
      return EmergencyAnalysis(
        isEmergency: _containsEmergencyKeywords(text),
        urgencyLevel: UrgencyLevel.medium,
        confidence: 0.3,
        suggestedActions: ['Contact emergency services'],
        analysis: 'Fallback analysis due to error',
      );
    }
  }

  /// Analyze current situation and generate smart emergency message
  Future<String> generateSmartEmergencyMessage({
    required String situation,
    String? location,
    String? additionalContext,
  }) async {
    try {
      final apiKey = await ApiConfig.getGeminiApiKey();
      if (apiKey == null) {
        return _generateFallbackMessage(situation, location);
      }

      // Get current location if not provided
      location ??= await _getCurrentLocationString();

      final prompt = '''
Generate a concise, urgent emergency message for SMS/call.

Situation: $situation
Location: $location
Additional context: ${additionalContext ?? 'None'}

Requirements:
- Maximum 160 characters for SMS
- Include key details: WHO, WHAT, WHERE
- Sound urgent but clear
- Include location if available
- Professional tone
- Ready to send immediately

Example format: "EMERGENCY: [Name] needs help. [Situation] at [Location]. Call immediately!"

Generate the message:
''';

      final response = await _callGeminiAPI(prompt, apiKey);
      final message = response.trim().replaceAll('"', '');

      // Ensure message isn't too long
      if (message.length > 160) {
        return '${message.substring(0, 157)}...';
      }

      return message;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating smart message: $e');
      }
      return _generateFallbackMessage(situation, location);
    }
  }

  /// Analyze voice tone for distress indicators
  Future<DistressAnalysis> analyzeVoiceDistress(String transcribedText) async {
    try {
      final apiKey = await ApiConfig.getGeminiApiKey();
      if (apiKey == null) {
        return DistressAnalysis(
          isDistressed: _containsDistressKeywords(transcribedText),
          distressLevel: DistressLevel.medium,
          confidence: 0.4,
          indicators: ['Basic keyword detection'],
        );
      }

      final prompt = '''
Analyze this voice transcription for signs of distress or emergency:
"$transcribedText"

Look for:
- Panic indicators (repeated words, incomplete sentences)
- Emotional distress (crying, shouting, fear)
- Emergency language patterns
- Urgency in communication style
- Background noise indicators

Respond with JSON:
{
  "isDistressed": boolean,
  "distressLevel": "low|medium|high|severe",
  "confidence": 0.0-1.0,
  "indicators": ["specific signs detected"],
  "recommendedAction": "immediate action to take"
}
''';

      final response = await _callGeminiAPI(prompt, apiKey);
      return _parseDistressAnalysis(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in voice distress analysis: $e');
      }
      return DistressAnalysis(
        isDistressed: _containsDistressKeywords(transcribedText),
        distressLevel: DistressLevel.medium,
        confidence: 0.3,
        indicators: ['Fallback analysis'],
      );
    }
  }

  /// Analyze behavioral patterns for threat assessment
  Future<ThreatAnalysis> analyzeThreatLevel({
    required String context,
    String? location,
    String? timeOfDay,
    List<String>? recentActivities,
  }) async {
    try {
      final apiKey = await ApiConfig.getGeminiApiKey();
      if (apiKey == null) {
        return ThreatAnalysis(
          threatLevel: ThreatLevel.medium,
          confidence: 0.3,
          riskFactors: ['Unable to perform AI analysis'],
          recommendations: ['Contact emergency services if needed'],
        );
      }

      final prompt = '''
Assess threat level based on this information:

Context: $context
Location: ${location ?? 'Unknown'}
Time: ${timeOfDay ?? 'Unknown'}
Recent activities: ${recentActivities?.join(', ') ?? 'None provided'}

Analyze for:
- Environmental risk factors
- Location-based threats
- Time-sensitive dangers
- Pattern recognition for safety

Respond with JSON:
{
  "threatLevel": "low|medium|high|critical",
  "confidence": 0.0-1.0,
  "riskFactors": ["identified risks"],
  "recommendations": ["safety actions"],
  "immediateActions": ["urgent steps if needed"]
}
''';

      final response = await _callGeminiAPI(prompt, apiKey);
      return _parseThreatAnalysis(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in threat analysis: $e');
      }
      return ThreatAnalysis(
        threatLevel: ThreatLevel.medium,
        confidence: 0.3,
        riskFactors: ['Analysis error'],
        recommendations: ['Use caution and contact help if needed'],
      );
    }
  }

  /// Call TeraxAI Elite Safety Engine - Advanced Protection System
  Future<Map<String, dynamic>> callTeraxAIEliteSafetyEngine({
    required String task,
    String? voiceText,
    String? audioTranscript,
    Map<String, dynamic>? audioFeatures,
    Map<String, dynamic>? backgroundAudioFeatures,
    Map<String, dynamic>? deviceSensors,
    Map<String, dynamic>? biometrics,
    Map<String, dynamic>? context,
    List<String>? recentEvents,
    Map<String, dynamic>? history,
    Map<String, dynamic>? externalData,
    Map<String, dynamic>? emergencySettings,
    Map<String, dynamic>? consent,
    bool? cameraPhotoPresent,
    String? facialEmotion,
    String? userName,
    int? userAge,
    bool? childMode,
    String language = 'en',
    String? customDuressPhrase,
    String? currentLocation,
    String? timeOfDay,
  }) async {
    try {
      final apiKey = await ApiConfig.getGeminiApiKey();
      if (apiKey == null) {
        throw Exception('No API key available');
      }

      // Construct comprehensive input for TeraxAI Elite Safety Engine
      final inputData = {
        'task': task,
        'timestamp': DateTime.now().toIso8601String(),
        'user': {
          'id': 'user_001',
          'name': userName,
          'age_estimate': userAge,
          'child_mode': childMode ?? (userAge != null && userAge < 16),
        },
        'audio_transcript': audioTranscript ?? voiceText,
        'audio_features': audioFeatures,
        'background_audio_features': backgroundAudioFeatures,
        'device_sensors': deviceSensors ??
            {
              'gps': currentLocation != null
                  ? _parseLocation(currentLocation)
                  : null,
              'accel_magnitude': null,
              'recent_shakes': null,
              'phone_locked': null,
              'bluetooth_devices': null,
              'wifi_bssids': null,
            },
        'biometrics': biometrics,
        'camera_photo_present': cameraPhotoPresent,
        'facial_emotion': facialEmotion,
        'context': context ??
            {
              'screen': 'SafetyEngine',
              'trigger_source': 'voice_command',
              'app_state': 'active',
              'time_of_day': timeOfDay ?? _getTimeOfDay(),
            },
        'recent_events': recentEvents ?? [],
        'history': history ??
            {
              'typical_routes_hash': null,
              'last_safe_check_in': null,
              'previous_incidents_count': 0,
            },
        'external_data': externalData ??
            {
              'danger_heatmap_score': null,
              'local_crime_index': null,
            },
        'emergency_settings': emergencySettings ??
            {
              'auto_alert': true,
              'auto_upload': false,
              'trusted_contacts': [],
              'min_confidence_auto_send': 0.85,
              'safe_zones': [],
              'duress_phrase': customDuressPhrase,
            },
        'consent': consent ??
            {
              'upload_allowed': false,
              'share_location_allowed': true,
            },
        'language': language,
      };

      final response = await _callTeraxAIElite(inputData, apiKey);

      // Parse and validate JSON response
      final jsonResponse = jsonDecode(response);
      return _validateAndEnhanceResponse(jsonResponse);
    } catch (e) {
      if (kDebugMode) {
        print('Error calling TeraxAI Elite Safety Engine: $e');
      }
      return _createFallbackSafetyResponse(task, voiceText ?? audioTranscript);
    }
  }

  /// Legacy method for backward compatibility
  Future<Map<String, dynamic>> callTeraxAISafetyAssistant({
    required String task,
    String? audioTranscript,
    Map<String, dynamic>? audioFeatures,
    Map<String, dynamic>? deviceSensors,
    Map<String, dynamic>? context,
    List<String>? recentEvents,
    Map<String, dynamic>? emergencySettings,
    Map<String, dynamic>? consent,
    bool? cameraPhotoPresent,
    String? facialEmotion,
    String? userName,
    String language = 'en',
  }) async {
    try {
      final apiKey = await ApiConfig.getGeminiApiKey();
      if (apiKey == null) {
        throw Exception('No API key available');
      }

      // Construct input data according to TeraxAI specification
      final inputData = {
        'task': task,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': 'user_001',
        'user_name': userName,
        'audio_transcript': audioTranscript,
        'audio_features': audioFeatures,
        'device_sensors': deviceSensors,
        'context': context ??
            {'screen': 'AIAnalysisScreen', 'trigger_source': 'manual'},
        'recent_events': recentEvents ?? [],
        'emergency_settings': emergencySettings ??
            {
              'auto_alert': false,
              'auto_upload': false,
              'trusted_contacts': [],
              'min_confidence_auto_send': 0.85
            },
        'consent': consent ??
            {'upload_allowed': false, 'share_location_allowed': false},
        'camera_photo_present': cameraPhotoPresent,
        'facial_emotion': facialEmotion,
        'language': language,
      };

      final response = await _callTeraxAI(inputData, apiKey);

      // Parse JSON response
      final jsonResponse = jsonDecode(response);
      return jsonResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Error calling TeraxAI Safety Assistant: $e');
      }
      // Return fallback response
      return {
        'version': '1.1',
        'timestamp': DateTime.now().toIso8601String(),
        'task': task,
        'voice_analysis': {
          'transcript': audioTranscript,
          'distress_score': null,
          'distress_score_percent': null,
          'primary_emotion': null,
          'prosodic_clues': {}
        },
        'situation_assessment': {
          'emergency_likelihood': null,
          'emergency_likelihood_percent': null,
          'false_alarm_risk': null,
          'false_alarm_risk_percent': null,
          'sensor_score': null,
          'key_factors': []
        },
        'recommendation': {
          'action': 'monitor',
          'send_alert': false,
          'action_restrictions': 'API_ERROR'
        },
        'emergency_message': {
          'sms_text': null,
          'whatsapp_text': null,
          'include_location': false,
          'location': null,
          'attachments': null
        },
        'confidence_overall': null,
        'confidence_overall_percent': null,
        'explanation': 'API error - using fallback analysis'
      };
    }
  }

  /// Helper method to parse location string
  Map<String, dynamic>? _parseLocation(String location) {
    try {
      final parts = location.split(',');
      if (parts.length >= 2) {
        return {
          'lat': double.parse(parts[0].trim()),
          'lon': double.parse(parts[1].trim()),
          'accuracy_m': 10.0,
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing location: $e');
      }
    }
    return null;
  }

  /// Helper method to get current time of day
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  /// Validate and enhance AI response
  Map<String, dynamic> _validateAndEnhanceResponse(
      Map<String, dynamic> response) {
    // Ensure all required fields exist
    response['version'] ??= '2.0';
    response['timestamp'] ??= DateTime.now().toIso8601String();

    // Add alert_id for traceability
    response['alert_id'] = 'alert_${DateTime.now().millisecondsSinceEpoch}';

    // Validate confidence scores
    if (response['confidence_overall'] != null) {
      response['confidence_overall'] =
          (response['confidence_overall'] as num).clamp(0.0, 1.0);
      response['confidence_overall_percent'] =
          (response['confidence_overall'] * 100).round();
    }

    return response;
  }

  /// Create fallback safety response when AI fails
  Map<String, dynamic> _createFallbackSafetyResponse(
      String task, String? inputText) {
    final hasEmergencyKeywords = inputText
            ?.toLowerCase()
            .contains(RegExp(r'\b(help|emergency|danger|attack|follow)\b')) ??
        false;

    return {
      'version': '2.0',
      'timestamp': DateTime.now().toIso8601String(),
      'task': task,
      'alert_id': 'fallback_${DateTime.now().millisecondsSinceEpoch}',
      'voice_analysis': {
        'transcript': inputText,
        'prosody_score': null,
        'lexical_score': hasEmergencyKeywords ? 0.7 : 0.1,
        'violence_score': null,
        'distress_score': hasEmergencyKeywords ? 0.6 : 0.1,
        'distress_percent': hasEmergencyKeywords ? 60 : 10,
        'primary_emotion': hasEmergencyKeywords ? 'fear' : 'neutral',
        'prosodic_clues': {}
      },
      'situation_assessment': {
        'emergency_likelihood': hasEmergencyKeywords ? 0.5 : 0.1,
        'emergency_percent': hasEmergencyKeywords ? 50 : 10,
        'false_alarm_risk': 0.4,
        'false_alarm_risk_percent': 40,
        'sensor_score': null,
        'biometrics_score': null,
        'key_factors': []
      },
      'recommendation': {
        'action': hasEmergencyKeywords ? 'confirm_send' : 'monitor',
        'send_alert': false,
        'action_restrictions': 'API_ERROR'
      },
      'emergency_message': {
        'sms_text': hasEmergencyKeywords
            ? 'Emergency alert: User may need assistance. Please check on them.'
            : null,
        'whatsapp_text': hasEmergencyKeywords
            ? 'Emergency alert: User may need assistance. Please check on them immediately.'
            : null,
        'include_location': false,
        'location': null,
        'attachments': null
      },
      'preventive_alert': {
        'warning': false,
        'reason': null,
        'recommended_safe_place': null
      },
      'confidence_overall': hasEmergencyKeywords ? 0.5 : 0.1,
      'confidence_overall_percent': hasEmergencyKeywords ? 50 : 10,
      'explanation': 'Fallback analysis - AI service unavailable'
    };
  }

  /// Call TeraxAI Elite Safety Engine with advanced prompt
  Future<String> _callTeraxAIElite(
      Map<String, dynamic> inputData, String apiKey) async {
    const systemPrompt = '''
SYSTEM PROMPT — TeraxAI Elite Safety Engine v3.0 (Production)

You are TERAX AI Elite Safety Engine v3.0, the world's most advanced personal safety AI with real-time threat prediction, behavioral analysis, and emergency response capabilities. Your mission is to protect lives through intelligent analysis and proactive safety measures.

ADVANCED CAPABILITIES:
• Real-time threat assessment with predictive modeling
• Behavioral pattern analysis and anomaly detection
• Multi-modal sensor fusion (audio, visual, biometric, environmental)
• Geospatial risk analysis with crime data integration
• Social engineering and stalking pattern detection
• Child protection with specialized algorithms
• Mental health crisis intervention
• Domestic violence early warning system
• Human trafficking detection protocols
• Workplace violence prevention
• School safety threat assessment
• Elder abuse detection

CORE PRINCIPLES
• Safety-first with 99.9% accuracy requirement for auto-actions
• Predictive threat modeling using historical patterns
• Privacy-by-design with zero-knowledge architecture
• Explainable AI with full audit trails
• Child protection priority: age < 16 OR child_mode=true triggers enhanced protocols
• Trauma-informed responses for vulnerable populations

ADVANCED ANALYSIS ALGORITHMS:
1. LINGUISTIC THREAT ANALYSIS: Parse transcript for 200+ emergency indicators, distress patterns, coercion language, duress codes
2. BEHAVIORAL PATTERN RECOGNITION: Analyze deviation from user's normal patterns (location, timing, communication style)
3. MULTI-MODAL SENSOR FUSION: Combine audio, accelerometer, GPS, heart rate, ambient sound for comprehensive threat assessment
4. GEOSPATIAL RISK MODELING: Cross-reference location with crime databases, safe zones, high-risk areas, time-of-day factors
5. SOCIAL ENGINEERING DETECTION: Identify manipulation tactics, grooming patterns, financial exploitation attempts
6. STALKING PATTERN ANALYSIS: Detect repeated unwanted contact, location tracking, escalating behavior
7. DOMESTIC VIOLENCE INDICATORS: Recognize control patterns, isolation tactics, escalation warning signs
8. CHILD PROTECTION PROTOCOLS: Enhanced sensitivity for minors, school safety, online predator detection
9. MENTAL HEALTH CRISIS ASSESSMENT: Identify self-harm indicators, suicidal ideation, psychotic episodes
10. PREDICTIVE THREAT MODELING: Use historical data to predict escalation probability and optimal intervention timing

ENHANCED OUTPUT SCHEMA (RETURN EXACT JSON OBJECT):
{
 "version":"3.0",
 "timestamp":"<ISO8601>",
 "task":"voice_analysis|situation_assessment|message_generation|combined",
 "voice_analysis":{
    "transcript": "<string|null>",
    "prosody_score": 0.0-1.0|null,
    "lexical_score": 0.0-1.0|null,
    "violence_score": 0.0-1.0|null,
    "distress_score": 0.0-1.0|null,
    "distress_percent": 0-100|null,
    "primary_emotion":"panic|fear|anger|sad|neutral|uncertain|null",
    "prosodic_clues": { "energy":0.0-1.0|null,"shouting_pct":0.0-1.0|null,"high_pitch_pct":0.0-1.0|null,"speech_rate_wpm":float|null },
    "threat_indicators": {
      "coercion_detected": true|false,
      "duress_code_used": true|false,
      "social_engineering": 0.0-1.0|null,
      "grooming_patterns": 0.0-1.0|null,
      "financial_exploitation": 0.0-1.0|null
    }
 },
 "situation_assessment":{
    "emergency_likelihood":0.0-1.0|null,
    "emergency_percent":0-100|null,
    "false_alarm_risk":0.0-1.0|null,
    "false_alarm_risk_percent":0-100|null,
    "sensor_score":0.0-1.0|null,
    "biometrics_score":0.0-1.0|null,
    "threat_level":"LOW|MEDIUM|HIGH|CRITICAL",
    "threat_type":"stalking|domestic_violence|stranger_danger|child_predator|human_trafficking|workplace_violence|mental_health_crisis|financial_scam|none",
    "escalation_probability":0.0-1.0|null,
    "time_to_intervention_minutes":int|null,
    "behavioral_anomalies": {
      "location_deviation": 0.0-1.0|null,
      "timing_unusual": true|false,
      "communication_pattern_change": 0.0-1.0|null,
      "stress_indicators": 0.0-1.0|null
    },
    "geospatial_risk": {
      "crime_index": 0.0-1.0|null,
      "safe_zone_distance_km": float|null,
      "high_risk_area": true|false,
      "time_of_day_risk": 0.0-1.0|null
    },
    "key_factors":[ {"name":"gps_accuracy_m","value":float|null},{"name":"recent_shakes","value":int|null},{"name":"proximity_repeat","value":int|null},{"name":"background_violence_score","value":float|null},{"name":"camera_photo_present","value":bool|null} ]
 },
 "recommendation":{
    "action":"auto_send|confirm_send|monitor|preventive_alert|ignore|escalate_authorities|safe_word_protocol|stealth_mode|lockdown_mode",
    "send_alert": true|false,
    "priority_level":"LOW|MEDIUM|HIGH|CRITICAL|LIFE_THREATENING",
    "response_time_required":"IMMEDIATE|URGENT|STANDARD|MONITORING",
    "specialized_response": {
      "law_enforcement": true|false,
      "medical_emergency": true|false,
      "child_protective_services": true|false,
      "domestic_violence_hotline": true|false,
      "mental_health_crisis": true|false,
      "school_security": true|false
    },
    "stealth_features": {
      "silent_alert": true|false,
      "fake_call_mode": true|false,
      "disguised_message": true|false
    },
    "action_restrictions": null | "MISSING_CONTACTS|NO_LOCATION|NO_CONSENT|LOW_CONFIDENCE|INSUFFICIENT_AUDIO|STEALTH_REQUIRED"
 },
 "emergency_message":{
    "sms_text":"<string|null>",
    "whatsapp_text":"<string|null>",
    "email_text":"<string|null>",
    "voice_message":"<string|null>",
    "include_location": true|false|null,
    "location": {"lat":float|null,"lon":float|null,"accuracy_m":float|null,"maps_url":string|null,"what3words":string|null},
    "attachments": {"recording_url":string|null,"photo_url":string|null,"video_url":string|null,"live_stream_url":string|null},
    "stealth_message": {
      "disguised_text":"<string|null>",
      "code_phrase":"<string|null>",
      "fake_conversation":"<string|null>"
    },
    "multi_language": {
      "primary_language":"en|es|fr|de|zh|ar|hi|pt|ru|ja",
      "translated_messages": {"<lang_code>":"<translated_text>"}
    },
    "accessibility": {
      "text_to_speech":"<string|null>",
      "large_text_format":"<string|null>",
      "sign_language_video":"<string|null>"
    }
 },
 "preventive_alert": {
    "warning":true|false,
    "reason": "danger_zone|route_deviation|stalking_pattern|unusual_behavior|high_crime_area|isolated_location|late_night_risk|suspicious_contact"|null,
    "recommended_safe_place":string|null,
    "safety_actions": ["<action1>","<action2>"],
    "escape_routes": ["<route1>","<route2>"],
    "nearby_help": {"police_station":"<address>","hospital":"<address>","safe_business":"<address>"}
 },
 "advanced_analytics": {
    "pattern_recognition": {"stalking_score":0.0-1.0|null,"routine_deviation":0.0-1.0|null,"contact_frequency_anomaly":0.0-1.0|null},
    "predictive_modeling": {"escalation_timeline":"<timeframe>","intervention_window":"<timeframe>","success_probability":0.0-1.0|null},
    "risk_factors": ["<factor1>","<factor2>"],
    "protective_factors": ["<factor1>","<factor2>"]
 },
 "confidence_overall":0.0-1.0|null,
 "confidence_overall_percent":0-100|null,
 "explanation":"<detailed machine rationale with reasoning chain>",
 "audit_trail": {"analysis_version":"3.0","processing_time_ms":int,"data_sources":["<source1>","<source2>"]}
}

ENHANCED SPECIAL RULES:
• CHILD PROTECTION: If child_mode=true or age < 16: auto_send threshold = 60%, immediate law enforcement contact for HIGH threats
• DOMESTIC VIOLENCE: Recognize control patterns, financial abuse, isolation tactics - enable stealth mode automatically
• STALKING DETECTION: Track location patterns, communication frequency, escalation indicators - predictive intervention
• MENTAL HEALTH: Identify self-harm language, suicidal ideation - immediate crisis intervention protocols
• HUMAN TRAFFICKING: Detect coercion language, movement restrictions, financial control - law enforcement escalation
• ELDER ABUSE: Financial exploitation, isolation, neglect indicators - adult protective services contact
• WORKPLACE VIOLENCE: Threat assessment, escalation patterns - security and HR notification protocols
• SCHOOL SAFETY: Bullying, violence threats, weapon indicators - immediate school security and parent notification
• FINANCIAL SCAMS: Social engineering, pressure tactics, urgency language - fraud prevention alerts
• ONLINE PREDATORS: Grooming language, meeting requests, gift offers - immediate parental and authority notification

Analyze the following input data and respond with the exact JSON schema above:
''';

    final userPrompt = jsonEncode(inputData);

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': systemPrompt},
              {'text': userPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.0,
          'topK': 1,
          'topP': 1.0,
          'maxOutputTokens': 1024,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('TeraxAI Elite API call failed: ${response.statusCode}');
    }
  }

  /// Call TeraxAI with structured input and system prompt
  Future<String> _callTeraxAI(
      Map<String, dynamic> inputData, String apiKey) async {
    const systemPrompt = '''
You are *TeraxAI Safety Assistant*, an AI module whose ONLY purpose is analyzing personal-safety signals and producing precise, auditable JSON outputs for Terax AI. You must not answer questions outside safety/emergency scope. If asked anything out of scope return:

{"error":"OUT_OF_SCOPE","reason":"This model only handles safety/emergency analysis."}

GENERAL REQUIREMENTS
• Always respond with a single JSON object ONLY (no extra prose).
• Provide both normalized float scores (0.00–1.00) and integer percentage fields (0–100). Percentages must equal round(score * 100).
• Be deterministic and conservative: prefer "confirm_send" to "auto_send" unless thresholds are clearly met.

OUTPUT SCHEMA (return EXACTLY this object; use null where not available)
{
  "version":"1.1",
  "timestamp":"<ISO8601 response time>",
  "task":"voice_analysis|situation_assessment|message_generation|combined",
  "voice_analysis": {
    "transcript": "<string|null>",
    "distress_score": 0.0-1.0|null,
    "distress_score_percent": 0-100|null,
    "primary_emotion": "panic|fear|anger|sad|neutral|uncertain|null",
    "prosodic_clues": {"energy":0.0-1.0|null,"shouting_pct":0.0-1.0|null,"high_pitch_pct":0.0-1.0|null,"speech_rate_wpm":float|null}
  },
  "situation_assessment": {
    "emergency_likelihood": 0.0-1.0|null,
    "emergency_likelihood_percent": 0-100|null,
    "false_alarm_risk": 0.0-1.0|null,
    "false_alarm_risk_percent": 0-100|null,
    "sensor_score": 0.0-1.0|null,
    "key_factors": [ {"name":"gps_accuracy_m","value":float|null}, {"name":"recent_shakes","value":int|null}, {"name":"background_noise_db","value":float|null}, {"name":"camera_photo_present","value":bool|null} ]
  },
  "recommendation": {
    "action":"auto_send|confirm_send|monitor|ignore",
    "send_alert": true|false,
    "action_restrictions": null | "MISSING_CONTACTS|NO_LOCATION|NO_CONSENT|LOW_CONFIDENCE|INSUFFICIENT_AUDIO"
  },
  "emergency_message": {
    "sms_text":"<short SMS text or null>",
    "whatsapp_text":"<long text or null>",
    "include_location": true|false|null,
    "location": {"lat":float|null,"lon":float|null,"accuracy_m":float|null,"maps_url":string|null},
    "attachments": {"recording_url":string|null,"photo_url":string|null}
  },
  "confidence_overall": 0.0-1.0|null,
  "confidence_overall_percent": 0-100|null,
  "explanation":"<one-line machine-readable rationale>"
}

Analyze the following input data and respond with the exact JSON schema above:
''';

    final userPrompt = jsonEncode(inputData);

    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': systemPrompt},
              {'text': userPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.0,
          'topK': 1,
          'topP': 1.0,
          'maxOutputTokens': 512,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('TeraxAI API call failed: ${response.statusCode}');
    }
  }

  /// Call Gemini API
  Future<String> _callGeminiAPI(String prompt, String apiKey) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
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
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('API call failed: ${response.statusCode}');
    }
  }

  // Helper methods for parsing responses and fallbacks
  EmergencyAnalysis _parseEmergencyAnalysis(String response) {
    try {
      final data = jsonDecode(response);
      return EmergencyAnalysis(
        isEmergency: data['isEmergency'] ?? false,
        urgencyLevel: _parseUrgencyLevel(data['urgencyLevel']),
        confidence: (data['confidence'] ?? 0.5).toDouble(),
        suggestedActions: List<String>.from(data['suggestedActions'] ?? []),
        analysis: data['analysis'] ?? '',
        keywords: List<String>.from(data['keywords'] ?? []),
      );
    } catch (e) {
      return EmergencyAnalysis(
        isEmergency: false,
        urgencyLevel: UrgencyLevel.medium,
        confidence: 0.3,
        suggestedActions: ['Contact emergency services'],
        analysis: 'Parse error',
      );
    }
  }

  DistressAnalysis _parseDistressAnalysis(String response) {
    try {
      final data = jsonDecode(response);
      return DistressAnalysis(
        isDistressed: data['isDistressed'] ?? false,
        distressLevel: _parseDistressLevel(data['distressLevel']),
        confidence: (data['confidence'] ?? 0.5).toDouble(),
        indicators: List<String>.from(data['indicators'] ?? []),
        recommendedAction: data['recommendedAction'] ?? '',
      );
    } catch (e) {
      return DistressAnalysis(
        isDistressed: false,
        distressLevel: DistressLevel.medium,
        confidence: 0.3,
        indicators: ['Parse error'],
      );
    }
  }

  ThreatAnalysis _parseThreatAnalysis(String response) {
    try {
      final data = jsonDecode(response);
      return ThreatAnalysis(
        threatLevel: _parseThreatLevel(data['threatLevel']),
        confidence: (data['confidence'] ?? 0.5).toDouble(),
        riskFactors: List<String>.from(data['riskFactors'] ?? []),
        recommendations: List<String>.from(data['recommendations'] ?? []),
        immediateActions: List<String>.from(data['immediateActions'] ?? []),
      );
    } catch (e) {
      return ThreatAnalysis(
        threatLevel: ThreatLevel.medium,
        confidence: 0.3,
        riskFactors: ['Parse error'],
        recommendations: ['Contact emergency services'],
      );
    }
  }

  // Fallback methods
  bool _containsEmergencyKeywords(String text) {
    final keywords = [
      'help',
      'emergency',
      'danger',
      'attack',
      'fire',
      'police',
      'ambulance',
      'save',
      'urgent'
    ];
    return keywords.any((keyword) => text.toLowerCase().contains(keyword));
  }

  bool _containsDistressKeywords(String text) {
    final keywords = [
      'scared',
      'afraid',
      'panic',
      'hurt',
      'pain',
      'trapped',
      'lost',
      'alone'
    ];
    return keywords.any((keyword) => text.toLowerCase().contains(keyword));
  }

  String _generateFallbackMessage(String situation, String? location) {
    final loc = location ?? 'Unknown location';
    return 'EMERGENCY: Need immediate help. $situation at $loc. Please call now!';
  }

  Future<String> _getCurrentLocationString() async {
    try {
      final location = await RealLocationService.instance.getCurrentLocation();
      if (location.position != null) {
        return '${location.position!.latitude.toStringAsFixed(4)}, ${location.position!.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
    }
    return 'Location unavailable';
  }

  // Enum parsers
  UrgencyLevel _parseUrgencyLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'low':
        return UrgencyLevel.low;
      case 'medium':
        return UrgencyLevel.medium;
      case 'high':
        return UrgencyLevel.high;
      case 'critical':
        return UrgencyLevel.critical;
      default:
        return UrgencyLevel.medium;
    }
  }

  DistressLevel _parseDistressLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'low':
        return DistressLevel.low;
      case 'medium':
        return DistressLevel.medium;
      case 'high':
        return DistressLevel.high;
      case 'severe':
        return DistressLevel.severe;
      default:
        return DistressLevel.medium;
    }
  }

  ThreatLevel _parseThreatLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'low':
        return ThreatLevel.low;
      case 'medium':
        return ThreatLevel.medium;
      case 'high':
        return ThreatLevel.high;
      case 'critical':
        return ThreatLevel.critical;
      default:
        return ThreatLevel.medium;
    }
  }
}

// Data classes
class EmergencyAnalysis {
  final bool isEmergency;
  final UrgencyLevel urgencyLevel;
  final double confidence;
  final List<String> suggestedActions;
  final String analysis;
  final List<String> keywords;

  EmergencyAnalysis({
    required this.isEmergency,
    required this.urgencyLevel,
    required this.confidence,
    required this.suggestedActions,
    required this.analysis,
    this.keywords = const [],
  });
}

class DistressAnalysis {
  final bool isDistressed;
  final DistressLevel distressLevel;
  final double confidence;
  final List<String> indicators;
  final String recommendedAction;

  DistressAnalysis({
    required this.isDistressed,
    required this.distressLevel,
    required this.confidence,
    required this.indicators,
    this.recommendedAction = '',
  });
}

class ThreatAnalysis {
  final ThreatLevel threatLevel;
  final double confidence;
  final List<String> riskFactors;
  final List<String> recommendations;
  final List<String> immediateActions;

  ThreatAnalysis({
    required this.threatLevel,
    required this.confidence,
    required this.riskFactors,
    required this.recommendations,
    this.immediateActions = const [],
  });
}

enum UrgencyLevel { low, medium, high, critical }

enum DistressLevel { low, medium, high, severe }

enum ThreatLevel { low, medium, high, critical }
