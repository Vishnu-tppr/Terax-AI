import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum SmsProvider {
  twilio,
  vonage,
  aws,
  custom,
}

enum SmsDeliveryStatus {
  pending,
  sent,
  delivered,
  failed,
  unknown,
}

class SmsMessage {
  final String id;
  final List<String> recipients;
  final String message;
  final DateTime timestamp;
  final SmsDeliveryStatus status;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  SmsMessage({
    required this.id,
    required this.recipients,
    required this.message,
    required this.timestamp,
    this.status = SmsDeliveryStatus.pending,
    this.errorMessage,
    this.metadata,
  });

  factory SmsMessage.fromJson(Map<String, dynamic> json) {
    return SmsMessage(
      id: json['id'],
      recipients: List<String>.from(json['recipients']),
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      status: SmsDeliveryStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SmsDeliveryStatus.unknown,
      ),
      errorMessage: json['error_message'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipients': recipients,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }
}

class SmsService {
  static SmsService? _instance;
  static SmsService get instance {
    _instance ??= SmsService._(Dio());
    return _instance!;
  }

  SmsService._(this._dio);

  Dio _dio;
  String? _baseUrl;
  String? _apiKey;
  SmsProvider _provider = SmsProvider.twilio;

  /// Test-only setter for dependency injection
  @visibleForTesting
  set dio(Dio dio) {
    _dio = dio;
  }

  /// Initialize SMS service with backend configuration
  Future<void> initialize({
    required String baseUrl,
    required String apiKey,
    SmsProvider provider = SmsProvider.twilio,
  }) async {
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    _provider = provider;

    // Configure Dio
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    };
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    if (kDebugMode) {
      print('SMS Service initialized with provider: $_provider');
    }
  }

  /// Send SMS via backend API (recommended approach)
  Future<SmsMessage> sendSmsViaBackend({
    required List<String> recipients,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    if (_baseUrl == null || _apiKey == null) {
      throw Exception('SMS service not initialized. Call initialize() first.');
    }

    try {
      final requestData = {
        'recipients': recipients,
        'message': message,
        'provider': _provider.toString().split('.').last,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        print('Sending SMS via backend: ${recipients.length} recipients');
      }

      final response = await _dio.post(
        '/v1/emergency/send-sms',
        data: requestData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        return SmsMessage(
          id: responseData['message_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          recipients: recipients,
          message: message,
          timestamp: DateTime.now(),
          status: SmsDeliveryStatus.sent,
          metadata: metadata,
        );
      } else {
        throw Exception('SMS sending failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('SMS sending error: ${e.message}');
      }
      
      String errorMessage = 'SMS sending failed';
      if (e.response?.data != null) {
        errorMessage = e.response!.data['error'] ?? errorMessage;
      }

      return SmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipients: recipients,
        message: message,
        timestamp: DateTime.now(),
        status: SmsDeliveryStatus.failed,
        errorMessage: errorMessage,
        metadata: metadata,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected SMS error: $e');
      }

      return SmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recipients: recipients,
        message: message,
        timestamp: DateTime.now(),
        status: SmsDeliveryStatus.failed,
        errorMessage: 'Unexpected error: $e',
        metadata: metadata,
      );
    }
  }

  /// Send emergency SMS with location
  Future<SmsMessage> sendEmergencySms({
    required List<String> recipients,
    required String emergencyMessage,
    double? latitude,
    double? longitude,
    String? locationName,
    Map<String, dynamic>? additionalData,
  }) async {
    String message = emergencyMessage;
    
    // Add location information if available
    if (latitude != null && longitude != null) {
      final mapLink = 'https://maps.google.com/?q=$latitude,$longitude';
      message += '\n\nLocation: $mapLink';
      
      if (locationName != null) {
        message += '\nNear: $locationName';
      }
    }

    final metadata = {
      'type': 'emergency',
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    };

    return await sendSmsViaBackend(
      recipients: recipients,
      message: message,
      metadata: metadata,
    );
  }

  /// Send location sharing SMS
  Future<SmsMessage> sendLocationSms({
    required List<String> recipients,
    required double latitude,
    required double longitude,
    String? customMessage,
    String? locationName,
  }) async {
    final mapLink = 'https://maps.google.com/?q=$latitude,$longitude';
    
    String message = customMessage ?? 'I\'m sharing my location with you:';
    message += '\n\n$mapLink';
    
    if (locationName != null) {
      message += '\nNear: $locationName';
    }

    final metadata = {
      'type': 'location_share',
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await sendSmsViaBackend(
      recipients: recipients,
      message: message,
      metadata: metadata,
    );
  }

  /// Fallback: Open device SMS composer (iOS/Android)
  Future<bool> openSmsComposer({
    required List<String> recipients,
    required String message,
  }) async {
    try {
      final recipientsString = recipients.join(',');
      final encodedMessage = Uri.encodeComponent(message);
      
      final Uri smsUri = Uri.parse('sms:$recipientsString?body=$encodedMessage');
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      } else {
        if (kDebugMode) {
          print('Cannot launch SMS composer');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error opening SMS composer: $e');
      }
      return false;
    }
  }

  /// Check SMS delivery status
  Future<SmsDeliveryStatus> checkDeliveryStatus(String messageId) async {
    if (_baseUrl == null || _apiKey == null) {
      return SmsDeliveryStatus.unknown;
    }

    try {
      final response = await _dio.get('/v1/emergency/sms-status/$messageId');
      
      if (response.statusCode == 200) {
        final status = response.data['status'];
        return SmsDeliveryStatus.values.firstWhere(
          (e) => e.toString().split('.').last == status,
          orElse: () => SmsDeliveryStatus.unknown,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking SMS status: $e');
      }
    }
    
    return SmsDeliveryStatus.unknown;
  }

  /// Get SMS sending history
  Future<List<SmsMessage>> getSmsHistory({
    int limit = 50,
    DateTime? since,
  }) async {
    if (_baseUrl == null || _apiKey == null) {
      return [];
    }

    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      
      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }

      final response = await _dio.get(
        '/v1/emergency/sms-history',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> messages = response.data['messages'];
        return messages.map((json) => SmsMessage.fromJson(json)).toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching SMS history: $e');
      }
    }
    
    return [];
  }

  /// Validate phone numbers
  static bool isValidPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it's a valid international format
    final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(cleaned);
  }

  /// Format phone number for display
  static String formatPhoneNumber(String phoneNumber) {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleaned.startsWith('+1') && cleaned.length == 12) {
      // US format: +1 (XXX) XXX-XXXX
      return '+1 (${cleaned.substring(2, 5)}) ${cleaned.substring(5, 8)}-${cleaned.substring(8)}';
    } else if (cleaned.startsWith('+')) {
      // International format: keep as is
      return cleaned;
    } else if (cleaned.length == 10) {
      // US format without country code: (XXX) XXX-XXXX
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    
    return phoneNumber; // Return original if can't format
  }

  /// Get service status
  bool get isInitialized => _baseUrl != null && _apiKey != null;
  
  SmsProvider get provider => _provider;
  
  String? get baseUrl => _baseUrl;
}