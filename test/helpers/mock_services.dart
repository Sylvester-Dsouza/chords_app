import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/services/api_service.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/services/audio_service.dart';
import '../../lib/services/cache_service.dart';
import '../../lib/services/offline_service.dart';
import '../../lib/services/song_service.dart';
import '../../lib/services/user_progress_service.dart';
import 'mock_data.dart';

// Generate mocks for services
@GenerateMocks([
  ApiService,
  AuthService,
  AudioService,
  CacheService,
  OfflineService,
  SongService,
  UserProgressService,
])
import 'mock_services.mocks.dart';

/// Service mock factory for creating configured mock services
class ServiceMockFactory {
  /// Creates a mock API service with default behavior
  static MockApiService createMockApiService() {
    final mock = MockApiService();
    
    // Setup default responses
    when(mock.get(any)).thenAnswer((_) async => MockData.createApiResponse(
      data: MockData.createSongList(),
    ));
    
    when(mock.post(any, any)).thenAnswer((_) async => MockData.createApiResponse(
      data: {'success': true},
    ));
    
    when(mock.put(any, any)).thenAnswer((_) async => MockData.createApiResponse(
      data: {'success': true},
    ));
    
    when(mock.delete(any)).thenAnswer((_) async => MockData.createApiResponse(
      data: {'success': true},
    ));
    
    return mock;
  }

  /// Creates a mock auth service with default behavior
  static MockAuthService createMockAuthService() {
    final mock = MockAuthService();
    
    // Setup default authentication responses
    when(mock.signIn(any, any)).thenAnswer((_) async => true);
    when(mock.signOut()).thenAnswer((_) async {});
    when(mock.signUp(any, any, any)).thenAnswer((_) async => true);
    when(mock.resetPassword(any)).thenAnswer((_) async => true);
    when(mock.isAuthenticated).thenReturn(false);
    when(mock.currentUser).thenReturn(null);
    
    return mock;
  }

  /// Creates a mock audio service with default behavior
  static MockAudioService createMockAudioService() {
    final mock = MockAudioService();
    
    // Setup default audio responses
    when(mock.play(any)).thenAnswer((_) async {});
    when(mock.pause()).thenAnswer((_) async {});
    when(mock.stop()).thenAnswer((_) async {});
    when(mock.seek(any)).thenAnswer((_) async {});
    when(mock.setVolume(any)).thenAnswer((_) async {});
    when(mock.isPlaying).thenReturn(false);
    when(mock.duration).thenReturn(const Duration(minutes: 3));
    when(mock.position).thenReturn(Duration.zero);
    
    return mock;
  }

