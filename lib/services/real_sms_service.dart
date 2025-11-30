import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emergency_contact.dart';
import 'package:terax_ai_app/services/ai_service.dart';

class RealSmsService {
  static RealSmsService? _instance;
  static RealSmsService get instance {
    _instance ??= RealSmsService._();
    return _instance!;
  }

  RealSmsService._();

  /// Send emergency SMS to multiple contacts using Twilio API
  Future<SmsResult> sendEmergencySms({
    required List<EmergencyContact> contacts,
    required String situation,
    required String location,
    required String userName,
  }) async {
    try {
      // Generate AI-powered emergency message
      String emergencyMessage;
      try {
        emergencyMessage = await AIService.instance.generateEmergencyMessage(
          situation: situation,
          location: location,
          userName: userName,
        );
      } catch (e) {
        // Fallback message if AI fails
        emergencyMessage =
            'EMERGENCY: $userName needs immediate help. Situation: $situation. Location: $location. Please respond ASAP.';
      }

      // Add timestamp and app signature
      final timestamp = DateTime.now().toString().substring(0, 16);
      final fullMessage =
          '$emergencyMessage\n\nTime: $timestamp\nSent via Terax AI Safety App';

      // Filter contacts that accept SMS notifications
      final smsContacts = contacts
          .where((contact) => contact.notificationMethods.contains(NotificationMethod.sms))
          .toList();

      if (smsContacts.isEmpty) {
        return SmsResult(
          success: false,
          message: 'No contacts configured for SMS notifications',
          sentCount: 0,
          failedContacts: [],
        );
      }

      // Sort by priority (Priority.one = highest)
      smsContacts.sort((a, b) => a.priority.compareTo(b.priority));

      // Send SMS via Twilio API
      List<String> failedContacts = [];
      int sentCount = 0;

      for (final contact in smsContacts) {
        try {
          final result = await _sendSmsViaTwilio(
            phoneNumber: contact.phoneNumber,
            message: fullMessage,
          );

          if (result) {
            sentCount++;
            if (kDebugMode) {
              print('SMS sent successfully to ${contact.name}: ${contact.phoneNumber}');
            }
          } else {
            failedContacts.add(contact.name);
            if (kDebugMode) {
              print('SMS failed to ${contact.name}: ${contact.phoneNumber}');
            }
          }

          // Small delay between sends to respect API rate limits
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          if (kDebugMode) {
            print('SMS error for ${contact.name}: $e');
          }
          failedContacts.add(contact.name);
        }
      }

      return SmsResult(
        success: sentCount > 0,
        message: sentCount > 0
            ? 'Emergency SMS sent to $sentCount contact(s)'
            : 'Failed to send SMS to any contacts',
        sentCount: sentCount,
        failedContacts: failedContacts,
      );
    } catch (e) {
      if (kDebugMode) {
        print('SMS service error: $e');
      }
      return SmsResult(
        success: false,
        message: 'SMS service error: $e',
        sentCount: 0,
        failedContacts: contacts.map((c) => c.name).toList(),
      );
    }
  }

