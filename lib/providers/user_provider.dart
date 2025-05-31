import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../services/api_service.dart';
import '../services/liked_songs_service.dart';
import '../services/optimized_cache_service.dart';

import '../services/collection_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final LikedSongsService _likedSongsService = LikedSongsService();
  final OptimizedCacheService _cacheService = OptimizedCacheService();
  final DefaultCacheManager _imageCacheManager = DefaultCacheManager();

  final CollectionService _collectionService = CollectionService();

  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;
  int? _likedCollectionsCount;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;
  int? get likedCollectionsCount => _likedCollectionsCount;

  String? get userName => _userData?['name'];
  String? get userEmail => _userData?['email'];
  String? get userId => _userData?['id'];

  // Update liked collections count
  Future<void> updateLikedCollectionsCount() async {
    if (!_isLoggedIn) {
      _likedCollectionsCount = 0;
      notifyListeners();
      return;
    }

    try {
      final likedCollections = await _collectionService.getLikedCollections();
      _likedCollectionsCount = likedCollections.length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating liked collections count: $e');
      // Don't update the count if there's an error
    }
  }

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

        // We have a token, so we're good to go
        return;
      }

      // No access token, check Firebase authentication
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint('No access token but Firebase user is authenticated: ${firebaseUser.email}');

        try {
          // Get Firebase token
          final idToken = await firebaseUser.getIdToken(true);

          // Store it for API service to use
          await _secureStorage.write(key: 'firebase_token', value: idToken);

          // Set logged in state
          _isLoggedIn = true;

          // Try to fetch user profile
          await fetchUserProfile();
        } catch (e) {
          debugPrint('Error getting Firebase token during initialization: $e');
          _isLoggedIn = false;
          _userData = null;
        }
      } else {
        debugPrint('No access token and no Firebase user found during initialization');
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

      // Sync liked songs with the server after login (non-blocking)
      _likedSongsService.syncAfterLogin().catchError((syncError) {
        debugPrint('Error syncing liked songs after login: $syncError');
        // Continue even if sync fails
      });
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
      // Check if we have a Firebase user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // We have a Firebase user, make sure we have a fresh token
        try {
          final idToken = await firebaseUser.getIdToken(true);
          await _secureStorage.write(key: 'firebase_token', value: idToken);
          debugPrint('Refreshed Firebase token before fetching profile');
        } catch (e) {
          debugPrint('Error refreshing Firebase token: $e');
          // Continue anyway, the API service will handle token issues
        }
      }

      // Add a timeout to prevent getting stuck
      final response = await Future.any([
        _apiService.getUserProfile(),
        Future.delayed(const Duration(seconds: 5), () {
          throw Exception('Profile fetch timeout');
        }),
      ]);

      if (response['success'] == true && response['data'] != null) {
        await setUserData(response['data']);
        debugPrint('Successfully fetched and set user profile');
      } else {
        debugPrint('Failed to get user profile: ${response['message']}');

        // Check if we have a Firebase user before logging out
        if (firebaseUser != null) {
          // We have a Firebase user but couldn't get profile
          // This might be a temporary issue, so keep the user logged in
          debugPrint('Firebase user exists, keeping user logged in despite profile fetch failure');
          _isLoggedIn = true;
        } else {
          // No Firebase user and profile fetch failed, log out
          await logout(silent: true);
        }
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');

      // Check if we have a Firebase user
      final firebaseUser = FirebaseAuth.instance.currentUser;

      // Don't logout on timeout if we have a Firebase user
      if (e.toString().contains('timeout') && firebaseUser != null) {
        debugPrint('Profile fetch timed out, but Firebase user exists. Keeping user logged in.');
        _isLoggedIn = true;
      }
      // Don't logout on timeout if we have existing user data
      else if (e.toString().contains('timeout') && _userData != null) {
        debugPrint('Profile fetch timed out, proceeding with existing data');
        _isLoggedIn = true;
      }
      // Only logout if we have no Firebase user and no existing data
      else if (firebaseUser == null && _userData == null) {
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
    if (token != null) {
      debugPrint('Found access token, user is authenticated');
      _isLoggedIn = true;
      notifyListeners();

      // Try to fetch user profile in the background
      fetchUserProfile().catchError((e) {
        debugPrint('Background profile fetch error: $e');
      });

      // Update liked collections count in the background
      updateLikedCollectionsCount().catchError((e) {
        debugPrint('Error updating liked collections count: $e');
      });

      return true;
    }

    // Check Firebase authentication
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      debugPrint('Firebase user is authenticated: ${firebaseUser.email}');

      // We have a Firebase user but no access token
      // This means we need to get a token from the API
      try {
        // Get Firebase token
        final idToken = await firebaseUser.getIdToken(true);

        // Store it for API service to use
        await _secureStorage.write(key: 'firebase_token', value: idToken);

        // Set logged in state
        _isLoggedIn = true;
        notifyListeners();

        // Try to fetch user profile in the background
        fetchUserProfile().catchError((e) {
          debugPrint('Background profile fetch error: $e');
        });

        // Update liked collections count in the background
        updateLikedCollectionsCount().catchError((e) {
          debugPrint('Error updating liked collections count: $e');
        });

        return true;
      } catch (e) {
        debugPrint('Error getting Firebase token: $e');
      }
    }

    // No token and no Firebase user
    _isLoggedIn = false;
    _userData = null;
    notifyListeners();
    return false;
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

  // Logout with enhanced error handling and session management
  Future<void> logout({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    // First, mark the user as logged out immediately to prevent any new API calls
    _isLoggedIn = false;
    _userData = null;

    // Notify listeners early to update UI and prevent user interactions during logout
    notifyListeners();

    // Create a list of all cleanup tasks to ensure we attempt all of them
    List<Future<void>> cleanupTasks = [];

    // 1. Call logout API
    cleanupTasks.add(
      Future(() async {
        try {
          await _apiService.logout();
          debugPrint('API logout successful');
        } catch (e) {
          debugPrint('Error during logout API call: $e');
          // Continue with local logout even if API call fails
        }
      })
    );

    // 2. Sign out from Firebase
    cleanupTasks.add(
      Future(() async {
        try {
          await FirebaseAuth.instance.signOut();
          debugPrint('Firebase sign out successful');
        } catch (e) {
          debugPrint('Error signing out from Firebase: $e');
          // Continue with local logout even if Firebase sign out fails
        }
      })
    );

    // 3. Clear all authentication tokens
    cleanupTasks.add(
      Future(() async {
        try {
          debugPrint('Clearing all authentication tokens...');
          await _secureStorage.delete(key: 'access_token');
          await _secureStorage.delete(key: 'refresh_token');
          await _secureStorage.delete(key: 'firebase_token');
          await _secureStorage.delete(key: 'user_data');

          // Clear all Firebase-related data
          await _secureStorage.delete(key: 'firebase_uid');
          await _secureStorage.delete(key: 'firebase_email');
          await _secureStorage.delete(key: 'firebase_display_name');

          // Clear all timestamps and cache markers
          await _secureStorage.delete(key: 'last_login_time');
          await _secureStorage.delete(key: 'last_token_refresh');
          await _secureStorage.delete(key: 'last_profile_fetch');

          debugPrint('Successfully cleared all authentication tokens');
        } catch (e) {
          debugPrint('Error clearing authentication tokens: $e');
        }
      })
    );

    // 4. Clear liked songs data
    cleanupTasks.add(
      Future(() async {
        try {
          await _likedSongsService.clearLocalDataOnLogout(forceFullClear: true);
          debugPrint('Successfully cleared liked songs data');
        } catch (e) {
          debugPrint('Error clearing liked songs data: $e');
        }
      })
    );

    // 5. Song request upvote state is now managed by the backend database
    // No need to clear local storage for upvotes

    // 6. Clear all data caches
    cleanupTasks.add(
      Future(() async {
        try {
          await _cacheService.clearAllCaches();
          debugPrint('Successfully cleared all data caches');
        } catch (e) {
          debugPrint('Error clearing data caches: $e');
        }
      })
    );

    // 7. Clear all image caches
    cleanupTasks.add(
      Future(() async {
        try {
          await _imageCacheManager.emptyCache();
          debugPrint('Successfully cleared all image caches');
        } catch (e) {
          debugPrint('Error clearing image caches: $e');
        }
      })
    );

    // Execute all cleanup tasks in parallel for faster logout
    try {
      await Future.wait(cleanupTasks);
      debugPrint('Successfully completed all logout cleanup tasks');
    } catch (e) {
      debugPrint('Error during logout cleanup: $e');
    }

    // Double-check that user state is reset
    _isLoggedIn = false;
    _userData = null;

    if (!silent) {
      _isLoading = false;
    }

    // Final notification to update UI
    notifyListeners();

    debugPrint('Logout process completed successfully');
  }
}
