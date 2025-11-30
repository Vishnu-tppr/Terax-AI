import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:terax_ai_app/models/emergency_contact.dart';
import 'package:terax_ai_app/providers/contacts_provider.dart';
import 'package:terax_ai_app/utils/app_theme.dart';

class AddContactDialog extends StatefulWidget {
  final EmergencyContact? contactToEdit;

  const AddContactDialog({super.key, this.contactToEdit});

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  ContactRelationship _selectedRelationship = ContactRelationship.emergency;
  ContactPriority _selectedPriority = ContactPriority.one;
  bool _isPrimary = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.contactToEdit != null) {
      _nameController.text = widget.contactToEdit!.name;
      _phoneController.text = widget.contactToEdit!.phoneNumber;
      _emailController.text = widget.contactToEdit!.email ?? '';
      _selectedRelationship = widget.contactToEdit!.relationship;
      _selectedPriority = widget.contactToEdit!.priority;
      _isPrimary = widget.contactToEdit!.isPrimary;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final contactsProvider = context.read<ContactsProvider>();

      if (widget.contactToEdit != null) {
        // Edit existing contact
        contactsProvider.updateContact(
          EmergencyContact( // Construct EmergencyContact object
            id: widget.contactToEdit!.id,
            name: _nameController.text.trim(),
            phoneNumber: _phoneController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            relationship: _selectedRelationship,
            priority: _selectedPriority,
            notificationMethods: widget.contactToEdit!.notificationMethods, // Keep existing methods or update if needed
            isPrimary: _isPrimary,
            createdAt: widget.contactToEdit!.createdAt, // Preserve original creation/update times
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        // Add new contact
        final newContact = EmergencyContact(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate a unique ID
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          relationship: _selectedRelationship,
          priority: _selectedPriority,
          notificationMethods: [
            NotificationMethod.sms,
            NotificationMethod.call,
          ],
          isPrimary: _isPrimary,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        contactsProvider.addContact(newContact);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _importFromContacts() async {
    // Show a message that this feature will be available in a future update
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Import from contacts feature coming soon!'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.neutral200)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.contactToEdit != null
                        ? 'Edit Contact'
                        : 'Add Contact',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.neutral800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.neutral600),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Import from Contacts Button
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: OutlinedButton.icon(
                          onPressed: _importFromContacts,
                          icon: const Icon(Icons.contacts, size: 20),
                          label: const Text('Import from Contacts'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryRed,
                            side: const BorderSide(color: AppTheme.primaryRed),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Enter full name',
                          labelStyle: const TextStyle(
                            color: AppTheme.neutral500,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.neutral300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryRed),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Phone Number Field
                      const Text(
                        'Phone Number *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.neutral800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          hintStyle: const TextStyle(
                            color: AppTheme.neutral400,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.neutral300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryRed),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.neutral800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter email address',
                          hintStyle: const TextStyle(
                            color: AppTheme.neutral400,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.neutral300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryRed),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Relationship Selection
                      const Text(
                        'Relationship *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.neutral800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildRelationshipChip('Emergency Contact',
                              ContactRelationship.emergency),
                          const SizedBox(width: 12),
                          _buildRelationshipChip(
                              'Family', ContactRelationship.family),
                          const SizedBox(width: 12),
                          _buildRelationshipChip(
                              'Friend', ContactRelationship.friend),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Priority Level
                      const Text(
                        'Priority Level (1-5)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.neutral800,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (int i = 1; i <= 5; i++)
                            Padding(
                              padding: EdgeInsets.only(right: i < 5 ? 12 : 0),
                              child: _buildPriorityButton(i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Primary Contact Toggle
                      Row(
                        children: [
                          const Text(
                            'Set as Primary Contact',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.neutral800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _isPrimary,
                            onChanged: (value) =>
                                setState(() => _isPrimary = value),
                            activeColor: AppTheme.primaryRed,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.neutral200)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.contactToEdit != null
                              ? 'Update Contact'
                              : 'Add Contact',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipChip(
      String label, ContactRelationship relationship) {
    final isSelected = _selectedRelationship == relationship;
    return GestureDetector(
      onTap: () => setState(() => _selectedRelationship = relationship),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryRed.withValues(alpha: 0.1)
              : AppTheme.neutral100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryRed : AppTheme.neutral300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppTheme.primaryRed : AppTheme.neutral600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(int priority) {
    final isSelected = _selectedPriority.index + 1 == priority;
    return GestureDetector(
      onTap: () => setState(
          () => _selectedPriority = ContactPriority.values[priority - 1]),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : AppTheme.neutral200,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            priority.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : AppTheme.neutral600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }
}
