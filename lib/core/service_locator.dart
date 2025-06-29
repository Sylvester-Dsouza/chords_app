import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/cache_service.dart';
import '../services/vocal_service.dart';
import '../services/notification_service.dart';
import 'crashlytics_service.dart';
import '../services/deep_link_service.dart';
import '../services/offline_service.dart';
import '../services/artist_service.dart';
import '../services/song_service.dart';
import '../services/collection_service.dart';
import '../services/setlist_service.dart';
import '../services/liked_songs_service.dart';
import '../services/home_section_service.dart';
import '../services/community_service.dart';

import '../services/audio_service.dart';
import '../services/memory_manager.dart';
import '../services/persistent_cache_manager.dart';
import '../services/smart_data_manager.dart';
import '../services/performance_service.dart';
import '../services/connectivity_service.dart';
import 'error_handler.dart';
import 'retry_service.dart';

/// Service Locator for dependency injection
/// This ensures single instances of services across the app
final GetIt serviceLocator = GetIt.instance;

/// Initialize all services with proper dependency injection
Future<void> setupServiceLocator() async {
  // Core utility services (no dependencies)
  serviceLocator.registerLazySingleton<ErrorHandler>(() => ErrorHandler());
  serviceLocator.registerLazySingleton<RetryService>(() => RetryService());

  // Core services (no dependencies) - Using lazy singletons for memory efficiency
  serviceLocator.registerLazySingleton<ApiService>(() => ApiService());
  serviceLocator.registerLazySingleton<CacheService>(() => CacheService());
  serviceLocator.registerLazySingleton<CrashlyticsService>(() => CrashlyticsService());
  serviceLocator.registerLazySingleton<PerformanceService>(() => PerformanceService());
  serviceLocator.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  
  // Auth service (depends on ApiService)
  serviceLocator.registerLazySingleton<AuthService>(() => AuthService());
  
  // Notification service (depends on ApiService)
  serviceLocator.registerLazySingleton<NotificationService>(() => NotificationService());
  
  // Deep link service (singleton but not lazy - needs immediate initialization)
  serviceLocator.registerSingleton<DeepLinkService>(DeepLinkService());
  
  // Offline service
  serviceLocator.registerLazySingleton<OfflineService>(() => OfflineService());
  
  // Data services (depend on ApiService and CacheService)
  serviceLocator.registerLazySingleton<ArtistService>(() => ArtistService());
  serviceLocator.registerLazySingleton<SongService>(() => SongService());
  serviceLocator.registerLazySingleton<CollectionService>(() => CollectionService());
  serviceLocator.registerLazySingleton<SetlistService>(() => SetlistService());
  serviceLocator.registerLazySingleton<LikedSongsService>(() => LikedSongsService());
  serviceLocator.registerLazySingleton<HomeSectionService>(() => HomeSectionService());
  serviceLocator.registerLazySingleton<CommunityService>(() => CommunityService(serviceLocator<AuthService>()));
  
  // Vocal services
  serviceLocator.registerLazySingleton<VocalService>(() => VocalService());
  
  // Audio services
  serviceLocator.registerLazySingleton<AudioService>(() => AudioService());

  // Memory management service
  serviceLocator.registerLazySingleton<MemoryManager>(() => MemoryManager());

  // Smart caching services
  serviceLocator.registerLazySingleton<PersistentCacheManager>(() => PersistentCacheManager());
  serviceLocator.registerLazySingleton<SmartDataManager>(() => SmartDataManager());
  
  // Initialize critical services immediately
  await _initializeCriticalServices();
}

/// Initialize services that need immediate setup
Future<void> _initializeCriticalServices() async {
  try {
    // Initialize Crashlytics first for error tracking
    await serviceLocator<CrashlyticsService>().initialize();

    // Initialize Performance Monitoring (non-blocking)
    serviceLocator<PerformanceService>().initialize().catchError((e) {
      debugPrint('⚠️ Performance service initialization failed: $e');
    });

    // Initialize cache service first (needed by others)
    await serviceLocator<CacheService>().initialize();

    // Initialize auth service
    await serviceLocator<AuthService>().initializeFirebase();

    // Initialize notification service
    debugPrint('🔔 About to initialize NotificationService...');
    try {
      await serviceLocator<NotificationService>().initialize();
      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ NotificationService initialization failed: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }

    // Initialize offline service
    await serviceLocator<OfflineService>().initialize();

    // Initialize connectivity service
    await serviceLocator<ConnectivityService>().initialize();

    // Initialize memory manager
    serviceLocator<MemoryManager>().startMonitoring();

    debugPrint('✅ Critical services initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing critical services: $e');
    // Don't rethrow to prevent app crash
  }
}

