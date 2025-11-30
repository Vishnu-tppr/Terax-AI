import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terax_ai_app/models/emergency_incident.dart';
import 'package:terax_ai_app/providers/incidents_provider.dart';
import 'package:terax_ai_app/utils/app_theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incidentsProvider = context.watch<IncidentsProvider>();
    final incidents = incidentsProvider.incidents;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Emergency incident logs',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutral600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.neutral100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: const EdgeInsets.all(4),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppTheme.neutral600,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('All'),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _tabController.index == 0
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : AppTheme.primaryRed
                                          .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${incidents.length}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _tabController.index == 0
                                        ? Colors.white
                                        : AppTheme.primaryRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Tab(text: 'Active'),
                        const Tab(text: 'Resolved'),
                        const Tab(text: 'Failed'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIncidentList(incidents),
                  _buildIncidentList(incidents
                      .where((i) => i.status == IncidentStatus.active)
                      .toList()),
                  _buildIncidentList(incidents
                      .where((i) => i.status == IncidentStatus.resolved)
                      .toList()),
                  _buildIncidentList(incidents
                      .where((i) => i.status == IncidentStatus.failed)
                      .toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentList(List<EmergencyIncident> incidents) {
    if (incidents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: AppTheme.neutral400,
              ),
              SizedBox(height: 16),
              Text(
                'No Activity Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neutral700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Emergency incidents will be logged here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral500,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: incidents.length,
      itemBuilder: (context, index) {
        final incident = incidents[index];
        return IncidentCard(incident: incident);
      },
    );
  }
}

class IncidentCard extends StatelessWidget {
  final EmergencyIncident incident;

  const IncidentCard({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppTheme.primaryRed,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.warning,
                    size: 16,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    incident.triggerTypeText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.neutral800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        _getStatusColor(incident.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    incident.statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(incident.status),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              incident.description ?? 'No description available',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.neutral700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.neutral500,
                ),
                const SizedBox(width: 8),
                Text(
                  incident.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            if (incident.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppTheme.neutral500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    incident.location!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.neutral500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: AppTheme.neutral500,
                ),
                const SizedBox(width: 8),
                Text(
                  '${incident.contactsNotified ?? 0} contacts notified',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.neutral500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.active:
        return AppTheme.primaryRed;
      case IncidentStatus.resolved:
        return AppTheme.successColor;
      case IncidentStatus.failed:
        return AppTheme.warningColor;
    }
  }
}
