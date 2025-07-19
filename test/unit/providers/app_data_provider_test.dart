import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chords_app/providers/app_data_provider.dart';
import 'package:chords_app/services/home_section_service.dart';
import 'package:chords_app/services/offline_service.dart';
import 'package:chords_app/services/liked_songs_service.dart';
import 'package:chords_app/services/cache_service.dart';
import 'package:chords_app/services/song_service.dart';
import 'package:chords_app/services/artist_service.dart';
import 'package:chords_app/services/collection_service.dart';
import 'package:chords_app/services/setlist_service.dart';
import 'package:chords_app/models/song.dart';
import 'package:chords_app/models/artist.dart';
import 'package:chords_app/models/collection.dart';
import 'package:chords_app/models/setlist.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_data.dart';

// Generate mocks
@GenerateMocks([
  HomeSectionService,
  OfflineService,
  LikedSongsService,
  CacheService,
  SongService,
  ArtistService,
  CollectionService,
  SetlistService,
])
import 'app_data_provider_test.mocks.dart';

void main() {
  // Initialize Flutter bindings for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppDataProvider', () {
    late AppDataProvider appDataProvider;
    late MockHomeSectionService mockHomeSectionService;
    late MockOfflineService mockOfflineService;
    late MockLikedSongsService mockLikedSongsService;
    late MockCacheService mockCacheService;
    late MockSongService mockSongService;
    late MockArtistService mockArtistService;
    late MockCollectionService mockCollectionService;
    late MockSetlistService mockSetlistService;

    setUp(() {
      mockHomeSectionService = MockHomeSectionService();
      mockOfflineService = MockOfflineService();
      mockLikedSongsService = MockLikedSongsService();
      mockCacheService = MockCacheService();
      mockSongService = MockSongService();
      mockArtistService = MockArtistService();
      mockCollectionService = MockCollectionService();
      mockSetlistService = MockSetlistService();

      // Setup default mock behaviors
      when(mockCacheService.initialize()).thenAnswer((_) async {});
      when(mockHomeSectionService.getHomeSections()).thenAnswer((_) async => []);
      when(mockSongService.getAllSongs()).thenAnswer((_) async => []);
      when(mockArtistService.getAllArtists()).thenAnswer((_) async => []);
      when(mockCollectionService.getAllCollections()).thenAnswer((_) async => []);
      when(mockSetlistService.getSetlists()).thenAnswer((_) async => []);
      when(mockLikedSongsService.getLikedSongs(forceSync: anyNamed('forceSync')))
          .thenAnswer((_) async => []);
      when(mockOfflineService.shouldUseOfflineData()).thenReturn(false);
      when(mockOfflineService.isOnline).thenReturn(true);
      when(mockOfflineService.isOffline).thenReturn(false);
      when(mockOfflineService.getCachedSongs()).thenAnswer((_) async => null);
      when(mockOfflineService.cacheSongsForOffline(any)).thenAnswer((_) async {});
      when(mockCacheService.clearAllCache()).thenAnswer((_) async {});

      appDataProvider = AppDataProvider();
    });

    group('Initialization', () {
      test('should create AppDataProvider instance successfully', () {
        expect(appDataProvider, isA<AppDataProvider>());
      });

      test('should have correct initial state', () {
        expect(appDataProvider.homeState, equals(DataState.loading));
        expect(appDataProvider.songsState, equals(DataState.loading));
        expect(appDataProvider.artistsState, equals(DataState.loading));
        expect(appDataProvider.collectionsState, equals(DataState.loading));
        expect(appDataProvider.setlistsState, equals(DataState.loading));
        expect(appDataProvider.likedSongsState, equals(DataState.loading));
        expect(appDataProvider.homeSections, isEmpty);
        expect(appDataProvider.songs, isEmpty);
        expect(appDataProvider.artists, isEmpty);
        expect(appDataProvider.collections, isEmpty);
        expect(appDataProvider.setlists, isEmpty);
        expect(appDataProvider.likedSongs, isEmpty);
      });

      test('should initialize app data successfully', () async {
        // Mock home sections
        final mockHomeSections = [
          HomeSection(id: '1', title: 'Featured', type: SectionType.COLLECTIONS, items: []),
          HomeSection(id: '2', title: 'Popular', type: SectionType.SONGS, items: []),
        ];
        when(mockHomeSectionService.getHomeSections())
            .thenAnswer((_) async => mockHomeSections);

        await appDataProvider.initializeAppData();

        expect(appDataProvider.homeState, equals(DataState.loaded));
        expect(appDataProvider.homeSections.length, equals(2));
        verify(mockCacheService.initialize()).called(1);
        verify(mockHomeSectionService.getHomeSections()).called(1);
      });

      test('should handle initialization errors gracefully', () async {
        when(mockHomeSectionService.getHomeSections())
            .thenThrow(Exception('Network error'));

        await appDataProvider.initializeAppData();

        expect(appDataProvider.homeState, equals(DataState.error));
        expect(appDataProvider.homeSections, isEmpty);
      });

      test('should initialize after login successfully', () async {
        final mockHomeSections = [
          HomeSection(id: '1', title: 'Featured', type: SectionType.COLLECTIONS, items: []),
        ];
        when(mockHomeSectionService.getHomeSections())
            .thenAnswer((_) async => mockHomeSections);

        await appDataProvider.initializeAfterLogin();

        expect(appDataProvider.homeState, equals(DataState.loaded));
        expect(appDataProvider.homeSections.length, equals(1));
      });
    });

    group('Home Sections Management', () {
      test('should get home sections successfully', () async {
        final mockHomeSections = [
          HomeSection(id: '1', title: 'Featured', type: SectionType.COLLECTIONS, items: []),
          HomeSection(id: '2', title: 'Popular', type: SectionType.SONGS, items: []),
        ];
        when(mockHomeSectionService.getHomeSections())
            .thenAnswer((_) async => mockHomeSections);

        final result = await appDataProvider.getHomeSections();

        expect(result.length, equals(2));
        expect(appDataProvider.homeState, equals(DataState.loaded));
        expect(appDataProvider.homeSections.length, equals(2));
      });

      test('should handle home sections fetch error', () async {
        when(mockHomeSectionService.getHomeSections())
            .thenThrow(Exception('API error'));

        final result = await appDataProvider.getHomeSections();

        expect(appDataProvider.homeState, equals(DataState.error));
        expect(result, isEmpty); // Should return empty list on error
      });

      test('should force refresh home sections', () async {
        final mockHomeSections = [
          HomeSection(id: '1', title: 'Updated', type: SectionType.COLLECTIONS, items: []),
        ];
        when(mockHomeSectionService.getHomeSections())
            .thenAnswer((_) async => mockHomeSections);

        final result = await appDataProvider.getHomeSections(forceRefresh: true);

        expect(result.length, equals(1));
        expect(result.first.title, equals('Updated'));
        verify(mockHomeSectionService.getHomeSections()).called(1);
      });
    });

    group('Songs Management', () {
      test('should get songs successfully', () async {
        final mockSongs = MockData.createSongList(count: 3);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);

        final result = await appDataProvider.getSongs();

        expect(result.length, equals(3));
        expect(appDataProvider.songsState, equals(DataState.loaded));
        expect(appDataProvider.songs.length, equals(3));
        verify(mockSongService.getAllSongs()).called(1);
      });

      test('should handle songs fetch error', () async {
        when(mockSongService.getAllSongs()).thenThrow(Exception('Network error'));

        final result = await appDataProvider.getSongs();

        expect(appDataProvider.songsState, equals(DataState.error));
        expect(result, isEmpty);
      });

      test('should limit songs in memory for performance', () async {
        // Create more songs than the memory limit (50)
        final mockSongs = List.generate(60, (index) => MockData.createSong(
          id: 'song-$index',
          title: 'Song $index',
        ));
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);

        final result = await appDataProvider.getSongs();

        // Should limit to maxSongsInMemory (50)
        expect(result.length, equals(50));
        expect(appDataProvider.songs.length, equals(50));
      });

      test('should use offline data when offline', () async {
        final offlineSongs = MockData.createSongList(count: 2);
        when(mockOfflineService.shouldUseOfflineData()).thenReturn(true);
        when(mockOfflineService.getCachedSongs()).thenAnswer((_) async => offlineSongs);

        final result = await appDataProvider.getSongs();

        expect(result.length, equals(2));
        expect(appDataProvider.songsState, equals(DataState.loaded));
        verify(mockOfflineService.getCachedSongs()).called(1);
      });

      test('should cache songs for offline use when online', () async {
        final mockSongs = MockData.createSongList(count: 3);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);
        when(mockOfflineService.isOnline).thenReturn(true);

        await appDataProvider.getSongs();

        verify(mockOfflineService.cacheSongsForOffline(mockSongs)).called(1);
      });

      test('should fallback to offline data on API error', () async {
        final offlineSongs = MockData.createSongList(count: 2);
        when(mockSongService.getAllSongs()).thenThrow(Exception('Network error'));
        when(mockOfflineService.isOffline).thenReturn(true);
        when(mockOfflineService.getCachedSongs()).thenAnswer((_) async => offlineSongs);

        final result = await appDataProvider.getSongs();

        expect(result.length, equals(2));
        expect(appDataProvider.songsState, equals(DataState.loaded));
      });
    });

    group('Artists Management', () {
      test('should get artists successfully', () async {
        final mockArtists = [
          Artist(id: '1', name: 'Artist 1', songCount: 5),
          Artist(id: '2', name: 'Artist 2', songCount: 3),
        ];
        when(mockArtistService.getAllArtists()).thenAnswer((_) async => mockArtists);

        final result = await appDataProvider.getArtists();

        expect(result.length, equals(2));
        expect(appDataProvider.artistsState, equals(DataState.loaded));
        expect(appDataProvider.artists.length, equals(2));
        verify(mockArtistService.getAllArtists()).called(1);
      });

      test('should handle artists fetch error', () async {
        when(mockArtistService.getAllArtists()).thenThrow(Exception('API error'));

        final result = await appDataProvider.getArtists();

        expect(appDataProvider.artistsState, equals(DataState.error));
        expect(result, isEmpty);
      });

      test('should limit artists in memory for performance', () async {
        // Create more artists than the memory limit (25)
        final mockArtists = List.generate(30, (index) => Artist(
          id: 'artist-$index',
          name: 'Artist $index',
          songCount: index,
        ));
        when(mockArtistService.getAllArtists()).thenAnswer((_) async => mockArtists);

        final result = await appDataProvider.getArtists();

        // Should limit to maxArtistsInMemory (25)
        expect(result.length, equals(25));
        expect(appDataProvider.artists.length, equals(25));
      });

      test('should force refresh artists', () async {
        final mockArtists = [
          Artist(id: '1', name: 'Updated Artist', songCount: 10),
        ];
        when(mockArtistService.getAllArtists()).thenAnswer((_) async => mockArtists);

        final result = await appDataProvider.getArtists(forceRefresh: true);

        expect(result.length, equals(1));
        expect(result.first.name, equals('Updated Artist'));
        verify(mockArtistService.getAllArtists()).called(1);
      });
    });

    group('Collections Management', () {
      test('should get collections successfully', () async {
        final mockCollections = [
          Collection(
            id: '1',
            title: 'Worship Songs',
            color: const Color(0xFF2196F3),
            songCount: 10,
          ),
          Collection(
            id: '2',
            title: 'Christmas Songs',
            color: const Color(0xFF4CAF50),
            songCount: 5,
          ),
        ];
        when(mockCollectionService.getAllCollections())
            .thenAnswer((_) async => mockCollections);

        final result = await appDataProvider.getCollections();

        expect(result.length, equals(2));
        expect(appDataProvider.collectionsState, equals(DataState.loaded));
        expect(appDataProvider.collections.length, equals(2));
        verify(mockCollectionService.getAllCollections()).called(1);
      });

      test('should handle collections fetch error', () async {
        when(mockCollectionService.getAllCollections())
            .thenThrow(Exception('Network error'));

        final result = await appDataProvider.getCollections();

        expect(appDataProvider.collectionsState, equals(DataState.error));
        expect(result, isEmpty);
      });

      test('should limit collections in memory for performance', () async {
        // Create more collections than the memory limit (15)
        final mockCollections = List.generate(20, (index) => Collection(
          id: 'collection-$index',
          title: 'Collection $index',
          color: const Color(0xFF2196F3),
          songCount: index,
        ));
        when(mockCollectionService.getAllCollections())
            .thenAnswer((_) async => mockCollections);

        final result = await appDataProvider.getCollections();

        // Should limit to maxCollectionsInMemory (15)
        expect(result.length, equals(15));
        expect(appDataProvider.collections.length, equals(15));
      });
    });

    group('Setlists Management', () {
      test('should get setlists successfully', () async {
        final mockSetlists = [
          Setlist(
            id: '1',
            name: 'Sunday Service',
            customerId: 'customer1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Setlist(
            id: '2',
            name: 'Youth Night',
            customerId: 'customer1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        when(mockSetlistService.getSetlists()).thenAnswer((_) async => mockSetlists);

        final result = await appDataProvider.getSetlists();

        expect(result.length, equals(2));
        expect(appDataProvider.setlistsState, equals(DataState.loaded));
        expect(appDataProvider.setlists.length, equals(2));
        verify(mockSetlistService.getSetlists()).called(1);
      });

      test('should handle setlists fetch error', () async {
        when(mockSetlistService.getSetlists()).thenThrow(Exception('API error'));

        final result = await appDataProvider.getSetlists();

        expect(appDataProvider.setlistsState, equals(DataState.error));
        expect(result, isEmpty);
      });

      test('should force refresh setlists', () async {
        final mockSetlists = [
          Setlist(
            id: '1',
            name: 'Updated Setlist',
            customerId: 'customer1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        when(mockSetlistService.getSetlists()).thenAnswer((_) async => mockSetlists);

        final result = await appDataProvider.getSetlists(forceRefresh: true);

        expect(result.length, equals(1));
        expect(result.first.name, equals('Updated Setlist'));
        verify(mockSetlistService.getSetlists()).called(1);
      });
    });

    group('Liked Songs Management', () {
      test('should get liked songs successfully', () async {
        final mockLikedSongs = MockData.createSongList(count: 5);
        when(mockLikedSongsService.getLikedSongs(forceSync: true))
            .thenAnswer((_) async => mockLikedSongs);

        final result = await appDataProvider.getLikedSongs();

        expect(result.length, equals(5));
        expect(appDataProvider.likedSongsState, equals(DataState.loaded));
        expect(appDataProvider.likedSongs.length, equals(5));
        verify(mockLikedSongsService.getLikedSongs(forceSync: true)).called(1);
      });

      test('should handle liked songs fetch error', () async {
        when(mockLikedSongsService.getLikedSongs(forceSync: true))
            .thenThrow(Exception('Network error'));

        final result = await appDataProvider.getLikedSongs();

        expect(appDataProvider.likedSongsState, equals(DataState.error));
        expect(result, isEmpty);
      });

      test('should force refresh liked songs', () async {
        final mockLikedSongs = MockData.createSongList(count: 3);
        when(mockLikedSongsService.getLikedSongs(forceSync: true))
            .thenAnswer((_) async => mockLikedSongs);

        final result = await appDataProvider.getLikedSongs(forceRefresh: true);

        expect(result.length, equals(3));
        verify(mockLikedSongsService.getLikedSongs(forceSync: true)).called(1);
      });
    });

    group('Data Refresh and Caching', () {
      test('should refresh all data sequentially', () async {
        final mockHomeSections = [HomeSection(id: '1', title: 'Featured', type: SectionType.COLLECTIONS, items: [])];
        final mockSongs = MockData.createSongList(count: 2);
        final mockArtists = [Artist(id: '1', name: 'Artist 1', songCount: 5)];
        final mockCollections = [Collection(id: '1', title: 'Collection 1', color: const Color(0xFF2196F3))];
        final mockSetlists = [
          Setlist(
            id: '1',
            name: 'Setlist 1',
            customerId: 'customer1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        ];
        final mockLikedSongs = MockData.createSongList(count: 1);

        when(mockHomeSectionService.getHomeSections()).thenAnswer((_) async => mockHomeSections);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);
        when(mockArtistService.getAllArtists()).thenAnswer((_) async => mockArtists);
        when(mockCollectionService.getAllCollections()).thenAnswer((_) async => mockCollections);
        when(mockSetlistService.getSetlists()).thenAnswer((_) async => mockSetlists);
        when(mockLikedSongsService.getLikedSongs(forceSync: true)).thenAnswer((_) async => mockLikedSongs);

        await appDataProvider.refreshAllData();

        expect(appDataProvider.homeState, equals(DataState.loaded));
        expect(appDataProvider.songsState, equals(DataState.loaded));
        expect(appDataProvider.artistsState, equals(DataState.loaded));
        expect(appDataProvider.collectionsState, equals(DataState.loaded));
        expect(appDataProvider.setlistsState, equals(DataState.loaded));
        expect(appDataProvider.likedSongsState, equals(DataState.loaded));

        // Verify all services were called
        verify(mockHomeSectionService.getHomeSections()).called(1);
        verify(mockSongService.getAllSongs()).called(1);
        verify(mockArtistService.getAllArtists()).called(1);
        verify(mockCollectionService.getAllCollections()).called(1);
        verify(mockSetlistService.getSetlists()).called(1);
        verify(mockLikedSongsService.getLikedSongs(forceSync: true)).called(1);
      });

      test('should handle refresh all data with partial failures', () async {
        // Mock some services to succeed and others to fail
        when(mockHomeSectionService.getHomeSections())
            .thenAnswer((_) async => [HomeSection(id: '1', title: 'Featured', type: SectionType.COLLECTIONS, items: [])]);
        when(mockSongService.getAllSongs()).thenThrow(Exception('Songs API error'));
        when(mockArtistService.getAllArtists())
            .thenAnswer((_) async => [Artist(id: '1', name: 'Artist 1', songCount: 5)]);
        when(mockCollectionService.getAllCollections()).thenThrow(Exception('Collections API error'));
        when(mockSetlistService.getSetlists())
            .thenAnswer((_) async => [
              Setlist(
                id: '1',
                name: 'Setlist 1',
                customerId: 'customer1',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              )
            ]);
        when(mockLikedSongsService.getLikedSongs(forceSync: true)).thenThrow(Exception('Liked songs error'));

        // Should not throw exception
        await appDataProvider.refreshAllData();

        // Check that successful services loaded data
        expect(appDataProvider.homeState, equals(DataState.loaded));
        expect(appDataProvider.artistsState, equals(DataState.loaded));
        expect(appDataProvider.setlistsState, equals(DataState.loaded));

        // Check that failed services are in error state
        expect(appDataProvider.songsState, equals(DataState.error));
        expect(appDataProvider.collectionsState, equals(DataState.error));
        expect(appDataProvider.likedSongsState, equals(DataState.error));
      });

      test('should clear all data and cache', () async {
        // First load some data
        final mockSongs = MockData.createSongList(count: 3);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);
        await appDataProvider.getSongs();

        expect(appDataProvider.songs.length, equals(3));

        // Clear all data
        await appDataProvider.clearAllData();

        expect(appDataProvider.homeSections, isEmpty);
        expect(appDataProvider.songs, isEmpty);
        expect(appDataProvider.artists, isEmpty);
        expect(appDataProvider.collections, isEmpty);
        expect(appDataProvider.setlists, isEmpty);
        expect(appDataProvider.likedSongs, isEmpty);

        expect(appDataProvider.homeState, equals(DataState.loading));
        expect(appDataProvider.songsState, equals(DataState.loading));
        expect(appDataProvider.artistsState, equals(DataState.loading));
        expect(appDataProvider.collectionsState, equals(DataState.loading));
        expect(appDataProvider.setlistsState, equals(DataState.loading));
        expect(appDataProvider.likedSongsState, equals(DataState.loading));

        verify(mockCacheService.clearAllCache()).called(1);
      });
    });

    group('Error Handling and Retry Mechanisms', () {
      test('should handle network timeout errors', () async {
        when(mockSongService.getAllSongs()).thenThrow(Exception('Network timeout'));

        final result = await appDataProvider.getSongs();

        expect(appDataProvider.songsState, equals(DataState.error));
        expect(result, isEmpty);
      });

      test('should handle API rate limiting errors', () async {
        when(mockArtistService.getAllArtists()).thenThrow(Exception('Rate limit exceeded'));

        final result = await appDataProvider.getArtists();

        expect(appDataProvider.artistsState, equals(DataState.error));
        expect(result, isEmpty);
      });

      test('should handle JSON parsing errors gracefully', () async {
        when(mockCollectionService.getAllCollections()).thenThrow(const FormatException('Invalid JSON'));

        final result = await appDataProvider.getCollections();

        expect(appDataProvider.collectionsState, equals(DataState.error));
        expect(result, isEmpty);
      });

      test('should return cached data on error as fallback', () async {
        // First load some data successfully
        final mockSongs = MockData.createSongList(count: 2);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);
        await appDataProvider.getSongs();

        expect(appDataProvider.songs.length, equals(2));

        // Now simulate an error on refresh
        when(mockSongService.getAllSongs()).thenThrow(Exception('Network error'));
        final result = await appDataProvider.getSongs();

        // Should return cached data
        expect(result.length, equals(2));
        expect(appDataProvider.songsState, equals(DataState.error));
      });

      test('should handle concurrent API calls gracefully', () async {
        final mockSongs = MockData.createSongList(count: 3);
        when(mockSongService.getAllSongs()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return mockSongs;
        });

        // Make multiple concurrent calls
        final futures = List.generate(3, (_) => appDataProvider.getSongs());
        final results = await Future.wait(futures);

        // All should return the same data
        for (final result in results) {
          expect(result.length, equals(3));
        }
        expect(appDataProvider.songsState, equals(DataState.loaded));
      });
    });

    group('Memory Management', () {
      test('should cleanup memory when requested', () {
        // This test would need access to private fields, so we'll test the public interface
        appDataProvider.cleanupMemory();
        
        // The cleanup method should execute without throwing
        expect(appDataProvider, isA<AppDataProvider>());
      });

      test('should get cache statistics', () async {
        // Load some data first
        final mockSongs = MockData.createSongList(count: 5);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);
        await appDataProvider.getSongs();

        final stats = await appDataProvider.getCacheStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['cache'], isNotNull);
        expect(stats['dataStates'], isA<Map<String, dynamic>>());
        expect(stats['dataCounts'], isA<Map<String, dynamic>>());
        expect(stats['timestamp'], isNotNull);
        expect(stats['dataCounts']['songs'], equals(5));
      });
    });

    group('State Notifications and Listeners', () {
      test('should notify listeners when data state changes', () async {
        bool notified = false;
        
        appDataProvider.addListener(() {
          notified = true;
        });

        final mockSongs = MockData.createSongList(count: 2);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);

        await appDataProvider.getSongs();

        expect(notified, isTrue);
      });

      test('should notify listeners when data is loaded', () async {
        List<DataState> stateChanges = [];
        
        appDataProvider.addListener(() {
          stateChanges.add(appDataProvider.songsState);
        });

        final mockSongs = MockData.createSongList(count: 3);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);

        await appDataProvider.getSongs();

        expect(stateChanges, contains(DataState.loading));
        expect(stateChanges, contains(DataState.loaded));
      });

      test('should notify listeners when error occurs', () async {
        List<DataState> stateChanges = [];
        
        appDataProvider.addListener(() {
          stateChanges.add(appDataProvider.artistsState);
        });

        when(mockArtistService.getAllArtists()).thenThrow(Exception('API error'));

        await appDataProvider.getArtists();

        expect(stateChanges, contains(DataState.loading));
        expect(stateChanges, contains(DataState.error));
      });

      test('should throttle notifications to prevent loops', () async {
        int notificationCount = 0;
        
        appDataProvider.addListener(() {
          notificationCount++;
        });

        // Trigger multiple rapid state changes
        final mockSongs = MockData.createSongList(count: 1);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);
        
        // Make multiple calls in quick succession
        await Future.wait([
          appDataProvider.getSongs(),
          appDataProvider.getSongs(),
          appDataProvider.getSongs(),
        ]);

        // Should have throttled notifications
        expect(notificationCount, lessThan(10)); // Reasonable upper bound
      });

      test('should handle multiple listeners correctly', () async {
        int listener1Count = 0;
        int listener2Count = 0;
        bool listener3Called = false;

        appDataProvider.addListener(() => listener1Count++);
        appDataProvider.addListener(() => listener2Count++);
        appDataProvider.addListener(() => listener3Called = true);

        final mockSongs = MockData.createSongList(count: 1);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);

        await appDataProvider.getSongs();

        expect(listener1Count, greaterThan(0));
        expect(listener2Count, greaterThan(0));
        expect(listener3Called, isTrue);
      });
    });

    group('Data Filtering and Search', () {
      test('should handle empty search results', () async {
        when(mockSongService.getAllSongs()).thenAnswer((_) async => []);

        final result = await appDataProvider.getSongs();

        expect(result, isEmpty);
        expect(appDataProvider.songsState, equals(DataState.loaded));
      });

      test('should handle large datasets efficiently', () async {
        // Create a large dataset
        final largeSongList = List.generate(100, (index) => MockData.createSong(
          id: 'song-$index',
          title: 'Song $index',
        ));
        when(mockSongService.getAllSongs()).thenAnswer((_) async => largeSongList);

        final result = await appDataProvider.getSongs();

        // Should limit to memory constraints
        expect(result.length, equals(50)); // maxSongsInMemory
        expect(appDataProvider.songsState, equals(DataState.loaded));
      });

      test('should maintain data consistency across operations', () async {
        final mockSongs = MockData.createSongList(count: 3);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => mockSongs);

        // Load songs
        await appDataProvider.getSongs();
        final initialCount = appDataProvider.songs.length;

        // Refresh songs
        await appDataProvider.getSongs(forceRefresh: true);
        final refreshedCount = appDataProvider.songs.length;

        expect(initialCount, equals(refreshedCount));
        expect(appDataProvider.songs.length, equals(3));
      });
    });

    group('Background Refresh and Sync', () {
      test('should handle background refresh without affecting UI state', () async {
        // Initial load
        final initialSongs = MockData.createSongList(count: 2);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => initialSongs);
        await appDataProvider.getSongs();

        expect(appDataProvider.songsState, equals(DataState.loaded));

        // Background refresh with updated data
        final updatedSongs = MockData.createSongList(count: 3);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => updatedSongs);

        // Simulate background refresh (this would normally be called internally)
        await appDataProvider.getSongs();

        expect(appDataProvider.songs.length, equals(3));
        expect(appDataProvider.songsState, equals(DataState.loaded));
      });

      test('should handle offline to online transition', () async {
        // Start offline
        when(mockOfflineService.shouldUseOfflineData()).thenReturn(true);
        final offlineSongs = MockData.createSongList(count: 2);
        when(mockOfflineService.getCachedSongs()).thenAnswer((_) async => offlineSongs);

        await appDataProvider.getSongs();
        expect(appDataProvider.songs.length, equals(2));

        // Go online
        when(mockOfflineService.shouldUseOfflineData()).thenReturn(false);
        when(mockOfflineService.isOnline).thenReturn(true);
        final onlineSongs = MockData.createSongList(count: 5);
        when(mockSongService.getAllSongs()).thenAnswer((_) async => onlineSongs);

        await appDataProvider.getSongs(forceRefresh: true);
        expect(appDataProvider.songs.length, equals(5));
        verify(mockOfflineService.cacheSongsForOffline(onlineSongs)).called(1);
      });
    });

    group('Dispose and Cleanup', () {
      test('should dispose properly', () {
        appDataProvider.dispose();

        // Data should be cleared after dispose
        expect(appDataProvider.songs, isEmpty);
        expect(appDataProvider.artists, isEmpty);
        expect(appDataProvider.collections, isEmpty);
        expect(appDataProvider.setlists, isEmpty);
        expect(appDataProvider.likedSongs, isEmpty);
        expect(appDataProvider.homeSections, isEmpty);
      });
    });
  });
}