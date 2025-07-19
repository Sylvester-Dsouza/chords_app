# Constants Reference Guide

This document provides a comprehensive reference for all constants used in the Stuthi Flutter application. Constants are centralized in `lib/core/constants.dart` for better maintainability and consistency.

## Overview

The constants system is organized into two main classes:
- **`AppConstants`**: Static application constants
- **`EnvironmentConstants`**: Environment-specific dynamic constants

## AppConstants

### App Information
Basic application metadata and branding information.

```dart
static const String appName = 'Stuthi';
static const String appDescription = 'Christian Song Chords & Lyrics App';
static const String appScheme = 'stuthi';
```

### Animation Durations
Standardized animation timings for consistent user experience.

```dart
static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
static const Duration slideAnimationDuration = Duration(milliseconds: 600);
static const Duration pulseAnimationDuration = Duration(milliseconds: 1200);
static const Duration waveAnimationDuration = Duration(milliseconds: 2000);
static const Duration quickAnimationDuration = Duration(milliseconds: 300);
static const Duration slowAnimationDuration = Duration(seconds: 2);
```

**Usage Example:**
```dart
AnimatedOpacity(
  duration: AppConstants.fadeAnimationDuration,
  opacity: isVisible ? 1.0 : 0.0,
  child: widget,
)
```

### Cache Configuration
Memory and cache management settings for optimal performance.

```dart
static const int maxCategoryItems = 50;
static const int maxMemoryCacheSize = 100;
static const int defaultCacheExpirationMinutes = 30;
static const int songCacheExpirationMinutes = 60;
static const int artistCacheExpirationMinutes = 120;
static const int collectionCacheExpirationMinutes = 120;
static const int trendingCacheExpirationMinutes = 30;
```

**Usage Example:**
```dart
final cacheExpiration = Duration(
  minutes: AppConstants.songCacheExpirationMinutes
);
```

### API Configuration
Network request settings and timeouts.

```dart
static const Duration apiTimeout = Duration(seconds: 30);
static const Duration connectionTimeout = Duration(seconds: 15);
static const int maxRetryAttempts = 3;
```

> **Note**: API URLs are centralized in `ApiConfig` class. See `lib/config/api_config.dart` for network-related configuration.

### Firebase Configuration
Firebase project settings and authentication keys.

```dart
static const String androidApiKey = "AIzaSyAwZJ_vJBUR8ROm15XzC3gsU0ZrH5QEt1s";
static const String androidAppId = "1:481447097360:android:6bc5b649641f11a8e5c695";
static const String iosApiKey = "AIzaSyCGoLuo8urFpvsR_ZPOZQl39U-0a5tvonk";
static const String iosAppId = "1:481447097360:ios:efeac889ed1f21d1e5c695";
static const String messagingSenderId = "481447097360";
static const String projectId = "chords-app-ecd47";
static const String storageBucket = "chords-app-ecd47.firebasestorage.app";
static const String iosClientId = "481447097360-vrqfvovk8lc10niqd0nl6prbnnsoff8u.apps.googleusercontent.com";
static const String webClientId = "481447097360-13s3qaeafrg1htmndilphq984komvbti.apps.googleusercontent.com";
```

> **Security Note**: These are public Firebase configuration values. Sensitive keys are managed through Firebase security rules and environment variables.

### Audio Configuration
Audio playback and metronome settings.

```dart
static const int defaultBpm = 120;
static const int minBpm = 40;
static const int maxBpm = 200;
static const int defaultBeatsPerMeasure = 4;
static const int countInBeats = 4;
static const Duration metronomeCheckInterval = Duration(milliseconds: 10);
static const Duration rewindDuration = Duration(seconds: 10);
static const Duration fastForwardDuration = Duration(seconds: 10);
```

**Usage Example:**
```dart
Slider(
  min: AppConstants.minBpm.toDouble(),
  max: AppConstants.maxBpm.toDouble(),
  value: currentBpm,
  onChanged: (value) => setBpm(value.toInt()),
)
```

### UI Configuration
Consistent spacing, sizing, and visual elements.

```dart
// Padding
static const double defaultPadding = 16.0;
static const double smallPadding = 8.0;
static const double largePadding = 24.0;
static const double extraLargePadding = 32.0;

// Border Radius
static const double defaultBorderRadius = 8.0;
static const double smallBorderRadius = 4.0;
static const double largeBorderRadius = 16.0;
static const double extraLargeBorderRadius = 20.0;

// Icon Sizes
static const double defaultIconSize = 24.0;
static const double smallIconSize = 16.0;
static const double largeIconSize = 32.0;
static const double extraLargeIconSize = 48.0;
```

