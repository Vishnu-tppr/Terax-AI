import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/activity_log.dart';
import '../models/activity_type.dart';

class ActivityLoggingService {
  static const String _storageKey = 'activity_logs';
  final SharedPreferences _prefs;

  ActivityLoggingService(this._prefs);

  Future<void> logActivity({
    required String contactId,
    required String description,
    required ActivityType type,
  }) async {
    try {
      final logs = await getActivityLogs();
      final newLog = ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        description: description,
        contactId: contactId,
        type: type,
      );

      logs.insert(0, newLog); // Add new log at the beginning
      await _saveLogs(logs);
    } catch (e) {
      debugPrint('Error logging activity: $e');
      // You might want to handle this error differently
    }
  }

  Future<List<ActivityLog>> getActivityLogs() async {
    try {
      final String? logsJson = _prefs.getString(_storageKey);
      if (logsJson == null) return [];

      final List<dynamic> decoded = jsonDecode(logsJson);
      return decoded.map((json) => ActivityLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting activity logs: $e');
      return [];
    }
  }

  Future<List<ActivityLog>> getLogsForContact(String contactId) async {
    final logs = await getActivityLogs();
    return logs.where((log) => log.contactId == contactId).toList();
  }

  Future<void> _saveLogs(List<ActivityLog> logs) async {
    final List<Map<String, dynamic>> jsonList =
        logs.map((log) => log.toJson()).toList();
    await _prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  Future<void> clearLogs() async {
    await _prefs.remove(_storageKey);
  }
}
