import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user.dart';
import '../services/auth_service.dart';


class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  AuthProvider() {
    if (kDebugMode) {
      print('🔍 [AuthProvider] Constructor called, starting initialization');
    }
    _initializeAuth();
  }

  /// Wait for authentication initialization to complete
  Future<void> waitForInitialization() async {
    if (kDebugMode) {
      print('🔍 [AuthProvider] waitForInitialization called, isInitialized: $_isInitialized');
    }
    
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔍 [AuthProvider] Already initialized, returning immediately');
      }
      return;
    }

    // Wait for up to 5 seconds for initialization
    int attempts = 0;
    while (!_isInitialized && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      if (kDebugMode && attempts % 10 == 0) {
        print('🔍 [AuthProvider] Still waiting for initialization... attempt $attempts/50');
      }
    }
    
    if (kDebugMode) {
      if (_isInitialized) {
        print('🔍 [AuthProvider] Initialization completed after $attempts attempts');
      } else {
        print('⚠️ [AuthProvider] Initialization timeout after $attempts attempts');
      }
    }
  }

  Future<void> _initializeAuth() async {
    const initializationTimeout = Duration(seconds: 10); // Max 10 seconds for auth initialization

    if (kDebugMode) {
      print('🔍 [AuthProvider] _initializeAuth started with ${initializationTimeout.inSeconds}s timeout');
    }

    _setLoading(true);

    try {
      // Add timeout wrapper around auth initialization
      await Future.any([
        _performAuthInitialization(),
        Future.delayed(initializationTimeout, () {
          throw TimeoutException('Auth initialization timeout exceeded');
        })
      ]);
    } on TimeoutException catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthProvider] Auth initialization timeout: $e');
        print('⚠️ [AuthProvider] Continuing with app startup anyway');
      }
      _setError('Authentication initialization timed out');
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ [AuthProvider] Auth initialization error: $e');
        print('❌ [AuthProvider] Stack trace: $stackTrace');
      }
      _setError('Failed to initialize authentication: $e');
    } finally {
      _setLoading(false);
      _isInitialized = true; // Mark as initialized regardless of success/failure

      if (kDebugMode) {
        print('🔍 [AuthProvider] _initializeAuth completed, isInitialized: $_isInitialized, isLoggedIn: $isLoggedIn');
      }

      notifyListeners();
    }
  }

  Future<void> _performAuthInitialization() async {
    if (kDebugMode) {
      print('🔍 [AuthProvider] Calling AuthService.getCurrentUser()');
    }

    final user = await AuthService.getCurrentUser();

    if (kDebugMode) {
      print('🔍 [AuthProvider] AuthService.getCurrentUser() returned: ${user?.email ?? "null"}');
    }

    if (user != null) {
      _currentUser = user;
      if (kDebugMode) {
        print('🔍 [AuthProvider] User logged in: ${user.email}');
      }
    } else {
      if (kDebugMode) {
        print('🔍 [AuthProvider] No user logged in');
      }
    }
  }

  Future<bool> signUp({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await AuthService.signUp(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
      
      if (success) {
        _currentUser = AuthService.currentUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Sign up failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await AuthService.signIn(
        email: email,
        password: password,
      );
      
      if (success) {
        _currentUser = AuthService.currentUser;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await AuthService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    if (_currentUser == null) return;
    
    _setLoading(true);
    
    try {
      await AuthService.updateProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
      );
      
      _currentUser = AuthService.currentUser;
      notifyListeners();
    } catch (e) {
      _setError('Profile update failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await AuthService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      if (success) {
        _clearError();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Password change failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await AuthService.resetPassword(email);
      
      if (success) {
        _clearError();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Password reset failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}
