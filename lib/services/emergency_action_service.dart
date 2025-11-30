import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'real_location_service.dart';

/// Enhanced Emergency Action Service - Advanced emergency response with AI-driven actions
class EmergencyActionService {
  static final EmergencyActionService _instance =
      EmergencyActionService._internal();
  static EmergencyActionService get instance => _instance;
  EmergencyActionService._internal();

  /// Emergency contacts list with priority levels
  final List<EmergencyContact> _emergencyContacts = [];
  

  /// Add emergency contact
  void addEmergencyContact(EmergencyContact contact) {
    _emergencyContacts.add(contact);
  }

  /// Remove emergency contact
  void removeEmergencyContact(String contactId) {
    _emergencyContacts.removeWhere((contact) => contact.id == contactId);
  }

  /// Get all emergency contacts
  List<EmergencyContact> get emergencyContacts =>
      List.unmodifiable(_emergencyContacts);

  /// Process AI analysis result and take appropriate action
  Future<EmergencyActionResult> processAIAnalysis(
    Map<String, dynamic> aiResult, {
    String? userInput,
    bool isChildMode = false,
  }) async {
    try {
      final recommendation =
          aiResult['recommendation'] as Map<String, dynamic>?;
      final emergencyMessage =
          aiResult['emergency_message'] as Map<String, dynamic>?;
      final preventiveAlert =
          aiResult['preventive_alert'] as Map<String, dynamic>?;

      if (recommendation == null) {
        return EmergencyActionResult(
          success: false,
          message: 'Invalid AI analysis result',
          actionTaken: EmergencyAction.none,
        );
      }

      final action = recommendation['action'] as String?;
      
      final alertId = aiResult['alert_id'] as String? ?? 'unknown';

      

      switch (action) {
        case 'auto_send':
          return await _handleAutoSend(emergencyMessage, alertId, isChildMode);

        case 'confirm_send':
          return await _handleConfirmSend(emergencyMessage, alertId, userInput);

        case 'preventive_alert':
          return await _handlePreventiveAlert(preventiveAlert, alertId);

        case 'monitor':
          return _handleMonitor(alertId);

        case 'ignore':
        default:
          return EmergencyActionResult(
            success: true,
            message: 'No action required',
            actionTaken: EmergencyAction.none,
            alertId: alertId,
          );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error processing AI analysis: $e');
      }
      return EmergencyActionResult(
        success: false,
        message: 'Error processing emergency analysis: $e',
        actionTaken: EmergencyAction.error,
      );
    }
  }

  /// Handle automatic emergency alert sending
  Future<EmergencyActionResult> _handleAutoSend(
    Map<String, dynamic>? emergencyMessage,
    String alertId,
    bool isChildMode,
  ) async {
    if (_emergencyContacts.isEmpty) {
      return EmergencyActionResult(
        success: false,
        message: 'No emergency contacts configured',
        actionTaken: EmergencyAction.failed,
        alertId: alertId,
      );
    }

    

    try {
      final location = await _getCurrentLocation();
      final message =
          _buildEmergencyMessage(emergencyMessage, location, isChildMode);

      // Send to all emergency contacts
      final results = await Future.wait([
        _sendSMSAlerts(message, location),
        _sendWhatsAppAlerts(message, location),
        if (isChildMode) _callEmergencyServices(),
      ]);

      final allSuccessful = results.every((result) => result);

      return EmergencyActionResult(
        success: allSuccessful,
        message: allSuccessful
            ? 'Emergency alerts sent to all contacts'
            : 'Some emergency alerts failed to send',
        actionTaken: EmergencyAction.autoSent,
        alertId: alertId,
        contactsNotified: _emergencyContacts.length,
      );
    } catch (e) {
      
      return EmergencyActionResult(
        success: false,
        message: 'Failed to send emergency alerts: $e',
        actionTaken: EmergencyAction.failed,
        alertId: alertId,
      );
    }
  }

  /// Handle confirm send (user confirmation required)
  Future<EmergencyActionResult> _handleConfirmSend(
    Map<String, dynamic>? emergencyMessage,
    String alertId,
    String? userInput,
  ) async {
    // This would typically show a confirmation dialog to the user
    // For now, we'll return a result indicating confirmation is needed
    return EmergencyActionResult(
      success: true,
      message: 'Emergency detected. Confirmation required to send alerts.',
      actionTaken: EmergencyAction.confirmationRequired,
      alertId: alertId,
      recommendedMessage: emergencyMessage?['sms_text'] as String?,
    );
  }

