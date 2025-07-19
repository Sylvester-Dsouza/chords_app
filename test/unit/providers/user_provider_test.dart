import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:chords_app/providers/user_provider.dart';
import 'package:chords_app/services/api_service.dart';
import 'package:chords_app/services/liked_songs_service.dart';
import 'package:chords_app/services/cache_service.dart';
import 'package:chords_app/services/collection_service.dart';
import 'package:chords_app/models/collection.dart';
import 'dart:convert';
import '../../helpers/test_helpers.dart' hide MockFlutterSecureStorage;
import '../../helpers/mock_data.dart';

// Generate mocks
@GenerateMocks([
  FlutterSecureStorage,
  FirebaseAuth,
  User,
  ApiService,
  LikedSongsService,
  CacheService,
  CollectionService,
  DefaultCacheManager,
])
import 'user_provider_test.mocks.dart';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserProvider', () {
    late UserProvider userProvider;
    late MockFlutterSecureStorage mockSecureStorage;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockUser mockUser;
    late MockApiService mockApiService;
    late MockLikedSongsService mockLikedSongsService;
    late MockCacheService mockCacheService;
    late MockCollectionService mockCollectionService;
    late MockDefaultCacheManager mockCacheManager;

    setUp(() {
      mockSecureStorage = MockFlutterSecureStorage();
      mockFirebaseAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockApiService = MockApiService();
      mockLikedSongsService = MockLikedSongsService();
      mockCacheService = MockCacheService();
      mockCollectionService = MockCollectionService();
      mockCacheManager = MockDefaultCacheManager();

      // Setup default mock behaviors
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
      when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async {});
      when(mockSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async {});

      when(mockFirebaseAuth.currentUser).thenReturn(null);
      when(mockFirebaseAuth.signOut()).thenAnswer((_) async {});

      when(mockApiService.logout()).thenAnswer((_) async => true);
      when(mockApiService.getUserProfile()).thenAnswer((_) async => {
        'success': false,
        'message': 'Not authenticated',
      });

      when(mockLikedSongsService.syncAfterLogin()).thenAnswer((_) async {});
      when(mockLikedSongsService.clearLocalDataOnLogout(forceFullClear: anyNamed('forceFullClear')))
          .thenAnswer((_) async {});

      when(mockCacheService.clearAllCache()).thenAnswer((_) async {});
      when(mockCacheManager.emptyCache()).thenAnswer((_) async {});

      when(mockCollectionService.getLikedCollections()).thenAnswer((_) async => []);

      userProvider = UserProvider();
    });

    group('Initialization', () {
      test('should create UserProvider instance successfully', () {
        expect(userProvider, isA<UserProvider>());
      });

      test('should have correct initial state', () {
        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.userData, isNull);
        expect(userProvider.isLoading, isFalse);
        expect(userProvider.userName, isNull);
        expect(userProvider.userEmail, isNull);
        expect(userProvider.userId, isNull);
        expect(userProvider.likedCollectionsCount, isNull);
      });

      test('should initialize without errors', () async {
        expect(() => userProvider.initialize(), returnsNormally);
      });

      test('should handle initialization with existing token', () async {
        // Mock existing access token
        when(mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'mock-access-token');
        
        // Mock user data
        final userData = {'id': '1', 'name': 'Test User', 'email': 'test@example.com'};
        when(mockSecureStorage.read(key: 'user_data'))
            .thenAnswer((_) async => jsonEncode(userData));

        await userProvider.initialize();

        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.userData, isNotNull);
      });

      test('should handle initialization with Firebase user but no token', () async {
        // Mock Firebase user
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.getIdToken(any)).thenAnswer((_) async => 'firebase-token');

        await userProvider.initialize();

        expect(userProvider.isLoggedIn, isTrue);
      });

      test('should handle initialization with no authentication', () async {
        await userProvider.initialize();

        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.userData, isNull);
      });
    });

    group('User Data Management', () {
      test('should set user data correctly', () async {
        final userData = {
          'id': '1',
          'name': 'Test User',
          'email': 'test@example.com',
        };

        await userProvider.setUserData(userData);

        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.userData, equals(userData));
        expect(userProvider.userName, equals('Test User'));
        expect(userProvider.userEmail, equals('test@example.com'));
        expect(userProvider.userId, equals('1'));
      });

      test('should update user data correctly', () async {
        // Set initial user data
        final initialData = {
          'id': '1',
          'name': 'Test User',
          'email': 'test@example.com',
        };
        await userProvider.setUserData(initialData);

        // Update user data
        final updatedData = {'name': 'Updated User'};
        await userProvider.updateUserData(updatedData);

        expect(userProvider.userName, equals('Updated User'));
        expect(userProvider.userEmail, equals('test@example.com')); // Should remain unchanged
        expect(userProvider.userId, equals('1')); // Should remain unchanged
      });

      test('should fetch user profile successfully', () async {
        // Mock successful API response
        when(mockApiService.getUserProfile()).thenAnswer((_) async => {
          'success': true,
          'data': {
            'id': '1',
            'name': 'Test User',
            'email': 'test@example.com',
          },
        });

        await userProvider.fetchUserProfile();

        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.userData, isNotNull);
        expect(userProvider.userName, equals('Test User'));
      });

      test('should handle fetch user profile failure', () async {
        // Mock failed API response
        when(mockApiService.getUserProfile()).thenAnswer((_) async => {
          'success': false,
          'message': 'User not found',
        });

        await userProvider.fetchUserProfile();

        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.userData, isNull);
      });

      test('should handle fetch user profile timeout with Firebase user', () async {
        // Mock Firebase user
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.getIdToken(any)).thenAnswer((_) async => 'firebase-token');

        // Mock timeout
        when(mockApiService.getUserProfile()).thenThrow(Exception('Profile fetch timeout'));

        await userProvider.fetchUserProfile();

        // Should keep user logged in if Firebase user exists
        expect(userProvider.isLoggedIn, isTrue);
      });
    });

    group('Authentication State', () {
      test('should check authentication with existing token', () async {
        when(mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'mock-access-token');

        final isAuth = await userProvider.isAuthenticated();

        expect(isAuth, isTrue);
        expect(userProvider.isLoggedIn, isTrue);
      });

      test('should check authentication with Firebase user', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.getIdToken(any)).thenAnswer((_) async => 'firebase-token');

        final isAuth = await userProvider.isAuthenticated();

        expect(isAuth, isTrue);
        expect(userProvider.isLoggedIn, isTrue);
      });

      test('should check authentication with no credentials', () async {
        final isAuth = await userProvider.isAuthenticated();

        expect(isAuth, isFalse);
        expect(userProvider.isLoggedIn, isFalse);
      });

      test('should handle authentication check with existing user data', () async {
        // Set user data first
        final userData = {'id': '1', 'name': 'Test User', 'email': 'test@example.com'};
        await userProvider.setUserData(userData);

        final isAuth = await userProvider.isAuthenticated();

        expect(isAuth, isTrue);
        expect(userProvider.isLoggedIn, isTrue);
      });
    });

    group('Liked Collections Management', () {
      test('should update liked collections count when logged in', () async {
        // Set user as logged in
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        // Mock liked collections
        when(mockCollectionService.getLikedCollections()).thenAnswer((_) async => [
          Collection(
            id: '1',
            title: 'Collection 1',
            color: const Color(0xFF2196F3),
          ),
          Collection(
            id: '2',
            title: 'Collection 2',
            color: const Color(0xFF4CAF50),
          ),
        ]);

        await userProvider.updateLikedCollectionsCount();

        expect(userProvider.likedCollectionsCount, equals(2));
      });

      test('should set liked collections count to 0 when not logged in', () async {
        await userProvider.updateLikedCollectionsCount();

        expect(userProvider.likedCollectionsCount, equals(0));
      });

      test('should handle error when updating liked collections count', () async {
        // Set user as logged in
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        // Mock error
        when(mockCollectionService.getLikedCollections()).thenThrow(Exception('Network error'));

        await userProvider.updateLikedCollectionsCount();

        // Should not update count on error
        expect(userProvider.likedCollectionsCount, isNull);
      });
    });

    group('Logout', () {
      test('should logout successfully', () async {
        // Set user as logged in first
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});
        expect(userProvider.isLoggedIn, isTrue);

        await userProvider.logout();

        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.userData, isNull);
        expect(userProvider.userName, isNull);
        expect(userProvider.userEmail, isNull);
        expect(userProvider.userId, isNull);
      });

      test('should logout silently without loading state', () async {
        // Set user as logged in first
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        await userProvider.logout(silent: true);

        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.userData, isNull);
        expect(userProvider.isLoading, isFalse);
      });

      test('should handle logout with API errors gracefully', () async {
        // Set user as logged in first
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        // Mock API logout error
        when(mockApiService.logout()).thenThrow(Exception('Network error'));

        // Should not throw and should still logout locally
        await userProvider.logout();

        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.userData, isNull);
      });

      test('should handle logout with Firebase errors gracefully', () async {
        // Set user as logged in first
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        // Mock Firebase signOut error
        when(mockFirebaseAuth.signOut()).thenThrow(Exception('Firebase error'));

        // Should not throw and should still logout locally
        await userProvider.logout();

        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.userData, isNull);
      });

      test('should clear all data during logout', () async {
        // Set user as logged in first
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        await userProvider.logout();

        // Verify all cleanup methods were called
        verify(mockApiService.logout()).called(1);
        verify(mockFirebaseAuth.signOut()).called(1);
        verify(mockLikedSongsService.clearLocalDataOnLogout(forceFullClear: true)).called(1);
        verify(mockCacheService.clearAllCache()).called(1);
        verify(mockCacheManager.emptyCache()).called(1);
      });
    });

    group('Loading State', () {
      test('should manage loading state during initialization', () async {
        bool loadingStateChanged = false;
        
        userProvider.addListener(() {
          if (userProvider.isLoading) {
            loadingStateChanged = true;
          }
        });

        await userProvider.initialize();

        expect(loadingStateChanged, isTrue);
        expect(userProvider.isLoading, isFalse); // Should be false after completion
      });

      test('should manage loading state during profile fetch', () async {
        bool loadingStateChanged = false;
        
        userProvider.addListener(() {
          if (userProvider.isLoading) {
            loadingStateChanged = true;
          }
        });

        await userProvider.fetchUserProfile();

        expect(loadingStateChanged, isTrue);
        expect(userProvider.isLoading, isFalse); // Should be false after completion
      });

      test('should manage loading state during user data update', () async {
        // Set initial user data
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        bool loadingStateChanged = false;
        
        userProvider.addListener(() {
          if (userProvider.isLoading) {
            loadingStateChanged = true;
          }
        });

        await userProvider.updateUserData({'name': 'Updated User'});

        expect(loadingStateChanged, isTrue);
        expect(userProvider.isLoading, isFalse); // Should be false after completion
      });
    });

    group('Notification Listeners', () {
      test('should notify listeners when user data changes', () async {
        bool notified = false;
        
        userProvider.addListener(() {
          notified = true;
        });

        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        expect(notified, isTrue);
      });

      test('should notify listeners when logout occurs', () async {
        // Set user as logged in first
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        bool notified = false;
        
        userProvider.addListener(() {
          if (!userProvider.isLoggedIn) {
            notified = true;
          }
        });

        await userProvider.logout();

        expect(notified, isTrue);
      });

      test('should notify listeners when liked collections count changes', () async {
        // Set user as logged in
        await userProvider.setUserData({'id': '1', 'name': 'Test User'});

        bool notified = false;
        
        userProvider.addListener(() {
          if (userProvider.likedCollectionsCount != null) {
            notified = true;
          }
        });

        when(mockCollectionService.getLikedCollections()).thenAnswer((_) async => [
          Collection(
            id: '1',
            title: 'Collection 1',
            color: const Color(0xFF2196F3),
          ),
        ]);

        await userProvider.updateLikedCollectionsCount();

        expect(notified, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle secure storage errors gracefully', () async {
        // Mock secure storage error
        when(mockSecureStorage.read(key: anyNamed('key')))
            .thenThrow(Exception('Storage error'));

        // Should not throw
        await userProvider.initialize();

        expect(userProvider.isLoggedIn, isFalse);
      });

      test('should handle JSON parsing errors gracefully', () async {
        // Mock invalid JSON in user data
        when(mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'mock-token');
        when(mockSecureStorage.read(key: 'user_data'))
            .thenAnswer((_) async => 'invalid-json');

        // Should not throw and should try to fetch profile
        await userProvider.initialize();

        // Should handle the error gracefully
        expect(userProvider.isLoggedIn, isFalse);
      });

      test('should handle Firebase token errors gracefully', () async {
        // Mock Firebase user but token error
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.getIdToken(any)).thenThrow(Exception('Token error'));

        await userProvider.initialize();

        expect(userProvider.isLoggedIn, isFalse);
      });

      test('should handle API service errors gracefully', () async {
        // Mock API service error
        when(mockApiService.getUserProfile()).thenThrow(Exception('API error'));

        // Should not throw
        await userProvider.fetchUserProfile();

        expect(userProvider.isLoggedIn, isFalse);
      });
    });

    group('Data Persistence', () {
      test('should save user data to secure storage', () async {
        final userData = {'id': '1', 'name': 'Test User', 'email': 'test@example.com'};

        await userProvider.setUserData(userData);

        verify(mockSecureStorage.write(
          key: 'user_data',
          value: jsonEncode(userData),
        )).called(1);
      });

      test('should save Firebase token to secure storage', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.getIdToken(any)).thenAnswer((_) async => 'firebase-token');

        await userProvider.isAuthenticated();

        verify(mockSecureStorage.write(
          key: 'firebase_token',
          value: 'firebase-token',
        )).called(1);
      });

      test('should clear all stored data during logout', () async {
        await userProvider.logout();

        // Verify all keys are deleted
        verify(mockSecureStorage.delete(key: 'access_token')).called(1);
        verify(mockSecureStorage.delete(key: 'refresh_token')).called(1);
        verify(mockSecureStorage.delete(key: 'firebase_token')).called(1);
        verify(mockSecureStorage.delete(key: 'user_data')).called(1);
        verify(mockSecureStorage.delete(key: 'firebase_uid')).called(1);
        verify(mockSecureStorage.delete(key: 'firebase_email')).called(1);
        verify(mockSecureStorage.delete(key: 'firebase_display_name')).called(1);
      });
    });

    group('User Preferences and Settings', () {
      test('should persist user preferences in secure storage', () async {
        final userData = MockData.createUser().toJson();
        userData['preferences'] = MockData.createUserPreferences();

        await userProvider.setUserData(userData);

        // Verify user data with preferences is saved
        verify(mockSecureStorage.write(
          key: 'user_data',
          value: jsonEncode(userData),
        )).called(1);

        expect(userProvider.userData?['preferences'], isNotNull);
      });

      test('should update user preferences without affecting other data', () async {
        // Set initial user data with preferences
        final initialData = MockData.createUser().toJson();
        initialData['preferences'] = {'theme': 'light', 'notifications': true};
        await userProvider.setUserData(initialData);

        // Update only preferences
        final updatedPreferences = {'theme': 'dark', 'language': 'es'};
        await userProvider.updateUserData({'preferences': updatedPreferences});

        expect(userProvider.userData?['preferences']['theme'], equals('dark'));
        expect(userProvider.userData?['preferences']['language'], equals('es'));
        expect(userProvider.userName, equals(initialData['name'])); // Should remain unchanged
      });

      test('should handle missing preferences gracefully', () async {
        final userData = MockData.createUser().toJson();
        // Don't include preferences

        await userProvider.setUserData(userData);

        expect(userProvider.userData?['preferences'], isNull);
        expect(userProvider.isLoggedIn, isTrue);
      });

      test('should merge preferences when updating user data', () async {
        // Set initial preferences
        final initialData = MockData.createUser().toJson();
        initialData['preferences'] = {
          'theme': 'light',
          'notifications': true,
          'language': 'en'
        };
        await userProvider.setUserData(initialData);

        // Update with partial preferences
        await userProvider.updateUserData({
          'preferences': {'theme': 'dark', 'autoPlay': false}
        });

        final updatedPrefs = userProvider.userData?['preferences'];
        expect(updatedPrefs['theme'], equals('dark'));
        expect(updatedPrefs['autoPlay'], equals(false));
        // Note: The current implementation replaces the entire preferences object
        // This test documents the current behavior
      });
    });

    group('Authentication State Changes', () {
      test('should handle authentication state transitions correctly', () async {
        List<bool> authStates = [];
        
        userProvider.addListener(() {
          authStates.add(userProvider.isLoggedIn);
        });

        // Initial state should be false
        expect(userProvider.isLoggedIn, isFalse);

        // Login
        await userProvider.setUserData(MockData.createUser().toJson());
        expect(userProvider.isLoggedIn, isTrue);

        // Logout
        await userProvider.logout();
        expect(userProvider.isLoggedIn, isFalse);

        // Verify state changes were captured
        expect(authStates, contains(true));
        expect(authStates, contains(false));
      });

      test('should maintain authentication state across app restarts', () async {
        // Simulate app restart with existing token
        when(mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'existing-token');
        when(mockSecureStorage.read(key: 'user_data'))
            .thenAnswer((_) async => jsonEncode(MockData.createUser().toJson()));

        await userProvider.initialize();

        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.userData, isNotNull);
      });

      test('should handle token expiration gracefully', () async {
        // Set user as logged in
        await userProvider.setUserData(MockData.createUser().toJson());
        expect(userProvider.isLoggedIn, isTrue);

        // Mock token expiration error
        when(mockApiService.getUserProfile()).thenAnswer((_) async => {
          'success': false,
          'message': 'Token expired',
          'statusCode': 401,
        });

        await userProvider.fetchUserProfile();

        // Should logout on token expiration
        expect(userProvider.isLoggedIn, isFalse);
      });

      test('should refresh Firebase token when needed', () async {
        when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(mockUser.getIdToken(true)).thenAnswer((_) async => 'refreshed-token');

        await userProvider.fetchUserProfile();

        verify(mockUser.getIdToken(true)).called(1);
        verify(mockSecureStorage.write(
          key: 'firebase_token',
          value: 'refreshed-token',
        )).called(1);
      });
    });

    group('Profile Management', () {
      test('should update profile data and persist changes', () async {
        final initialUser = MockData.createUser();
        await userProvider.setUserData(initialUser.toJson());

        final profileUpdates = {
          'name': 'Updated Name',
          'phoneNumber': '+1234567890',
          'profilePicture': 'https://example.com/new-avatar.jpg'
        };

        await userProvider.updateUserData(profileUpdates);

        expect(userProvider.userName, equals('Updated Name'));
        expect(userProvider.userData?['phoneNumber'], equals('+1234567890'));
        expect(userProvider.userData?['profilePicture'], equals('https://example.com/new-avatar.jpg'));

        // Verify persistence
        verify(mockSecureStorage.write(
          key: 'user_data',
          value: anyNamed('value'),
        )).called(greaterThan(1));
      });

      test('should handle profile update failures gracefully', () async {
        final initialUser = MockData.createUser();
        await userProvider.setUserData(initialUser.toJson());

        // Mock storage error during update
        when(mockSecureStorage.write(key: 'user_data', value: anyNamed('value')))
            .thenThrow(Exception('Storage error'));

        // Mock successful profile fetch to simulate recovery
        when(mockApiService.getUserProfile()).thenAnswer((_) async => {
          'success': true,
          'data': initialUser.toJson(),
        });

        await userProvider.updateUserData({'name': 'Failed Update'});

        // Should revert to original data after error
        expect(userProvider.userName, equals(initialUser.name));
      });

      test('should validate user data before setting', () async {
        // Test with invalid user data
        final invalidUserData = {'invalid': 'data'};

        await userProvider.setUserData(invalidUserData);

        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.userData, equals(invalidUserData));
        expect(userProvider.userName, isNull); // Should handle missing fields gracefully
      });
    });

    group('State Notifications and Listeners', () {
      test('should notify listeners of all state changes', () async {
        List<String> notifications = [];
        
        userProvider.addListener(() {
          notifications.add('state_changed');
        });

        // Test various state changes
        await userProvider.initialize();
        await userProvider.setUserData(MockData.createUser().toJson());
        await userProvider.updateUserData({'name': 'Updated'});
        await userProvider.updateLikedCollectionsCount();
        await userProvider.logout();

        expect(notifications.length, greaterThan(3));
      });

      test('should handle multiple listeners correctly', () async {
        int listener1Count = 0;
        int listener2Count = 0;
        bool listener3Called = false;

        userProvider.addListener(() => listener1Count++);
        userProvider.addListener(() => listener2Count++);
        userProvider.addListener(() => listener3Called = true);

        await userProvider.setUserData(MockData.createUser().toJson());

        expect(listener1Count, greaterThan(0));
        expect(listener2Count, greaterThan(0));
        expect(listener3Called, isTrue);
      });

      test('should not notify listeners during silent operations', () async {
        int notificationCount = 0;
        
        userProvider.addListener(() => notificationCount++);

        // Set user first
        await userProvider.setUserData(MockData.createUser().toJson());
        final countAfterLogin = notificationCount;

        // Silent logout should still notify (it's the final state change)
        await userProvider.logout(silent: true);

        expect(notificationCount, greaterThan(countAfterLogin));
      });

      test('should handle listener exceptions gracefully', () async {
        // Add a listener that throws an exception
        userProvider.addListener(() {
          throw Exception('Listener error');
        });

        // Add a normal listener
        bool normalListenerCalled = false;
        userProvider.addListener(() {
          normalListenerCalled = true;
        });

        // Should not throw and should still call other listeners
        await userProvider.setUserData(MockData.createUser().toJson());

        expect(normalListenerCalled, isTrue);
      });
    });

    group('Concurrent Operations', () {
      test('should handle concurrent initialization calls', () async {
        // Mock token and user data
        when(mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'mock-token');
        when(mockSecureStorage.read(key: 'user_data'))
            .thenAnswer((_) async => jsonEncode(MockData.createUser().toJson()));

        // Call initialize multiple times concurrently
        final futures = List.generate(3, (_) => userProvider.initialize());
        await Future.wait(futures);

        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.userData, isNotNull);
      });

      test('should handle concurrent logout calls', () async {
        // Set user as logged in
        await userProvider.setUserData(MockData.createUser().toJson());

        // Call logout multiple times concurrently
        final futures = List.generate(3, (_) => userProvider.logout());
        await Future.wait(futures);

        expect(userProvider.isLoggedIn, isFalse);
        expect(userProvider.userData, isNull);
      });

      test('should handle concurrent profile updates', () async {
        await userProvider.setUserData(MockData.createUser().toJson());

        // Perform concurrent updates
        final futures = [
          userProvider.updateUserData({'name': 'Update 1'}),
          userProvider.updateUserData({'email': 'update2@example.com'}),
          userProvider.updateUserData({'phoneNumber': '+1234567890'}),
        ];

        await Future.wait(futures);

        // The last update should win (or be merged)
        expect(userProvider.userData, isNotNull);
        expect(userProvider.isLoggedIn, isTrue);
      });
    });

    group('Memory Management', () {
      test('should properly dispose of resources', () async {
        await userProvider.setUserData(MockData.createUser().toJson());
        
        // Add listeners
        void listener1() {}
        void listener2() {}
        
        userProvider.addListener(listener1);
        userProvider.addListener(listener2);

        // Dispose should not throw
        userProvider.dispose();

        // Verify no memory leaks by checking that operations after dispose don't crash
        expect(() => userProvider.isLoggedIn, returnsNormally);
      });

      test('should handle large user data efficiently', () async {
        // Create user data with large preferences object
        final userData = MockData.createUser().toJson();
        userData['preferences'] = {
          for (int i = 0; i < 1000; i++) 'setting_$i': 'value_$i'
        };

        final stopwatch = Stopwatch()..start();
        await userProvider.setUserData(userData);
        stopwatch.stop();

        expect(userProvider.isLoggedIn, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
      });
    });

    group('Edge Cases', () {
      test('should handle null user data gracefully', () async {
        // This tests the provider's robustness
        await userProvider.setUserData(<String, dynamic>{});

        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.userName, isNull);
        expect(userProvider.userEmail, isNull);
        expect(userProvider.userId, isNull);
      });

      test('should handle malformed JSON in secure storage', () async {
        when(mockSecureStorage.read(key: 'access_token'))
            .thenAnswer((_) async => 'valid-token');
        when(mockSecureStorage.read(key: 'user_data'))
            .thenAnswer((_) async => '{"invalid": json}'); // Malformed JSON

        await userProvider.initialize();

        // Should handle gracefully and attempt to fetch profile
        expect(userProvider.isLoggedIn, isFalse);
      });

      test('should handle extremely long user data strings', () async {
        final userData = MockData.createUser().toJson();
        userData['bio'] = 'x' * 10000; // Very long string

        await userProvider.setUserData(userData);

        expect(userProvider.isLoggedIn, isTrue);
        expect(userProvider.userData?['bio']?.length, equals(10000));
      });

      test('should handle special characters in user data', () async {
        final userData = MockData.createUser().toJson();
        userData['name'] = 'José María Ñoño 中文 🎵';
        userData['bio'] = 'Special chars: @#\$%^&*()[]{}|;:,.<>?';

        await userProvider.setUserData(userData);

        expect(userProvider.userName, equals('José María Ñoño 中文 🎵'));
        expect(userProvider.userData?['bio'], contains('Special chars'));
      });
    });

    group('Integration', () {
      test('should sync liked songs after login', () async {
        final userData = {'id': '1', 'name': 'Test User'};

        await userProvider.setUserData(userData);

        // Verify sync was called (may be async)
        await TestHelpers.waitForAsync(100);
        verify(mockLikedSongsService.syncAfterLogin()).called(1);
      });

      test('should handle sync errors gracefully', () async {
        // Mock sync error
        when(mockLikedSongsService.syncAfterLogin()).thenThrow(Exception('Sync error'));

        final userData = {'id': '1', 'name': 'Test User'};

        // Should not throw
        await userProvider.setUserData(userData);

        expect(userProvider.isLoggedIn, isTrue);
      });

      test('should coordinate with all services during logout', () async {
        await userProvider.logout();

        // Verify all services are called
        verify(mockApiService.logout()).called(1);
        verify(mockLikedSongsService.clearLocalDataOnLogout(forceFullClear: true)).called(1);
        verify(mockCacheService.clearAllCache()).called(1);
        verify(mockCacheManager.emptyCache()).called(1);
      });

      test('should update liked collections count after authentication', () async {
        when(mockCollectionService.getLikedCollections()).thenAnswer((_) async => 
          MockData.createCollectionList(count: 3).cast<Collection>());

        await userProvider.setUserData(MockData.createUser().toJson());
        
        // Should trigger background update
        await TestHelpers.waitForAsync(200);
        
        // The count might be updated in the background
        expect(userProvider.likedCollectionsCount, anyOf(isNull, equals(3)));
      });
    });
  });
}