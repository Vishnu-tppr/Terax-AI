import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emergency_incident.dart';
import '../models/emergency_contact.dart';
import '../models/user_settings.dart';
import 'real_sms_service.dart';
import 'real_call_service.dart';
import 'real_location_service.dart';

enum EmergencyLevel {
  none,
  low,
  medium,
  high,
  critical,
}

class EmergencyService {
  static EmergencyService? _instance;
  static EmergencyService get instance => _instance ??= EmergencyService._();

  EmergencyService._();

  bool _isEmergencyActive = false;
  final bool _isInitialized = true; // Service is initialized by default
  Timer? _countdownTimer;
  EmergencyIncident? _currentIncident;
  final EmergencyLevel _currentLevel = EmergencyLevel.none;

  bool get isEmergencyActive => _isEmergencyActive;
  EmergencyIncident? get currentIncident => _currentIncident;

  // Stream controllers for real-time updates
  final StreamController<bool> _emergencyStatusController =
      StreamController<bool>.broadcast();
  final StreamController<EmergencyIncident> _incidentController =
      StreamController<EmergencyIncident>.broadcast();

  Stream<bool> get emergencyStatusStream => _emergencyStatusController.stream;
  Stream<EmergencyIncident> get incidentStream => _incidentController.stream;

  Future<void> triggerEmergency({
    required TriggerType triggerType,
    required UserSettings settings,
    required List<EmergencyContact> contacts,
    String? location,
  }) async {
    if (_isEmergencyActive) return;

    _isEmergencyActive = true;
    _emergencyStatusController.add(true);

    // Create emergency incident
    _currentIncident = EmergencyIncident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(), // Added timestamp
      triggerType: triggerType,
      status: IncidentStatus.active,
      description: 'Emergency alert triggered from Terax AI Safety App',
      triggeredAt: DateTime.now(),
      location: location ?? 'Current location',
      contactIds: contacts.map((c) => c.id).toList(),
      contactsNotified: 0,
    );

    _incidentController.add(_currentIncident!);

    // Start countdown timer if enabled
    if (settings.autoTriggerIfNotCancelled) {
      _startCountdownTimer(settings.countdownTimer);
    }

    // Trigger haptic feedback (removed for compatibility)
    // In a real app, you would use HapticFeedback.mediumImpact()

    // Notify emergency contacts
    await _notifyContacts(contacts, settings);

