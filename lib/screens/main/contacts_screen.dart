import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terax_ai_app/models/emergency_contact.dart';
import 'package:terax_ai_app/providers/contacts_provider.dart';
import 'package:terax_ai_app/utils/app_theme.dart';
import 'package:terax_ai_app/widgets/add_contact_dialog.dart';
import 'package:terax_ai_app/widgets/loading_animation.dart';

import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contactsProvider = context.watch<ContactsProvider>();
    final contacts = contactsProvider.contacts;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      _showAddContactDialog(context);
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const Text(
                'People to notify in case of emergency',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.neutral600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),

              // Contacts List
              Expanded(
                child: contacts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return SlideInAnimation(
                            begin: Offset(1.0, 0.0),
                            duration:
                                Duration(milliseconds: 300 + (index * 100)),
                            child: _buildContactCard(contact, context),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.neutral100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.contacts_outlined,
              size: 40,
              color: AppTheme.neutral500,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Emergency Contacts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.neutral800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add trusted contacts who will be notified\nin case of an emergency',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.neutral600,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, BuildContext context) {
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
            // Header with name and star
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.neutral800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (contact.isPrimary) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppTheme.warningColor,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditContactDialog(context, contact);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, contact);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outlined,
                              size: 16, color: AppTheme.primaryRed),
                          SizedBox(width: 8),
                          Text('Delete',
                              style: TextStyle(color: AppTheme.primaryRed)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                    color: AppTheme.neutral500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Phone number
            Row(
              children: [
                const Icon(
                  Icons.phone,
                  size: 16,
                  color: AppTheme.neutral500,
                ),
                const SizedBox(width: 8),
                Text(
                  contact.phoneNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.neutral600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),

            if (contact.email != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.email,
                    size: 16,
                    color: AppTheme.neutral500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    contact.email!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.neutral600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Relationship and priority
            Text(
              '${contact.relationshipText} • Priority ${contact.priorityText}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.neutral500,
                fontFamily: 'Poppins',
              ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sendSMS(context, contact),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SMS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _makeCall(context, contact),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CALL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddContactDialog(),
    );
  }

  void _showEditContactDialog(BuildContext context, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(contactToEdit: contact),
    );
  }

  void _showDeleteConfirmation(BuildContext context, EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ContactsProvider>().removeContact(contact.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSMS(BuildContext context, EmergencyContact contact) async {
    try {
      final message =
          'Emergency alert from Terax AI Safety App. I need help! Please contact me immediately.';

      final Uri smsUri = Uri(
        scheme: 'sms',
        path: contact.phoneNumber,
        queryParameters: {'body': message},
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency SMS sent to ${contact.name}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending SMS: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }

  Future<void> _makeCall(BuildContext context, EmergencyContact contact) async {
    try {
      final phoneUrl = Uri.parse('tel:${contact.phoneNumber}');

      if (await canLaunchUrl(phoneUrl)) {
        await launchUrl(phoneUrl);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Calling ${contact.name}...'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot make call to ${contact.name}'),
              backgroundColor: AppTheme.primaryRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
      }
    }
  }
}
