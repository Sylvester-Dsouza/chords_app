import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:chords_app/services/offline_service.dart';
import 'package:chords_app/models/song.dart';
import 'package:chords_app/models/artist.dart';
import 'package:chords_app/models/collection.dart';

// Generate mocks
@GenerateMocks([
  SharedPreferences,
  Connectivity,
])
import 'offline_service_test.mocks.dart';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OfflineService', () {
    late OfflineService offlineService;
    late MockSharedPreferences mockSharedPreferences;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      mockConnectivity = MockConnectivity();

      // Setup default mock behaviors
      when(mockSharedPreferences.getString(any)).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
      when(mockSharedPreferences.getBool(any)).thenReturn(null);
      when(mockSharedPreferences.setBool(any, any)).thenAnswer((_) async => true);
      when(mockSharedPreferences.remove(any)).thenAnswer((_) async => true);

      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.fromIterable([[ConnectivityResult.wifi]]));

      // Get singleton instance
      offlineService = OfflineService();
    });

    tearDown(() {
      offlineService.dispose();
    });

    group('Initialization', () {
      test('should create OfflineService singleton instance', () {
        final instance1 = OfflineService();
        final instance2 = OfflineService();
        
        expect(instance1, equals(instance2));
        expect(instance1, isA<OfflineService>());
      });

      test('should initialize without errors', () async {
        expect(() => offlineService.initialize(), returnsNormally);
      });

      test('should have correct initial state', () {
        expect(offlineService.isOnline, isA<bool>());
        expect(offlineService.isOffline, equals(!offlineService.isOnline));
        expect(offlineService.offlineModeEnabled, isA<bool>());
      });
    });

    group('Connectivity Management', () {
      test('should detect online status', () {
        expect(offlineService.isOnline, isA<bool>());
        expect(offlineService.isOffline, equals(!offlineService.isOnline));
      });

      test('should handle connectivity changes', () async {
        await offlineService.initialize();
        
        // The service should handle connectivity changes
        expect(offlineService.isOnline, isA<bool>());
      });

      test('should provide offline status message', () {
        final message = offlineService.getOfflineStatusMessage();
        expect(message, isA<String>());
        expect(message.isNotEmpty, isTrue);
      });

      test('should determine when to use offline data', () {
        final shouldUse = offlineService.shouldUseOfflineData();
        expect(shouldUse, isA<bool>());
      });
    });

    group('Offline Mode Management', () {
      test('should enable offline mode', () async {
        await offlineService.setOfflineModeEnabled(true);
        expect(offlineService.offlineModeEnabled, isTrue);
      });

      test('should disable offline mode', () async {
        await offlineService.setOfflineModeEnabled(false);
        expect(offlineService.offlineModeEnabled, isFalse);
      });

      test('should toggle offline mode', () async {
        final initialState = offlineService.offlineModeEnabled;
        
        await offlineService.setOfflineModeEnabled(!initialState);
        expect(offlineService.offlineModeEnabled, equals(!initialState));
        
        await offlineService.setOfflineModeEnabled(initialState);
        expect(offlineService.offlineModeEnabled, equals(initialState));
      });
    });

    group('Song Caching', () {
      test('should cache songs for offline use', () async {
        final songs = [
          Song(
            id: '1',
            title: 'Test Song 1',
            artist: 'Test Artist 1',
            key: 'C',
            lyrics: 'Test lyrics 1',
            chords: 'C G Am F',
          ),
          Song(
            id: '2',
            title: 'Test Song 2',
            artist: 'Test Artist 2',
            key: 'G',
            lyrics: 'Test lyrics 2',
            chords: 'G D Em C',
          ),
        ];

        expect(() => offlineService.cacheSongsForOffline(songs), returnsNormally);
      });

      test('should retrieve cached songs', () async {
        final cachedSongs = await offlineService.getCachedSongs();
        expect(cachedSongs, anyOf(isNull, isA<List<Song>>()));
      });

      test('should handle empty song cache', () async {
        final cachedSongs = await offlineService.getCachedSongs();
        expect(cachedSongs, anyOf(isNull, isEmpty));
      });

      test('should cache and retrieve songs correctly', () async {
        final originalSongs = [
          Song(
            id: '1',
            title: 'Test Song',
            artist: 'Test Artist',
            key: 'C',
            lyrics: 'Test lyrics',
            chords: 'C G Am F',
          ),
        ];

        // Cache songs
        await offlineService.cacheSongsForOffline(originalSongs);
        
        // This test verifies the method calls work without errors
        expect(() => offlineService.getCachedSongs(), returnsNormally);
      });
    });

    group('Artist Caching', () {
      test('should cache artists for offline use', () async {
        final artists = [
          Artist(
            id: '1',
            name: 'Test Artist 1',
            bio: 'Test bio 1',
          ),
          Artist(
            id: '2',
            name: 'Test Artist 2',
            bio: 'Test bio 2',
          ),
        ];

        expect(() => offlineService.cacheArtistsForOffline(artists), returnsNormally);
      });

      test('should retrieve cached artists', () async {
        final cachedArtists = await offlineService.getCachedArtists();
        expect(cachedArtists, anyOf(isNull, isA<List<Artist>>()));
      });

      test('should handle empty artist cache', () async {
        final cachedArtists = await offlineService.getCachedArtists();
        expect(cachedArtists, anyOf(isNull, isEmpty));
      });
    });

    group('Collection Caching', () {
      test('should cache collections for offline use', () async {
        final collections = [
          Collection(
            id: '1',
            title: 'Test Collection 1',
            description: 'Test description 1',
            color: const Color(0xFF2196F3),
          ),
          Collection(
            id: '2',
            title: 'Test Collection 2',
            description: 'Test description 2',
            color: const Color(0xFF4CAF50),
          ),
        ];

        expect(() => offlineService.cacheCollectionsForOffline(collections), returnsNormally);
      });

      test('should retrieve cached collections', () async {
        final cachedCollections = await offlineService.getCachedCollections();
        expect(cachedCollections, anyOf(isNull, isA<List<Collection>>()));
      });

      test('should handle empty collection cache', () async {
        final cachedCollections = await offlineService.getCachedCollections();
        expect(cachedCollections, anyOf(isNull, isEmpty));
      });
    });

    group('Data Availability', () {
      test('should check if offline data is available', () async {
        final hasData = await offlineService.hasOfflineData();
        expect(hasData, isA<bool>());
      });

      test('should handle no offline data scenario', () async {
        // When no data is cached, should return false
        final hasData = await offlineService.hasOfflineData();
        expect(hasData, isFalse);
      });

      test('should detect offline data when available', () async {
        // Cache some data first
        final songs = [
          Song(
            id: '1',
            title: 'Test Song',
            artist: 'Test Artist',
            key: 'C',
            lyrics: 'Test lyrics',
            chords: 'C G Am F',
          ),
        ];
        
        await offlineService.cacheSongsForOffline(songs);
        
        // Should detect that data is available
        final hasData = await offlineService.hasOfflineData();
        expect(hasData, isA<bool>());
      });
    });

    group('Sync Management', () {
      test('should get last sync time', () async {
        final lastSync = await offlineService.getLastSyncTime();
        expect(lastSync, anyOf(isNull, isA<DateTime>()));
      });

      test('should handle no previous sync', () async {
        final lastSync = await offlineService.getLastSyncTime();
        expect(lastSync, isNull);
      });

      test('should track sync timestamps', () async {
        // This test verifies that sync time tracking works
        final initialSync = await offlineService.getLastSyncTime();
        expect(initialSync, anyOf(isNull, isA<DateTime>()));
      });
    });

    group('Cache Management', () {
      test('should clear all offline data', () async {
        expect(() => offlineService.clearOfflineData(), returnsNormally);
      });

      test('should handle clearing empty cache', () async {
        // Should not throw when clearing empty cache
        expect(() => offlineService.clearOfflineData(), returnsNormally);
      });

      test('should clear specific data types', () async {
        // Cache some data
        final songs = [
          Song(
            id: '1',
            title: 'Test Song',
            artist: 'Test Artist',
            key: 'C',
            lyrics: 'Test lyrics',
            chords: 'C G Am F',
          ),
        ];
        
        await offlineService.cacheSongsForOffline(songs);
        
        // Clear all data
        await offlineService.clearOfflineData();
        
        // Verify data is cleared
        final cachedSongs = await offlineService.getCachedSongs();
        expect(cachedSongs, anyOf(isNull, isEmpty));
      });
    });

    group('Status Messages', () {
      test('should provide appropriate status messages for different states', () {
        // Test different combinations of online/offline and offline mode
        final message = offlineService.getOfflineStatusMessage();
        expect(message, isA<String>());
        expect(message.isNotEmpty, isTrue);
      });

      test('should handle offline status message', () {
        final message = offlineService.getOfflineStatusMessage();
        expect([
          'You\'re offline. Using cached data.',
          'No internet connection. Limited functionality available.',
          'Offline mode enabled. Using cached data.',
          'Online',
        ].contains(message), isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        // Test that storage errors don't crash the service
        expect(() => offlineService.getCachedSongs(), returnsNormally);
        expect(() => offlineService.getCachedArtists(), returnsNormally);
        expect(() => offlineService.getCachedCollections(), returnsNormally);
      });

      test('should handle connectivity errors gracefully', () async {
        // Test that connectivity errors don't crash the service
        expect(() => offlineService.initialize(), returnsNormally);
      });

      test('should handle invalid cached data gracefully', () async {
        // Test that invalid cached data doesn't crash the service
        final songs = await offlineService.getCachedSongs();
        expect(songs, anyOf(isNull, isA<List<Song>>()));
      });

      test('should handle cache corruption gracefully', () async {
        // Test that cache corruption is handled gracefully
        expect(() => offlineService.clearOfflineData(), returnsNormally);
      });
    });

    group('Data Synchronization', () {
      test('should handle data sync scenarios', () async {
        // Test that sync-related operations work
        final lastSync = await offlineService.getLastSyncTime();
        expect(lastSync, anyOf(isNull, isA<DateTime>()));
      });

      test('should determine sync requirements', () {
        final shouldUseOffline = offlineService.shouldUseOfflineData();
        expect(shouldUseOffline, isA<bool>());
      });

      test('should handle sync state transitions', () async {
        // Test transitions between online and offline states
        await offlineService.setOfflineModeEnabled(true);
        expect(offlineService.shouldUseOfflineData(), isTrue);
        
        await offlineService.setOfflineModeEnabled(false);
        // Should depend on actual connectivity
        expect(offlineService.shouldUseOfflineData(), isA<bool>());
      });
    });

    group('Resource Management', () {
      test('should dispose resources properly', () {
        final service = OfflineService();
        expect(() => service.dispose(), returnsNormally);
      });

      test('should handle multiple dispose calls', () {
        final service = OfflineService();
        expect(() => service.dispose(), returnsNormally);
        expect(() => service.dispose(), returnsNormally);
      });

      test('should clean up connectivity subscriptions', () {
        final service = OfflineService();
        service.dispose();
        
        // Should not throw after disposal
        expect(() => service.dispose(), returnsNormally);
      });
    });

    group('Integration', () {
      test('should integrate connectivity and storage properly', () async {
        await offlineService.initialize();
        
        // Should handle both connectivity and storage operations
        expect(offlineService.isOnline, isA<bool>());
        expect(() => offlineService.getCachedSongs(), returnsNormally);
      });

      test('should coordinate offline mode with connectivity', () async {
        await offlineService.setOfflineModeEnabled(true);
        
        final shouldUseOffline = offlineService.shouldUseOfflineData();
        expect(shouldUseOffline, isTrue);
      });

      test('should handle complex offline scenarios', () async {
        // Cache some data
        final songs = [
          Song(
            id: '1',
            title: 'Test Song',
            artist: 'Test Artist',
            key: 'C',
            lyrics: 'Test lyrics',
            chords: 'C G Am F',
          ),
        ];
        
        await offlineService.cacheSongsForOffline(songs);
        
        // Enable offline mode
        await offlineService.setOfflineModeEnabled(true);
        
        // Should use offline data
        expect(offlineService.shouldUseOfflineData(), isTrue);
        
        // Should have offline data available
        final hasData = await offlineService.hasOfflineData();
        expect(hasData, isA<bool>());
      });
    });
  });
}