/// Initialize services that can be deferred until after login
Future<void> initializeDeferredServices() async {
  try {
    // Initialize vocal service (heavy initialization)
    await serviceLocator<VocalService>().initialize();
    

    
    debugPrint('✅ Deferred services initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing deferred services: $e');
  }
}

/// Dispose all services properly with memory cleanup
Future<void> disposeServices() async {
  try {
    debugPrint('🧹 Disposing all services and cleaning memory...');

    // Stop memory monitoring first
    if (serviceLocator.isRegistered<MemoryManager>()) {
      serviceLocator<MemoryManager>().stopMonitoring();
    }

    // Dispose services in reverse order of initialization

    // Audio services - no metronome services to dispose

    // Vocal service
    if (serviceLocator.isRegistered<VocalService>()) {
      serviceLocator<VocalService>().dispose();
    }

    // Deep link service
    if (serviceLocator.isRegistered<DeepLinkService>()) {
      serviceLocator<DeepLinkService>().dispose();
    }

    // Offline service
    if (serviceLocator.isRegistered<OfflineService>()) {
      serviceLocator<OfflineService>().dispose();
    }

    // Connectivity service
    if (serviceLocator.isRegistered<ConnectivityService>()) {
      serviceLocator<ConnectivityService>().dispose();
    }

    // Performance service
    if (serviceLocator.isRegistered<PerformanceService>()) {
      serviceLocator<PerformanceService>().dispose();
    }

    // Reset the service locator
    await serviceLocator.reset();

    debugPrint('✅ All services disposed and memory cleaned successfully');
  } catch (e) {
    debugPrint('❌ Error disposing services: $e');
  }
}

/// Helper methods for easy access to services
extension ServiceLocatorExtensions on GetIt {
  // Core utility services
  ErrorHandler get errorHandler => get<ErrorHandler>();
  RetryService get retryService => get<RetryService>();

  // Core services
  ApiService get apiService => get<ApiService>();
  AuthService get authService => get<AuthService>();
  CacheService get cacheService => get<CacheService>();
  CrashlyticsService get crashlyticsService => get<CrashlyticsService>();
  PerformanceService get performanceService => get<PerformanceService>();
  
  // Data services
  ArtistService get artistService => get<ArtistService>();
  SongService get songService => get<SongService>();
  CollectionService get collectionService => get<CollectionService>();
  SetlistService get setlistService => get<SetlistService>();
  LikedSongsService get likedSongsService => get<LikedSongsService>();
  HomeSectionService get homeSectionService => get<HomeSectionService>();
  
  // Vocal services
  VocalService get vocalService => get<VocalService>();
  
  // Audio services
  AudioService get audioService => get<AudioService>();
  
  // Utility services
  NotificationService get notificationService => get<NotificationService>();
  DeepLinkService get deepLinkService => get<DeepLinkService>();
  OfflineService get offlineService => get<OfflineService>();
  ConnectivityService get connectivityService => get<ConnectivityService>();
  MemoryManager get memoryManager => get<MemoryManager>();
  PersistentCacheManager get persistentCacheManager => get<PersistentCacheManager>();
  SmartDataManager get smartDataManager => get<SmartDataManager>();
}

/// Check if all critical services are ready
bool areServicesReady() {
  try {
    return serviceLocator.isRegistered<CacheService>() &&
           serviceLocator.isRegistered<AuthService>() &&
           serviceLocator.isRegistered<ApiService>();
  } catch (e) {
    return false;
  }
}



/// Get service safely with error handling
T? getServiceSafely<T extends Object>() {
  try {
    if (serviceLocator.isRegistered<T>()) {
      return serviceLocator.get<T>();
    }
    return null;
  } catch (e) {
    debugPrint('❌ Error getting service ${T.toString()}: $e');
    return null;
  }
}
