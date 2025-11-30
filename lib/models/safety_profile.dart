import 'package:json_annotation/json_annotation.dart';

part 'safety_profile.g.dart';

enum SafetyMode { normal, heightened, stealth, travel, custom }

enum TriggerSensitivity { low, medium, high, custom }

enum BiometricType { fingerprint, faceId, none }

@JsonSerializable()
class SafetyProfile {
  final String id;
  final String userId;
  final String name;
  final SafetyMode mode;
  final bool isActive;
  final TriggerSensitivity triggerSensitivity;

  // Trigger Settings
  final bool enableVoiceTrigger;
  final bool enableGestureTrigger;
  final bool enableShakeTrigger;
  final bool enableButtonTrigger;
  final bool enableAITrigger;
  final bool enableBiometricTrigger;

  // Biometric Settings
  final BiometricType primaryBiometric;
  final BiometricType secondaryBiometric;
  final bool requireBiometricForDeactivation;

  // Location Settings
  final bool trackLocation;
  final int locationUpdateInterval; // in seconds
  final double safeZoneRadius; // in meters
  final List<String> safeZoneIds;

  // Notification Settings
  final bool enablePushNotifications;
  final bool enableSoundAlerts;
  final bool enableVibration;
  final bool enableStealthMode;

  // Emergency Response Settings
  final List<String> primaryContactIds;
  final List<String> secondaryContactIds;
  final String? emergencyMessage;
  final String? emergencyAudioMessage;
  final bool autoCallEmergencyServices;
  final bool shareLocationWithContacts;
  final bool recordAudio;
  final bool recordVideo;

  // AI Settings
  final bool enableFacialDistressDetection;
  final bool enableVoiceStressDetection;
  final bool enableBehaviorAnalysis;
  final double aiSensitivityThreshold; // 0.0 to 1.0

