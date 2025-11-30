import 'package:flutter/material.dart';
import 'package:terax_ai_app/services/countdown_service.dart';
import 'package:terax_ai_app/utils/app_theme.dart';

class CountdownWidget extends StatefulWidget {
  final Function()? onComplete;
  final Function()? onCancel;

  const CountdownWidget({
    super.key,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CountdownEvent>(
      stream: CountdownService.instance.countdownStream,
      builder: (context, snapshot) {
        final isActive = CountdownService.instance.isActive;
        final remainingSeconds = CountdownService.instance.remainingSeconds;
        final progress = CountdownService.instance.progress;

        if (!isActive) {
          return const SizedBox.shrink();
        }

        // Update progress animation
        _progressController.animateTo(progress);

        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: (0.8 * 255).toDouble()),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emergency text
                const Text(
                  'EMERGENCY MODE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Countdown circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: remainingSeconds <= 3 ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: remainingSeconds <= 3 
                                ? AppTheme.primaryRed 
                                : AppTheme.warningAmber,
                            width: 8,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Progress indicator
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: _progressAnimation.value,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    remainingSeconds <= 3 
                                        ? AppTheme.primaryRed 
                                        : AppTheme.warningAmber,
                                  ),
                                );
                              },
                            ),
                            
                            // Countdown number
                            Center(
                              child: Text(
                                '$remainingSeconds',
                                style: TextStyle(
                                  color: remainingSeconds <= 3 
                                      ? AppTheme.primaryRed 
                                      : Colors.white,
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Message
                Text(
                  remainingSeconds <= 3 
                      ? 'ACTIVATING EMERGENCY...' 
                      : 'Tap CANCEL to stop',
                  style: TextStyle(
                    color: remainingSeconds <= 3 
                        ? AppTheme.primaryRed 
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Cancel button (only show if more than 1 second remaining)
                if (remainingSeconds > 1)
                  SizedBox(
                    width: 200,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {
                        CountdownService.instance.cancelCountdown();
                        widget.onCancel?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CountdownOverlay extends StatelessWidget {
  final Widget child;
  final Function()? onEmergencyActivated;

  const CountdownOverlay({
    super.key,
    required this.child,
    this.onEmergencyActivated,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        StreamBuilder<CountdownEvent>(
          stream: CountdownService.instance.countdownStream,
          builder: (context, snapshot) {
            final isActive = CountdownService.instance.isActive;
            
            if (!isActive) {
              return const SizedBox.shrink();
            }

            return CountdownWidget(
              onComplete: onEmergencyActivated,
              onCancel: () {
                // Handle cancel if needed
              },
            );
          },
        ),
      ],
    );
  }
}
