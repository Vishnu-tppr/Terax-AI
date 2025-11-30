import 'package:flutter/foundation.dart';
import '../models/emergency_contact.dart';

class ContactsProvider extends ChangeNotifier {
  final List<EmergencyContact> _contacts = [];

  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);

  void addContact(EmergencyContact contact) {
    // ensure only one primary
    if (contact.isPrimary) {
      for (var i = 0; i < _contacts.length; i++) {
        if (_contacts[i].isPrimary) {
          _contacts[i] = _contacts[i].copyWith(isPrimary: false);
        }
      }
    }
    _contacts.add(contact);
    _sortByPriority();
    notifyListeners();
  }

  void updateContact(EmergencyContact contact) {
    final idx = _contacts.indexWhere((c) => c.id == contact.id);
    if (idx != -1) {
      if (contact.isPrimary) {
        for (var i = 0; i < _contacts.length; i++) {
          if (_contacts[i].isPrimary) {
            _contacts[i] = _contacts[i].copyWith(isPrimary: false);
          }
        }
      }
      _contacts[idx] = contact;
      _sortByPriority();
      notifyListeners();
    }
  }

  void removeContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void _sortByPriority() {
    // Lower number = higher priority
    _contacts.sort((a, b) => a.priority.compareTo(b.priority));
  }
}
