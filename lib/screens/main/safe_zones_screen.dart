import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terax_ai_app/models/safe_zone.dart';
import 'package:terax_ai_app/providers/safe_zones_provider.dart';
import 'package:terax_ai_app/utils/theme/app_theme.dart';
import 'package:terax_ai_app/widgets/add_zone_dialog.dart';
import 'package:terax_ai_app/widgets/custom_app_bar.dart';
import 'package:terax_ai_app/widgets/empty_state.dart';
import 'package:terax_ai_app/widgets/safe_zone_card.dart';
import 'package:terax_ai_app/widgets/stat_card.dart';

class SafeZonesScreen extends StatelessWidget {
  const SafeZonesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final safeZonesProvider = Provider.of<SafeZonesProvider>(context);
    final safeZones = safeZonesProvider.safeZones;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'Safe Zones'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monitor your safety in designated areas',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightTextSecondary,
                    ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Active Zones',
                      value: safeZones
                          .where((zone) => zone.isActive)
                          .length
                          .toString(),
                      icon: Icons.location_on,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Total Zones',
                      value: safeZones.length.toString(),
                      icon: Icons.map,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: safeZones.isEmpty
                    ? const EmptyState(
                        assetPath: 'assets/images/no_zones.svg',
                        title: 'No Safe Zones Yet',
                        message: 'Add your first safe zone to start monitoring',
                      )
                    : ListView.builder(
                        itemCount: safeZones.length,
                        itemBuilder: (context, index) {
                          final zone = safeZones[index];
                          return SafeZoneCard(
                            zone: zone,
                            onToggle: (value) => safeZonesProvider
                                .toggleSafeZone(zone.id, value),
                            onEdit: () =>
                                _showAddZoneDialog(context, zoneToEdit: zone),
                            onDelete: () => _deleteZone(context, zone.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddZoneDialog(context),
        backgroundColor: AppTheme.primaryRed,
        icon: const Icon(Icons.add_location, color: Colors.white),
        label: const Text(
          'Add Zone',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _deleteZone(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Safe Zone'),
        content: const Text('Are you sure you want to delete this safe zone?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<SafeZonesProvider>(context, listen: false)
                  .deleteSafeZone(id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Safe zone deleted'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddZoneDialog(BuildContext context, {SafeZone? zoneToEdit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddZoneDialog(
        zone: zoneToEdit,
        onSave: (newZone) {
          if (zoneToEdit != null) {
            Provider.of<SafeZonesProvider>(context, listen: false)
                .updateSafeZone(newZone);
          } else {
            Provider.of<SafeZonesProvider>(context, listen: false)
                .addSafeZone(newZone);
          }
        },
      ),
    );
  }
}
