import 'package:flutter/foundation.dart';
import 'package:terax_ai_app/models/safe_zone.dart';

class SafeZonesProvider extends ChangeNotifier {
  final List<SafeZone> _safeZones = [
    SafeZone(
      id: '1',
      name: 'Home',
      address: '123 Main Street, City, State',
      latitude: 40.7128,
      longitude: -74.0060,
      radius: 100.0,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    SafeZone(
      id: '2',
      name: 'Work Office',
      address: '456 Business Ave, Downtown',
      latitude: 40.7589,
      longitude: -73.9851,
      radius: 150.0,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    SafeZone(
      id: '3',
      name: 'Gym',
      address: '789 Fitness Blvd, Sports Center',
      latitude: 40.7505,
      longitude: -73.9934,
      radius: 75.0,
      isActive: false,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
  ];

  List<SafeZone> get safeZones => _safeZones;

  void addSafeZone(SafeZone zone) {
    _safeZones.add(zone);
    notifyListeners();
  }

  void updateSafeZone(SafeZone zone) {
    final index = _safeZones.indexWhere((z) => z.id == zone.id);
    if (index != -1) {
      _safeZones[index] = zone;
      notifyListeners();
    }
  }

  void deleteSafeZone(String id) {
    _safeZones.removeWhere((zone) => zone.id == id);
    notifyListeners();
  }

  void toggleSafeZone(String id, bool value) {
    final index = _safeZones.indexWhere((zone) => zone.id == id);
    if (index != -1) {
      _safeZones[index] = _safeZones[index].copyWith(isActive: value);
      notifyListeners();
    }
  }
}
