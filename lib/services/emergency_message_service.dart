import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Emergency Message Service - Dynamic template system with multi-channel delivery
class EmergencyMessageService {
  static final EmergencyMessageService _instance =
      EmergencyMessageService._internal();
  static EmergencyMessageService get instance => _instance;
  EmergencyMessageService._internal() {
    // Initialize templates when the service is first created.
    _initializeTemplates();
  }

  bool _isInitialized = false;
  Map<String, EmergencyTemplate> _templates = {};

  /// Initializes templates from the JSON asset file.
  Future<void> _initializeTemplates() async {
    if (_isInitialized) return;
    try {
      final String response =
          await rootBundle.loadString('assets/emergency_templates.json');
      final data = await json.decode(response);
      final templatesData = data['templates'] as Map<String, dynamic>;

      _templates = templatesData.map((key, value) {
        return MapEntry(key, EmergencyTemplate.fromJson(value));
      });
      _isInitialized = true;
      if (kDebugMode) {
        print('Emergency templates loaded successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load emergency templates: $e');
      }
      // Handle error, maybe load fallback templates
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeTemplates();
    }
  }

  /// Generate emergency message from template and context
  Future<EmergencyMessage> generateEmergencyMessage({
    required String emergencyType,
    required String? currentLocation,
    required double? latitude,
    required double? longitude,
    required String userName,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      await _ensureInitialized();
      final template =
          _templates[emergencyType] ?? _templates['general_emergency']!;

      // Generate location information
      final locationInfo =
          await _generateLocationInfo(currentLocation, latitude, longitude);

      // Generate timestamp
      final timestamp = DateTime.now();
      final timeString =
          '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

      // Generate messages for different channels
      final smsMessage =
          _generateSMSMessage(template, locationInfo, userName, timeString);
      final whatsappMessage = _generateWhatsAppMessage(
          template, locationInfo, userName, timeString);
      final emailMessage = _generateEmailMessage(
          template, locationInfo, userName, timeString, additionalContext);

      return EmergencyMessage(
        emergencyType: emergencyType,
        template: template,
        locationInfo: locationInfo,
        timestamp: timestamp,
        smsMessage: smsMessage,
        whatsappMessage: whatsappMessage,
        emailMessage: emailMessage,
        userName: userName,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error generating emergency message: $e');
      }
      return _generateFallbackMessage(emergencyType, currentLocation, userName);
    }
  }

  /// Generate SMS message (160 character limit consideration)
  String _generateSMSMessage(EmergencyTemplate template,
      LocationInfo locationInfo, String userName, String timeString) {
    return '''🚨 EMERGENCY ALERT (TERAX AI) 🚨

${template.icon} ${template.category}

User: $userName
Problem: ${template.problemDescription}
Time: $timeString
Location: ${locationInfo.address}
GPS: ${locationInfo.gpsLink}

${template.specialInstructions}

Stay Alert. Stay Safe.
- TERAX AI''';
  }

  /// Generate WhatsApp message (rich formatting)
  String _generateWhatsAppMessage(EmergencyTemplate template,
      LocationInfo locationInfo, String userName, String timeString) {
    return '''🚨 *EMERGENCY ALERT (from TERAX AI)* 🚨

This is an automated emergency message sent by *TERAX AI*. The user is facing an emergency and requires *immediate assistance*.

${template.icon} *${template.category}*
📱 *User:* $userName
⏰ *Time:* $timeString
🎯 *Problem:* ${template.problemDescription}
📍 *Current Location:* ${locationInfo.address}
🗺️ *Live GPS Location:* ${locationInfo.gpsLink}

⚡ *URGENT ACTION REQUIRED:*
${template.specialInstructions}

Please respond *immediately* to assist the user.

*Stay Alert. Stay Safe.*
*- TERAX AI Emergency System*''';
  }

  /// Generate Email message (clean text format for immediate action)
  EmailContent _generateEmailMessage(
      EmergencyTemplate template,
      LocationInfo locationInfo,
      String userName,
      String timeString,
      Map<String, dynamic>? context) {
    final subject = '🚨 EMERGENCY ALERT: ${template.category} - $userName';

    final body = '''🚨 EMERGENCY ALERT (from TERAX AI) 🚨

This is an automated emergency message sent by TERAX AI. The user is facing an emergency and requires immediate assistance.

${template.icon} ${template.category}

User: $userName
Time: $timeString
Problem: ${template.problemDescription}
Current Location: ${locationInfo.address}
Live GPS Location: ${locationInfo.gpsLink}

⚡ IMMEDIATE ACTION REQUIRED:
${template.specialInstructions}

${context != null ? _generateContextText(context) : ''}

Please respond immediately to assist the user.

Stay Alert. Stay Safe.
- TERAX AI Emergency System

This is an automated message. Please take immediate action.''';

    return EmailContent(subject: subject, htmlBody: body);
  }

