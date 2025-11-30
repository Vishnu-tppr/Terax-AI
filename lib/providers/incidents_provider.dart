import 'package:flutter/material.dart';
import 'package:terax_ai_app/models/emergency_contact.dart';
import 'package:terax_ai_app/models/emergency_incident.dart';

class IncidentsProvider with ChangeNotifier {
  final List<EmergencyIncident> _incidents = [];
  final List<EmergencyContact> _contacts = [];

  List<EmergencyIncident> get incidents => _incidents;
  List<EmergencyContact> get contacts => _contacts;

  void addIncident(EmergencyIncident incident) {
    _incidents.add(incident);
    notifyListeners();
  }

  void addContact(EmergencyContact contact) {
    _contacts.add(contact);
    notifyListeners();
  }

  void removeIncident(String id) {
    _incidents.removeWhere((incident) => incident.id == id);
    notifyListeners();
  }

  void removeContact(String id) {
    _contacts.removeWhere((contact) => contact.id == id);
    notifyListeners();
  }
}