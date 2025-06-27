/// Application constants and configuration values.
///
/// This library centralizes all magic numbers, strings, and configuration values
/// used throughout the Flutter application for better maintainability.
library;

import '../config/api_config.dart';

class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ============================================================================
  // APP INFORMATION
  // ============================================================================
  static const String appName = 'Stuthi';
  static const String appDescription = 'Christian Song Chords & Lyrics App';
  static const String appScheme = 'stuthi';

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration slideAnimationDuration = Duration(milliseconds: 600);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1200);
  static const Duration waveAnimationDuration = Duration(milliseconds: 2000);
  static const Duration quickAnimationDuration = Duration(milliseconds: 300);
  static const Duration slowAnimationDuration = Duration(seconds: 2);

  // ============================================================================
  // CACHE CONFIGURATION
  // ============================================================================
  static const int maxCategoryItems = 50;
  static const int maxMemoryCacheSize = 100;
  static const int defaultCacheExpirationMinutes = 30;
  static const int songCacheExpirationMinutes = 60;
  static const int artistCacheExpirationMinutes = 120;
  static const int collectionCacheExpirationMinutes = 120;
  static const int trendingCacheExpirationMinutes = 30;

  // ============================================================================
  // API CONFIGURATION
  // ============================================================================
  // IP addresses and API URLs are now centralized in ApiConfig class
  // See lib/config/api_config.dart for all network-related configuration
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const int maxRetryAttempts = 3;

  // ============================================================================
  // FIREBASE CONFIGURATION
  // ============================================================================
  static const String androidApiKey = "AIzaSyAwZJ_vJBUR8ROm15XzC3gsU0ZrH5QEt1s";
  static const String androidAppId =
      "1:481447097360:android:6bc5b649641f11a8e5c695";
  static const String iosApiKey = "AIzaSyCGoLuo8urFpvsR_ZPOZQl39U-0a5tvonk";
  static const String iosAppId = "1:481447097360:ios:efeac889ed1f21d1e5c695";
  static const String messagingSenderId = "481447097360";
  static const String projectId = "chords-app-ecd47";
  static const String storageBucket = "chords-app-ecd47.firebasestorage.app";
  static const String iosClientId =
      "481447097360-vrqfvovk8lc10niqd0nl6prbnnsoff8u.apps.googleusercontent.com";
  static const String webClientId =
      "481447097360-13s3qaeafrg1htmndilphq984komvbti.apps.googleusercontent.com";

  // ============================================================================
  // AUDIO CONFIGURATION
  // ============================================================================
  static const int defaultBpm = 120;
  static const int minBpm = 40;
  static const int maxBpm = 200;
  static const int defaultBeatsPerMeasure = 4;
  static const int countInBeats = 4;
  static const Duration metronomeCheckInterval = Duration(milliseconds: 10);
  static const Duration rewindDuration = Duration(seconds: 10);
  static const Duration fastForwardDuration = Duration(seconds: 10);

  // ============================================================================
  // UI CONFIGURATION
  // ============================================================================
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  static const double defaultBorderRadius = 8.0;
  static const double smallBorderRadius = 4.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 20.0;

  static const double defaultIconSize = 24.0;
  static const double smallIconSize = 16.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;

  // ============================================================================
  // PAGINATION
  // ============================================================================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int searchResultsLimit = 50;

  // ============================================================================
  // VALIDATION
  // ============================================================================
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxBioLength = 500;
  static const int maxSetlistNameLength = 100;
  static const int maxSongTitleLength = 200;

  // ============================================================================
  // STORAGE KEYS
  // ============================================================================
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String firebaseTokenKey = 'firebase_token';
  static const String userDataKey = 'user_data';
  static const String offlineModeKey = 'offline_mode_enabled';
  static const String lastSyncKey = 'last_sync_timestamp';
  static const String downloadedSongsKey = 'downloaded_songs';
  static const String downloadedVocalsKey = 'downloaded_vocals';

  // ============================================================================
  // CACHE KEYS
  // ============================================================================
  static const String homeSectionsCacheKey = 'home_sections';
  static const String songsCacheKey = 'songs';
  static const String artistsCacheKey = 'artists';
  static const String collectionsCacheKey = 'collections';
  static const String setlistsCacheKey = 'setlists';
  static const String likedSongsCacheKey = 'liked_songs';
  static const String trendingSongsCacheKey = 'trending_songs';
  static const String seasonalCollectionsCacheKey = 'seasonal_collections';

  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================
  static const String networkErrorMessage =
      'Please check your internet connection and try again.';
  static const String serverErrorMessage =
      'Server error occurred. Please try again later.';
  static const String authErrorMessage =
      'Authentication failed. Please log in again.';
  static const String cacheErrorMessage = 'Failed to load cached data.';
  static const String downloadErrorMessage =
      'Download failed. Please try again.';
  static const String uploadErrorMessage = 'Upload failed. Please try again.';
  static const String permissionErrorMessage =
      'Permission denied. Please grant required permissions.';

  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================
  static const String loginSuccessMessage = 'Login successful!';
  static const String logoutSuccessMessage = 'Logout successful!';
  static const String downloadSuccessMessage =
      'Download completed successfully!';
  static const String uploadSuccessMessage = 'Upload completed successfully!';
  static const String saveSuccessMessage = 'Saved successfully!';
  static const String deleteSuccessMessage = 'Deleted successfully!';

  // ============================================================================
  // ASSET PATHS
  // ============================================================================
  static const String logoPath = 'assets/images/stuthi logo light.png';
  static const String logoDarkPath = 'assets/images/stuthi logo dark.png';
  static const String logoPrimaryPath = 'assets/images/logo-primary.png';
  static const String appIconPath = 'assets/images/appicon.png';
  static const String audioAssetsPath = 'assets/audio/';

  // ============================================================================
  // AUDIO ASSETS
  // ============================================================================
  static const String kickSoundPath = 'assets/audio/kick.wav';
  static const String hihatSoundPath = 'assets/audio/hihat.wav';
  static const String clickSoundPath = 'assets/audio/click.wav';
  static const String accentSoundPath = 'assets/audio/accent.wav';

  // ============================================================================
  // DEEP LINK PATTERNS
  // ============================================================================
  static const String setlistJoinPattern = r'^/join/(\d{4})$';
  static const String songDetailPattern = r'^/song/([a-zA-Z0-9-]+)$';
  static const String artistDetailPattern = r'^/artist/([a-zA-Z0-9-]+)$';
  static const String collectionDetailPattern =
      r'^/collection/([a-zA-Z0-9-]+)$';

  // ============================================================================
  // PERFORMANCE THRESHOLDS
  // ============================================================================
  static const int maxConcurrentDownloads = 3;
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const Duration backgroundRefreshInterval = Duration(minutes: 15);
  static const Duration dataFreshnessThreshold = Duration(minutes: 5);
  static const Duration backgroundRefreshThreshold = Duration(minutes: 10);

  // ============================================================================
  // FEATURE FLAGS
  // ============================================================================
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = false; // Disabled for privacy
  static const bool enableCrashReporting = true; // Enabled for error tracking
  static const bool enableDeepLinking = true;
  static const bool enableVoiceSearch = true;

  // ============================================================================
  // CRASHLYTICS CONFIGURATION
  // ============================================================================
  static const bool enableCrashlyticsInDebug =
      true; // Enable in debug for testing
  static const int performanceThresholdMs = 2000; // Log slow operations
  static const int maxCustomKeys = 64; // Firebase limit
  static const int maxLogLength = 1024; // Firebase limit

  // ============================================================================
  // DEVELOPMENT FLAGS
  // ============================================================================
  static const bool enableDebugLogging = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableMemoryMonitoring = true;
  static const bool mockApiResponses = false;
}

/// Environment-specific constants
class EnvironmentConstants {
  // Prevent instantiation
  EnvironmentConstants._();

  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  static bool get isDebug => !isProduction;

  // Use the centralized API config
  static String get apiBaseUrl => ApiConfig.baseUrlWithoutSuffix;

  static Duration get cacheExpiration {
    return isProduction
        ? const Duration(minutes: 30)
        : const Duration(minutes: 5);
  }

  static bool get enableLogging => isDebug || AppConstants.enableDebugLogging;
  static bool get enablePerformanceMonitoring =>
      isDebug || AppConstants.enablePerformanceMonitoring;
  static bool get enableMemoryMonitoring =>
      isDebug || AppConstants.enableMemoryMonitoring;
}
