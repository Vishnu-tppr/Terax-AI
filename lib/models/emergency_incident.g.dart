// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_incident.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyIncident _$EmergencyIncidentFromJson(Map<String, dynamic> json) =>
    EmergencyIncident(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      triggerType: $enumDecode(_$TriggerTypeEnumMap, json['triggerType']),
      status: $enumDecode(_$IncidentStatusEnumMap, json['status']),
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      userName: json['userName'] as String?,
      emergencyContacts: (json['emergencyContacts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      emailContacts: (json['emailContacts'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      recordingUrl: json['recordingUrl'] as String?,
      aiAnalysis: json['aiAnalysis'] as String?,
      description: json['description'] as String?,
      triggeredAt: json['triggeredAt'] == null
          ? null
          : DateTime.parse(json['triggeredAt'] as String),
      contactIds: (json['contactIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      contactsNotified: (json['contactsNotified'] as num?)?.toInt(),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EmergencyIncidentToJson(EmergencyIncident instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'triggerType': _$TriggerTypeEnumMap[instance.triggerType]!,
      'status': _$IncidentStatusEnumMap[instance.status]!,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'userName': instance.userName,
      'emergencyContacts': instance.emergencyContacts,
      'emailContacts': instance.emailContacts,
      'recordingUrl': instance.recordingUrl,
      'aiAnalysis': instance.aiAnalysis,
      'description': instance.description,
      'triggeredAt': instance.triggeredAt?.toIso8601String(),
      'contactIds': instance.contactIds,
      'contactsNotified': instance.contactsNotified,
      'resolvedAt': instance.resolvedAt?.toIso8601String(),
      'notes': instance.notes,
    };

const _$TriggerTypeEnumMap = {
  TriggerType.button: 'button',
  TriggerType.voice: 'voice',
  TriggerType.gesture: 'gesture',
  TriggerType.facialDistress: 'facial_distress',
  TriggerType.safeZone: 'safe_zone',
  TriggerType.manual: 'manual',
};

const _$IncidentStatusEnumMap = {
  IncidentStatus.active: 'active',
  IncidentStatus.resolved: 'resolved',
  IncidentStatus.failed: 'failed',
};
