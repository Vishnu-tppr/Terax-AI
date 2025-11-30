// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SafetyProfile _$SafetyProfileFromJson(Map<String, dynamic> json) =>
    SafetyProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      mode: $enumDecodeNullable(_$SafetyModeEnumMap, json['mode']) ??
          SafetyMode.normal,
      isActive: json['isActive'] as bool? ?? true,
      triggerSensitivity: $enumDecodeNullable(
              _$TriggerSensitivityEnumMap, json['triggerSensitivity']) ??
          TriggerSensitivity.medium,
      enableVoiceTrigger: json['enableVoiceTrigger'] as bool? ?? true,
      enableGestureTrigger: json['enableGestureTrigger'] as bool? ?? true,
      enableShakeTrigger: json['enableShakeTrigger'] as bool? ?? true,
      enableButtonTrigger: json['enableButtonTrigger'] as bool? ?? true,
      enableAITrigger: json['enableAITrigger'] as bool? ?? false,
      enableBiometricTrigger: json['enableBiometricTrigger'] as bool? ?? false,
      primaryBiometric: $enumDecodeNullable(
              _$BiometricTypeEnumMap, json['primaryBiometric']) ??
          BiometricType.none,
      secondaryBiometric: $enumDecodeNullable(
              _$BiometricTypeEnumMap, json['secondaryBiometric']) ??
          BiometricType.none,
      requireBiometricForDeactivation:
          json['requireBiometricForDeactivation'] as bool? ?? false,
      trackLocation: json['trackLocation'] as bool? ?? true,
      locationUpdateInterval:
          (json['locationUpdateInterval'] as num?)?.toInt() ?? 300,
      safeZoneRadius: (json['safeZoneRadius'] as num?)?.toDouble() ?? 100.0,
      safeZoneIds: (json['safeZoneIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      enablePushNotifications: json['enablePushNotifications'] as bool? ?? true,
      enableSoundAlerts: json['enableSoundAlerts'] as bool? ?? true,
      enableVibration: json['enableVibration'] as bool? ?? true,
      enableStealthMode: json['enableStealthMode'] as bool? ?? false,
      primaryContactIds: (json['primaryContactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      secondaryContactIds: (json['secondaryContactIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      emergencyMessage: json['emergencyMessage'] as String?,
      emergencyAudioMessage: json['emergencyAudioMessage'] as String?,
      autoCallEmergencyServices:
          json['autoCallEmergencyServices'] as bool? ?? false,
      shareLocationWithContacts:
          json['shareLocationWithContacts'] as bool? ?? true,
      recordAudio: json['recordAudio'] as bool? ?? false,
      recordVideo: json['recordVideo'] as bool? ?? false,
      enableFacialDistressDetection:
          json['enableFacialDistressDetection'] as bool? ?? false,
      enableVoiceStressDetection:
          json['enableVoiceStressDetection'] as bool? ?? false,
      enableBehaviorAnalysis: json['enableBehaviorAnalysis'] as bool? ?? false,
      aiSensitivityThreshold:
          (json['aiSensitivityThreshold'] as num?)?.toDouble() ?? 0.7,
      customSettings: json['customSettings'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SafetyProfileToJson(SafetyProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'mode': _$SafetyModeEnumMap[instance.mode]!,
      'isActive': instance.isActive,
      'triggerSensitivity':
          _$TriggerSensitivityEnumMap[instance.triggerSensitivity]!,
      'enableVoiceTrigger': instance.enableVoiceTrigger,
      'enableGestureTrigger': instance.enableGestureTrigger,
      'enableShakeTrigger': instance.enableShakeTrigger,
      'enableButtonTrigger': instance.enableButtonTrigger,
      'enableAITrigger': instance.enableAITrigger,
      'enableBiometricTrigger': instance.enableBiometricTrigger,
      'primaryBiometric': _$BiometricTypeEnumMap[instance.primaryBiometric]!,
      'secondaryBiometric':
          _$BiometricTypeEnumMap[instance.secondaryBiometric]!,
      'requireBiometricForDeactivation':
          instance.requireBiometricForDeactivation,
      'trackLocation': instance.trackLocation,
      'locationUpdateInterval': instance.locationUpdateInterval,
      'safeZoneRadius': instance.safeZoneRadius,
      'safeZoneIds': instance.safeZoneIds,
      'enablePushNotifications': instance.enablePushNotifications,
      'enableSoundAlerts': instance.enableSoundAlerts,
      'enableVibration': instance.enableVibration,
      'enableStealthMode': instance.enableStealthMode,
      'primaryContactIds': instance.primaryContactIds,
      'secondaryContactIds': instance.secondaryContactIds,
      'emergencyMessage': instance.emergencyMessage,
      'emergencyAudioMessage': instance.emergencyAudioMessage,
      'autoCallEmergencyServices': instance.autoCallEmergencyServices,
      'shareLocationWithContacts': instance.shareLocationWithContacts,
      'recordAudio': instance.recordAudio,
      'recordVideo': instance.recordVideo,
      'enableFacialDistressDetection': instance.enableFacialDistressDetection,
      'enableVoiceStressDetection': instance.enableVoiceStressDetection,
      'enableBehaviorAnalysis': instance.enableBehaviorAnalysis,
      'aiSensitivityThreshold': instance.aiSensitivityThreshold,
      'customSettings': instance.customSettings,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$SafetyModeEnumMap = {
  SafetyMode.normal: 'normal',
  SafetyMode.heightened: 'heightened',
  SafetyMode.stealth: 'stealth',
  SafetyMode.travel: 'travel',
  SafetyMode.custom: 'custom',
};

const _$TriggerSensitivityEnumMap = {
  TriggerSensitivity.low: 'low',
  TriggerSensitivity.medium: 'medium',
  TriggerSensitivity.high: 'high',
  TriggerSensitivity.custom: 'custom',
};

const _$BiometricTypeEnumMap = {
  BiometricType.fingerprint: 'fingerprint',
  BiometricType.faceId: 'faceId',
  BiometricType.none: 'none',
};
