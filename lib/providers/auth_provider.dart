import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  AuthStatus _status = AuthStatus.uninitialized;
  // User? _firebaseUser;
  UserModel? _user;
  String? _error;
  bool _loading = false;

  // Getters
  AuthStatus get status => _status;
  // User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Constructor
  AuthProvider() {
    // Initialize auth status
    _status = AuthStatus.unauthenticated;
  }

  // Update auth status
  Future<void> updateAuthStatus(bool isAuthenticated, {String? name, String? email}) async {
    if (!isAuthenticated) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _status = AuthStatus.authenticated;

      // Create a basic user model
      _user = UserModel(
        id: 'temp-id',
        name: name ?? 'User',
        email: email ?? 'user@example.com',
        subscriptionType: 'FREE',
        isActive: true,
        isEmailVerified: true,
        authProvider: 'GOOGLE',
        rememberMe: true,
        termsAccepted: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    notifyListeners();
  }

  // This method is no longer needed as we're using a mock user

  // Register with email and password
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
        termsAccepted: termsAccepted,
      );

      _loading = false;

      if (result['success']) {
        // User profile will be fetched by the auth state listener
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Login with email and password
  Future<bool> loginWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.loginWithEmail(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      _loading = false;

      if (result['success']) {
        // User profile will be fetched by the auth state listener
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Login with Google
  Future<bool> loginWithGoogle({
    required bool rememberMe,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.loginWithGoogle(
        rememberMe: rememberMe,
      );

      _loading = false;

      if (result['success']) {
        // User profile will be fetched by the auth state listener
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Login with Facebook
  Future<bool> loginWithFacebook({
    required bool rememberMe,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.loginWithFacebook(
        rememberMe: rememberMe,
      );

      _loading = false;

      if (result['success']) {
        // User profile will be fetched by the auth state listener
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Login with Apple
  Future<bool> loginWithApple({
    required bool rememberMe,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.loginWithApple(
        rememberMe: rememberMe,
      );

      _loading = false;

      if (result['success']) {
        // User profile will be fetched by the auth state listener
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    await _authService.logout();

    _status = AuthStatus.unauthenticated;
    _user = null;
    _loading = false;

    notifyListeners();
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail({
    required String email,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.sendPasswordResetEmail(
        email: email,
      );

      _loading = false;

      if (result['success']) {
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    required String name,
    String? profilePicture,
  }) async {
    if (_user == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.updateProfile(
        name: name,
        profilePicture: profilePicture,
      );

      _loading = false;

      if (result['success']) {
        _user = UserModel.fromJson(result['data']);
        notifyListeners();
        return true;
      } else {
        _error = result['message'];
        notifyListeners();
        return false;
      }
    } catch (e) {
      _loading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
