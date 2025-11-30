import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:terax_ai_app/utils/app_theme.dart';
import 'package:terax_ai_app/widgets/custom_icon_widget.dart';
import 'package:terax_ai_app/config/api_config.dart';
import 'package:terax_ai_app/providers/settings_provider.dart';
import 'package:terax_ai_app/screens/settings/custom_phrases_screen.dart';
import 'package:terax_ai_app/screens/settings/about_screen.dart';
import 'package:terax_ai_app/services/gesture_detection_service.dart';
import 'package:terax_ai_app/screens/main/widgets/backup_restore_widget.dart';
import 'package:terax_ai_app/screens/main/widgets/gesture_test_widget.dart';
import 'package:terax_ai_app/screens/main/widgets/settings_action_widget.dart';
import 'package:terax_ai_app/screens/main/widgets/settings_section_widget.dart';
import 'package:terax_ai_app/screens/main/widgets/settings_slider_widget.dart';
import 'package:terax_ai_app/screens/main/widgets/settings_toggle_widget.dart';
import 'package:terax_ai_app/screens/main/widgets/voice_phrase_recorder_widget.dart';

class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettingsState();
}

class _AppSettingsState extends State<AppSettings>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _apiKeyController = TextEditingController();
  ApiKeyStatus _apiKeyStatus = ApiKeyStatus.notSet;
  String? _currentApiKey;

  // Voice Activation Settings
  bool _voiceActivationEnabled = true;
  double _voiceSensitivity = 0.7;

  // Gesture Detection Settings
  bool _gestureDetectionEnabled = true;
  double _shakeThreshold = 12.0;
  double _tapSensitivity = 0.8;

  // Location Services Settings
  bool _locationServicesEnabled = true;
  bool _highAccuracyGPS = true;
  bool _locationSharingEnabled = true;

  // Additional Settings
  bool _autoRecordingEnabled = false;
  bool _emergencyContactsEnabled = true;
  bool _dataBackupEnabled = false;
  bool _analyticsEnabled = true;
  bool _safeZoneAlertsEnabled = true;

  // Emergency Response Settings
  bool _autoCallEmergencyServices = false;
  double _sirenVolume = 0.8;
  double _countdownDuration = 10.0;
  bool _stealthModeEnabled = false;

  // Notification Settings
  bool _pushAlertsEnabled = true;
  bool _soundAlertsEnabled = true;
  bool _vibrationEnabled = true;

  // Privacy Settings
  bool _dataEncryptionEnabled = true;
  double _autoClearDays = 30.0;
  bool _biometricAuthEnabled = false;

  // Account Settings
  String _userName = "";
  String _userEmail = "";
  File? _profileImage;
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadApiKeyStatus();
    _initializeGestureDetection();
    _loadUserData();
  }

  Future<void> _loadApiKeyStatus() async {
    try {
      final hasKey = await ApiConfig.hasGeminiApiKey();
      if (hasKey) {
        final apiKey = await ApiConfig.getGeminiApiKey();
        if (apiKey != null) {
          _currentApiKey = ApiConfig.getMaskedApiKey(apiKey);
          _apiKeyStatus = await ApiKeyManager.validateApiKey();
        }
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading API key status: $e');
      }
    }
  }

  Future<void> _initializeGestureDetection() async {
    try {
      await GestureDetectionService.instance.initialize();

      // Set up gesture callbacks
      GestureDetectionService.instance.setEmergencyCallback(() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Emergency gesture detected!'),
              backgroundColor: AppTheme.primaryRed,
              duration: Duration(seconds: 2),
            ),
          );
        }
      });

      // Start gesture detection if enabled
      if (_gestureDetectionEnabled) {
        await GestureDetectionService.instance
            .startShakeDetection(threshold: _shakeThreshold);
        await GestureDetectionService.instance
            .startTapDetection(sensitivity: _tapSensitivity);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing gesture detection: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Settings'),
        content: const Text(
            'This will reset all settings to their default values. Emergency contacts and history will not be affected. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetAllSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmergency,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllSettings() async {
    setState(() {
      _voiceActivationEnabled = true;
      _voiceSensitivity = 0.7;
      _gestureDetectionEnabled = true;
      _shakeThreshold = 12.0;
      _tapSensitivity = 0.8;
      _locationServicesEnabled = true;
      _highAccuracyGPS = true;
      _locationSharingEnabled = true;
      _safeZoneAlertsEnabled = true;
      _autoCallEmergencyServices = false;
      _sirenVolume = 0.8;
      _countdownDuration = 10.0;
      _stealthModeEnabled = false;
      _pushAlertsEnabled = true;
      _soundAlertsEnabled = true;
      _vibrationEnabled = true;
      _dataEncryptionEnabled = true;
      _autoClearDays = 30.0;
      _biometricAuthEnabled = false;
      _autoRecordingEnabled = false;
      _emergencyContactsEnabled = true;
      _dataBackupEnabled = false;
      _analyticsEnabled = true;
    });

    await _saveUserData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All settings have been reset to defaults'),
          backgroundColor: AppTheme.safeStateGreen,
        ),
      );
    }
  }

  void _saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid API key'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    if (!ApiConfig.isValidApiKeyFormat(apiKey)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Invalid API key format. Gemini API keys should start with "AIza"'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    try {
      await ApiConfig.setGeminiApiKey(apiKey);

      // Validate the API key
      final status = await ApiKeyManager.validateApiKey(apiKey);

      if (mounted) {
        if (status == ApiKeyStatus.valid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gemini API key saved and validated successfully!'),
              backgroundColor: AppTheme.safeStateGreen,
            ),
          );
          _apiKeyController.clear(); // Clear for security
          _loadApiKeyStatus(); // Refresh status
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'API key saved but validation failed: ${ApiKeyManager.getStatusMessage(status)}'),
              backgroundColor: AppTheme.warningAmber,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving API key: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  void _clearApiKey() async {
    try {
      await ApiConfig.clearGeminiApiKey();
      _currentApiKey = null;
      _apiKeyStatus = ApiKeyStatus.notSet;

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key cleared successfully'),
            backgroundColor: AppTheme.safeStateGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing API key: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (_apiKeyStatus) {
      case ApiKeyStatus.notSet:
        return Colors.orange;
      case ApiKeyStatus.invalid:
        return Colors.red;
      case ApiKeyStatus.valid:
        return Colors.green;
      case ApiKeyStatus.expired:
        return Colors.red;
      case ApiKeyStatus.rateLimited:
        return Colors.orange;
    }
  }

  void _testEmergencyAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const CustomIconWidget(
              assetPath: 'assets/icons/warning.svg',
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Test Emergency Alert'),
          ],
        ),
        content: const Text(
            'This will send a test alert to your emergency contacts. They will receive a message indicating this is a test. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test alert sent to emergency contacts'),
                  backgroundColor: AppTheme.safeStateGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningAmber,
            ),
            child: const Text('Send Test'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Theme Settings Section
          SettingsSectionWidget(
            title: 'Appearance',
            children: [
              Consumer<SettingsProvider>(
                builder: (context, settingsProvider, child) {
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.palette_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text(
                          'Theme Mode',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        subtitle: Text(
                          _getThemeModeText(
                              settingsProvider.settings.themeMode),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        trailing: DropdownButton<ThemeMode>(
                          value: settingsProvider.settings.themeMode,
                          onChanged: (ThemeMode? newMode) {
                            if (newMode != null) {
                              settingsProvider.updateThemeMode(newMode);
                            }
                          },
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Text('System'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),

          // AI Settings Section
          SettingsSectionWidget(
            title: 'AI Configuration',
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Gemini API Key',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.neutral800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            ApiKeyManager.getStatusMessage(_apiKeyStatus),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_currentApiKey != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.neutral50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.neutral200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.key,
                                size: 16, color: AppTheme.neutral600),
                            const SizedBox(width: 8),
                            Text(
                              'Current: $_currentApiKey',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.neutral600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _clearApiKey,
                              child: const Text('Clear',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: _currentApiKey != null
                            ? 'Enter new API key to replace current'
                            : 'Enter your Gemini Pro API key',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: _saveApiKey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Required for AI-powered emergency analysis and smart message generation',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.neutral600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Voice Activation Section
          SettingsSectionWidget(
            title: 'Voice Activation',
            children: [
              SettingsToggleWidget(
                title: 'Voice Trigger',
                value: _voiceActivationEnabled,
                onChanged: (value) async {
                  setState(() => _voiceActivationEnabled = value);
                  await _saveUserData();
                },
              ),
              if (_voiceActivationEnabled) ...[
                const VoicePhraseRecorderWidget(),
                SettingsSliderWidget(
                  title: 'Voice Sensitivity',
                  value: _voiceSensitivity,
                  onChanged: (value) async {
                    setState(() => _voiceSensitivity = value);
                    await _saveUserData();
                  },
                ),
                // Custom Phrases Navigation
                ListTile(
                  leading: Icon(
                    Icons.mic_external_on,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Custom Voice Phrases',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  subtitle: const Text(
                    'Add your own trigger phrases',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CustomPhrasesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),

          // Gesture Detection Section
          SettingsSectionWidget(
            title: 'Gesture Detection',
            children: [
              SettingsToggleWidget(
                title: 'Gesture Activation',
                value: _gestureDetectionEnabled,
                onChanged: (value) async {
                  setState(() => _gestureDetectionEnabled = value);
                  if (value) {
                    await GestureDetectionService.instance
                        .startShakeDetection(threshold: _shakeThreshold);
                    await GestureDetectionService.instance
                        .startTapDetection(sensitivity: _tapSensitivity);
                  } else {
                    GestureDetectionService.instance.stopShakeDetection();
                    GestureDetectionService.instance.stopTapDetection();
                  }
                  await _saveUserData();
                },
              ),
              if (_gestureDetectionEnabled) ...[
                SettingsSliderWidget(
                  title: 'Shake Threshold',
                  value: _shakeThreshold,
                  min: 1.0,
                  max: 20.0,
                  divisions: 19,
                  onChanged: (value) async {
                    setState(() => _shakeThreshold = value);
                    GestureDetectionService.instance
                        .updateShakeThreshold(value);
                    await _saveUserData();
                  },
                ),
                SettingsSliderWidget(
                  title: 'Tap Sensitivity',
                  value: _tapSensitivity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) async {
                    setState(() => _tapSensitivity = value);
                    GestureDetectionService.instance
                        .updateTapSensitivity(value);
                    await _saveUserData();
                  },
                ),
                const GestureTestWidget(),
              ],
            ],
          ),

          // Location Services Section
          SettingsSectionWidget(
            title: 'Location Services',
            children: [
              SettingsToggleWidget(
                title: 'GPS Tracking',
                value: _locationServicesEnabled,
                onChanged: (value) async {
                  setState(() => _locationServicesEnabled = value);
                  await _saveUserData();
                },
              ),
              if (_locationServicesEnabled) ...[
                SettingsToggleWidget(
                  title: 'High Accuracy GPS',
                  value: _highAccuracyGPS,
                  onChanged: (value) async {
                    setState(() => _highAccuracyGPS = value);
                    await _saveUserData();
                  },
                ),
                SettingsToggleWidget(
                  title: 'Auto Location Sharing',
                  value: _locationSharingEnabled,
                  onChanged: (value) async {
                    setState(() => _locationSharingEnabled = value);
                    await _saveUserData();
                  },
                ),
                SettingsToggleWidget(
                  title: 'Safe Zone Alerts',
                  value: _safeZoneAlertsEnabled,
                  onChanged: (value) =>
                      setState(() => _safeZoneAlertsEnabled = value),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Emergency Response Section
          SettingsSectionWidget(
            title: 'Emergency Response',
            children: [
              SettingsToggleWidget(
                title: 'Auto-Call Emergency Services',
                value: _autoCallEmergencyServices,
                onChanged: (value) =>
                    setState(() => _autoCallEmergencyServices = value),
              ),
              SettingsSliderWidget(
                title: 'Emergency Siren Volume',
                value: _sirenVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (value) => setState(() => _sirenVolume = value),
              ),
              SettingsSliderWidget(
                title: 'Countdown Duration',
                value: _countdownDuration,
                min: 3.0,
                max: 30.0,
                divisions: 27,
                onChanged: (value) =>
                    setState(() => _countdownDuration = value),
              ),
              SettingsToggleWidget(
                title: 'Stealth Mode',
                value: _stealthModeEnabled,
                onChanged: (value) =>
                    setState(() => _stealthModeEnabled = value),
              ),
            ],
          ),

          // Test Emergency Section
          SettingsSectionWidget(
            title: 'Emergency Testing',
            children: [
              SettingsActionWidget(
                title: 'Test Emergency Alert',
                onTap: _testEmergencyAlert,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Notification Preferences Section
          SettingsSectionWidget(
            title: 'Notification Preferences',
            children: [
              SettingsToggleWidget(
                title: 'Push Notifications',
                value: _pushAlertsEnabled,
                onChanged: (value) =>
                    setState(() => _pushAlertsEnabled = value),
              ),
              SettingsToggleWidget(
                title: 'Sound Alerts',
                value: _soundAlertsEnabled,
                onChanged: (value) =>
                    setState(() => _soundAlertsEnabled = value),
              ),
              SettingsToggleWidget(
                title: 'Vibration',
                value: _vibrationEnabled,
                onChanged: (value) => setState(() => _vibrationEnabled = value),
              ),
            ],
          ),

          // Privacy & Security Section
          SettingsSectionWidget(
            title: 'Privacy & Security',
            children: [
              SettingsToggleWidget(
                title: 'Data Encryption',
                value: _dataEncryptionEnabled,
                onChanged: (value) =>
                    setState(() => _dataEncryptionEnabled = value),
              ),
              SettingsSliderWidget(
                title: 'Auto-Clear Data',
                value: _autoClearDays,
                min: 1.0,
                max: 365.0,
                divisions: 36,
                onChanged: (value) => setState(() => _autoClearDays = value),
              ),
              SettingsToggleWidget(
                title: 'Biometric Authentication',
                value: _biometricAuthEnabled,
                onChanged: (value) =>
                    setState(() => _biometricAuthEnabled = value),
              ),
              SettingsActionWidget(
                title: 'Clear All Data',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear All Data'),
                      content: const Text(
                          'This will permanently delete all recordings, logs, and cached data. This action cannot be undone. Continue?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All data has been cleared'),
                                backgroundColor: AppTheme.safeStateGreen,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryEmergency,
                          ),
                          child: const Text('Clear Data'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          // Backup & Restore Section
          const BackupRestoreWidget(),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Profile Section
          SettingsSectionWidget(
            title: 'Profile Information',
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _showImageSourcePicker,
                      borderRadius: BorderRadius.circular(30),
                      child: Material(
                        elevation: 4,
                        shadowColor: AppTheme.statusBlue.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.statusBlue,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: _profileImage != null &&
                                    _profileImage!.existsSync()
                                ? Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 60,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildInitialsAvatar();
                                    },
                                  )
                                : _buildInitialsAvatar(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _editUserName,
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName
                                  : 'Tap to set name',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: _userName.isNotEmpty
                                    ? AppTheme.textPrimary
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _editUserEmail,
                            child: Text(
                              _userEmail.isNotEmpty
                                  ? _userEmail
                                  : 'Tap to set email',
                              style: AppTheme.lightTheme.textTheme.bodyMedium
                                  ?.copyWith(
                                color: _userEmail.isNotEmpty
                                    ? AppTheme.textSecondary
                                    : AppTheme.textSecondary
                                        .withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _editProfile,
                      icon: const CustomIconWidget(
                        assetPath: 'assets/icons/edit.svg',
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Account Actions Section
          SettingsSectionWidget(
            title: 'Account Actions',
            children: [
              SettingsActionWidget(
                title: 'Change Password',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Password change feature coming soon')),
                  );
                },
              ),
              SettingsActionWidget(
                title: 'Emergency Contacts',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Emergency Contacts feature coming soon')),
                  );
                },
              ),
              SettingsActionWidget(
                title: 'Emergency History',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Emergency History feature coming soon')),
                  );
                },
              ),
            ],
          ),

          // About Section
          SettingsSectionWidget(
            title: 'About',
            children: [
              SettingsActionWidget(
                title: 'About TERAX AI',
                subtitle: 'App information and version details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          // Advanced Section
          SettingsSectionWidget(
            title: 'Advanced',
            children: [
              SettingsActionWidget(
                title: 'Reset All Settings',
                onTap: _showResetDialog,
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.go('/signin');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryRed.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryRed,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.primaryRed,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileImagePath = prefs.getString('profile_image_path');

      setState(() {
        _userName = prefs.getString('user_name') ?? '';
        _userEmail = prefs.getString('user_email') ?? '';
        _profileImagePath = profileImagePath;
        _gestureDetectionEnabled =
            prefs.getBool('gesture_detection_enabled') ?? true;
        _shakeThreshold = prefs.getDouble('shake_threshold') ?? 12.0;
        _tapSensitivity = prefs.getDouble('tap_sensitivity') ?? 0.8;
        _voiceActivationEnabled =
            prefs.getBool('voice_activation_enabled') ?? true;
        _autoRecordingEnabled =
            prefs.getBool('auto_recording_enabled') ?? false;
        _locationSharingEnabled =
            prefs.getBool('location_sharing_enabled') ?? true;
        _emergencyContactsEnabled =
            prefs.getBool('emergency_contacts_enabled') ?? true;
        _dataBackupEnabled = prefs.getBool('data_backup_enabled') ?? false;
        _analyticsEnabled = prefs.getBool('analytics_enabled') ?? true;
      });

      // Load profile image if path exists and file exists
      if (profileImagePath != null) {
        final profileImageFile = File(profileImagePath);
        if (await profileImageFile.exists()) {
          setState(() {
            _profileImage = profileImageFile;
          });
        } else {
          // File doesn't exist, remove the path from preferences
          await prefs.remove('profile_image_path');
          setState(() {
            _profileImagePath = null;
            _profileImage = null;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user data: $e');
      }
    }
  }

  /// Save user data to storage
  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_email', _userEmail);
      if (_profileImagePath != null) {
        await prefs.setString('profile_image_path', _profileImagePath!);
      } else {
        await prefs.remove('profile_image_path');
      }
      await prefs.setBool(
          'gesture_detection_enabled', _gestureDetectionEnabled);
      await prefs.setDouble('shake_threshold', _shakeThreshold);
      await prefs.setDouble('tap_sensitivity', _tapSensitivity);
      await prefs.setBool('voice_activation_enabled', _voiceActivationEnabled);
      await prefs.setBool('auto_recording_enabled', _autoRecordingEnabled);
      await prefs.setBool('location_sharing_enabled', _locationSharingEnabled);
      await prefs.setBool(
          'emergency_contacts_enabled', _emergencyContactsEnabled);
      await prefs.setBool('data_backup_enabled', _dataBackupEnabled);
      await prefs.setBool('analytics_enabled', _analyticsEnabled);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user data: $e');
      }
    }
  }

  /// Edit user name
  Future<void> _editUserName() async {
    final TextEditingController controller =
        TextEditingController(text: _userName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _userName = result;
      });
      await _saveUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully')),
        );
      }
    }
  }

  /// Edit user email
  Future<void> _editUserEmail() async {
    final TextEditingController controller =
        TextEditingController(text: _userEmail);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Email'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email address',
          ),
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _userEmail = result;
      });
      await _saveUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email updated successfully')),
        );
      }
    }
  }

  /// Edit profile (both name and email)
  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email address',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        if (result['name']?.isNotEmpty == true) _userName = result['name']!;
        if (result['email']?.isNotEmpty == true) _userEmail = result['email']!;
      });
      await _saveUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    }
  }

  /// Pick profile image from gallery or camera
  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        // Load and process the image
        final File imageFile = File(pickedFile.path);
        final img.Image? originalImage = img.decodeImage(await imageFile.readAsBytes());

        if (originalImage != null) {
          // Resize to 512x512 and compress to 80% quality
          final img.Image resizedImage = img.copyResize(originalImage, width: 512, height: 512);
          final Uint8List compressedImage = img.encodePng(resizedImage, level: 8); // Level 8 = ~80% quality

          // Save to app directory
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String fileName = 'profile_image_$timestamp.png';
          final File savedImage = await File('${appDir.path}/$fileName').writeAsBytes(compressedImage);

          setState(() {
            _profileImage = savedImage;
            _profileImagePath = savedImage.path;
          });

          await _saveUserData();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                backgroundColor: AppTheme.safeStateGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking profile image: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating profile picture'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  /// Show image source picker dialog
  Future<void> _showImageSourcePicker() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            if (_profileImage != null) ...[
              const Divider(),
              ListTile(
                leading: Icon(Icons.delete, color: AppTheme.primaryRed),
                title: Text('Remove Picture', style: TextStyle(color: AppTheme.primaryRed)),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Remove current profile image
  Future<void> _removeProfileImage() async {
    try {
      if (_profileImage != null && await _profileImage!.exists()) {
        await _profileImage!.delete();
      }

      setState(() {
        _profileImage = null;
        _profileImagePath = null;
      });

      await _saveUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed'),
            backgroundColor: AppTheme.safeStateGreen,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error removing profile image: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error removing profile picture'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  /// Build initials avatar widget as fallback
  Widget _buildInitialsAvatar() {
    return Container(
      color: AppTheme.statusBlue.withValues(alpha: 0.1),
      width: 60,
      height: 60,
      child: Center(
        child: Text(
          _userName.isNotEmpty
              ? _userName
                  .split(' ')
                  .map((name) => name.isNotEmpty ? name[0] : '')
                  .join('')
                  .toUpperCase()
              : 'U',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.statusBlue,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryEmergency,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryEmergency,
          indicatorWeight: 3,
          labelStyle: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle:
              AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Settings'),
            Tab(text: 'Emergency'),
            Tab(text: 'Privacy'),
            Tab(text: 'Account'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSettingsTab(),
          _buildEmergencyTab(),
          _buildNotificationsTab(),
          _buildAccountTab(),
        ],
      ),
    );
  }
}
