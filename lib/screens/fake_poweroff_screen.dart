import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terax_ai_app/services/recording_service.dart';
import 'package:terax_ai_app/services/real_location_service.dart';
import 'package:terax_ai_app/services/emergency_service.dart';

class FakePowerOffScreen extends StatefulWidget {
  final Function()? onExit;

  const FakePowerOffScreen({
    super.key,
    this.onExit,
  });

  @override
  State<FakePowerOffScreen> createState() => _FakePowerOffScreenState();
}

class _FakePowerOffScreenState extends State<FakePowerOffScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _logoController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _logoAnimation;

  bool _isRecording = false;
  bool _showSecretMenu = false;
  int _tapCount = 0;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();

    // Hide system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _logoAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Start fake shutdown animation
    _startFakeShutdown();

    // Start secret recording
    _startSecretRecording();
  }

  @override
  void dispose() {
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _fadeController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _startFakeShutdown() async {
    // Wait a bit then start fade animation
    await Future.delayed(const Duration(milliseconds: 500));
    _fadeController.forward();

    // Start logo fade after main fade
    await Future.delayed(const Duration(milliseconds: 1000));
    _logoController.forward();
  }

  void _startSecretRecording() async {
    try {
      final success =
          await RecordingService.instance.startEmergencyRecording(silent: true);
      setState(() {
        _isRecording = success;
      });

      if (success) {
        // Also start location tracking
        RealLocationService.instance.startLocationTracking();

        // Log the stealth activation
        EmergencyService.instance.logIncident(
          'stealth_mode',
          metadata: {
            'description':
                'Fake power-off screen activated with secret recording',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      debugPrint('Error starting secret recording: $e');
    }
  }

  void _handleSecretTap() {
    final now = DateTime.now();

    // Reset tap count if too much time has passed
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 2) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTap = now;

    // Show secret menu after 7 taps in the top-left corner
    if (_tapCount >= 7) {
      setState(() {
        _showSecretMenu = true;
      });
      _tapCount = 0;
    }
  }

  void _exitFakeMode() {
    // Stop recording
    RecordingService.instance.stopEmergencyRecording();

    // Stop location tracking
    RealLocationService.instance.stopLocationTracking();

    // Exit fake mode
    widget.onExit?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main fake shutdown screen
          AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Fake device logo
                        AnimatedBuilder(
                          animation: _logoAnimation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _logoAnimation.value,
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.android,
                                    size: 80,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Powering off...',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Secret tap area (top-left corner)
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: _handleSecretTap,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.transparent,
              ),
            ),
          ),

          // Secret menu overlay
          if (_showSecretMenu)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.9),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.error, width: 2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'STEALTH MODE ACTIVE',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Recording status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isRecording
                                ? Icons.fiber_manual_record
                                : Icons.stop,
                            color: _isRecording
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isRecording
                                ? 'Recording Active'
                                : 'Recording Stopped',
                            style: TextStyle(
                              color: _isRecording
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showSecretMenu = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.7),
                              foregroundColor:
                                  Theme.of(context).colorScheme.surface,
                            ),
                            child: const Text('Hide'),
                          ),
                          ElevatedButton(
                            onPressed: _exitFakeMode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onError,
                            ),
                            child: const Text('Exit'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Instructions
                      Text(
                        'Tap top-left corner 7 times to show this menu',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Recording indicator (small red dot)
          if (_isRecording && !_showSecretMenu)
            Positioned(
              top: 50,
              right: 20,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class FakePowerOffService {
  static FakePowerOffService? _instance;
  static FakePowerOffService get instance {
    _instance ??= FakePowerOffService._();
    return _instance!;
  }

  FakePowerOffService._();

  bool _isActive = false;

  /// Check if fake power-off is active
  bool get isActive => _isActive;

  /// Activate fake power-off mode
  void activate() {
    _isActive = true;
  }

  /// Deactivate fake power-off mode
  void deactivate() {
    _isActive = false;
  }

  /// Show fake power-off screen
  void showFakePowerOff(BuildContext context) {
    _isActive = true;

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FakePowerOffScreen(
          onExit: () {
            _isActive = false;
            Navigator.of(context).pop();
          },
        ),
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }
}
