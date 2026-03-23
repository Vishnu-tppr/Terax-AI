import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user.dart';
import 'biometric_auth_service.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _isLoggedInKey = 'is_logged_in';

  static User? _currentUser;
  static String? _authToken;
  static String? _refreshToken;

  static User? get currentUser => _currentUser;
  static String? get authToken => _authToken;

  static String get _baseUrl {
    final baseUrl = EnvironmentConfig.backendBaseUrl.trim();
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<User?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final prefs = await SharedPreferences.getInstance();
    final cachedUserJson = prefs.getString(_userKey);
    final storedToken = prefs.getString(_tokenKey);
    final storedRefreshToken = prefs.getString(_refreshTokenKey);

    User? cachedUser;
    if (cachedUserJson != null) {
      try {
        cachedUser = User.fromJson(
          jsonDecode(cachedUserJson) as Map<String, dynamic>,
        );
      } catch (_) {
        cachedUser = null;
      }
    }

    if (storedToken == null || storedToken.isEmpty) {
      if (cachedUser == null) {
        await logout();
      } else {
        _currentUser = cachedUser;
      }
      return cachedUser;
    }

    try {
      final user = await _fetchCurrentUser(storedToken);
      await _saveUserData(user, storedToken, storedRefreshToken);
      return user;
    } on _AuthApiException catch (error) {
      if (error.statusCode == 401 &&
          storedRefreshToken != null &&
          storedRefreshToken.isNotEmpty) {
        try {
          final refreshedSession = await _refreshSession(
            storedToken,
            storedRefreshToken,
          );
          await _saveUserData(
            refreshedSession.user,
            refreshedSession.accessToken,
            refreshedSession.refreshToken,
          );
          return refreshedSession.user;
        } on _AuthApiException {
          await logout();
          return null;
        }
      }

      if (cachedUser != null && error.statusCode == null) {
        _currentUser = cachedUser;
        _authToken = storedToken;
        _refreshToken = storedRefreshToken;
        return cachedUser;
      }

      await logout();
      return null;
    } catch (_) {
      if (cachedUser != null) {
        _currentUser = cachedUser;
        _authToken = storedToken;
        _refreshToken = storedRefreshToken;
        return cachedUser;
      }

      await logout();
      return null;
    }
  }

  static Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    final response = await http
        .post(
          _uri('/v1/auth/sign-up'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'fullName': fullName,
            'email': email,
            'password': password,
            'phoneNumber': phoneNumber,
          }),
        )
        .timeout(EnvironmentConfig.authTimeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw _buildApiException(response);
    }

    final payload = _decodeJson(response);
    final session = _tryParseSession(payload);

    if (session != null) {
      await _saveUserData(
        session.user,
        session.accessToken,
        session.refreshToken,
      );
    } else {
      await logout();
    }

    return true;
  }

  static Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          _uri('/v1/auth/sign-in'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(EnvironmentConfig.authTimeout);

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    final payload = _decodeJson(response);
    final session = _requireSession(payload);
    await _saveUserData(
        session.user, session.accessToken, session.refreshToken);
    return true;
  }

  static Future<bool> signInWithGoogle() async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux)) {
      throw const _AuthApiException(
        'Google sign-in is available on Android, iOS, macOS, and web builds. Use email login on Windows desktop or run the mobile app/emulator.',
        null,
      );
    }

    final webClientId = _googleWebClientId;
    if (webClientId.isEmpty) {
      throw const _AuthApiException(
        'Google sign-in is not configured. Add GOOGLE_WEB_CLIENT_ID to .env first.',
        null,
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: kIsWeb ? null : webClientId,
      clientId: _googleClientId(webClientId),
    );

    GoogleSignInAccount? googleUser;
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      googleUser = await googleSignIn.signIn();
    } on AssertionError {
      throw _AuthApiException(
        kIsWeb
            ? 'Google sign-in is running in Flutter Web right now. Set GOOGLE_WEB_CLIENT_ID in .env or run the Android build instead of Chrome.'
            : 'Google sign-in is missing its client ID configuration. Check GOOGLE_WEB_CLIENT_ID in .env.',
        null,
      );
    }

    if (googleUser == null) {
      throw const _AuthApiException('Google sign-in was cancelled.', null);
    }

    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
      throw const _AuthApiException(
        'Google sign-in did not return an ID token. Check GOOGLE_WEB_CLIENT_ID configuration.',
        null,
      );
    }
    if (googleAuth.accessToken == null || googleAuth.accessToken!.isEmpty) {
      throw const _AuthApiException(
        'Google sign-in did not return an access token.',
        null,
      );
    }

    final response = await http
        .post(
          _uri('/v1/auth/sign-in/google'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'idToken': googleAuth.idToken,
            'accessToken': googleAuth.accessToken,
            'email': googleUser.email,
            'fullName': googleUser.displayName,
            'avatarUrl': googleUser.photoUrl,
          }),
        )
        .timeout(EnvironmentConfig.authTimeout);

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    final payload = _decodeJson(response);
    final session = _requireSession(payload);
    await _saveUserData(
      session.user,
      session.accessToken,
      session.refreshToken,
    );
    return true;
  }

  static Future<bool> signInWithBiometrics() async {
    final token = await _resolveAccessToken();
    if (token == null || token.isEmpty) {
      throw const _AuthApiException(
        'No saved session found. Sign in once with email or Google first.',
        401,
      );
    }

    final biometricService = BiometricAuthService.instance;
    final result = await biometricService.authenticate(
      reason: 'Use your fingerprint or face unlock to continue',
      stickyAuth: true,
    );

    if (!result.isAuthenticated) {
      throw _AuthApiException(
        BiometricAuthService.getResultMessage(result),
        null,
      );
    }

    final user = await getCurrentUser();
    if (user == null) {
      throw const _AuthApiException(
        'Your saved session has expired. Sign in again with email or Google.',
        401,
      );
    }

    return true;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.setBool(_isLoggedInKey, false);

    _currentUser = null;
    _authToken = null;
    _refreshToken = null;
  }

  static Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    final response = await _sendAuthenticatedRequest(
      (token) => http.patch(
        _uri('/v1/profile'),
        headers: _authorizedJsonHeaders(token),
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    final payload = _decodeJson(response);
    final user = User.fromJson(payload['user'] as Map<String, dynamic>);
    await _saveUserData(user, _authToken, _refreshToken);
  }

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _sendAuthenticatedRequest(
      (token) => http.post(
        _uri('/v1/auth/change-password'),
        headers: _authorizedJsonHeaders(token),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    return true;
  }

  static Future<bool> resetPassword(String email) async {
    final response = await http
        .post(
          _uri('/v1/auth/reset-password'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email}),
        )
        .timeout(EnvironmentConfig.authTimeout);

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    return true;
  }

  static Future<User> _fetchCurrentUser(String accessToken) async {
    final response = await http
        .get(
          _uri('/v1/auth/me'),
          headers: _authorizedJsonHeaders(accessToken),
        )
        .timeout(EnvironmentConfig.authTimeout);

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    final payload = _decodeJson(response);
    return User.fromJson(payload['user'] as Map<String, dynamic>);
  }

  static Future<_AuthSession> _refreshSession(
    String accessToken,
    String refreshToken,
  ) async {
    final response = await http
        .post(
          _uri('/v1/auth/refresh'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          }),
        )
        .timeout(EnvironmentConfig.authTimeout);

    if (response.statusCode != 200) {
      throw _buildApiException(response);
    }

    return _requireSession(_decodeJson(response));
  }

  static Future<http.Response> _sendAuthenticatedRequest(
    Future<http.Response> Function(String token) requestBuilder,
  ) async {
    final token = await _resolveAccessToken();
    if (token == null || token.isEmpty) {
      throw _AuthApiException('You are not signed in.', 401);
    }

    var response = await requestBuilder(token).timeout(
      EnvironmentConfig.authTimeout,
    );

    if (response.statusCode == 401 &&
        _refreshToken != null &&
        _refreshToken!.isNotEmpty) {
      final refreshedSession = await _refreshSession(token, _refreshToken!);
      await _saveUserData(
        refreshedSession.user,
        refreshedSession.accessToken,
        refreshedSession.refreshToken,
      );

      response = await requestBuilder(refreshedSession.accessToken).timeout(
        EnvironmentConfig.authTimeout,
      );
    }

    return response;
  }

  static Future<String?> _resolveAccessToken() async {
    if (_authToken != null && _authToken!.isNotEmpty) {
      return _authToken;
    }

    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    return _authToken;
  }

  static Future<void> _saveUserData(
    User user,
    String? accessToken,
    String? refreshToken,
  ) async {
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    } else {
      await prefs.remove(_refreshTokenKey);
    }
    await prefs.setBool(_isLoggedInKey, true);

    _currentUser = user;
    _authToken = accessToken;
    _refreshToken = refreshToken;
  }

  static _AuthSession _requireSession(Map<String, dynamic> payload) {
    final session = _tryParseSession(payload);
    if (session == null) {
      throw const _AuthApiException(
        'Authentication succeeded but no active session was returned.',
        null,
      );
    }
    return session;
  }

  static _AuthSession? _tryParseSession(Map<String, dynamic> payload) {
    final userJson = payload['user'];
    final sessionJson = payload['session'];

    if (userJson is! Map<String, dynamic> ||
        sessionJson is! Map<String, dynamic>) {
      return null;
    }

    final accessToken = sessionJson['accessToken'] as String?;
    final refreshToken = sessionJson['refreshToken'] as String?;
    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    return _AuthSession(
      user: User.fromJson(userJson),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static Map<String, dynamic> _decodeJson(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const _AuthApiException(
          'Invalid response from authentication server.', null);
    }
    return decoded;
  }

  static _AuthApiException _buildApiException(http.Response response) {
    try {
      final payload = _decodeJson(response);
      final detail =
          payload['detail'] ?? payload['message'] ?? payload['error'];
      if (detail is String && detail.isNotEmpty) {
        return _AuthApiException(detail, response.statusCode);
      }
    } catch (_) {
      // Ignore JSON parsing issues and fall back to the raw response body.
    }

    final fallback = response.body.isNotEmpty
        ? response.body
        : 'Authentication request failed.';
    return _AuthApiException(fallback, response.statusCode);
  }

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> _authorizedJsonHeaders(String token) => {
        ..._jsonHeaders,
        'Authorization': 'Bearer $token',
      };

  static String get _googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';

  static String? _googleClientId(String webClientId) {
    if (kIsWeb) {
      return webClientId;
    }

    final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']?.trim();
    if (iosClientId == null || iosClientId.isEmpty) {
      return null;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return iosClientId;
      default:
        return null;
    }
  }
}

class _AuthSession {
  const _AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
}

class _AuthApiException implements Exception {
  const _AuthApiException(this.message, this.statusCode);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
