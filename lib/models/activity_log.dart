import 'activity_type.dart';

class ActivityLog {
  final String id;
  final String contactId;
  final ActivityType type;
  final DateTime timestamp;
  final String description;

  ActivityLog({
    required this.id,
    required this.contactId,
    required this.type,
    required this.timestamp,
    required this.description,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      contactId: json['contactId']?.toString() ?? '',
      type: ActivityType.values.firstWhere(
          (e) => e.toString() == json['type'].toString(),
          orElse: () => ActivityType.other),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }
}
