import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';

class EmergencyContactsService extends ChangeNotifier {
  static const String _contactsKey = 'emergency_contacts';
  static const String _activityLogsKey = 'activity_logs';

  List<EmergencyContact> _contacts = [];
  List<ActivityLog> _activityLogs = [];

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  List<ActivityLog> get activityLogs => List.unmodifiable(_activityLogs);

  EmergencyContact? get primaryContact =>
      _contacts.where((c) => c.isPrimary).isNotEmpty
          ? _contacts.firstWhere((c) => c.isPrimary)
          : null;

  // Initialize service
  Future<void> initialize() async {
    await _loadContacts();
    await _loadActivityLogs();
  }

  // Load contacts from storage
  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString(_contactsKey);

      if (contactsJson != null) {
        final List<dynamic> contactsList = json.decode(contactsJson);
        _contacts = contactsList
            .map((json) => EmergencyContact.fromJson(json))
            .toList();

        // Sort by priority
        _contacts.sort((a, b) => a.priorityNumber.compareTo(b.priorityNumber));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading contacts: $e');
    }
  }

  // Save contacts to storage
  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = json.encode(
        _contacts.map((contact) => contact.toJson()).toList(),
      );
      await prefs.setString(_contactsKey, contactsJson);
    } catch (e) {
      debugPrint('Error saving contacts: $e');
    }
  }

  // Load activity logs
  Future<void> _loadActivityLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString(_activityLogsKey);

      if (logsJson != null) {
        final List<dynamic> logsList = json.decode(logsJson);
        _activityLogs =
            logsList.map((json) => ActivityLog.fromJson(json)).toList();

        // Sort by timestamp (newest first)
        _activityLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading activity logs: $e');
    }
  }

  // Save activity logs
  Future<void> _saveActivityLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = json.encode(
        _activityLogs.map((log) => log.toJson()).toList(),
      );
      await prefs.setString(_activityLogsKey, logsJson);
    } catch (e) {
      debugPrint('Error saving activity logs: $e');
    }
  }

  // Add new contact
  Future<bool> addContact(EmergencyContact contact) async {
    try {
      // If setting as primary, remove primary from others
      if (contact.isPrimary) {
        _contacts = _contacts.map((c) => c.copyWith(isPrimary: false)).toList();
      }

      _contacts.add(contact);
      _contacts.sort((a, b) => a.priorityNumber.compareTo(b.priorityNumber));

      await _saveContacts();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding contact: $e');
      return false;
    }
  }

  // Update contact
  Future<bool> updateContact(EmergencyContact updatedContact) async {
    try {
      final index = _contacts.indexWhere((c) => c.id == updatedContact.id);
      if (index == -1) return false;

      // If setting as primary, remove primary from others
      if (updatedContact.isPrimary) {
        _contacts = _contacts
            .map((c) =>
                c.id == updatedContact.id ? c : c.copyWith(isPrimary: false))
            .toList();
      }

      _contacts[index] = updatedContact;
      _contacts.sort((a, b) => a.priorityNumber.compareTo(b.priorityNumber));

      await _saveContacts();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating contact: $e');
      return false;
    }
  }

  // Delete contact
  Future<bool> deleteContact(String contactId) async {
    try {
      _contacts.removeWhere((c) => c.id == contactId);
      await _saveContacts();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting contact: $e');
      return false;
    }
  }

  // Import from device contacts
  Future<List<Contact>> getDeviceContacts() async {
    try {
      if (await FlutterContacts.requestPermission()) {
        final contacts = await FlutterContacts.getContacts(
          withProperties: true,
        );
        return contacts
            .where((c) => c.displayName.isNotEmpty && c.phones.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting device contacts: $e');
      return [];
    }
  }

  // Make phone call
  Future<void> makeCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);

      // Log the call
      await _logActivity(
        'Phone Call',
        ActivityStatus.active,
        'Emergency call made to $phoneNumber',
      );
    }
  }

  // Send SMS
  Future<void> sendSMS(String phoneNumber) async {
    final uri = Uri.parse('sms:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);

      // Log the SMS
      await _logActivity(
        'SMS Alert',
        ActivityStatus.active,
        'Emergency SMS sent to $phoneNumber',
      );
    }
  }

  // Log activity
  Future<void> _logActivity(
    String incidentType,
    ActivityStatus status,
    String description,
  ) async {
    // Get actual location from LocationProvider if available
    String location = 'Current location';
    try {
      // Note: This service doesn't have direct access to providers
      // In a real implementation, you would pass the location from the calling context
      // or inject a location service. For now, we'll keep the placeholder.
      location = 'Current location';
    } catch (e) {
      location = 'Location unavailable';
    }

    final log = ActivityLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      incidentType: incidentType,
      status: status,
      description: description,
      timestamp: DateTime.now(),
      location: location,
      contactsNotified: _contacts.length,
    );

    _activityLogs.insert(0, log);
    await _saveActivityLogs();
    notifyListeners();
  }

  // Trigger emergency alert
  Future<void> triggerEmergencyAlert() async {
    // Send alerts to all contacts
    for (final contact in _contacts) {
      if (contact.notificationMethods.contains(NotificationMethod.call)) {
        await makeCall(contact.phoneNumber);
      }
      if (contact.notificationMethods.contains(NotificationMethod.sms)) {
        await sendSMS(contact.phoneNumber);
      }
    }

    // Log the emergency trigger
    await _logActivity(
      'Button Trigger',
      ActivityStatus.active,
      'Emergency alert triggered from Terax AI Safety App',
    );
  }

  // Get filtered activity logs
  List<ActivityLog> getFilteredLogs(String filter) {
    switch (filter.toLowerCase()) {
      case 'active':
        return _activityLogs
            .where((log) => log.status == ActivityStatus.active)
            .toList();
      case 'resolved':
        return _activityLogs
            .where((log) => log.status == ActivityStatus.resolved)
            .toList();
      case 'false':
        return _activityLogs
            .where((log) => log.status == ActivityStatus.falseAlarm)
            .toList();
      default:
        return _activityLogs;
    }
  }

  // Update activity log status
  Future<void> updateLogStatus(String logId, ActivityStatus newStatus) async {
    final index = _activityLogs.indexWhere((log) => log.id == logId);
    if (index != -1) {
      _activityLogs[index] = ActivityLog(
        id: _activityLogs[index].id,
        incidentType: _activityLogs[index].incidentType,
        status: newStatus,
        description: _activityLogs[index].description,
        timestamp: _activityLogs[index].timestamp,
        location: _activityLogs[index].location,
        contactsNotified: _activityLogs[index].contactsNotified,
      );

      await _saveActivityLogs();
      notifyListeners();
    }
  }
}

// Activity Log Model
enum ActivityStatus { active, resolved, falseAlarm }

class ActivityLog {
  final String id;
  final String incidentType;
  final ActivityStatus status;
  final String description;
  final DateTime timestamp;
  final String? location;
  final int? contactsNotified;

  ActivityLog({
    required this.id,
    required this.incidentType,
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
    this.contactsNotified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incidentType': incidentType,
      'status': status.toString().split('.').last,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'contactsNotified': contactsNotified,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'],
      incidentType: json['incidentType'],
      status: ActivityStatus.values.firstWhere(
        (e) => e.toString() == 'ActivityStatus.${json['status']}',
        orElse: () => ActivityStatus.active,
      ),
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
      contactsNotified: json['contactsNotified'],
    );
  }

  String get statusText {
    switch (status) {
      case ActivityStatus.active:
        return 'Active';
      case ActivityStatus.resolved:
        return 'Resolved';
      case ActivityStatus.falseAlarm:
        return 'False';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
