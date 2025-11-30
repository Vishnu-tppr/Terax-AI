import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';

class RealCallService {
  static RealCallService? _instance;
  static RealCallService get instance {
    _instance ??= RealCallService._();
    return _instance!;
  }

  RealCallService._();

  /// Make emergency call to the highest priority contact
  Future<CallResult> makeEmergencyCall(List<EmergencyContact> contacts) async {
    try {
      // Check phone permission
      final permission = await Permission.phone.request();
      if (permission != PermissionStatus.granted) {
        return CallResult(
          success: false,
          message: 'Phone permission denied',
          contactCalled: null,
        );
      }

      // Filter contacts that accept call notifications
      final callContacts = contacts
          .where((contact) =>
              contact.notificationMethods.contains(NotificationMethod.call))
          .toList();

      if (callContacts.isEmpty) {
        return CallResult(
          success: false,
          message: 'No contacts configured for phone calls',
          contactCalled: null,
        );
      }

      // Sort by priority (Priority.one = highest priority)
      callContacts.sort((a, b) => a.priority.compareTo(b.priority));

      // Try to call the highest priority contact first
      final primaryContact = callContacts.first;

      final success = await _makeCall(primaryContact.phoneNumber);

      if (success) {
        return CallResult(
          success: true,
          message: 'Emergency call initiated to ${primaryContact.name}',
          contactCalled: primaryContact,
        );
      } else {
        return CallResult(
          success: false,
          message: 'Failed to initiate call to ${primaryContact.name}',
          contactCalled: primaryContact,
        );
      }
    } catch (e) {
      return CallResult(
        success: false,
        message: 'Call service error: $e',
        contactCalled: null,
      );
    }
  }

  /// Make call to a specific contact
  Future<CallResult> callContact(EmergencyContact contact) async {
    try {
      final permission = await Permission.phone.request();
      if (permission != PermissionStatus.granted) {
        return CallResult(
          success: false,
          message: 'Phone permission denied',
          contactCalled: contact,
        );
      }

      final success = await _makeCall(contact.phoneNumber);

      if (success) {
        return CallResult(
          success: true,
          message: 'Call initiated to ${contact.name}',
          contactCalled: contact,
        );
      } else {
        return CallResult(
          success: false,
          message: 'Failed to initiate call to ${contact.name}',
          contactCalled: contact,
        );
      }
    } catch (e) {
      return CallResult(
        success: false,
        message: 'Call error: $e',
        contactCalled: contact,
      );
    }
  }

  /// Call emergency services (911, 112, etc.)
  Future<CallResult> callEmergencyServices(
      {String emergencyNumber = '911'}) async {
    try {
      final permission = await Permission.phone.request();
      if (permission != PermissionStatus.granted) {
        return CallResult(
          success: false,
          message: 'Phone permission denied for emergency call',
          contactCalled: null,
        );
      }

      final success = await _makeCall(emergencyNumber);

      if (success) {
        return CallResult(
          success: true,
          message: 'Emergency services call initiated ($emergencyNumber)',
          contactCalled: null,
        );
      } else {
        return CallResult(
          success: false,
          message: 'Failed to call emergency services ($emergencyNumber)',
          contactCalled: null,
        );
      }
    } catch (e) {
      return CallResult(
        success: false,
        message: 'Emergency call error: $e',
        contactCalled: null,
      );
    }
  }

  /// Make sequential calls to multiple contacts
  Future<List<CallResult>> makeSequentialCalls(
    List<EmergencyContact> contacts, {
    Duration delayBetweenCalls = const Duration(seconds: 2),
  }) async {
    List<CallResult> results = [];

    // Filter and sort contacts
    final callContacts = contacts
        .where((contact) =>
            contact.notificationMethods.contains(NotificationMethod.call))
        .toList();

    callContacts.sort((a, b) => a.priority.compareTo(b.priority));

    for (int i = 0; i < callContacts.length; i++) {
      final contact = callContacts[i];
      final result = await callContact(contact);
      results.add(result);

      // Add delay between calls (except for the last one)
      if (i < callContacts.length - 1) {
        await Future.delayed(delayBetweenCalls);
      }
    }

    return results;
  }

  /// Internal method to make the actual phone call
  Future<bool> _makeCall(String phoneNumber) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);

      if (await canLaunchUrl(phoneUri)) {
        final launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );

        return launched;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Check if phone permission is granted
  Future<bool> hasPhonePermission() async {
    final status = await Permission.phone.status;
    return status == PermissionStatus.granted;
  }

  /// Request phone permission
  Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status == PermissionStatus.granted;
  }

  /// Format phone number for display
  String formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    } else if (cleaned.length == 11 && cleaned.startsWith('1')) {
      return '+1 (${cleaned.substring(1, 4)}) ${cleaned.substring(4, 7)}-${cleaned.substring(7)}';
    } else {
      return phoneNumber; // Return original if format is unknown
    }
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Basic validation: should have at least 10 digits
    final digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length >= 10;
  }

  Future<void> placeCalls(List<EmergencyContact> contacts,
      {int maxPriority = 2}) async {
    final callContacts = contacts
        .where((c) => c.phoneNumber.isNotEmpty && c.priorityNumber <= maxPriority)
        .toList();
    callContacts.sort((a, b) => a.priority.compareTo(b.priority));
    for (final _ in callContacts) {
      // Simulate call initiation
      // In emulator we cannot actually place calls; integrate url_launcher in UI instead
      // This method can log or call a backend
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}

class CallResult {
  final bool success;
  final String message;
  final EmergencyContact? contactCalled;

  CallResult({
    required this.success,
    required this.message,
    required this.contactCalled,
  });

  @override
  String toString() {
    return 'CallResult(success: $success, message: $message, contact: ${contactCalled?.name})';
  }
}