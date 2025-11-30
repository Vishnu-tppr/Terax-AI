import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:terax_ai_app/utils/theme/app_theme.dart';

class EmergencyCountdownScreen extends StatefulWidget {
  final int initialCountdown;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const EmergencyCountdownScreen({
    super.key,
    required this.initialCountdown,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  State<EmergencyCountdownScreen> createState() =>
      _EmergencyCountdownScreenState();
}

class _EmergencyCountdownScreenState extends State<EmergencyCountdownScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late int _countdownValue;

  @override
  void initState() {
    super.initState();
    _countdownValue = widget.initialCountdown;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = widget.initialCountdown; i > 0; i--) {
      if (mounted) {
        setState(() {
          _countdownValue = i;
        });
        HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1 + _animationController.value * 0.1,
                  child: Text(
                    '$_countdownValue',
                    style: const TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Emergency Alert Activating',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: widget.onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryRed,
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