**Usage Example:**
```dart
Container(
  padding: EdgeInsets.all(AppConstants.defaultPadding),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
  ),
  child: Icon(
    Icons.music_note,
    size: AppConstants.defaultIconSize,
  ),
)
```

### Pagination
Data loading and pagination settings.

```dart
static const int defaultPageSize = 20;
static const int maxPageSize = 100;
static const int searchResultsLimit = 50;
```

### Validation
Input validation constraints.

```dart
static const int minPasswordLength = 6;
static const int maxPasswordLength = 128;
static const int minUsernameLength = 3;
static const int maxUsernameLength = 30;
static const int maxBioLength = 500;
static const int maxSetlistNameLength = 100;
static const int maxSongTitleLength = 200;
```

**Usage Example:**
```dart
TextFormField(
  maxLength: AppConstants.maxUsernameLength,
  validator: (value) {
    if (value == null || value.length < AppConstants.minUsernameLength) {
      return 'Username must be at least ${AppConstants.minUsernameLength} characters';
    }
    return null;
  },
)
```

### Storage Keys
Secure storage and SharedPreferences keys.

```dart
static const String accessTokenKey = 'access_token';
static const String refreshTokenKey = 'refresh_token';
static const String firebaseTokenKey = 'firebase_token';
static const String userDataKey = 'user_data';
static const String offlineModeKey = 'offline_mode_enabled';
static const String lastSyncKey = 'last_sync_timestamp';
static const String downloadedSongsKey = 'downloaded_songs';
static const String downloadedVocalsKey = 'downloaded_vocals';
```

### Cache Keys
Cache identification keys for different data types.

```dart
static const String homeSectionsCacheKey = 'home_sections';
static const String songsCacheKey = 'songs';
static const String artistsCacheKey = 'artists';
static const String collectionsCacheKey = 'collections';
static const String setlistsCacheKey = 'setlists';
static const String likedSongsCacheKey = 'liked_songs';
static const String trendingSongsCacheKey = 'trending_songs';
static const String seasonalCollectionsCacheKey = 'seasonal_collections';
```

### User Messages
Standardized user-facing messages for consistency.

#### Error Messages
```dart
static const String networkErrorMessage = 'Please check your internet connection and try again.';
static const String serverErrorMessage = 'Server error occurred. Please try again later.';
static const String authErrorMessage = 'Authentication failed. Please log in again.';
static const String cacheErrorMessage = 'Failed to load cached data.';
static const String downloadErrorMessage = 'Download failed. Please try again.';
static const String uploadErrorMessage = 'Upload failed. Please try again.';
static const String permissionErrorMessage = 'Permission denied. Please grant required permissions.';
```

#### Success Messages
```dart
static const String loginSuccessMessage = 'Login successful!';
static const String logoutSuccessMessage = 'Logout successful!';
static const String downloadSuccessMessage = 'Download completed successfully!';
static const String uploadSuccessMessage = 'Upload completed successfully!';
static const String saveSuccessMessage = 'Saved successfully!';
static const String deleteSuccessMessage = 'Deleted successfully!';
```