  /// Handle preventive alert
  Future<EmergencyActionResult> _handlePreventiveAlert(
    Map<String, dynamic>? preventiveAlert,
    String alertId,
  ) async {
    final warning = preventiveAlert?['warning'] as bool? ?? false;
    final reason = preventiveAlert?['reason'] as String?;
    final safePlaceRecommendation =
        preventiveAlert?['recommended_safe_place'] as String?;

    if (warning) {
      return EmergencyActionResult(
        success: true,
        message: 'Safety warning: ${reason ?? "Potential risk detected"}',
        actionTaken: EmergencyAction.preventiveAlert,
        alertId: alertId,
        safetyTip: safePlaceRecommendation,
      );
    }

    return EmergencyActionResult(
      success: true,
      message: 'Monitoring situation',
      actionTaken: EmergencyAction.monitor,
      alertId: alertId,
    );
  }

  /// Handle monitor mode
  EmergencyActionResult _handleMonitor(String alertId) {
    return EmergencyActionResult(
      success: true,
      message: 'Monitoring for safety signals',
      actionTaken: EmergencyAction.monitor,
      alertId: alertId,
    );
  }

  /// Get current location for emergency messages
  Future<LocationData?> _getCurrentLocation() async {
    try {
      final locationResult =
          await RealLocationService.instance.getCurrentLocation();
      if (locationResult.position != null) {
        return LocationData(
          latitude: locationResult.position!.latitude,
          longitude: locationResult.position!.longitude,
          accuracy: locationResult.position!.accuracy,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting location: $e');
      }
    }
    return null;
  }

  /// Build emergency message with location and context
  String _buildEmergencyMessage(
    Map<String, dynamic>? emergencyMessage,
    LocationData? location,
    bool isChildMode,
  ) {
    final baseMessage = emergencyMessage?['sms_text'] as String? ??
        'Emergency alert: User may need assistance.';

    final locationText = location != null
        ? ' Location: https://maps.google.com/maps?q=${location.latitude},${location.longitude}'
        : '';

    final urgencyText = isChildMode ? ' [CHILD EMERGENCY]' : '';
    final timestamp = ' Time: ${DateTime.now().toString().substring(0, 19)}';

    return '$baseMessage$urgencyText$locationText$timestamp';
  }

  /// Send SMS alerts to emergency contacts
  Future<bool> _sendSMSAlerts(String message, LocationData? location) async {
    try {
      for (final contact in _emergencyContacts) {
        if (contact.phone.isNotEmpty) {
          final uri = Uri(
            scheme: 'sms',
            path: contact.phone,
            queryParameters: {'body': message},
          );

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending SMS alerts: $e');
      }
      return false;
    }
  }

  /// Send WhatsApp alerts to emergency contacts
  Future<bool> _sendWhatsAppAlerts(
      String message, LocationData? location) async {
    try {
      for (final contact in _emergencyContacts) {
        if (contact.whatsappId.isNotEmpty) {
          final uri = Uri.parse(
              'https://wa.me/${contact.whatsappId}?text=${Uri.encodeComponent(message)}');

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending WhatsApp alerts: $e');
      }
      return false;
    }
  }

  /// Call emergency services (for child mode or severe emergencies)
  Future<bool> _callEmergencyServices() async {
    try {
      const emergencyNumber = 'tel:911'; // Change based on country
      final uri = Uri.parse(emergencyNumber);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calling emergency services: $e');
      }
    }
    return false;
  }

  /// Cancel current emergency
  void cancelEmergency() {
    
    
  }

  
}

/// Emergency contact model
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String whatsappId;
  final String relationship;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.whatsappId = '',
    this.relationship = 'Emergency Contact',
  });
}

/// Location data model
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}

/// Emergency action result
class EmergencyActionResult {
  final bool success;
  final String message;
  final EmergencyAction actionTaken;
  final String? alertId;
  final int? contactsNotified;
  final String? recommendedMessage;
  final String? safetyTip;

  EmergencyActionResult({
    required this.success,
    required this.message,
    required this.actionTaken,
    this.alertId,
    this.contactsNotified,
    this.recommendedMessage,
    this.safetyTip,
  });
}

/// Emergency action types
enum EmergencyAction {
  none,
  autoSent,
  confirmationRequired,
  preventiveAlert,
  monitor,
  failed,
  error,
  stealthMode,
  escalateAuthorities,
  lockdownMode,
  safeWordProtocol,
}

/// Emergency severity levels
enum EmergencyLevel {
  none,
  low,
  medium,
  high,
  critical,
  lifeThreatening,
}

/// Professional emergency contact
class ProfessionalContact {
  final String id;
  final String name;
  final String organization;
  final String phone;
  final String email;
  final String specialization;
  final bool available24x7;

  ProfessionalContact({
    required this.id,
    required this.name,
    required this.organization,
    required this.phone,
    this.email = '',
    required this.specialization,
    this.available24x7 = false,
  });
}