    // Auto-call emergency services if enabled
    if (settings.autoCallEmergencyServices) {
      await _callEmergencyServices();
    }
  }

  Future<void> cancelEmergency() async {
    if (!_isEmergencyActive) return;

    _isEmergencyActive = false;
    _countdownTimer?.cancel();

    if (_currentIncident != null) {
      _currentIncident = _currentIncident!.copyWith(
        status: IncidentStatus.resolved,
        resolvedAt: DateTime.now(),
      );
      _incidentController.add(_currentIncident!);
    }

    _emergencyStatusController.add(false);
  }

  Future<void> resolveEmergency() async {
    if (!_isEmergencyActive) return;

    _isEmergencyActive = false;
    _countdownTimer?.cancel();

    if (_currentIncident != null) {
      _currentIncident = _currentIncident!.copyWith(
        status: IncidentStatus.resolved,
        resolvedAt: DateTime.now(),
      );
      _incidentController.add(_currentIncident!);
    }

    _emergencyStatusController.add(false);
  }

  void _startCountdownTimer(int seconds) {
    _countdownTimer = Timer(Duration(seconds: seconds), () {
      if (_isEmergencyActive) {
        // Auto-trigger if not cancelled
        _autoTriggerEmergency();
      }
    });
  }

  Future<void> _autoTriggerEmergency() async {
    // In a real app, this would trigger additional emergency protocols
    // For demo purposes, we'll just log it
    debugPrint('Auto-triggering emergency after countdown');
  }

  Future<void> _notifyContacts(
    List<EmergencyContact> contacts,
    UserSettings settings,
  ) async {
    // Sort contacts by priority
    contacts.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    for (final contact in contacts) {
      try {
        if (contact.notificationMethods.contains(NotificationMethod.sms)) {
          await _sendSMS(contact);
        }

        if (contact.notificationMethods.contains(NotificationMethod.call)) {
          await _makeCall(contact);
        }

        if (contact.notificationMethods.contains(NotificationMethod.email)) {
          await _sendEmail(contact);
        }

        // Update incident with notification count
        if (_currentIncident != null) {
          _currentIncident = _currentIncident!.copyWith(
            contactsNotified: (_currentIncident!.contactsNotified ?? 0) + 1,
          );
          _incidentController.add(_currentIncident!);
        }
      } catch (e) {
        debugPrint('Failed to notify contact ${contact.name}: $e');
      }
    }
  }

  Future<void> _sendSMS(EmergencyContact contact) async {
    try {
      // Get current location for the message
      final locationService = RealLocationService.instance;
      final location = locationService.getEmergencyLocationString();

      // Send SMS using the real SMS service
      final result = await RealSmsService.instance.sendEmergencySms(
        contacts: [contact],
        situation: 'Emergency alert triggered',
        location: location,
        userName: 'User', // This should come from user settings
      );

      if (result.success) {
        debugPrint(
            'Emergency SMS sent to ${contact.name} at ${contact.phoneNumber}');
      } else {
        debugPrint('Failed to send SMS to ${contact.name}: ${result.message}');
        throw Exception(result.message);
      }
    } catch (e) {
      debugPrint('Failed to send SMS to ${contact.name}: $e');
      rethrow;
    }
  }

  Future<void> _makeCall(EmergencyContact contact) async {
    try {
      // Use the real call service
      final result = await RealCallService.instance.callContact(contact);

      if (result.success) {
        debugPrint(
            'Emergency call initiated to ${contact.name} at ${contact.phoneNumber}');
      } else {
        debugPrint(
            'Cannot make call to ${contact.name} at ${contact.phoneNumber}');
        throw Exception(result.message);
      }
    } catch (e) {
      debugPrint('Failed to make call to ${contact.name}: $e');
      rethrow;
    }
  }

  Future<void> _sendEmail(EmergencyContact contact) async {
    if (contact.email == null) return;

    // In a real app, this would use email service
    debugPrint('Sending email to ${contact.name} at ${contact.email}');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate delay
  }

  Future<void> _callEmergencyServices() async {
    // Call emergency services using RealCallService
    final result = await RealCallService.instance.callEmergencyServices();
    if (result.success) {
      debugPrint('Emergency services called successfully: ${result.message}');
    } else {
      debugPrint('Failed to call emergency services: ${result.message}');
      // Optionally, log this failure or show a user message
    }
  }

  Future<void> testEmergencyAlert({
    required List<EmergencyContact> contacts,
    required UserSettings settings,
  }) async {
    // Create a test incident
    final testIncident = EmergencyIncident(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(), // Added timestamp
      triggerType: TriggerType.manual,
      status: IncidentStatus.active,
      description: 'Test emergency alert',
      triggeredAt: DateTime.now(),
      location: 'Test location',
      contactIds: contacts.map((c) => c.id).toList(),
      contactsNotified: 0,
      notes: 'This is a test alert',
    );

    // Notify contacts (but don't actually call emergency services)
    for (final contact in contacts) {
      try {
        if (contact.notificationMethods.contains(NotificationMethod.sms)) {
          debugPrint('TEST: Would send SMS to ${contact.name}');
        }

        if (contact.notificationMethods.contains(NotificationMethod.email)) {
          debugPrint('TEST: Would send email to ${contact.name}');
        }
      } catch (e) {
        debugPrint('Test notification failed for ${contact.name}: $e');
      }
    }

    // Resolve test incident after a short delay
    await Future.delayed(const Duration(seconds: 3));
    final resolvedIncident = testIncident.copyWith(
      status: IncidentStatus.resolved,
      resolvedAt: DateTime.now(),
    );

    _incidentController.add(resolvedIncident);
  }

  /// Log an incident for tracking and analysis
  Future<void> logIncident(
    String incidentType, {
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create an EmergencyIncident object for logging
      final incident = EmergencyIncident(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        triggerType: TriggerType.manual, // Assuming manual logging
        status: IncidentStatus.resolved, // Or a specific 'logged' status if available
        description: 'Incident logged: $incidentType',
        triggeredAt: DateTime.now(),
        notes: metadata?.toString() ?? 'No metadata',
      );

      // Add to incidents provider (or a dedicated logging service)
      // For now, we'll just print to debug console
      if (kDebugMode) {
        print('Incident logged: ${incident.description}');
      }
      // In a real app, you would save this incident:
      // final incidentsProvider = Provider.of<IncidentsProvider>(context, listen: false);
      // incidentsProvider.addIncident(incident);

    } catch (e) {
      if (kDebugMode) {
        print('Error logging incident: $e');
      }
    }
  }

  /// Get emergency service status
  bool get isInitialized => _isInitialized;

  /// Get current emergency level
  EmergencyLevel get currentLevel => _currentLevel;

  void dispose() {
    _countdownTimer?.cancel();
    _emergencyStatusController.close();
    _incidentController.close();
  }
}