  /// Creates a mock cache service with default behavior
  static MockCacheService createMockCacheService() {
    final mock = MockCacheService();
    final Map<String, dynamic> cache = {};
    
    // Setup cache behavior
    when(mock.get(any)).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      return cache[key];
    });
    
    when(mock.set(any, any)).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      final value = invocation.positionalArguments[1];
      cache[key] = value;
    });
    
    when(mock.remove(any)).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      cache.remove(key);
    });
    
    when(mock.clear()).thenAnswer((_) async {
      cache.clear();
    });
    
    when(mock.has(any)).thenAnswer((invocation) async {
      final key = invocation.positionalArguments[0] as String;
      return cache.containsKey(key);
    });
    
    return mock;
  }

  /// Creates a mock offline service with default behavior
  static MockOfflineService createMockOfflineService() {
    final mock = MockOfflineService();
    
    // Setup offline service behavior
    when(mock.isOnline).thenReturn(true);
    when(mock.syncData()).thenAnswer((_) async {});
    when(mock.cacheData(any, any)).thenAnswer((_) async {});
    when(mock.getCachedData(any)).thenAnswer((_) async => null);
    when(mock.clearCache()).thenAnswer((_) async {});
    
    return mock;
  }

  /// Creates a mock song service with default behavior
  static MockSongService createMockSongService() {
    final mock = MockSongService();
    
    // Setup song service behavior
    when(mock.getSongs()).thenAnswer((_) async => MockData.createSongList());
    when(mock.getSong(any)).thenAnswer((_) async => MockData.createSong());
    when(mock.searchSongs(any)).thenAnswer((_) async => MockData.createSongList());
    when(mock.likeSong(any)).thenAnswer((_) async => true);
    when(mock.unlikeSong(any)).thenAnswer((_) async => true);
    when(mock.rateSong(any, any)).thenAnswer((_) async => true);
    
    return mock;
  }

  /// Creates a mock user progress service with default behavior
  static MockUserProgressService createMockUserProgressService() {
    final mock = MockUserProgressService();
    
    // Setup user progress behavior
    when(mock.getUserProgress()).thenAnswer((_) async => {
      'songsLearned': 10,
      'practiceTime': 120,
      'achievements': ['first_song', 'practice_streak'],
    });
    
    when(mock.updateProgress(any)).thenAnswer((_) async {});
    when(mock.resetProgress()).thenAnswer((_) async {});
    
    return mock;
  }

  /// Creates a complete set of mock services for testing
  static Map<Type, dynamic> createAllMockServices() {
    return {
      ApiService: createMockApiService(),
      AuthService: createMockAuthService(),
      AudioService: createMockAudioService(),
      CacheService: createMockCacheService(),
      OfflineService: createMockOfflineService(),
      SongService: createMockSongService(),
      UserProgressService: createMockUserProgressService(),
    };
  }
}

/// Helper class for configuring mock service behaviors for specific test scenarios
class MockServiceConfigurator {
  /// Configures auth service for authenticated user scenario
  static void configureAuthenticatedUser(MockAuthService mockAuthService) {
    when(mockAuthService.isAuthenticated).thenReturn(true);
    when(mockAuthService.currentUser).thenReturn(MockData.createUser());
  }

  /// Configures auth service for unauthenticated user scenario
  static void configureUnauthenticatedUser(MockAuthService mockAuthService) {
    when(mockAuthService.isAuthenticated).thenReturn(false);
    when(mockAuthService.currentUser).thenReturn(null);
  }

  /// Configures API service for error scenarios
  static void configureApiError(MockApiService mockApiService) {
    when(mockApiService.get(any)).thenThrow(Exception('Network error'));
    when(mockApiService.post(any, any)).thenThrow(Exception('Network error'));
    when(mockApiService.put(any, any)).thenThrow(Exception('Network error'));
    when(mockApiService.delete(any)).thenThrow(Exception('Network error'));
  }

  /// Configures offline service for offline scenario
  static void configureOfflineMode(MockOfflineService mockOfflineService) {
    when(mockOfflineService.isOnline).thenReturn(false);
    when(mockOfflineService.getCachedData(any)).thenAnswer((_) async => 
      MockData.createSongList());
  }

  /// Configures audio service for playing state
  static void configureAudioPlaying(MockAudioService mockAudioService) {
    when(mockAudioService.isPlaying).thenReturn(true);
    when(mockAudioService.position).thenReturn(const Duration(seconds: 30));
  }

  /// Configures audio service for paused state
  static void configureAudioPaused(MockAudioService mockAudioService) {
    when(mockAudioService.isPlaying).thenReturn(false);
    when(mockAudioService.position).thenReturn(const Duration(seconds: 45));
  }

  /// Configures song service with empty results
  static void configureEmptyResults(MockSongService mockSongService) {
    when(mockSongService.getSongs()).thenAnswer((_) async => []);
    when(mockSongService.searchSongs(any)).thenAnswer((_) async => []);
  }

  /// Configures song service with loading delay
  static void configureSlowLoading(MockSongService mockSongService) {
    when(mockSongService.getSongs()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
      return MockData.createSongList();
    });
  }
}