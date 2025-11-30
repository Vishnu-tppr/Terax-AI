import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:terax_ai_app/services/ai_analysis_service.dart';
import 'package:terax_ai_app/services/emergency_action_service.dart';
import 'package:terax_ai_app/services/emergency_message_service.dart';
import 'package:terax_ai_app/utils/theme/app_theme.dart';
import 'package:terax_ai_app/utils/logger.dart';
import 'package:terax_ai_app/providers/location_provider.dart';
import 'package:terax_ai_app/providers/auth_provider.dart';
import 'package:terax_ai_app/providers/contacts_provider.dart';
import 'package:terax_ai_app/models/emergency_contact.dart';

import 'package:terax_ai_app/widgets/advanced_threat_display.dart';
import 'package:terax_ai_app/widgets/emergency_message_demo.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isAnalyzing = false;
  bool _showEmergencyAlert = false;
  String? _emergencyMessage;
  String? _safetyTip;
  double? _emergencyConfidence;
  String? _recommendedAction;
  String? _alertId;
  Map<String, dynamic>? _fullAnalysisResult;

  // Add a logger for better error tracking
  static const _tag = 'AIAnalysisScreen';

  @override
  void initState() {
    super.initState();
    _setupErrorHandling();
  }

  void _setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint(
          '[$_tag] Flutter error: ${details.exception}\n${details.stack}');
    };
  }

  @override
  void dispose() {
    // Clean up the controller
    _textController.dispose();

    // Clear any ongoing analysis state

    // Clear sensitive data
    _fullAnalysisResult = null;
    _emergencyMessage = null;
    _alertId = null;

    super.dispose();
  }

  Future<void> _analyzeEmergency() async {
    final inputText = _textController.text.trim();
    if (inputText.isEmpty) {
      _showSnackBar('Please enter some text to analyze');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _showEmergencyAlert = false;
    });

    try {
      // Call TeraxAI Elite Safety Engine with comprehensive analysis
      final payload = _buildAIPayload();
      final teraxResult =
          await AIAnalysisService.instance.callTeraxAIEliteSafetyEngine(
        task: payload['task'],
        voiceText: payload['voiceText'],
        audioFeatures: payload['audioFeatures'],
        backgroundAudioFeatures: payload['backgroundAudioFeatures'],
        deviceSensors: payload['deviceSensors'],
        biometrics: payload['biometrics'],
        context: payload['context'],
        recentEvents: payload['recentEvents'],
        history: payload['history'],
        externalData: payload['externalData'],
        emergencySettings: payload['emergencySettings'],
        consent: payload['consent'],
        cameraPhotoPresent: payload['cameraPhotoPresent'],
        facialEmotion: payload['facialEmotion'],
        userName: payload['userName'],
        userAge: payload['userAge'],
        childMode: payload['childMode'],
        language: payload['language'],
        customDuressPhrase: payload['customDuressPhrase'],
        currentLocation: payload['currentLocation'],
        timeOfDay: payload['timeOfDay'],
      );

      // Process the AI result and extract emergency information
      _processEmergencyResult(teraxResult);

      // Process emergency actions if needed
      final actionResult =
          await EmergencyActionService.instance.processAIAnalysis(
        teraxResult,
        userInput: _textController.text,
        isChildMode: false,
      );

      _handleEmergencyAction(actionResult);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Emergency analysis failed. Using safety fallback.');
        // Show fallback safety message
        setState(() {
          _emergencyMessage =
              'Unable to analyze. If this is an emergency, call 911 immediately.';
          _safetyTip = 'Stay calm and seek help from trusted contacts.';
          _showEmergencyAlert = true;
          _emergencyConfidence = 0.0;
          _recommendedAction = 'manual_action_required';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildAIPayload() {
    // This could be converted to a proper data class for even better type safety.
    return {
      'task': 'combined',
      'voiceText': _textController.text,
      'audioFeatures': {
        'duration_ms': _textController.text.length * 50,
        'avg_pitch_hz': null,
        'pitch_variance': null,
        'energy': 0.7,
        'shouting_pct': _textController.text.contains('!') ? 0.3 : 0.0,
        'high_pitch_pct': null,
        'speech_rate_wpm': null,
      },
      'backgroundAudioFeatures': {
        'scream_score': 0.0,
        'glass_break_score': 0.0,
        'firearm_klaxon': 0.0,
      },
      'deviceSensors': {
        'gps': null,
        'accel_magnitude': null,
        'recent_shakes': null,
        'phone_locked': false,
        'bluetooth_devices': null,
        'wifi_bssids': null,
      },
      'biometrics': {
        'heart_rate': null,
        'hrv': null,
        'breathing_rate': null,
      },
      'context': {
        'screen': 'AIAnalysisScreen',
        'trigger_source': 'manual_text_analysis',
        'app_state': 'active',
      },
      'recentEvents': ['text_analysis_requested', 'user_input_detected'],
      'history': {
        'typical_routes_hash': null,
        'last_safe_check_in':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'previous_incidents_count': 0,
      },
      'externalData': {
        'danger_heatmap_score': null,
        'local_crime_index': null,
      },
      // In a real app, these settings would come from a provider.
      'emergencySettings': {
        'auto_alert': false,
        'auto_upload': false,
        'trusted_contacts': [],
        'min_confidence_auto_send': 0.85,
        'safe_zones': [],
      },
      'consent': {
        'upload_allowed': false,
        'share_location_allowed': true,
      },
      'cameraPhotoPresent': false,
      'facialEmotion': null,
      'userName': 'User', // Should come from AuthProvider
      'userAge': null,
      'childMode': false,
      'language': 'en',
      'customDuressPhrase': null,
      'currentLocation': null,
      'timeOfDay': null,
    };
  }

  void _processEmergencyResult(Map<String, dynamic> result) {
    final recommendation = result['recommendation'] as Map<String, dynamic>?;
    final emergencyMessage =
        result['emergency_message'] as Map<String, dynamic>?;
    final preventiveAlert = result['preventive_alert'] as Map<String, dynamic>?;
    final situationAssessment =
        result['situation_assessment'] as Map<String, dynamic>?;
    final advancedAnalytics =
        result['advanced_analytics'] as Map<String, dynamic>?;

    setState(() {
      // Store the full analysis result for advanced display
      _fullAnalysisResult = result;

      _emergencyConfidence =
          (result['confidence_overall'] as num?)?.toDouble() ?? 0.0;
      _alertId = result['alert_id'] as String?;
      _recommendedAction = recommendation?['action'] as String?;

      // Extract enhanced emergency message with multiple formats
      _emergencyMessage = emergencyMessage?['sms_text'] as String? ??
          emergencyMessage?['whatsapp_text'] as String? ??
          emergencyMessage?['email_text'] as String?;

      // Extract comprehensive safety information
      final safetyActions =
          preventiveAlert?['safety_actions'] as List<dynamic>?;
      final escapeRoutes = preventiveAlert?['escape_routes'] as List<dynamic>?;
      final nearbyHelp =
          preventiveAlert?['nearby_help'] as Map<String, dynamic>?;

      _safetyTip = _buildComprehensiveSafetyTip(
        preventiveAlert?['recommended_safe_place'] as String?,
        safetyActions?.cast<String>(),
        escapeRoutes?.cast<String>(),
        nearbyHelp,
        result['explanation'] as String?,
      );

      // Enhanced alert triggering based on threat level and type
      final threatLevel = situationAssessment?['threat_level'] as String?;
      final threatType = situationAssessment?['threat_type'] as String?;
      final escalationProbability =
          situationAssessment?['escalation_probability'] as num?;

      _showEmergencyAlert = _shouldShowAlert(
        _emergencyConfidence ?? 0.0,
        threatLevel,
        threatType,
        escalationProbability?.toDouble(),
      );

      // Log advanced analytics for debugging
      if (kDebugMode && advancedAnalytics != null) {
        logger.info('Advanced Analytics: $advancedAnalytics');
      }
    });
  }

  void _handleEmergencyAction(EmergencyActionResult actionResult) {
    if (actionResult.success) {
      switch (actionResult.actionTaken) {
        case EmergencyAction.autoSent:
          _showSnackBar(
              'Emergency alerts sent to ${actionResult.contactsNotified} contacts');
          break;
        case EmergencyAction.confirmationRequired:
          _showConfirmationDialog(actionResult);
          break;
        case EmergencyAction.preventiveAlert:
          _showSnackBar(
              'Safety warning: ${actionResult.safetyTip ?? "Stay alert"}');
          break;
        case EmergencyAction.monitor:
          _showSnackBar('Monitoring situation for safety');
          break;
        default:
          break;
      }
    }
  }

  void _showConfirmationDialog(EmergencyActionResult actionResult) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(actionResult.message),
            if (actionResult.recommendedMessage != null) ...[
              const SizedBox(height: 16),
              const Text('Recommended message:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(actionResult.recommendedMessage!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendEmergencyAlert();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Send Alert', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendEmergencyAlert() async {
    try {
      if (_fullAnalysisResult == null) {
        _showSnackBar('No analysis data available');
        return;
      }

      // Show loading indicator
      _showSnackBar('Sending emergency alert...');
      HapticFeedback.heavyImpact();

      // Determine emergency type from analysis
      final situationAssessment =
          _fullAnalysisResult!['situation_assessment'] as Map<String, dynamic>?;
      final threatType =
          situationAssessment?['threat_type'] as String? ?? 'general_emergency';

      // Get providers before async operations to avoid context issues
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final contactsProvider =
          Provider.of<ContactsProvider>(context, listen: false);

      // Get actual location from LocationProvider
      String currentLocation = 'Current Location';
      double? latitude;
      double? longitude;

      if (locationProvider.hasValidLocation) {
        currentLocation = locationProvider.currentAddress ?? 'Current Location';
        latitude = locationProvider.currentLatitude;
        longitude = locationProvider.currentLongitude;
      }

      // Get actual user name from AuthProvider
      final userName = authProvider.currentUser?.fullName ?? 'User';

      // Generate emergency message using the new service
      final emergencyMessage =
          await EmergencyMessageService.instance.generateEmergencyMessage(
        emergencyType: threatType,
        currentLocation: currentLocation,
        latitude: latitude,
        longitude: longitude,
        userName: userName,
        additionalContext: {
          'confidence_score': ((_emergencyConfidence ?? 0.0) * 100).toInt(),
          'threat_level': situationAssessment?['threat_level'],
          'voice_analysis': _fullAnalysisResult!['voice_analysis'],
          'behavioral_indicators': situationAssessment?['behavioral_anomalies'],
        },
      );

      // Get actual emergency contacts from ContactsProvider
      final emergencyContacts = contactsProvider.contacts
          .where((contact) =>
              contact.relationship == ContactRelationship.emergency)
          .toList();

      final phoneNumbers =
          emergencyContacts.map((contact) => contact.phoneNumber).toList();

      final emailAddresses = emergencyContacts
          .where((contact) => contact.email != null)
          .map((contact) => contact.email!)
          .toList();

      // Send emergency message via multiple channels
      final deliveryResult =
          await EmergencyMessageService.instance.sendEmergencyMessage(
        message: emergencyMessage,
        phoneNumbers: phoneNumbers,
        emailAddresses: emailAddresses,
        sendSMS: true,
        sendWhatsApp: true,
        sendEmail: true,
      );

      // Show result to user
      if (deliveryResult.success) {
        final successCount =
            deliveryResult.results.values.where((success) => success).length;
        final totalCount = deliveryResult.results.length;
        _showSnackBar(
            'Emergency alert sent successfully ($successCount/$totalCount channels)');

        // Log success for debugging
        if (kDebugMode) {
          logger.info('Emergency message sent successfully');
          logger.info('SMS: ${emergencyMessage.smsMessage}');
          logger.info('WhatsApp: ${emergencyMessage.whatsappMessage}');
          logger
              .info('Email Subject: ${emergencyMessage.emailMessage.subject}');
        }
      } else {
        _showSnackBar('Failed to send emergency alert - please try again');
        if (kDebugMode) {
          logger.warning('Delivery errors: ${deliveryResult.errors}');
        }
      }
    } catch (e) {
      _showSnackBar('Error sending emergency alert: $e');
      if (kDebugMode) {
        logger.warning('Emergency alert error: $e');
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _buildComprehensiveSafetyTip(
    String? safePlaceRecommendation,
    List<String>? safetyActions,
    List<String>? escapeRoutes,
    Map<String, dynamic>? nearbyHelp,
    String? explanation,
  ) {
    final tips = <String>[];

    if (safePlaceRecommendation != null) {
      tips.add('Safe place: $safePlaceRecommendation');
    }

    if (safetyActions != null && safetyActions.isNotEmpty) {
      tips.add('Actions: ${safetyActions.join(', ')}');
    }

    if (escapeRoutes != null && escapeRoutes.isNotEmpty) {
      tips.add('Escape routes: ${escapeRoutes.join(', ')}');
    }

    if (nearbyHelp != null) {
      final helpLocations =
          nearbyHelp.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      if (helpLocations.isNotEmpty) {
        tips.add('Nearby help: $helpLocations');
      }
    }

    if (explanation != null) {
      tips.add('Analysis: $explanation');
    }

    return tips.isNotEmpty
        ? tips.join('\n')
        : 'Stay alert and trust your instincts.';
  }

  bool _shouldShowAlert(
    double confidence,
    String? threatLevel,
    String? threatType,
    double? escalationProbability,
  ) {
    // Enhanced alert logic based on multiple factors
    if (confidence > 0.7) return true; // High confidence always shows alert

    if (threatLevel == 'HIGH' || threatLevel == 'CRITICAL') return true;

    if (threatType != null && threatType != 'none') {
      // Specific threat types that should always trigger alerts
      final highPriorityThreats = [
        'stalking',
        'domestic_violence',
        'child_predator',
        'human_trafficking',
        'mental_health_crisis'
      ];
      if (highPriorityThreats.contains(threatType)) return true;
    }

    if (escalationProbability != null && escalationProbability > 0.6) {
      return true;
    }

    // Default threshold for general threats
    return confidence > 0.3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TeraxAI Emergency Analysis'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advanced Emergency Alert Display
            if (_showEmergencyAlert && _fullAnalysisResult != null) ...[
              AdvancedThreatDisplay(
                analysisResult: _fullAnalysisResult!,
                onSendAlert: _sendEmergencyAlert,
                onDismiss: () {
                  setState(() {
                    _showEmergencyAlert = false;
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
            if (_fullAnalysisResult != null) ...[
              const SizedBox(height: 20),
              Text('Emergency Message: ${_emergencyMessage ?? 'N/A'}'),
              Text('Safety Tip: ${_safetyTip ?? 'N/A'}'),
              Text('Recommended Action: ${_recommendedAction ?? 'N/A'}'),
              Text('Alert ID: ${_alertId ?? 'N/A'}'),
            ],

            // Input Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology,
                            color: AppTheme.primaryRed, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'TeraxAI Elite Safety Engine',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Speak or type what\'s happening. Our AI will analyze for emergencies and provide instant help.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'Example: "Help me, someone is following me" or "I feel unsafe walking home"',
          
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white, 
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _analyzeEmergency,
                        icon: _isAnalyzing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.security),
                        label: Text(_isAnalyzing
                            ? 'Analyzing...'
                            : 'Analyze for Emergency'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Quick Examples
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Test Examples',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildExampleButton('Help me, someone is following me!'),
                    const SizedBox(height: 8),
                    _buildExampleButton('I feel unsafe walking home alone'),
                    const SizedBox(height: 8),
                    _buildExampleButton('There\'s a strange person at my door'),
                    const SizedBox(height: 8),
                    _buildExampleButton('I\'m lost and my phone is dying'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        const Text(
                          'How It Works',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• AI analyzes your text for emergency indicators\n'
                      '• Calculates confidence scores and threat levels\n'
                      '• Generates smart emergency messages\n'
                      '• Can automatically alert emergency contacts\n'
                      '• Provides safety tips and recommendations',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const EmergencyMessageDemo(),
            ),
          );
        },
        icon: const Icon(Icons.message),
        label: const Text('Help'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildExampleButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isAnalyzing
            ? null
            : () {
                _textController.text = text;
                _analyzeEmergency();
              },
        child: Text(
          text,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.left,
        ),
      ),
    );
  }
}
