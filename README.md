# Stuthi - Christian Worship App

A comprehensive Flutter application for Christian worship songs, chords, and worship tools.

## Getting Started

This project is built with Flutter and follows modern app development practices.

### Prerequisites
- Flutter 3.7.2+
- Dart SDK
- Android Studio / Xcode for mobile deployment

### Installation
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase (see Firebase setup section)
4. Run `flutter run` to start the app

## Architecture

The app follows a clean architecture approach with:
- **lib/config/** - App configuration and theming
- **lib/core/** - Core utilities, service locator, and error handling
- **lib/data/** - Data layer with repositories and data sources
- **lib/models/** - Data models with type-safe JSON parsing
- **lib/providers/** - State management
- **lib/screens/** - UI screens with robust data handling
- **lib/services/** - Business logic and services
- **lib/utils/** - Utility functions
- **lib/widgets/** - Reusable UI components

### Type Safety and Data Handling

The app implements comprehensive type safety measures throughout the data layer:

- **Explicit Type Casting**: All JSON parsing uses explicit type casting to prevent runtime errors
- **Null Safety**: Comprehensive null handling with meaningful fallback values
- **Dynamic Data Validation**: Type checking before data extraction, especially for nested objects
- **Error Isolation**: Parsing errors are caught and handled gracefully without breaking the UI
- **Flexible Data Structures**: Handles varying API response formats (e.g., artist data as string or object)

Recent improvements include enhanced type safety in the setlist management system, where song data extraction now uses explicit type casting and validation to handle dynamic API responses safely. Additionally, the ListScreen now implements intelligent collection loading strategies that preserve section-specific context while ensuring complete metadata is available for UI rendering, using selective data fetching to optimize performance.

### Navigation Architecture

The app uses Flutter's modern navigation system with custom patterns for data synchronization:

- **PopScope Integration**: Uses Flutter 3.12+ `PopScope` widget for custom back navigation handling
- **Data Synchronization**: Screens track modifications and communicate changes to parent screens
- **Manual Navigation Control**: Custom navigation handlers prevent data loss and ensure proper state management
- **Collaborative Editing Support**: Handles real-time collaboration with conflict resolution

Key navigation features:
- Modification tracking across screens
- Automatic data refresh when returning from modified screens
- Graceful handling of unsaved changes
- Consistent back button behavior throughout the app

For detailed navigation patterns, see [Navigation Patterns Documentation](lib/docs/NAVIGATION_PATTERNS.md).

### Service Architecture

The app uses a centralized service locator pattern (GetIt) for dependency injection. All services are registered in `lib/core/service_locator.dart` and follow a lazy singleton pattern for memory efficiency.

#### Data Loading Optimization

The app implements intelligent data loading strategies that optimize for both performance and data completeness:

- **Dual-Strategy Loading**: Different API endpoints are used based on data requirements (e.g., collections use dedicated API for complete metadata)
- **Cache-First Approach**: Prioritizes cached data when available, with graceful fallback to API calls
- **Context-Aware Loading**: Screens adapt their loading strategy based on navigation context and data needs
- **Complete Data Integrity**: Ensures UI components receive complete data sets, preventing display issues

#### Core Services
- **ErrorHandler**: Centralized error handling and recovery
- **RetryService**: Comprehensive retry mechanism with exponential backoff and circuit breaker pattern
- **CrashlyticsService**: Error reporting and crash analytics
- **PerformanceService**: App performance monitoring
- **ConnectivityService**: Network connectivity management

#### Data Services
- **ApiService**: HTTP client for backend communication with type-safe JSON parsing
- **AuthService**: Firebase authentication integration
- **CacheService**: Intelligent caching for offline support
- **MemoryManager**: Memory usage monitoring and optimization

#### Business Logic Services
- **SongService**: Song data management
- **ArtistService**: Artist information handling
- **SetlistService**: User setlist management
- **AudioService**: Media playback and audio processing
- **NotificationService**: Push notifications via Firebase

## Theming System

The app uses a comprehensive theming system defined in `lib/config/theme.dart`. The theme is designed with a single source of truth for the primary color, making it easy to rebrand the entire app by changing just one value.

### Key Theme Features

#### Color System
- **Primary Color**: The main brand color used throughout the app
- **Background Colors**: True black for OLED efficiency and contrast
- **Surface Colors**: Dark grays for cards and elevated elements
- **Text Colors**: High contrast white and grays for readability
- **Semantic Colors**: Success, error, warning, and info colors
- **Accent Colors**: Used sparingly for visual interest

#### Typography
- Uses Apple San Francisco Pro fonts for a premium look
- Consistent text styles with proper hierarchy
- Monospace font (JetBrains Mono) for chord sheets

#### Component Styling
- Consistent styling for buttons, inputs, cards
- Flat design with minimal shadows
- High contrast for readability
- Dark theme optimized for OLED screens

### Customizing the Theme

To change the app's primary color:
1. Open `lib/config/theme.dart`
2. Locate the `primary` color constant (around line 22)
3. Change the color value to your desired color
4. The entire app will automatically update with the new color scheme

```dart
/// ⭐ PRIMARY BRAND COLOR - SINGLE SOURCE OF TRUTH ⭐
static const Color primary = Color.fromARGB(255, 59, 255, 203);
```

### Predefined Text Styles

The theme includes predefined text styles for common use cases:
- `songTitleStyle` - For song titles
- `artistNameStyle` - For artist names
- `sectionTitleStyle` - For section titles
- `chordSheetStyle` - For chord sheet text
- `chordStyle` - For chord notations
- And more...

### Font System

The app includes a comprehensive font management system:

#### FontUtils Class
- **Font Family Management**: Apply standard fonts to existing styles
- **Style Creation**: Create new TextStyles with proper font families
- **Development Tools**: Font audit utilities to identify inconsistencies

```dart
// Apply fonts to existing styles
final style = FontUtils.withPrimaryFont(existingStyle);
final displayStyle = FontUtils.withDisplayFont(existingStyle);
final monoStyle = FontUtils.withMonospaceFont(existingStyle);

// Create new styles with proper fonts
final newStyle = FontUtils.createPrimaryStyle(
  fontSize: 16,
  fontWeight: FontWeight.w500,
  color: AppTheme.textPrimary,
);
```

#### Font Weight Standardization
- **Standardized Weights**: Consistent font weights across the app
- **Helper Methods**: Easy creation of properly weighted text styles
- **Weight Conversion**: Standardize existing styles

```dart
// Use standardized font weights
FontUtils.primary    // w600 - Primary headings
FontUtils.secondary  // w500 - Secondary headings  
FontUtils.regular    // w400 - Body text
FontUtils.light      // w300 - De-emphasized text
FontUtils.emphasis   // w700 - Special emphasis (use sparingly)
```

#### Development Audit Tools
- **Font Consistency Checking**: Identify non-standard font usage
- **Visual Debugging**: Highlight problematic text widgets
- **Usage Reporting**: Generate font usage descriptions

### Utility Methods

Helper methods for consistent styling:
- `withOpacity()` - Get a color with reduced opacity
- `getTextColorForBackground()` - Get appropriate text color based on background
- `cardDecoration` - Get consistent card decoration
- `elevatedCardDecoration` - Get elevated card decoration

## Testing

The app includes a comprehensive testing infrastructure with multiple testing layers:

### Testing Dependencies

The following testing dependencies are configured in `pubspec.yaml`:

- **mockito**: Mock object generation for unit testing
- **build_runner**: Code generation for mocks and other build tasks
- **test**: Core Dart testing framework
- **fake_async**: Utilities for testing asynchronous code
- **flutter_driver**: End-to-end testing framework
- **integration_test**: Flutter integration testing support

### Test Structure

```
test/
├── unit/                    # Unit tests for services, providers, models
├── widget/                  # Widget tests for UI components
├── integration/             # Integration tests for complete flows
└── helpers/                 # Test utilities and mock factories
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Generate HTML coverage report
./test_coverage.sh

# Run specific test types
flutter test --tags unit
flutter test --tags widget
flutter test --tags integration
```

### Test Coverage Goals

- **Overall Coverage**: 80% minimum, 90% target
- **Critical Business Logic**: 95% coverage required
- **Services Layer**: 90% coverage required
- **UI Components**: 75% coverage required

For detailed testing documentation, see [test/README.md](test/README.md).

## Error Handling and Retry System

The app implements a robust error handling and retry system designed to provide a seamless user experience even when network or service issues occur.

### Key Features

- **Automatic Retry Logic**: Failed operations are automatically retried with exponential backoff
- **Circuit Breaker Pattern**: Prevents cascading failures by temporarily disabling failing services
- **Intelligent Error Classification**: Distinguishes between retryable and non-retryable errors
- **User-Friendly Error Messages**: Technical errors are converted to user-friendly messages
- **Comprehensive Logging**: Detailed logging for debugging and monitoring

### Retry Strategies

The system provides specialized retry methods for different types of operations:

- **API Calls**: `RetryService.retryApiCall()` - Excludes authentication errors from retry
- **Network Operations**: `RetryService.retryNetworkOperation()` - Focuses on connectivity issues
- **Cache Operations**: `RetryService.retryCacheOperation()` - Optimized for local storage with fewer retries
- **Fallback Operations**: `RetryService.executeFirstSuccessful()` - Tries multiple data sources in sequence

### Example Usage

```dart
// Automatic API retry with fallback
final songs = await RetryService.executeFirstSuccessful([
  () => primaryApiService.getSongs(),
  () => backupApiService.getSongs(),
  () => cacheService.getCachedSongs(),
], context: 'Loading songs with fallback');

// Circuit breaker for critical services
final circuitBreaker = RetryService.createCircuitBreaker(
  name: 'Payment Service',
  failureThreshold: 3,
  timeout: Duration(seconds: 30),
);
```

### Documentation

For comprehensive documentation on the error handling and retry system:
- [Error Handling System](lib/docs/ERROR_HANDLING_SYSTEM.md)
- [Retry Service API](lib/docs/RETRY_SERVICE_API.md)

## Configuration and Constants

The app uses a centralized constants system for maintainability and consistency. All application constants are defined in `lib/core/constants.dart` and organized into logical categories.

### Key Configuration Areas

- **App Information**: Branding, naming, and app metadata
- **UI Constants**: Spacing, sizing, animations, and visual elements
- **API Configuration**: Timeouts, retry attempts, and network settings
- **Firebase Configuration**: Authentication keys and project settings
- **Audio Settings**: BPM ranges, metronome settings, and audio controls
- **Cache Management**: Expiration times and memory limits
- **Feature Flags**: Enable/disable features for different builds
- **Performance Thresholds**: Memory limits and performance monitoring

### Environment-Specific Constants

The `EnvironmentConstants` class provides dynamic constants that adapt based on the build environment:

```dart
// Production vs Debug behavior
static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
static Duration get cacheExpiration => isProduction 
    ? const Duration(minutes: 30) 
    : const Duration(minutes: 5);
```

For detailed information about all available constants and their usage, see the [Constants Reference Guide](lib/docs/CONSTANTS_REFERENCE.md).

## Documentation

The app includes comprehensive documentation in the `lib/docs/` directory:

- **[Data Models API](lib/docs/DATA_MODELS_API.md)** - Data models, JSON parsing patterns, and type safety improvements
- **[Constants Reference Guide](lib/docs/CONSTANTS_REFERENCE.md)** - Complete constants and configuration reference
- **[Error Handling System](lib/docs/ERROR_HANDLING_SYSTEM.md)** - Complete error handling architecture
- **[Retry Service API](lib/docs/RETRY_SERVICE_API.md)** - Retry mechanisms and circuit breaker patterns
- **[Navigation Patterns](lib/docs/NAVIGATION_PATTERNS.md)** - Screen navigation and data synchronization patterns
- **[Font System Documentation](lib/docs/FONT_USAGE_GUIDE.md)** - Typography and font management
- **[Performance Monitoring](lib/docs/PERFORMANCE_UTILS_API.md)** - Performance optimization tools
- **[Memory Management](lib/docs/MEMORY_LEAK_DETECTION.md)** - Memory leak detection and prevention

## Resources

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
