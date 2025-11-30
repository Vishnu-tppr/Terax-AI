import 'package:flutter/material.dart';
import 'package:terax_ai_app/utils/app_theme.dart';
import 'package:terax_ai_app/widgets/custom_icon_widget.dart';
import 'settings_section_widget.dart';

class BackupRestoreWidget extends StatelessWidget {
  const BackupRestoreWidget({super.key});

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Cloud Backup'),
        content: const Text(
            'This will back up your settings, emergency contacts, and safe zones to the cloud. Your recordings and history will not be included. Continue?'),
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
                  content: Text('Cloud backup created successfully'),
                  backgroundColor: AppTheme.safeStateGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusBlue,
            ),
            child: const Text('Backup Now'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Cloud'),
        content: const Text(
            'This will restore your settings from the latest cloud backup. This will overwrite your current settings. Continue?'),
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
                  content: Text('Settings restored from cloud backup'),
                  backgroundColor: AppTheme.safeStateGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryEmergency,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWidget(
      title: 'Backup & Restore',
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(7, 93, 194, 0.1),
              shape: BoxShape.circle,
            ),
            child: const CustomIconWidget(
              assetPath: 'assets/icons/cloud_upload.svg',
              size: 20,
            ),
          ),
          title: Text(
            'Cloud Backup',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            'Last backup: 2 days ago',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: ElevatedButton(
            onPressed: () => _showBackupDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Backup'),
          ),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(39, 174, 96, 0.1),
              shape: BoxShape.circle,
            ),
            child: const CustomIconWidget(
              assetPath: 'assets/icons/cloud_download.svg',
              size: 20,
            ),
          ),
          title: Text(
            'Restore from Backup',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            'Restore settings from the cloud',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          trailing: ElevatedButton(
            onPressed: () => _showRestoreDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.safeStateGreen,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Restore'),
          ),
        ),
      ],
    );
  }
}
