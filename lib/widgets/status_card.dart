import 'package:flutter/material.dart';
import 'package:terax_ai_app/widgets/custom_icon_widget.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String? status;
  final String assetPath;
  final Color? color;
  final bool? isActive;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.title,
    this.status,
    required this.assetPath,
    this.color,
    this.isActive,
    this.onTap,
  });

  Color _getColor(BuildContext context) {
    if (color != null) return color!;
    if (isActive == true) return Colors.green;
    if (isActive == false) return Colors.red;
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
  }

  String get _status {
    if (status != null) return status!;
    if (isActive == true) return 'Active';
    if (isActive == false) return 'Inactive';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getColor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor.withAlpha((255 * 0.1).round()),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardColor.withAlpha((255 * 0.3).round()),
          ),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              assetPath: assetPath,
              size: 32,
              color: cardColor,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cardColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              _status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cardColor.withAlpha((255 * 0.8).round()),
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            if (onTap != null) ...[
              const SizedBox(height: 8),
              Icon(
                Icons.touch_app,
                size: 16,
                color: cardColor.withAlpha((255 * 0.6).round()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
