import 'package:flutter_test/flutter_test.dart';
import 'package:terax_ai_app/models/emergency_incident.dart';

void main() {
  group('EmergencyIncident.fromJson', () {
    test('should parse timestamp from ISO string', () {
      final json = {
        'id': 'test-123',
        'timestamp': '2024-09-07T10:30:00.000Z',
        'triggerType': 'button',
        'status': 'active',
        'description': 'Test incident',
        'resolvedAt': '2024-09-07T11:30:00.000Z',
        'triggeredAt': '2024-09-07T10:30:00.000Z',
        'contactsNotified': 2,
        'contactIds': ['contact-1', 'contact-2'],
        'notes': 'Test notes'
      };

      final incident = EmergencyIncident.fromJson(json);

      expect(incident.id, 'test-123');
      expect(incident.timestamp.year, 2024);
      expect(incident.timestamp.month, 9);
      expect(incident.timestamp.day, 7);
      expect(incident.notes, 'Test notes');
      expect(incident.statusText, 'Active');
      expect(incident.timeAgo.contains('ago'), true);
    });

    test('should parse timestamp from milliseconds since epoch (int)', () {
      const timestamp = 1723127400000; // 2024-08-08T12:30:00.000Z in milliseconds
      const triggeredAt = 1723127400000;
      const resolvedAt = 1723129200000; // 1 hour later

      final json = {
        'id': 'test-456',
        'timestamp': timestamp,
        'triggerType': 'voice',
        'status': 'resolved',
        'description': 'Voice triggered incident',
        'triggeredAt': triggeredAt,
        'resolvedAt': resolvedAt
      };

      final incident = EmergencyIncident.fromJson(json);

      expect(incident.id, 'test-456');
      expect(incident.timestamp.year, 2024);
      expect(incident.timestamp.month, 8);
      expect(incident.timestamp.day, 8);
      expect(incident.triggerTypeText, 'Voice Command');
      expect(incident.status, IncidentStatus.resolved);
      expect(incident.resolvedAt, isNotNull);
      expect(incident.resolvedAt!.isAfter(incident.timestamp), true);
    });

    test('should handle nullable fields correctly', () {
      final json = {
        'id': 'test-789',
        'timestamp': 1723127400000,
        'triggerType': 'gesture',
        'status': 'active'
      };

      final incident = EmergencyIncident.fromJson(json);

      expect(incident.location, null);
      expect(incident.notes, null);
      expect(incident.contactsNotified, null);
      expect(incident.contactIds, null);
    });

    test('should throw FormatException for invalid timestamp format', () {
      final json = {
        'id': 'test-invalid',
        'timestamp': 'invalid-timestamp',
        'triggerType': 'button',
        'status': 'active'
      };

      expect(() => EmergencyIncident.fromJson(json),
          throwsA(isA<FormatException>()));
    });
  });

  group('EmergencyIncident getters', () {
    late EmergencyIncident incident;

    setUp(() {
      incident = EmergencyIncident(
        id: 'test-xyz',
        timestamp: DateTime.parse('2024-09-07T10:30:00.000Z'),
        triggerType: TriggerType.gesture,
        status: IncidentStatus.failed,
      );
    });

    test('statusText should return correct string', () {
      expect(incident.statusText, 'Failed');
    });

    test('triggerTypeText should return correct string', () {
      expect(incident.triggerTypeText, 'Gesture Detected');
    });

    test('timeAgo should work for recent incident', () {
      final recentIncident = EmergencyIncident(
        id: 'recent',
        timestamp: DateTime.now(),
        triggerType: TriggerType.button,
        status: IncidentStatus.active,
      );
      expect(recentIncident.timeAgo, 'Just now');
    });

    test('copyWith should create modified copy', () {
      final copied = incident.copyWith(
        status: IncidentStatus.resolved,
        notes: 'Updated notes'
      );

      expect(copied.id, incident.id);
      expect(copied.status, IncidentStatus.resolved);
      expect(copied.notes, 'Updated notes');
      expect(copied.timestamp, incident.timestamp);
    });
  });
}
