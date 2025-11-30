import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';

class EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCall;
  final VoidCallback? onSms;

  const EmergencyContactCard({
    super.key,
    required this.contact,
    this.onEdit,
    this.onDelete,
    this.onCall,
    this.onSms,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(contact.name),
                    if (contact.isPrimary) const SizedBox(width: 8),
                    if (contact.isPrimary)
                      const Icon(Icons.star, color: Colors.amber, size: 16)
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onEdit),
                    IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete)
                  ],
                )
              ],
            ),
            const SizedBox(height: 8),
            if (contact.phoneNumber.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Text(contact.phoneNumber)
                ],
              ),
            if (contact.email != null && contact.email!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(contact.email!)
                ],
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(contact.relationshipText),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: onSms, child: const Text('SMS')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: onCall, child: const Text('CALL'))
              ],
            )
          ],
        ),
      ),
    );
  }
}