  /// Send follow-up SMS (e.g., "I'm safe now") using Twilio
  Future<SmsResult> sendFollowUpSms({
    required List<EmergencyContact> contacts,
    required String message,
    required String userName,
  }) async {
    try {
      final timestamp = DateTime.now().toString().substring(0, 16);
      final fullMessage =
          'UPDATE from $userName: $message\n\nTime: $timestamp\nSent via Terax AI Safety App';

      final smsContacts = contacts
          .where((contact) => contact.notificationMethods.contains(NotificationMethod.sms))
          .toList();

      if (smsContacts.isEmpty) {
        return SmsResult(
          success: false,
          message: 'No contacts configured for SMS notifications',
          sentCount: 0,
          failedContacts: [],
        );
      }

      List<String> failedContacts = [];
      int sentCount = 0;

      for (final contact in smsContacts) {
        try {
          final result = await _sendSmsViaTwilio(
            phoneNumber: contact.phoneNumber,
            message: fullMessage,
          );

          if (result) {
            sentCount++;
            if (kDebugMode) {
              print('Follow-up SMS sent to ${contact.name}');
            }
          } else {
            failedContacts.add(contact.name);
          }

          // Rate limiting delay
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          if (kDebugMode) {
            print('Follow-up SMS error for ${contact.name}: $e');
          }
          failedContacts.add(contact.name);
        }
      }

      return SmsResult(
        success: sentCount > 0,
        message: sentCount > 0
            ? 'Follow-up SMS sent to $sentCount contact(s)'
            : 'Failed to send follow-up SMS to any contacts',
        sentCount: sentCount,
        failedContacts: failedContacts,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Follow-up SMS service error: $e');
      }
      return SmsResult(
        success: false,
        message: 'Follow-up SMS error: $e',
        sentCount: 0,
        failedContacts: contacts.map((c) => c.name).toList(),
      );
    }
  }

  /// Send SMS via Twilio API
  Future<bool> _sendSmsViaTwilio({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Get Twilio credentials from environment
      final accountSid = dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
      final authToken = dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
      final fromNumber = dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';

      if (accountSid.isEmpty || authToken.isEmpty || fromNumber.isEmpty) {
        if (kDebugMode) {
          print('Twilio credentials not configured. Please set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_PHONE_NUMBER in .env');
        }
        return false;
      }

      final url = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json');

      // Twilio API credentials for basic authentication
      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': fromNumber,
          'To': phoneNumber,
          'Body': message,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (kDebugMode) {
          print('Twilio SMS sent successfully to $phoneNumber');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('Twilio SMS failed: ${response.statusCode} - ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Twilio SMS error: $e');
      }
      return false;
    }
  }

  /// Get SMS delivery status (useful for emergency tracking)
  Future<Map<String, dynamic>?> getSmsStatus(String messageSid) async {
    try {
      final accountSid = dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
      final authToken = dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';

      if (accountSid.isEmpty || authToken.isEmpty) {
        return null;
      }

      final url = Uri.parse('https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages/$messageSid.json');

      final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting SMS status: $e');
      }
      return null;
    }
  }

  /// Check if SMS service is properly configured
  bool isSmsConfigured() {
    final accountSid = dotenv.env['TWILIO_ACCOUNT_SID'] ?? '';
    final authToken = dotenv.env['TWILIO_AUTH_TOKEN'] ?? '';
    final fromNumber = dotenv.env['TWILIO_PHONE_NUMBER'] ?? '';

    return accountSid.isNotEmpty && authToken.isNotEmpty && fromNumber.isNotEmpty;
  }

  /// Get SMS configuration status for UI display
  String getSmsConfigurationStatus() {
    if (!isSmsConfigured()) {
      return 'Twilio SMS not configured. Please set environment variables.';
    }
    return 'Twilio SMS service is configured and ready.';
  }

  /// Legacy method for backward compatibility
  Future<void> sendSmsToContacts(List<EmergencyContact> contacts,
      {int maxPriority = 2}) async {
    final smsContacts = contacts
        .where((c) => c.phoneNumber.isNotEmpty && c.priorityNumber <= maxPriority)
        .toList();
    smsContacts.sort((a, b) => a.priority.compareTo(b.priority));

    for (final contact in smsContacts) {
      await _sendSmsViaTwilio(
        phoneNumber: contact.phoneNumber,
        message: 'Emergency alert from TERAX AI',
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}

class SmsResult {
  final bool success;
  final String message;
  final int sentCount;
  final List<String> failedContacts;

  SmsResult({
    required this.success,
    required this.message,
    required this.sentCount,
    required this.failedContacts,
  });

  @override
  String toString() {
    return 'SmsResult(success: $success, message: $message, sentCount: $sentCount, failedContacts: $failedContacts)';
  }
}
