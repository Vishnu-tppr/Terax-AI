import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  // Mock user data for demo purposes
  static final Map<String, User> _mockUsers = {
    'demo@terax.ai': User(
      id: '1',
      fullName: 'Demo User',
      email: 'demo@terax.ai',
      phoneNumber: '+1234567890',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    ),
  };

  static User? _currentUser;
  static String? _authToken;

  static User? get currentUser => _currentUser;
  static String? get authToken => _authToken;

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final token = prefs.getString(_tokenKey);

    if (userJson != null && token != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
        _authToken = token;
        return _currentUser;
      } catch (e) {
        await logout();
        return null;
      }
    }
    return null;
  }

  static Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      // Check if user already exists
      if (_mockUsers.containsKey(email)) {
        throw Exception('User already exists');
      }

      // Create new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to mock database
      _mockUsers[email] = newUser;

      // Generate auth token
      final token = _generateToken(email);

      // Save to local storage
      await _saveUserData(newUser, token);

      _currentUser = newUser;
      _authToken = token;

      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Check if user exists
      final user = _mockUsers[email];
      if (user == null) {
        throw Exception('Invalid credentials');
      }

      // In a real app, you would verify the password hash here
      // For demo purposes, we'll accept any password

      // Generate auth token
      final token = _generateToken(email);

      // Save to local storage
      await _saveUserData(user, token);

      _currentUser = user;
      _authToken = token;

      return true;
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.setBool(_isLoggedInKey, false);

    _currentUser = null;
    _authToken = null;
  }

  static Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      fullName: fullName,
      phoneNumber: phoneNumber,
      updatedAt: DateTime.now(),
    );

    // Update mock database
    _mockUsers[_currentUser!.email] = updatedUser;

    // Update local storage
    await _saveUserData(updatedUser, _authToken!);

    _currentUser = updatedUser;
  }

  static String _generateToken(String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final data = '$email:$timestamp:terax_ai_secret';
    // Simple hash function for demo purposes
    int hash = 0;
    for (int i = 0; i < data.length; i++) {
      hash = ((hash << 5) - hash + data.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static Future<void> _saveUserData(User user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isLoggedInKey, true);
  }

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // In a real app, you would verify the current password and hash the new one
    // For demo purposes, we'll just return success
    return true;
  }

  static Future<bool> resetPassword(String email) async {
    // In a real app, you would send a password reset email
    // For demo purposes, we'll just return success
    return true;
  }
}