**Usage Example:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(AppConstants.loginSuccessMessage)),
);
```

### Asset Paths
Centralized asset path management.

```dart
static const String logoPath = 'assets/images/stuthi logo light.png';
static const String logoDarkPath = 'assets/images/stuthi logo dark.png';
static const String logoPrimaryPath = 'assets/images/logo-primary.png';
static const String appIconPath = 'assets/images/appicon.png';
static const String audioAssetsPath = 'assets/audio/';
```

### Audio Assets
Audio file paths for metronome and sound effects.

```dart
static const String kickSoundPath = 'assets/audio/kick.wav';
static const String hihatSoundPath = 'assets/audio/hihat.wav';
static const String clickSoundPath = 'assets/audio/click.wav';
static const String accentSoundPath = 'assets/audio/accent.wav';
```

### Deep Link Patterns
URL pattern matching for deep linking.

```dart
static const String setlistJoinPattern = r'^/join/(\d{4})$';
static const String songDetailPattern = r'^/song/([a-zA-Z0-9-]+)$';
static const String artistDetailPattern = r'^/artist/([a-zA-Z0-9-]+)$';
static const String collectionDetailPattern = r'^/collection/([a-zA-Z0-9-]+)$';
```

### Performance Thresholds
Performance monitoring and optimization settings.

```dart
static const int maxConcurrentDownloads = 3;
static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
static const Duration backgroundRefreshInterval = Duration(minutes: 15);
static const Duration dataFreshnessThreshold = Duration(minutes: 5);
static const Duration backgroundRefreshThreshold = Duration(minutes: 10);
```

### Feature Flags
Enable/disable features for different builds or testing.

```dart
static const bool enableOfflineMode = true;
static const bool enablePushNotifications = true;
static const bool enableAnalytics = false; // Disabled for privacy
static const bool enableCrashReporting = true; // Enabled for error tracking
static const bool enableDeepLinking = true;
static const bool enableVoiceSearch = true;
```

**Usage Example:**
```dart
if (AppConstants.enableVoiceSearch) {
  // Show voice search button
  IconButton(
    icon: Icon(Icons.mic),
    onPressed: () => startVoiceSearch(),
  )
}
```

### Crashlytics Configuration
Firebase Crashlytics settings and limits.

```dart
static const bool enableCrashlyticsInDebug = true; // Enable in debug for testing
static const int performanceThresholdMs = 2000; // Log slow operations
static const int maxCustomKeys = 64; // Firebase limit
static const int maxLogLength = 1024; // Firebase limit
```

### Development Flags
Debug and development-specific settings.

```dart
static const bool enableDebugLogging = true;
static const bool enablePerformanceMonitoring = true;
static const bool enableMemoryMonitoring = true;
static const bool mockApiResponses = false;
```

## EnvironmentConstants

Dynamic constants that change based on the build environment.

### Environment Detection
```dart
static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
static bool get isDebug => !isProduction;
```

### API Configuration
```dart
static String get apiBaseUrl => ApiConfig.baseUrlWithoutSuffix;
```

### Cache Settings
```dart
static Duration get cacheExpiration {
  return isProduction
      ? const Duration(minutes: 30)
      : const Duration(minutes: 5);
}
```

### Feature Toggles
```dart
static bool get enableLogging => isDebug || AppConstants.enableDebugLogging;
static bool get enablePerformanceMonitoring => isDebug || AppConstants.enablePerformanceMonitoring;
static bool get enableMemoryMonitoring => isDebug || AppConstants.enableMemoryMonitoring;
```

## Best Practices

### 1. Using Constants
Always use constants instead of magic numbers or hardcoded strings:

```dart
// ❌ Bad
Container(padding: EdgeInsets.all(16.0))

// ✅ Good
Container(padding: EdgeInsets.all(AppConstants.defaultPadding))
```

### 2. Environment-Specific Behavior
Use `EnvironmentConstants` for behavior that should differ between debug and production:

```dart
// ❌ Bad
if (kDebugMode) {
  print('Debug message');
}

// ✅ Good
if (EnvironmentConstants.enableLogging) {
  Logger.debug('Debug message');
}
```

### 3. Feature Flags
Use feature flags to control feature availability:

```dart
// ✅ Good
Widget buildVoiceSearchButton() {
  if (!AppConstants.enableVoiceSearch) {
    return SizedBox.shrink();
  }
  
  return IconButton(
    icon: Icon(Icons.mic),
    onPressed: () => startVoiceSearch(),
  );
}
```

### 4. Validation Constants
Use validation constants for consistent input validation:

```dart
// ✅ Good
String? validatePassword(String? value) {
  if (value == null || value.length < AppConstants.minPasswordLength) {
    return 'Password must be at least ${AppConstants.minPasswordLength} characters';
  }
  if (value.length > AppConstants.maxPasswordLength) {
    return 'Password must be less than ${AppConstants.maxPasswordLength} characters';
  }
  return null;
}
```

## Maintenance Guidelines

### Adding New Constants
1. Choose the appropriate category or create a new one
2. Use descriptive names with proper prefixes
3. Add documentation comments for complex constants
4. Update this documentation file

### Modifying Existing Constants
1. Consider backward compatibility
2. Update all usages throughout the codebase
3. Test thoroughly, especially for UI-related constants
4. Update documentation

### Environment-Specific Constants
1. Use `EnvironmentConstants` for values that change between environments
2. Prefer feature flags over environment checks where possible
3. Document the behavior differences clearly

## Related Documentation

- [API Configuration](../config/api_config.dart) - Network and API settings
- [Theme Configuration](../config/theme.dart) - UI theming and styling
- [Error Handling System](ERROR_HANDLING_SYSTEM.md) - Error handling constants and messages
- [Performance Monitoring](PERFORMANCE_UTILS_API.md) - Performance-related constants

## Migration Notes

### Version 2.0.0
- Moved API URLs to separate `ApiConfig` class
- Added environment-specific cache expiration
- Introduced feature flags for better control

### Version 1.5.0
- Added deep link patterns
- Introduced performance thresholds
- Added Crashlytics configuration constants