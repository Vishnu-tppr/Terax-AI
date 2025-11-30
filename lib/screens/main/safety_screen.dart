import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:terax_ai_app/providers/safety_provider.dart';
import 'package:terax_ai_app/providers/location_provider.dart';
import 'package:terax_ai_app/providers/voice_provider.dart';
import 'package:terax_ai_app/providers/contacts_provider.dart';
import 'package:terax_ai_app/providers/incidents_provider.dart';
import 'package:terax_ai_app/providers/settings_provider.dart';
import 'package:terax_ai_app/widgets/loading_animation.dart';
import 'package:terax_ai_app/services/emergency_service.dart';
import 'package:terax_ai_app/services/countdown_service.dart';
import 'package:terax_ai_app/models/emergency_incident.dart';
import 'package:terax_ai_app/widgets/countdown_widget.dart';

import 'dart:async';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _emergencyController;
  late Animation<double> _pulseAnimation;

  Timer? _countdownTimer;
  TriggerType? _currentTriggerType; // Track the trigger type

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _emergencyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Set up voice trigger callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final voiceProvider = context.read<VoiceProvider>();
      voiceProvider.setTriggerCallback((phrase) {
        if (mounted) {
          _currentTriggerType = TriggerType.voice; // Set trigger type for voice
          _startEmergencyCountdown();
        }
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emergencyController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startEmergencyCountdown() {
    HapticFeedback.heavyImpact();

    // Set up countdown service callbacks
    CountdownService.instance.setCallbacks(
      onComplete: () {
        _activateEmergency();
      },
      onCancelled: () {
        _cancelEmergencyCountdown();
      },
      onTick: (remainingSeconds) {
        HapticFeedback.mediumImpact();
      },
    );

    // Start countdown with configured duration (10 seconds default)
    CountdownService.instance.startCountdown(duration: 10);
  }

  void _cancelEmergencyCountdown() {
    _countdownTimer?.cancel();
    CountdownService.instance.cancelCountdown();
    HapticFeedback.lightImpact();
  }

  void _activateEmergency() async {

    final safetyProvider = context.read<SafetyProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final locationProvider = context.read<LocationProvider>();
    final incidentsProvider = context.read<IncidentsProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    safetyProvider.activateEmergency();
    _emergencyController.forward(from: 0);
    HapticFeedback.heavyImpact();

    // Create emergency incident
    final incident = EmergencyIncident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(), // Added timestamp
      triggerType: _currentTriggerType ?? TriggerType.button, // Use tracked trigger type
      status: IncidentStatus.active,
      description: 'Emergency alert triggered from Terax AI Safety App',
      triggeredAt: DateTime.now(),
      location: locationProvider.currentAddress ?? 'Current location',
      contactIds: contactsProvider.contacts.map((c) => c.id).toList(),
      contactsNotified: 0,
    );

    // Add incident to provider
    incidentsProvider.addIncident(incident);

    // Trigger emergency service
    try {
      await EmergencyService.instance.triggerEmergency(
        triggerType: _currentTriggerType ?? TriggerType.button, // Use tracked trigger type
        settings: settingsProvider.settings,
        contacts: contactsProvider.contacts,
        location: locationProvider.currentAddress,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Emergency alert activated! Contacts are being notified.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency alert failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final safetyProvider = context.watch<SafetyProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final voiceProvider = context.watch<VoiceProvider>();

    return CountdownOverlay(
      onEmergencyActivated: () {
        // Emergency will be activated by the countdown service callback
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terax AI',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'Personal Safety',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: safetyProvider.isEmergencyActive
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: safetyProvider.isEmergencyActive
                              ? Colors.red
                              : Colors.green,
                        ),
                      ),
                      child: Text(
                        safetyProvider.isEmergencyActive ? 'ACTIVE' : 'SAFE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: safetyProvider.isEmergencyActive
                              ? Colors.red
                              : Colors.green,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Status indicators
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        'NO LOCATION',
                        !locationProvider.hasLocation,
                        Icons.location_off,
                        Colors.red,
                        onTap: () =>
                            locationProvider.requestLocationPermission(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        'VOICE OFF',
                        !voiceProvider.isVoiceEnabled,
                        Icons.mic_off,
                        Theme.of(context).colorScheme.primary,
                        onTap: () => voiceProvider.toggleVoice(),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Emergency Button
                Center(
                  child: PulseAnimation(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: safetyProvider.isEmergencyActive
                              ? _pulseAnimation.value
                              : 1.0,
                          child: GestureDetector(
                            onLongPress: () {
                              if (!safetyProvider.isEmergencyActive) {
                                _currentTriggerType = TriggerType.button; // Set trigger type for button
                                _startEmergencyCountdown();
                              }
                            },
                            onTap: () {
                              if (safetyProvider.isEmergencyActive) {
                                safetyProvider.cancelEmergency();
                              }
                            },
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: safetyProvider.isEmergencyActive
                                    ? Colors.red
                                    : Colors.red,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    safetyProvider.isEmergencyActive
                                        ? Icons.stop
                                        : Icons.warning,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    safetyProvider.isEmergencyActive
                                        ? 'STOP'
                                        : 'EMERGENCY',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Spacer(),

                // Instructions
                Text(
                  safetyProvider.isEmergencyActive
                      ? 'Emergency alert is active. Tap to stop.'
                      : 'Press and hold to activate emergency alert',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 32),

                // Voice Activation Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        voiceProvider.isVoiceEnabled
                            ? Icons.mic
                            : Icons.mic_off,
                        color: voiceProvider.isVoiceEnabled
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Activation',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            Text(
                              voiceProvider.isVoiceEnabled
                                  ? 'Say "Help me" to trigger emergency'
                                  : 'Voice activation is disabled',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: voiceProvider.isVoiceEnabled,
                        onChanged: (value) => voiceProvider.toggleVoice(),
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      String title, bool isActive, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? color
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? color
                    : Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                fontFamily: 'Poppins',
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tap to ${isActive ? 'disable' : 'enable'}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
