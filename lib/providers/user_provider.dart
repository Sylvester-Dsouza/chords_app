import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  String? get userName => _userData?['name'];
  String? get userEmail => _userData?['email'];
  String? get userId => _userData?['id'];

  // Initialize the provider
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if we have a token
      final token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        final previewLength = token.length > 20 ? 20 : token.length;
        debugPrint('Found access token during initialization: ${token.substring(0, previewLength)}...');

        // Try to get user data
        final userData = await _secureStorage.read(key: 'user_data');
        if (userData != null) {
          try {
            _userData = json.decode(userData);
            _isLoggedIn = true;
            debugPrint('Loaded user data from secure storage: ${_userData?['name']}');
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            // Try to fetch profile if parsing fails
            await fetchUserProfile();
          }
        } else {
          debugPrint('Token exists but no user data, fetching profile');
          // If we have a token but no user data, try to fetch it
          await fetchUserProfile();
        }
      } else {
        debugPrint('No access token found during initialization');
        _isLoggedIn = false;
        _userData = null;
      }
    } catch (e) {
      debugPrint('Error initializing user provider: $e');
      // Clear any invalid data
      await logout(silent: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set user data after login
  Future<void> setUserData(Map<String, dynamic> userData) async {
    _userData = userData;
    _isLoggedIn = true;

    // Save user data to secure storage
    try {
      final encodedData = json.encode(userData);
      await _secureStorage.write(
        key: 'user_data',
        value: encodedData,
      );
      debugPrint('Saved user data to secure storage: ${userData['name']}');

      // Verify the data was saved correctly
      final savedData = await _secureStorage.read(key: 'user_data');
      if (savedData != null) {
        debugPrint('Verified user data was saved correctly');
      } else {
        debugPrint('Warning: User data was not saved correctly');
      }
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }

    notifyListeners();
  }

  // Fetch user profile from API
  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Add a timeout to prevent getting stuck
      final response = await Future.any([
        _apiService.getUserProfile(),
        Future.delayed(const Duration(seconds: 3), () {
          throw Exception('Profile fetch timeout');
        }),
      ]);

      if (response['success'] == true && response['data'] != null) {
        await setUserData(response['data']);
        debugPrint('Successfully fetched and set user profile');
      } else {
        debugPrint('Failed to get user profile: ${response['message']}');
        // If we can't get the profile, consider the user logged out
        await logout(silent: true);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      // Don't logout on timeout, just proceed with what we have
      if (e.toString().contains('timeout')) {
        debugPrint('Profile fetch timed out, proceeding with existing data');
        // If we have some user data from login, keep it
        if (_userData != null) {
          _isLoggedIn = true;
        } else {
          await logout(silent: true);
        }
      } else {
        await logout(silent: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check if the user is authenticated
  Future<bool> isAuthenticated() async {
    if (_isLoggedIn && _userData != null) {
      // We already have user data, so we're authenticated
      return true;
    }

    // Check if we have a token
    final token = await _secureStorage.read(key: 'access_token');
    if (token == null) {
      // No token, definitely not authenticated
      _isLoggedIn = false;
      notifyListeners();
      return false;
    }

    // We have a token but no user data or not marked as logged in
    // Try to fetch the user profile to validate the token
    try {
      // Add a timeout to prevent getting stuck
      await Future.any([
        fetchUserProfile(),
        Future.delayed(const Duration(seconds: 3), () {
          // If we have a token, assume we're authenticated even if profile fetch times out
          _isLoggedIn = true;
          notifyListeners();
          throw Exception('Authentication check timeout');
        }),
      ]);
      return _isLoggedIn;
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      // If it's a timeout, we'll assume the user is authenticated since we have a token
      if (e.toString().contains('timeout')) {
        return true;
      }
      return false;
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> updatedData) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Merge updated data with existing data
      _userData = {...?_userData, ...updatedData};

      // Save updated user data to secure storage
      final encodedData = json.encode(_userData);
      await _secureStorage.write(
        key: 'user_data',
        value: encodedData,
      );

      debugPrint('Updated user data: ${_userData?['name']}');

      // In a real app, you would also update the data on the server
      // await _apiService.updateUserProfile(updatedData);
    } catch (e) {
      debugPrint('Error updating user data: $e');
      // Revert changes if there's an error
      await fetchUserProfile();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // Call logout API
      await _apiService.logout();
      debugPrint('API logout successful');
    } catch (e) {
      debugPrint('Error during logout API call: $e');
      // Continue with local logout even if API call fails
    }

    // Clear local data
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_data');
    debugPrint('Cleared all auth tokens and user data');

    _isLoggedIn = false;
    _userData = null;

    if (!silent) {
      _isLoading = false;
      notifyListeners();
    } else {
      // Still notify listeners to update UI
      notifyListeners();
    }
  }
}
