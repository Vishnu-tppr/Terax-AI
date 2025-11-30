import 'package:flutter/material.dart';
import 'package:terax_ai_app/widgets/custom_icon_widget.dart';

class SettingsActionWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String assetPath;
  final Color? iconColor;
  final bool isDestructive;
  final bool showArrow;

  const SettingsActionWidget({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.onTap,
    this.assetPath = '',
    this.iconColor,
    this.isDestructive = false,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDestructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.onSurface;
    final subtitleColor = isDestructive
        ? Theme.of(context).colorScheme.error.withValues(alpha: 0.8)
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
    final bgColor = iconColor ?? Theme.of(context).colorScheme.primary;
    final iconBgColor = bgColor.withValues(alpha: 0.1);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: assetPath.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                assetPath: assetPath,
                size: 20,
              ),
            )
          : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: titleColor,
            ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: subtitleColor,
                  ),
            )
          : null,
      trailing: showArrow
          ? const CustomIconWidget(
              assetPath: 'assets/icons/arrow_forward_ios.svg',
              size: 16,
            )
          : null,
      onTap: onTap,
    );
  }
}
