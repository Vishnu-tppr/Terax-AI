import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:terax_ai_app/models/emergency_contact.dart';
import 'package:terax_ai_app/providers/contacts_provider.dart';
import 'package:terax_ai_app/widgets/custom_app_bar.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  ContactRelationship _selectedRelationship = ContactRelationship.emergency;
  ContactPriority _selectedPriority = ContactPriority.one;
  bool _isPrimary = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addContact() async {
    if (!_formKey.currentState!.validate()) return;

    final contactsProvider = context.read<ContactsProvider>();

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

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Add Contact'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number *'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              Text(
                'Relationship *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ContactRelationship.values.map((relationship) {
                  return ChoiceChip(
                    label: Text(relationship.toString().split('.').last),
                    selected: _selectedRelationship == relationship,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedRelationship = relationship;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Priority Level (1-5)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ContactPriority.values.map((priority) {
                  return ChoiceChip(
                    label: Text(priority.toString().split('.').last),
                    selected: _selectedPriority == priority,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedPriority = priority;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Set as Primary Contact'),
                value: _isPrimary,
                onChanged: (value) {
                  setState(() {
                    _isPrimary = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addContact,
                  child: const Text('Add Contact'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
