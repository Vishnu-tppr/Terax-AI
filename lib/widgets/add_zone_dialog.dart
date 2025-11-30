import 'package:flutter/material.dart';
import 'package:terax_ai_app/models/safe_zone.dart';

class AddZoneDialog extends StatefulWidget {
  final SafeZone? zone;
  final Function(SafeZone) onSave;

  const AddZoneDialog({super.key, this.zone, required this.onSave});

  @override
  State<AddZoneDialog> createState() => _AddZoneDialogState();
}

class _AddZoneDialogState extends State<AddZoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _address;
  late double _radius;

  @override
  void initState() {
    super.initState();
    _name = widget.zone?.name ?? '';
    _address = widget.zone?.address ?? '';
    _radius = widget.zone?.radius ?? 100.0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.zone == null ? 'Add Safe Zone' : 'Edit Safe Zone'),
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
              onSaved: (value) => _name = value!,
            ),
            TextFormField(
              initialValue: _address,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
              onSaved: (value) => _address = value!,
            ),
            TextFormField(
              initialValue: _radius.toString(),
              decoration: const InputDecoration(labelText: 'Radius (in meters)'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || double.tryParse(value) == null) {
                  return 'Please enter a valid radius';
                }
                return null;
              },
              onSaved: (value) => _radius = double.parse(value!),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final newZone = SafeZone(
                    id: widget.zone?.id ?? DateTime.now().toString(),
                    name: _name,
                    address: _address,
                    latitude: 0, // Replace with actual latitude
                    longitude: 0, // Replace with actual longitude
                    radius: _radius,
                    isActive: widget.zone?.isActive ?? true,
                    createdAt: widget.zone?.createdAt ?? DateTime.now(),
                  );
                  widget.onSave(newZone);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
