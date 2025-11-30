import 'package:json_annotation/json_annotation.dart';

part 'location_alert.g.dart';

enum GeofenceType { safeZone, dangerZone, temporaryZone, travelRoute, custom }

enum AlertTrigger { enter, exit, dwell, proximity, speed, deviation }

enum LocationAlertStatus { active, snoozed, disabled, expired }

@JsonSerializable()
class LocationAlert {
  final String id;
  final String userId;
  final String name;
  final String description;
  final GeofenceType type;
  final LocationAlertStatus status;

  // Location Settings
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final List<Map<String, double>>? polygon; // for custom shapes
  final String? address;

  // Alert Configuration
  final List<AlertTrigger> triggers;
  final double? speedThreshold; // in km/h
  final int? dwellTime; // in minutes
  final double? proximityThreshold; // in meters

  // Schedule
  final bool hasSchedule;
  final List<int>? activeDays; // 1-7 for Monday-Sunday
  final String? startTime; // HH:mm format
  final String? endTime; // HH:mm format
  final DateTime? expiryDate;

  // Response Settings
  final bool notifyUser;
  final bool notifyContacts;
  final List<String> contactIds;
  final String? customMessage;
  final bool autoActivateProfile;
  final String? linkedProfileId;

  // Monitoring
  final int entryCount;
  final int exitCount;
  final DateTime? lastTriggered;
  final Map<String, dynamic>? lastLocation;
  final bool isCurrentlyInside;

  // Metadata
  final Map<String, dynamic>? customData;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationAlert({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.type,
    this.status = LocationAlertStatus.active,

    // Location Settings
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.polygon,
    this.address,

    // Alert Configuration
    required this.triggers,
    this.speedThreshold,
    this.dwellTime,
    this.proximityThreshold,

    // Schedule
    this.hasSchedule = false,
    this.activeDays,
    this.startTime,
    this.endTime,
    this.expiryDate,

    // Response Settings
    this.notifyUser = true,
    this.notifyContacts = false,
    this.contactIds = const [],
    this.customMessage,
    this.autoActivateProfile = false,
    this.linkedProfileId,

    // Monitoring
    this.entryCount = 0,
    this.exitCount = 0,
    this.lastTriggered,
    this.lastLocation,
    this.isCurrentlyInside = false,

    // Metadata
    this.customData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LocationAlert.fromJson(Map<String, dynamic> json) =>
      _$LocationAlertFromJson(json);

  Map<String, dynamic> toJson() => _$LocationAlertToJson(this);

  LocationAlert copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    GeofenceType? type,
    LocationAlertStatus? status,
    double? latitude,
    double? longitude,
    double? radius,
    List<Map<String, double>>? polygon,
    String? address,
    List<AlertTrigger>? triggers,
    double? speedThreshold,
    int? dwellTime,
    double? proximityThreshold,
    bool? hasSchedule,
    List<int>? activeDays,
    String? startTime,
    String? endTime,
    DateTime? expiryDate,
    bool? notifyUser,
    bool? notifyContacts,
    List<String>? contactIds,
    String? customMessage,
    bool? autoActivateProfile,
    String? linkedProfileId,
    int? entryCount,
    int? exitCount,
    DateTime? lastTriggered,
    Map<String, dynamic>? lastLocation,
    bool? isCurrentlyInside,
    Map<String, dynamic>? customData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      polygon: polygon ?? this.polygon,
      address: address ?? this.address,
      triggers: triggers ?? this.triggers,
      speedThreshold: speedThreshold ?? this.speedThreshold,
      dwellTime: dwellTime ?? this.dwellTime,
      proximityThreshold: proximityThreshold ?? this.proximityThreshold,
      hasSchedule: hasSchedule ?? this.hasSchedule,
      activeDays: activeDays ?? this.activeDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      expiryDate: expiryDate ?? this.expiryDate,
      notifyUser: notifyUser ?? this.notifyUser,
      notifyContacts: notifyContacts ?? this.notifyContacts,
      contactIds: contactIds ?? this.contactIds,
      customMessage: customMessage ?? this.customMessage,
      autoActivateProfile: autoActivateProfile ?? this.autoActivateProfile,
      linkedProfileId: linkedProfileId ?? this.linkedProfileId,
      entryCount: entryCount ?? this.entryCount,
      exitCount: exitCount ?? this.exitCount,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      lastLocation: lastLocation ?? this.lastLocation,
      isCurrentlyInside: isCurrentlyInside ?? this.isCurrentlyInside,
      customData: customData ?? this.customData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeText {
    switch (type) {
      case GeofenceType.safeZone:
        return 'Safe Zone';
      case GeofenceType.dangerZone:
        return 'Danger Zone';
      case GeofenceType.temporaryZone:
        return 'Temporary Zone';
      case GeofenceType.travelRoute:
        return 'Travel Route';
      case GeofenceType.custom:
        return 'Custom Zone';
    }
  }

  String get statusText {
    switch (status) {
      case LocationAlertStatus.active:
        return 'Active';
      case LocationAlertStatus.snoozed:
        return 'Snoozed';
      case LocationAlertStatus.disabled:
        return 'Disabled';
      case LocationAlertStatus.expired:
        return 'Expired';
    }
  }

  List<String> get triggerTypes {
    return triggers.map((trigger) {
      switch (trigger) {
        case AlertTrigger.enter:
          return 'Zone Entry';
        case AlertTrigger.exit:
          return 'Zone Exit';
        case AlertTrigger.dwell:
          return 'Extended Stay';
        case AlertTrigger.proximity:
          return 'Proximity Alert';
        case AlertTrigger.speed:
          return 'Speed Alert';
        case AlertTrigger.deviation:
          return 'Route Deviation';
      }
    }).toList();
  }

  bool get isScheduled =>
      hasSchedule && activeDays != null && startTime != null && endTime != null;
  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);
  bool get hasCustomShape => polygon != null && polygon!.isNotEmpty;
  bool get hasLinkedProfile =>
      linkedProfileId != null && linkedProfileId!.isNotEmpty;
  bool get hasContacts => contactIds.isNotEmpty;

  bool isActiveOnDay(int day) {
    if (!hasSchedule || activeDays == null) return true;
    return activeDays!.contains(day);
  }

  bool isActiveAtTime(DateTime time) {
    if (!hasSchedule || startTime == null || endTime == null) return true;

    final timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (startTime!.compareTo(endTime!) <= 0) {
      // Normal time range (e.g., 09:00-17:00)
      return timeString.compareTo(startTime!) >= 0 &&
          timeString.compareTo(endTime!) <= 0;
    } else {
      // Overnight time range (e.g., 22:00-06:00)
      return timeString.compareTo(startTime!) >= 0 ||
          timeString.compareTo(endTime!) <= 0;
    }
  }

  bool isActive(DateTime time) {
    if (status != LocationAlertStatus.active) return false;
    if (isExpired) return false;
    if (!isActiveOnDay(time.weekday)) return false;
    if (!isActiveAtTime(time)) return false;
    return true;
  }
}
