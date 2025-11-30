import 'package:json_annotation/json_annotation.dart';

part 'emergency_incident.g.dart';

enum TriggerType {
  @JsonValue('button')
  button,
  @JsonValue('voice')
  voice,
  @JsonValue('gesture')
  gesture,
  @JsonValue('facial_distress')
  facialDistress,
  @JsonValue('safe_zone')
  safeZone,
  @JsonValue('manual')
  manual,
}

enum IncidentStatus {
  @JsonValue('active')
  active,
  @JsonValue('resolved')
  resolved,
  @JsonValue('failed')
  failed,
}

@JsonSerializable()
class EmergencyIncident {
  final String id;
  final DateTime timestamp;
  final TriggerType triggerType;
  final IncidentStatus status;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? userName;
  final List<String>? emergencyContacts;
  final List<String>? emailContacts;
  final String? recordingUrl;
  final String? aiAnalysis;
  final String? description;
  final DateTime? triggeredAt;
  final List<String>? contactIds;
  final int? contactsNotified;
  final DateTime? resolvedAt;
  final String? notes;

  EmergencyIncident({
    required this.id,
    required this.timestamp,
    required this.triggerType,
    required this.status,
    this.location,
    this.latitude,
    this.longitude,
    this.userName,
    this.emergencyContacts,
    this.emailContacts,
    this.recordingUrl,
    this.aiAnalysis,
    this.description,
    this.triggeredAt,
    this.contactIds,
    this.contactsNotified,
    this.resolvedAt,
    this.notes,
  });

  factory EmergencyIncident.fromJson(Map<String, dynamic> json) =>
      _$EmergencyIncidentFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyIncidentToJson(this);



  String get triggerTypeText {
    switch (triggerType) {
      case TriggerType.button:
        return 'Button Pressed';
      case TriggerType.voice:
        return 'Voice Command';
      case TriggerType.gesture:
        return 'Gesture Detected';
      case TriggerType.facialDistress:
        return 'Facial Distress';
      case TriggerType.safeZone:
        return 'Safe Zone Exit';
      case TriggerType.manual:
        return 'Manual Trigger';
      default:
        return 'Unknown';
    }
  }

  String get statusText {
    switch (status) {
      case IncidentStatus.active:
        return 'Active';
      case IncidentStatus.resolved:
        return 'Resolved';
      case IncidentStatus.failed:
        return 'Failed';
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final referenceTime = triggeredAt ?? timestamp;
    final diff = now.difference(referenceTime);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  EmergencyIncident copyWith({
    String? id,
    DateTime? timestamp,
    TriggerType? triggerType,
    IncidentStatus? status,
    String? location,
    double? latitude,
    double? longitude,
    String? userName,
    List<String>? emergencyContacts,
    List<String>? emailContacts,
    String? recordingUrl,
    String? aiAnalysis,
    String? description,
    DateTime? triggeredAt,
    List<String>? contactIds,
    int? contactsNotified,
    DateTime? resolvedAt,
    String? notes,
  }) {
    return EmergencyIncident(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      triggerType: triggerType ?? this.triggerType,
      status: status ?? this.status,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userName: userName ?? this.userName,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      emailContacts: emailContacts ?? this.emailContacts,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      description: description ?? this.description,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      contactIds: contactIds ?? this.contactIds,
      contactsNotified: contactsNotified ?? this.contactsNotified,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'EmergencyIncident{id: $id, status: $status, triggeredAt: $triggeredAt}';
  }
}