  /// Generate additional context section for email (simple text format)
  String _generateContextText(Map<String, dynamic> context) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Additional Context:');

    if (context['confidence_score'] != null) {
      buffer.writeln('AI Confidence: ${context['confidence_score']}%');
    }
    if (context['threat_level'] != null) {
      buffer.writeln('Threat Level: ${context['threat_level']}');
    }
    if (context['voice_analysis'] != null) {
      buffer.writeln('Voice Analysis: ${context['voice_analysis']}');
    }
    if (context['behavioral_indicators'] != null) {
      buffer.writeln(
          'Behavioral Indicators: ${context['behavioral_indicators']}');
    }

    return buffer.toString();
  }

  /// Generate location information
  Future<LocationInfo> _generateLocationInfo(
      String? currentLocation, double? latitude, double? longitude) async {
    String address = currentLocation ?? 'Location not available';
    String coordinates = 'Not available';
    String gpsLink = 'Location not available';

    if (latitude != null && longitude != null) {
      coordinates = '$latitude, $longitude';
      gpsLink = 'https://www.google.com/maps?q=$latitude,$longitude';

      // If no address provided, try to get it from coordinates
      if (currentLocation == null || currentLocation.isEmpty) {
        address = 'GPS: $coordinates';
      }
    }

    return LocationInfo(
      address: address,
      coordinates: coordinates,
      gpsLink: gpsLink,
    );
  }

  /// Generate fallback message for errors
  EmergencyMessage _generateFallbackMessage(
      String emergencyType, String? location, String userName) {
    final template = EmergencyTemplate(
      category: 'Emergency Alert',
      icon: '🚨',
      problemDescription: 'Emergency situation detected',
      urgencyLevel: 'HIGH',
      specialInstructions: 'Please contact the user immediately',
    );

    final locationInfo = LocationInfo(
      address: location ?? 'Location not available',
      coordinates: 'Not available',
      gpsLink: 'Location not available',
    );

    final timestamp = DateTime.now();
    final timeString =
        '${timestamp.day}/${timestamp.month}/${timestamp.year} at ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';

    final fallbackMessage = '''🚨 EMERGENCY ALERT (TERAX AI) 🚨

User: $userName needs immediate help!
Time: $timeString
Location: ${locationInfo.address}

Please contact the user immediately.

- TERAX AI''';

    return EmergencyMessage(
      emergencyType: emergencyType,
      template: template,
      locationInfo: locationInfo,
      timestamp: timestamp,
      smsMessage: fallbackMessage,
      whatsappMessage: fallbackMessage,
      emailMessage: EmailContent(
        subject: '🚨 EMERGENCY ALERT - $userName',
        htmlBody: '<h1>Emergency Alert</h1><p>$fallbackMessage</p>',
      ),
      userName: userName,
    );
  }

  /// Send emergency message via multiple channels
  Future<MessageDeliveryResult> sendEmergencyMessage({
    required EmergencyMessage message,
    required List<String> phoneNumbers,
    required List<String> emailAddresses,
    bool sendSMS = true,
    bool sendWhatsApp = true,
    bool sendEmail = true,
  }) async {
    final results = <String, bool>{};
    final errors = <String, String>{};

    try {
      // Send SMS
      if (sendSMS && phoneNumbers.isNotEmpty) {
        for (final phone in phoneNumbers) {
          try {
            final success = await _sendSMS(phone, message.smsMessage);
            results['SMS_$phone'] = success;
          } catch (e) {
            errors['SMS_$phone'] = e.toString();
            results['SMS_$phone'] = false;
          }
        }
      }

      // Send WhatsApp
      if (sendWhatsApp && phoneNumbers.isNotEmpty) {
        for (final phone in phoneNumbers) {
          try {
            final success = await _sendWhatsApp(phone, message.whatsappMessage);
            results['WhatsApp_$phone'] = success;
          } catch (e) {
            errors['WhatsApp_$phone'] = e.toString();
            results['WhatsApp_$phone'] = false;
          }
        }
      }

      // Send Email
      if (sendEmail && emailAddresses.isNotEmpty) {
        for (final email in emailAddresses) {
          try {
            final success = await _sendEmail(email, message.emailMessage);
            results['Email_$email'] = success;
          } catch (e) {
            errors['Email_$email'] = e.toString();
            results['Email_$email'] = false;
          }
        }
      }

      return MessageDeliveryResult(
        success: results.values.any((success) => success),
        results: results,
        errors: errors,
        message: message,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error sending emergency message: $e');
      }
      return MessageDeliveryResult(
        success: false,
        results: {},
        errors: {'general': e.toString()},
        message: message,
      );
    }
  }

  /// Send SMS (implementation depends on SMS service provider)
  Future<bool> _sendSMS(String phoneNumber, String message) async {
    try {
      // For demo purposes, we'll use URL launcher to open SMS app
      final uri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending SMS: $e');
      }
      return false;
    }
  }

  /// Send WhatsApp message
  Future<bool> _sendWhatsApp(String phoneNumber, String message) async {
    try {
      // Clean phone number (remove non-digits)
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      final uri = Uri.parse(
          'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending WhatsApp: $e');
      }
      return false;
    }
  }

  /// Send Email (implementation depends on email service provider)
  Future<bool> _sendEmail(
      String emailAddress, EmailContent emailContent) async {
    try {
      final uri = Uri(
        scheme: 'mailto',
        path: emailAddress,
        queryParameters: {
          'subject': emailContent.subject,
          'body': emailContent.htmlBody
              .replaceAll(RegExp(r'<[^>]*>'), ''), // Strip HTML for mailto
        },
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending email: $e');
      }
      return false;
    }
  }

  /// Get available emergency templates
  Map<String, EmergencyTemplate> getAvailableTemplates() {
    return Map.from(_templates);
  }

  /// Get template by emergency type
  EmergencyTemplate? getTemplate(String emergencyType) {
    return _templates[emergencyType];
  }
}

