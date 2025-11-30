// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationAlert _$LocationAlertFromJson(Map<String, dynamic> json) =>
    LocationAlert(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$GeofenceTypeEnumMap, json['type']),
      status:
          $enumDecodeNullable(_$LocationAlertStatusEnumMap, json['status']) ??
              LocationAlertStatus.active,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: (json['radius'] as num).toDouble(),
      polygon: (json['polygon'] as List<dynamic>?)
          ?.map((e) => (e as Map<String, dynamic>).map(
                (k, e) => MapEntry(k, (e as num).toDouble()),
              ))
          .toList(),
      address: json['address'] as String?,
      triggers: (json['triggers'] as List<dynamic>)
          .map((e) => $enumDecode(_$AlertTriggerEnumMap, e))
          .toList(),
      speedThreshold: (json['speedThreshold'] as num?)?.toDouble(),
      dwellTime: (json['dwellTime'] as num?)?.toInt(),
      proximityThreshold: (json['proximityThreshold'] as num?)?.toDouble(),
      hasSchedule: json['hasSchedule'] as bool? ?? false,
      activeDays: (json['activeDays'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.parse(json['expiryDate'] as String),
      notifyUser: json['notifyUser'] as bool? ?? true,
      notifyContacts: json['notifyContacts'] as bool? ?? false,
      contactIds: (json['contactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      customMessage: json['customMessage'] as String?,
      autoActivateProfile: json['autoActivateProfile'] as bool? ?? false,
      linkedProfileId: json['linkedProfileId'] as String?,
      entryCount: (json['entryCount'] as num?)?.toInt() ?? 0,
      exitCount: (json['exitCount'] as num?)?.toInt() ?? 0,
      lastTriggered: json['lastTriggered'] == null
          ? null
          : DateTime.parse(json['lastTriggered'] as String),
      lastLocation: json['lastLocation'] as Map<String, dynamic>?,
      isCurrentlyInside: json['isCurrentlyInside'] as bool? ?? false,
      customData: json['customData'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$LocationAlertToJson(LocationAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'type': _$GeofenceTypeEnumMap[instance.type]!,
      'status': _$LocationAlertStatusEnumMap[instance.status]!,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius': instance.radius,
      'polygon': instance.polygon,
      'address': instance.address,
      'triggers':
          instance.triggers.map((e) => _$AlertTriggerEnumMap[e]!).toList(),
      'speedThreshold': instance.speedThreshold,
      'dwellTime': instance.dwellTime,
      'proximityThreshold': instance.proximityThreshold,
      'hasSchedule': instance.hasSchedule,
      'activeDays': instance.activeDays,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'notifyUser': instance.notifyUser,
      'notifyContacts': instance.notifyContacts,
      'contactIds': instance.contactIds,
      'customMessage': instance.customMessage,
      'autoActivateProfile': instance.autoActivateProfile,
      'linkedProfileId': instance.linkedProfileId,
      'entryCount': instance.entryCount,
      'exitCount': instance.exitCount,
      'lastTriggered': instance.lastTriggered?.toIso8601String(),
      'lastLocation': instance.lastLocation,
      'isCurrentlyInside': instance.isCurrentlyInside,
      'customData': instance.customData,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$GeofenceTypeEnumMap = {
  GeofenceType.safeZone: 'safeZone',
  GeofenceType.dangerZone: 'dangerZone',
  GeofenceType.temporaryZone: 'temporaryZone',
  GeofenceType.travelRoute: 'travelRoute',
  GeofenceType.custom: 'custom',
};

const _$LocationAlertStatusEnumMap = {
  LocationAlertStatus.active: 'active',
  LocationAlertStatus.snoozed: 'snoozed',
  LocationAlertStatus.disabled: 'disabled',
  LocationAlertStatus.expired: 'expired',
};

const _$AlertTriggerEnumMap = {
  AlertTrigger.enter: 'enter',
  AlertTrigger.exit: 'exit',
  AlertTrigger.dwell: 'dwell',
  AlertTrigger.proximity: 'proximity',
  AlertTrigger.speed: 'speed',
  AlertTrigger.deviation: 'deviation',
};
