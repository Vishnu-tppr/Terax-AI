import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:terax_ai_app/services/sms_service.dart';

// Generate mocks
@GenerateMocks([Dio])
import 'sms_service_test.mocks.dart';

void main() {
  group('SmsService', () {
    late SmsService service;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      service = SmsService.instance;
      service.dio = mockDio;
    });

    group('Initialization', () {
      test('should initialize with backend configuration', () async {
        // Arrange
        const baseUrl = 'https://api.example.com';
        const apiKey = 'test_api_key';

        // Act
        await service.initialize(
          baseUrl: baseUrl,
          apiKey: apiKey,
          provider: SmsProvider.twilio,
        );

        // Assert
        expect(service.isInitialized, true);
        expect(service.baseUrl, baseUrl);
        expect(service.provider, SmsProvider.twilio);
      });
    });

    group('SMS Sending', () {
      setUp(() async {
        await service.initialize(
          baseUrl: 'https://api.example.com',
          apiKey: 'test_api_key',
        );
      });

      test('should send SMS successfully via backend', () async {
        // Arrange
        final recipients = ['+1234567890', '+0987654321'];
        const message = 'Test emergency message';
        
        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: {'message_id': 'msg_123', 'status': 'sent'},
                  statusCode: 200,
                  requestOptions: RequestOptions(path: ''),
                ));

        // Act
        final result = await service.sendSmsViaBackend(
          recipients: recipients,
          message: message,
        );

        // Assert
        expect(result.status, SmsDeliveryStatus.sent);
        expect(result.recipients, recipients);
        expect(result.message, message);
        expect(result.id, isNotEmpty);
      });

      test('should handle backend errors gracefully', () async {
        // Arrange
        final recipients = ['+1234567890'];
        const message = 'Test message';
        
        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                data: {'error': 'Rate limit exceeded'},
                statusCode: 429,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        // Act
        final result = await service.sendSmsViaBackend(
          recipients: recipients,
          message: message,
        );

        // Assert
        expect(result.status, SmsDeliveryStatus.failed);
        expect(result.errorMessage, contains('Rate limit exceeded'));
      });

      test('should send emergency SMS with location', () async {
        // Arrange
        final recipients = ['+1234567890'];
        const emergencyMessage = 'Emergency! I need help.';
        const latitude = 37.7749;
        const longitude = -122.4194;
        const locationName = 'San Francisco, CA';

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: {'message_id': 'emergency_123'},
                  statusCode: 200,
                  requestOptions: RequestOptions(path: ''),
                ));

        // Act
        final result = await service.sendEmergencySms(
          recipients: recipients,
          emergencyMessage: emergencyMessage,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
        );

        // Assert
        expect(result.status, SmsDeliveryStatus.sent);
        expect(result.message, contains(emergencyMessage));
        expect(result.message, contains('https://maps.google.com'));
        expect(result.message, contains(locationName));
        expect(result.metadata?['type'], 'emergency');
        expect(result.metadata?['latitude'], latitude);
        expect(result.metadata?['longitude'], longitude);
      });

      test('should send location sharing SMS', () async {
        // Arrange
        final recipients = ['+1234567890', '+0987654321'];
        const latitude = 40.7128;
        const longitude = -74.0060;
        const customMessage = 'Sharing my location for safety';

        when(mockDio.post(any, data: anyNamed('data')))
            .thenAnswer((_) async => Response(
                  data: {'message_id': 'location_123'},
                  statusCode: 200,
                  requestOptions: RequestOptions(path: ''),
                ));

        // Act
        final result = await service.sendLocationSms(
          recipients: recipients,
          latitude: latitude,
          longitude: longitude,
          customMessage: customMessage,
        );

        // Assert
        expect(result.status, SmsDeliveryStatus.sent);
        expect(result.message, contains(customMessage));
        expect(result.message, contains('https://maps.google.com'));
        expect(result.metadata?['type'], 'location_share');
      });
    });

    group('Phone Number Validation', () {
      test('should validate correct phone numbers', () {
        expect(SmsService.isValidPhoneNumber('+1234567890'), true);
        expect(SmsService.isValidPhoneNumber('+44123456789'), true);
        expect(SmsService.isValidPhoneNumber('1234567890'), true);
        expect(SmsService.isValidPhoneNumber('+91 98765 43210'), true);
      });

      test('should reject invalid phone numbers', () {
        expect(SmsService.isValidPhoneNumber(''), false);
        expect(SmsService.isValidPhoneNumber('123'), false);
        expect(SmsService.isValidPhoneNumber('abc123'), false);
        expect(SmsService.isValidPhoneNumber('+'), false);
        expect(SmsService.isValidPhoneNumber('++1234567890'), false);
      });
    });

    group('Phone Number Formatting', () {
      test('should format US phone numbers correctly', () {
        expect(
          SmsService.formatPhoneNumber('+12345678901'),
          '+1 (234) 567-8901',
        );
        expect(
          SmsService.formatPhoneNumber('2345678901'),
          '(234) 567-8901',
        );
      });

      test('should preserve international format', () {
        expect(
          SmsService.formatPhoneNumber('+441234567890'),
          '+441234567890',
        );
        expect(
          SmsService.formatPhoneNumber('+91987654321'),
          '+91987654321',
        );
      });

      test('should return original for unrecognized formats', () {
        const original = '123-456-7890';
        expect(SmsService.formatPhoneNumber(original), original);
      });
    });

    group('Service Status', () {
      test('should report uninitialized status', () {
        final newService = SmsService.instance;
        expect(newService.isInitialized, false);
      });

      test('should report initialized status', () async {
        await service.initialize(
          baseUrl: 'https://api.example.com',
          apiKey: 'test_key',
        );
        expect(service.isInitialized, true);
      });
    });

    group('Error Handling', () {
      test('should throw error when sending SMS without initialization', () async {
        final uninitializedService = SmsService.instance;
        
        expect(
          () async => await uninitializedService.sendSmsViaBackend(
            recipients: ['+1234567890'],
            message: 'Test',
          ),
          throwsException,
        );
      });

      test('should handle network errors gracefully', () async {
        // Arrange
        await service.initialize(
          baseUrl: 'https://api.example.com',
          apiKey: 'test_key',
        );

        when(mockDio.post(any, data: anyNamed('data')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        // Act
        final result = await service.sendSmsViaBackend(
          recipients: ['+1234567890'],
          message: 'Test message',
        );

        // Assert
        expect(result.status, SmsDeliveryStatus.failed);
        expect(result.errorMessage, isNotNull);
      });
    });

    group('SMS History and Status', () {
      setUp(() async {
        await service.initialize(
          baseUrl: 'https://api.example.com',
          apiKey: 'test_key',
        );
      });

      test('should check delivery status', () async {
        // Arrange
        const messageId = 'msg_123';
        
        when(mockDio.get('/v1/emergency/sms-status/$messageId'))
            .thenAnswer((_) async => Response(
                  data: {'status': 'delivered'},
                  statusCode: 200,
                  requestOptions: RequestOptions(path: ''),
                ));

        // Act
        final status = await service.checkDeliveryStatus(messageId);

        // Assert
        expect(status, SmsDeliveryStatus.delivered);
      });

      test('should get SMS history', () async {
        // Arrange
        when(mockDio.get(
          '/v1/emergency/sms-history',
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: {
                'messages': [
                  {
                    'id': 'msg_1',
                    'recipients': ['+1234567890'],
                    'message': 'Test message 1',
                    'timestamp': '2023-01-01T12:00:00Z',
                    'status': 'sent',
                  },
                  {
                    'id': 'msg_2',
                    'recipients': ['+0987654321'],
                    'message': 'Test message 2',
                    'timestamp': '2023-01-01T13:00:00Z',
                    'status': 'delivered',
                  },
                ]
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final history = await service.getSmsHistory(limit: 10);

        // Assert
        expect(history, hasLength(2));
        expect(history[0].id, 'msg_1');
        expect(history[1].id, 'msg_2');
      });
    });
  });
}