  // Custom Settings
  final Map<String, dynamic>? customSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  SafetyProfile({
    required this.id,
    required this.userId,
    required this.name,
    this.mode = SafetyMode.normal,
    this.isActive = true,
    this.triggerSensitivity = TriggerSensitivity.medium,

    // Trigger Settings
    this.enableVoiceTrigger = true,
    this.enableGestureTrigger = true,
    this.enableShakeTrigger = true,
    this.enableButtonTrigger = true,
    this.enableAITrigger = false,
    this.enableBiometricTrigger = false,

    // Biometric Settings
    this.primaryBiometric = BiometricType.none,
    this.secondaryBiometric = BiometricType.none,
    this.requireBiometricForDeactivation = false,

    // Location Settings
    this.trackLocation = true,
    this.locationUpdateInterval = 300, // 5 minutes
    this.safeZoneRadius = 100.0, // 100 meters
    this.safeZoneIds = const [],

    // Notification Settings
    this.enablePushNotifications = true,
    this.enableSoundAlerts = true,
    this.enableVibration = true,
    this.enableStealthMode = false,

    // Emergency Response Settings
    this.primaryContactIds = const [],
    this.secondaryContactIds = const [],
    this.emergencyMessage,
    this.emergencyAudioMessage,
    this.autoCallEmergencyServices = false,
    this.shareLocationWithContacts = true,
    this.recordAudio = false,
    this.recordVideo = false,

    // AI Settings
    this.enableFacialDistressDetection = false,
    this.enableVoiceStressDetection = false,
    this.enableBehaviorAnalysis = false,
    this.aiSensitivityThreshold = 0.7,

    // Custom Settings
    this.customSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafetyProfile.fromJson(Map<String, dynamic> json) =>
      _$SafetyProfileFromJson(json);

  Map<String, dynamic> toJson() => _$SafetyProfileToJson(this);

  SafetyProfile copyWith({
    String? id,
    String? userId,
    String? name,
    SafetyMode? mode,
    bool? isActive,
    TriggerSensitivity? triggerSensitivity,
    bool? enableVoiceTrigger,
    bool? enableGestureTrigger,
    bool? enableShakeTrigger,
    bool? enableButtonTrigger,
    bool? enableAITrigger,
    bool? enableBiometricTrigger,
    BiometricType? primaryBiometric,
    BiometricType? secondaryBiometric,
    bool? requireBiometricForDeactivation,
    bool? trackLocation,
    int? locationUpdateInterval,
    double? safeZoneRadius,
    List<String>? safeZoneIds,
    bool? enablePushNotifications,
    bool? enableSoundAlerts,
    bool? enableVibration,
    bool? enableStealthMode,
    List<String>? primaryContactIds,
    List<String>? secondaryContactIds,
    String? emergencyMessage,
    String? emergencyAudioMessage,
    bool? autoCallEmergencyServices,
    bool? shareLocationWithContacts,
    bool? recordAudio,
    bool? recordVideo,
    bool? enableFacialDistressDetection,
    bool? enableVoiceStressDetection,
    bool? enableBehaviorAnalysis,
    double? aiSensitivityThreshold,
    Map<String, dynamic>? customSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SafetyProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      isActive: isActive ?? this.isActive,
      triggerSensitivity: triggerSensitivity ?? this.triggerSensitivity,
      enableVoiceTrigger: enableVoiceTrigger ?? this.enableVoiceTrigger,
      enableGestureTrigger: enableGestureTrigger ?? this.enableGestureTrigger,
      enableShakeTrigger: enableShakeTrigger ?? this.enableShakeTrigger,
      enableButtonTrigger: enableButtonTrigger ?? this.enableButtonTrigger,
      enableAITrigger: enableAITrigger ?? this.enableAITrigger,
      enableBiometricTrigger:
          enableBiometricTrigger ?? this.enableBiometricTrigger,
      primaryBiometric: primaryBiometric ?? this.primaryBiometric,
      secondaryBiometric: secondaryBiometric ?? this.secondaryBiometric,
      requireBiometricForDeactivation:
          requireBiometricForDeactivation ??
          this.requireBiometricForDeactivation,
      trackLocation: trackLocation ?? this.trackLocation,
      locationUpdateInterval:
          locationUpdateInterval ?? this.locationUpdateInterval,
      safeZoneRadius: safeZoneRadius ?? this.safeZoneRadius,
      safeZoneIds: safeZoneIds ?? this.safeZoneIds,
      enablePushNotifications:
          enablePushNotifications ?? this.enablePushNotifications,
      enableSoundAlerts: enableSoundAlerts ?? this.enableSoundAlerts,
      enableVibration: enableVibration ?? this.enableVibration,
      enableStealthMode: enableStealthMode ?? this.enableStealthMode,
      primaryContactIds: primaryContactIds ?? this.primaryContactIds,
      secondaryContactIds: secondaryContactIds ?? this.secondaryContactIds,
      emergencyMessage: emergencyMessage ?? this.emergencyMessage,
      emergencyAudioMessage:
          emergencyAudioMessage ?? this.emergencyAudioMessage,
      autoCallEmergencyServices:
          autoCallEmergencyServices ?? this.autoCallEmergencyServices,
      shareLocationWithContacts:
          shareLocationWithContacts ?? this.shareLocationWithContacts,
      recordAudio: recordAudio ?? this.recordAudio,
      recordVideo: recordVideo ?? this.recordVideo,
      enableFacialDistressDetection:
          enableFacialDistressDetection ?? this.enableFacialDistressDetection,
      enableVoiceStressDetection:
          enableVoiceStressDetection ?? this.enableVoiceStressDetection,
      enableBehaviorAnalysis:
          enableBehaviorAnalysis ?? this.enableBehaviorAnalysis,
      aiSensitivityThreshold:
          aiSensitivityThreshold ?? this.aiSensitivityThreshold,
      customSettings: customSettings ?? this.customSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get modeText {
    switch (mode) {
      case SafetyMode.normal:
        return 'Normal Mode';
      case SafetyMode.heightened:
        return 'Heightened Security';
      case SafetyMode.stealth:
        return 'Stealth Mode';
      case SafetyMode.travel:
        return 'Travel Mode';
      case SafetyMode.custom:
        return 'Custom Mode';
    }
  }

  String get sensitivityText {
    switch (triggerSensitivity) {
      case TriggerSensitivity.low:
        return 'Low Sensitivity';
      case TriggerSensitivity.medium:
        return 'Medium Sensitivity';
      case TriggerSensitivity.high:
        return 'High Sensitivity';
      case TriggerSensitivity.custom:
        return 'Custom Sensitivity';
    }
  }

  bool get hasBiometricSetup => primaryBiometric != BiometricType.none;
  bool get hasSecondaryBiometric => secondaryBiometric != BiometricType.none;
  bool get hasSafeZones => safeZoneIds.isNotEmpty;
  bool get hasEmergencyMessage =>
      emergencyMessage != null && emergencyMessage!.isNotEmpty;
  bool get hasCustomSettings =>
      mode == SafetyMode.custom || customSettings != null;
  bool get isAIEnabled =>
      enableFacialDistressDetection ||
      enableVoiceStressDetection ||
      enableBehaviorAnalysis;

  List<String> get enabledTriggers {
    final triggers = <String>[];
    if (enableVoiceTrigger) triggers.add('voice');
    if (enableGestureTrigger) triggers.add('gesture');
    if (enableShakeTrigger) triggers.add('shake');
    if (enableButtonTrigger) triggers.add('button');
    if (enableAITrigger) triggers.add('ai');
    if (enableBiometricTrigger) triggers.add('biometric');
    return triggers;
  }
}
