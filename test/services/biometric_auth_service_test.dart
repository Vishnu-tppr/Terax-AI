import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:terax_ai_app/services/biometric_auth_service.dart';

// Generate mocks
@GenerateMocks([LocalAuthentication, FlutterSecureStorage])
import 'biometric_auth_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('BiometricAuthService', () {
    late BiometricAuthService service;
    late MockLocalAuthentication mockLocalAuth;
    late MockFlutterSecureStorage mockSecureStorage;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      mockSecureStorage = MockFlutterSecureStorage();
      service = BiometricAuthService.instance;
      service.auth = mockLocalAuth;
      service.storage = mockSecureStorage;
    });

    group('Biometric Availability', () {
      test('should return true when biometrics are available', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);

        // Act
        final result = await service.isBiometricAvailable();

        // Assert
        expect(result, true);
        verify(mockLocalAuth.canCheckBiometrics).called(1);
        verify(mockLocalAuth.isDeviceSupported()).called(1);
      });

      test('should return false when biometrics are not available', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);

        // Act
        final result = await service.isBiometricAvailable();

        // Assert
        expect(result, false);
      });

      test('should return false when device is not supported', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await service.isBiometricAvailable();

        // Assert
        expect(result, false);
      });
    });

    group('PIN Management', () {
      test('should setup PIN successfully with valid input', () async {
        // Arrange
        const pin = '1234';
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        final result = await service.setupPin(pin);

        // Assert
        expect(result, true);
        verify(mockSecureStorage.write(
          key: 'biometric_pin_hash',
          value: anyNamed('value'),
        )).called(1);
        verify(mockSecureStorage.write(
          key: 'biometric_pin_salt',
          value: anyNamed('value'),
        )).called(1);
      });

      test('should fail to setup PIN with invalid length', () async {
        // Arrange
        const shortPin = '12';
        const longPin = '1234567';

        // Act
        final shortResult = await service.setupPin(shortPin);
        final longResult = await service.setupPin(longPin);

        // Assert
        expect(shortResult, false);
        expect(longResult, false);
        verifyNever(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')));
      });

      test('should verify correct PIN', () async {
        // Arrange
        const pin = '1234';
        const salt = 'test_salt';
        const hashedPin = 'hashed_pin_value';

        when(mockSecureStorage.read(key: 'biometric_pin_hash'))
            .thenAnswer((_) async => hashedPin);
        when(mockSecureStorage.read(key: 'biometric_pin_salt'))
            .thenAnswer((_) async => salt);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // First setup the PIN
        await service.setupPin(pin);

        // Act
        final result = await service.verifyPin(pin);

        // Assert
        expect(result, BiometricAuthResult.success);
      });

      test('should reject incorrect PIN', () async {
        // Arrange
        const correctPin = '1234';
        const incorrectPin = '5678';
        const salt = 'test_salt';

        // Setup PIN first
        await service.setupPin(correctPin);

        when(mockSecureStorage.read(key: 'biometric_pin_hash'))
            .thenAnswer((_) async => 'correct_hash');
        when(mockSecureStorage.read(key: 'biometric_pin_salt'))
            .thenAnswer((_) async => salt);
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        final result = await service.verifyPin(incorrectPin);

        // Assert
        expect(result, BiometricAuthResult.pinIncorrect);
      });

      test('should check if PIN is setup', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'biometric_pin_hash'))
            .thenAnswer((_) async => 'some_hash');

        // Act
        final result = await service.isPinSetup();

        // Assert
        expect(result, true);
        verify(mockSecureStorage.read(key: 'biometric_pin_hash')).called(1);
      });

      test('should return false when PIN is not setup', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'biometric_pin_hash'))
            .thenAnswer((_) async => null);

        // Act
        final result = await service.isPinSetup();

        // Assert
        expect(result, false);
      });
    });

    group('Biometric Settings', () {
      test('should enable biometric authentication', () async {
        // Arrange
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await service.setBiometricEnabled(true);

        // Assert
        verify(mockSecureStorage.write(
          key: 'biometric_enabled',
          value: 'true',
        )).called(1);
      });

      test('should disable biometric authentication', () async {
        // Arrange
        when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenAnswer((_) async {});

        // Act
        await service.setBiometricEnabled(false);

        // Assert
        verify(mockSecureStorage.write(
          key: 'biometric_enabled',
          value: 'false',
        )).called(1);
      });

      test('should check if biometric is enabled', () async {
        // Arrange
        when(mockSecureStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'true');

        // Act
        final result = await service.isBiometricEnabled();

        // Assert
        expect(result, true);
        verify(mockSecureStorage.read(key: 'biometric_enabled')).called(1);
      });
    });

    group('Data Management', () {
      test('should remove PIN data', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await service.removePin();

        // Assert
        verify(mockSecureStorage.delete(key: 'biometric_pin_hash')).called(1);
        verify(mockSecureStorage.delete(key: 'biometric_pin_salt')).called(1);
      });

      test('should clear all biometric data', () async {
        // Arrange
        when(mockSecureStorage.delete(key: anyNamed('key')))
            .thenAnswer((_) async {});

        // Act
        await service.clearAllData();

        // Assert
        verify(mockSecureStorage.delete(key: 'biometric_pin_hash')).called(1);
        verify(mockSecureStorage.delete(key: 'biometric_pin_salt')).called(1);
        verify(mockSecureStorage.delete(key: 'biometric_enabled')).called(1);
      });
    });

    group('Result Messages', () {
      test('should return correct messages for each result type', () {
        expect(
          BiometricAuthService.getResultMessage(BiometricAuthResult.success),
          'Authentication successful',
        );
        expect(
          BiometricAuthService.getResultMessage(BiometricAuthResult.failed),
          'Authentication failed',
        );
        expect(
          BiometricAuthService.getResultMessage(BiometricAuthResult.notAvailable),
          'Biometric authentication not available',
        );
        expect(
          BiometricAuthService.getResultMessage(BiometricAuthResult.cancelled),
          'Authentication cancelled',
        );
        expect(
          BiometricAuthService.getResultMessage(BiometricAuthResult.pinIncorrect),
          'Incorrect PIN',
        );
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        // Arrange
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(() async => await service.isPinSetup(), returnsNormally);
        expect(() async => await service.isBiometricEnabled(), returnsNormally);
      });

      test('should handle biometric errors gracefully', () async {
        // Arrange
        when(mockLocalAuth.canCheckBiometrics)
            .thenThrow(Exception('Biometric error'));

        // Act & Assert
        expect(() async => await service.isBiometricAvailable(), returnsNormally);
      });
    });
  });
}