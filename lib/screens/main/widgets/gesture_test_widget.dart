import 'package:flutter/material.dart';
import 'package:terax_ai_app/utils/app_theme.dart';
import 'package:terax_ai_app/widgets/custom_icon_widget.dart';

class GestureTestWidget extends StatelessWidget {
  final double shakeThreshold;
  final double tapSensitivity;

  const GestureTestWidget({
    super.key,
    this.shakeThreshold = 12.0,
    this.tapSensitivity = 0.8,
  });

  void _showTestDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGray, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CustomIconWidget(
                assetPath: 'assets/icons/science.svg',
                color: AppTheme.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Test Your Gestures',
                style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Test the current sensitivity settings for shake and tap gestures to ensure they work for you.',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showTestDialog(
                  context,
                  'Testing Shake Gesture',
                  'Shake your device 3 times firmly to trigger the test alert. Current threshold: ${shakeThreshold.toStringAsFixed(1)}',
                ),
                icon: const CustomIconWidget(
                  assetPath: 'assets/icons/vibration.svg',
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text('Test Shake'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.safeStateGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showTestDialog(
                  context,
                  'Testing Tap Gesture',
                  'Tap your device 5 times firmly in your pocket or hand to trigger the test alert. Current sensitivity: ${(tapSensitivity * 100).toInt()}% ',
                ),
                icon: const CustomIconWidget(
                  assetPath: 'assets/icons/touch_app.svg',
                  color: Colors.white,
                  size: 16,
                ),
                label: const Text('Test Tap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.safeStateGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