// Data models
class EmergencyTemplate {
  final String category;
  final String icon;
  final String problemDescription;
  final String urgencyLevel;
  final String specialInstructions;

  // Fields from JSON for more detailed templates
  final String? smsTemplate;
  final String? whatsappTemplate;
  final String? emailSubject;
  final int? priority;
  final bool? autoCall911;

  const EmergencyTemplate({
    required this.category,
    required this.icon,
    required this.problemDescription,
    required this.urgencyLevel,
    required this.specialInstructions,
    this.smsTemplate,
    this.whatsappTemplate,
    this.emailSubject,
    this.priority,
    this.autoCall911,
  });

  factory EmergencyTemplate.fromJson(Map<String, dynamic> json) {
    return EmergencyTemplate(
      category: json['category'] ?? 'General Emergency',
      icon: json['icon'] ?? '🚨',
      problemDescription:
          json['problem_description'] ?? 'Emergency situation detected',
      urgencyLevel: json['urgency_level'] ?? 'HIGH',
      specialInstructions:
          json['special_instructions'] ?? 'Respond immediately',
      smsTemplate: json['sms_template'],
      whatsappTemplate: json['whatsapp_template'],
      emailSubject: json['email_subject'],
      priority: json['priority'],
      autoCall911: json['auto_call_911'],
    );
  }
}

class LocationInfo {
  final String address;
  final String coordinates;
  final String gpsLink;

  const LocationInfo({
    required this.address,
    required this.coordinates,
    required this.gpsLink,
  });
}

class EmailContent {
  final String subject;
  final String htmlBody;

  const EmailContent({
    required this.subject,
    required this.htmlBody,
  });
}

class EmergencyMessage {
  final String emergencyType;
  final EmergencyTemplate template;
  final LocationInfo locationInfo;
  final DateTime timestamp;
  final String smsMessage;
  final String whatsappMessage;
  final EmailContent emailMessage;
  final String userName;

  const EmergencyMessage({
    required this.emergencyType,
    required this.template,
    required this.locationInfo,
    required this.timestamp,
    required this.smsMessage,
    required this.whatsappMessage,
    required this.emailMessage,
    required this.userName,
  });
}

class MessageDeliveryResult {
  final bool success;
  final Map<String, bool> results;
  final Map<String, String> errors;
  final EmergencyMessage message;

  const MessageDeliveryResult({
    required this.success,
    required this.results,
    required this.errors,
    required this.message,
  });
}
