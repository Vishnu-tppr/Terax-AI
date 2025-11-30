import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class EmergencyButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;
  final Animation<double> pulseAnimation;
  final Animation<double> emergencyAnimation;

  const EmergencyButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    required this.pulseAnimation,
    required this.emergencyAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([pulseAnimation, emergencyAnimation]),
        builder: (context, child) {
          final scale = isActive 
              ? emergencyAnimation.value 
              : pulseAnimation.value;
          
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onLongPress: onPressed,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: isActive 
                      ? AppTheme.primaryGradient
                      : AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryRed.withAlpha((255 * 0.3).round()),
                      blurRadius: isActive ? 40 : 30,
                      offset: const Offset(0, 15),
                      spreadRadius: isActive ? 5 : 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPressed,
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha((255 * 0.3).round()),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isActive ? Icons.warning_rounded : Icons.shield,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isActive ? 'ACTIVE' : 'EMERGENCY',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (isActive) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Help is on the way',
                                style: TextStyle(
                                  color: Colors.white.withAlpha((255 * 0.9).round()),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}