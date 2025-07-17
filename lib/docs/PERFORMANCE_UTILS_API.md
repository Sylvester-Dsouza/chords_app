# PerformanceUtils API Reference

This document provides a complete API reference for the `PerformanceUtils` class, which is the central utility for monitoring and optimizing app performance.

## Overview

The `PerformanceUtils` class provides two main categories of functionality:
1. **Basic Performance Monitoring** - Simple stopwatch-based performance tracking
2. **Advanced Performance Tracking** - Integration with performance services for detailed analytics

> **Note:** All performance utilities have been consolidated into a single `PerformanceUtils` class for better maintainability and consistency.

## Basic Performance Monitoring

### Configuration Methods

#### `setEnabled(bool enabled)`
Enable or disable performance monitoring.

**Parameters:**
- `enabled` (bool): Whether performance monitoring should be enabled

**Example:**
```dart
final monitor = PerformanceUtils();
monitor.setEnabled(true); // Enable monitoring
```

#### `setLogToConsole(bool logToConsole)`
Set whether to log performance data to the console.

**Parameters:**
- `logToConsole` (bool): Whether to log to console

**Example:**
```dart
final monitor = PerformanceUtils();
monitor.setLogToConsole(true); // Enable console logging
```

### Timing Methods

#### `startOperation(String operationName)`
Start timing an operation.

**Parameters:**
- `operationName` (String): Name of the operation to time

**Example:**
```dart
final monitor = PerformanceUtils();
monitor.startOperation('load_data');
```

#### `endOperation(String operationName)`
End timing an operation and record its duration.

**Parameters:**
- `operationName` (String): Name of the operation to end

**Returns:** Duration - The elapsed time of the operation

**Example:**
```dart
final monitor = PerformanceUtils();
monitor.startOperation('load_data');
// ... perform operation
final duration = monitor.endOperation('load_data');
print('Operation took ${duration.inMilliseconds}ms');
```

### Memory Tracking

#### `trackMemoryUsage(String tag, int bytes)`
Track memory usage for a specific component.

**Parameters:**
- `tag` (String): Identifier for the memory usage
- `bytes` (int): Memory usage in bytes

**Example:**
```dart
final monitor = PerformanceUtils();
monitor.trackMemoryUsage('image_cache', 1024 * 1024); // 1MB
```

### Reporting Methods

#### `getPerformanceReport()`
Get a formatted performance report.

**Returns:** String - Formatted performance report

**Example:**
```dart
final monitor = PerformanceUtils();
// ... perform operations
final report = monitor.getPerformanceReport();
print(report);
```

#### `logPerformanceReport()`
Log the performance report to the console and DevTools timeline.

**Example:**
```dart
final monitor = PerformanceUtils();
// ... perform operations
monitor.logPerformanceReport();
```

#### `reset()`
Reset all performance data.

**Example:**
```dart
final monitor = PerformanceUtils();
monitor.reset();
```

### Widget Tracking

#### `trackRebuild(String widgetName)` (static)
Track widget rebuilds.

**Parameters:**
- `widgetName` (String): Name of the widget being rebuilt

**Example:**
```dart
@override
void build(BuildContext context) {
  PerformanceUtils.trackRebuild('HomeScreen');
  return Scaffold(...);
}
```

## Advanced Performance Tracking

### Function Tracking

#### `track<T>(String operationName, Future<T> Function() operation, {Map<String, String>? attributes})` (static)
Track a function execution time with detailed metrics.

**Parameters:**
- `operationName` (String): Name of the operation to track
- `operation` (Future<T> Function()): Async function to execute and track
- `attributes` (Map<String, String>?): Additional attributes to record

**Returns:** Future<T> - The result of the operation

**Example:**
```dart
final result = await PerformanceUtils.track(
  'fetch_user_data',
  () => userRepository.fetchUserData(),
  attributes: {'user_id': '123', 'source': 'network'},
);
```

### API Call Tracking

#### `trackApiCall<T>(String endpoint, Future<T> Function() apiCall, {Map<String, String>? attributes})` (static)
Track API calls with detailed metrics.

**Parameters:**
- `endpoint` (String): API endpoint being called
- `apiCall` (Future<T> Function()): API call function to execute and track
- `attributes` (Map<String, String>?): Additional attributes to record

**Returns:** Future<T> - The result of the API call

**Example:**
```dart
final userData = await PerformanceUtils.trackApiCall(
  '/api/users/123',
  () => api.getUser(123),
  attributes: {'method': 'GET', 'cache': 'false'},
);
```

### Screen Load Tracking

#### `trackScreenLoad(String screenName, Duration loadTime)` (static)
Track screen loading performance.

**Parameters:**
- `screenName` (String): Name of the screen being loaded
- `loadTime` (Duration): Time taken to load the screen

**Example:**
```dart
final stopwatch = Stopwatch()..start();
// ... load screen
stopwatch.stop();
await PerformanceUtils.trackScreenLoad('HomeScreen', stopwatch.elapsed);
```

### User Interaction Tracking

#### `trackUserInteraction(String interaction)` (static)
Track user interaction performance.

**Parameters:**
- `interaction` (String): Description of the user interaction

**Example:**
```dart
ElevatedButton(
  onPressed: () async {
    await PerformanceUtils.trackUserInteraction('login_button_tap');
    // ... handle button press
  },
  child: Text('Login'),
)
```

### Media Operation Tracking

#### `trackMediaOperation(String operation, String mediaType, Duration duration, {Map<String, String>? attributes})` (static)
Track audio/media operations.

**Parameters:**
- `operation` (String): Type of operation (load, play, pause, etc.)
- `mediaType` (String): Type of media (audio, video, image)
- `duration` (Duration): Duration of the operation
- `attributes` (Map<String, String>?): Additional attributes to record

**Example:**
```dart
final stopwatch = Stopwatch()..start();
await audioPlayer.load('song.mp3');
stopwatch.stop();
await PerformanceUtils.trackMediaOperation(
  'load',
  'audio',
  stopwatch.elapsed,
  attributes: {'format': 'mp3', 'size_kb': '1024'},
);
```

### Database Operation Tracking

#### `trackDatabaseOperation<T>(String operation, Future<T> Function() dbOperation, {Map<String, String>? attributes})` (static)
Track database operations.

**Parameters:**
- `operation` (String): Type of database operation
- `dbOperation` (Future<T> Function()): Database operation to execute and track
- `attributes` (Map<String, String>?): Additional attributes to record

**Returns:** Future<T> - The result of the database operation

**Example:**
```dart
final songs = await PerformanceUtils.trackDatabaseOperation(
  'query_songs',
  () => songsDao.getAllSongs(),
  attributes: {'filter': 'none', 'sort': 'title'},
);
```

### Cache Operation Tracking

#### `trackCacheOperation<T>(String operation, Future<T> Function() cacheOperation, {Map<String, String>? attributes})` (static)
Track cache operations.

**Parameters:**
- `operation` (String): Type of cache operation
- `cacheOperation` (Future<T> Function()): Cache operation to execute and track
- `attributes` (Map<String, String>?): Additional attributes to record

**Returns:** Future<T> - The result of the cache operation

**Example:**
```dart
final cachedData = await PerformanceUtils.trackCacheOperation(
  'get_user_preferences',
  () => cache.getUserPreferences(),
  attributes: {'cache_type': 'memory'},
);
```

### Navigation Tracking

#### `trackNavigation(String fromScreen, String toScreen, Duration navigationTime)` (static)
Track navigation performance between screens.

**Parameters:**
- `fromScreen` (String): Source screen name
- `toScreen` (String): Destination screen name
- `navigationTime` (Duration): Time taken for navigation

**Example:**
```dart
final stopwatch = Stopwatch()..start();
Navigator.pushNamed(context, '/details');
stopwatch.stop();
await PerformanceUtils.trackNavigation(
  'HomeScreen',
  'DetailsScreen',
  stopwatch.elapsed,
);
```

### App Startup Tracking

#### `trackAppStartup()` (static)
Start tracking app startup performance.

**Example:**
```dart
void main() async {
  await PerformanceUtils.trackAppStartup();
  runApp(MyApp());
}
```

#### `completeAppStartup({Map<String, String>? attributes})` (static)
Complete app startup tracking.

**Parameters:**
- `attributes` (Map<String, String>?): Additional attributes to record

**Example:**
```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceUtils.completeAppStartup(
        attributes: {'cold_start': 'true'},
      );
    });
  }
  
  // ...
}
```

### Authentication Tracking

#### `trackLogin<T>(String loginMethod, Future<T> Function() loginOperation)` (static)
Track login performance.

**Parameters:**
- `loginMethod` (String): Method of login (email, social, etc.)
- `loginOperation` (Future<T> Function()): Login operation to execute and track

**Returns:** Future<T> - The result of the login operation

**Example:**
```dart
final user = await PerformanceUtils.trackLogin(
  'email_password',
  () => authService.signInWithEmailAndPassword(email, password),
);
```

### Data Loading Tracking

#### `trackDataLoad<T>(String dataType, Future<T> Function() loadOperation, {int? itemCount, Map<String, String>? attributes})` (static)
Track data loading performance.

**Parameters:**
- `dataType` (String): Type of data being loaded
- `loadOperation` (Future<T> Function()): Data loading operation to execute and track
- `itemCount` (int?): Number of items loaded
- `attributes` (Map<String, String>?): Additional attributes to record

**Returns:** Future<T> - The result of the data loading operation

**Example:**
```dart
final songs = await PerformanceUtils.trackDataLoad(
  'songs',
  () => songsRepository.getAllSongs(),
  itemCount: 150,
  attributes: {'source': 'local_db'},
);
```

### Search Tracking

#### `trackSearch<T>(String searchType, String query, Future<T> Function() searchOperation, {int? resultCount})` (static)
Track search performance.

**Parameters:**
- `searchType` (String): Type of search
- `query` (String): Search query
- `searchOperation` (Future<T> Function()): Search operation to execute and track
- `resultCount` (int?): Number of search results

**Returns:** Future<T> - The result of the search operation

**Example:**
```dart
final results = await PerformanceUtils.trackSearch(
  'song_search',
  'hallelujah',
  () => searchService.searchSongs('hallelujah'),
  resultCount: results.length,
);
```

### File Operation Tracking

#### `trackFileOperation<T>(String operation, String fileType, Future<T> Function() fileOperation, {int? fileSizeBytes, Map<String, String>? attributes})` (static)
Track file operations.

**Parameters:**
- `operation` (String): Type of file operation (read, write, etc.)
- `fileType` (String): Type of file
- `fileOperation` (Future<T> Function()): File operation to execute and track
- `fileSizeBytes` (int?): Size of the file in bytes
- `attributes` (Map<String, String>?): Additional attributes to record

**Returns:** Future<T> - The result of the file operation

**Example:**
```dart
final fileContent = await PerformanceUtils.trackFileOperation(
  'read',
  'pdf',
  () => fileService.readFile('document.pdf'),
  fileSizeBytes: 1024 * 1024, // 1MB
  attributes: {'cached': 'false'},
);
```

### Image Loading Tracking

#### `trackImageLoad(String imageUrl, Duration loadTime, {int? imageSizeBytes})` (static)
Track image loading performance.

**Parameters:**
- `imageUrl` (String): URL of the image
- `loadTime` (Duration): Time taken to load the image
- `imageSizeBytes` (int?): Size of the image in bytes

**Example:**
```dart
final stopwatch = Stopwatch()..start();
await precacheImage(NetworkImage(imageUrl), context);
stopwatch.stop();
await PerformanceUtils.trackImageLoad(
  imageUrl,
  stopwatch.elapsed,
  imageSizeBytes: 51200, // 50KB
);
```

### Custom Trace Methods

#### `startTrace(String traceName)` (static)
Start a custom trace for manual control.

**Parameters:**
- `traceName` (String): Name of the trace

**Example:**
```dart
await PerformanceUtils.startTrace('complex_operation');
```

#### `stopTrace(String traceName, {Map<String, String>? attributes})` (static)
Stop a custom trace.

**Parameters:**
- `traceName` (String): Name of the trace to stop
- `attributes` (Map<String, String>?): Additional attributes to record

**Example:**
```dart
await PerformanceUtils.startTrace('complex_operation');
// ... perform complex operation
await PerformanceUtils.stopTrace(
  'complex_operation',
  attributes: {'result': 'success'},
);
```

#### `setMetric(String traceName, String metricName, int value)` (static)
Set a metric for an active trace.

**Parameters:**
- `traceName` (String): Name of the trace
- `metricName` (String): Name of the metric
- `value` (int): Value of the metric

**Example:**
```dart
await PerformanceUtils.startTrace('data_processing');
// ... process data
await PerformanceUtils.setMetric(
  'data_processing',
  'items_processed',
  150,
);
await PerformanceUtils.stopTrace('data_processing');
```

#### `incrementMetric(String traceName, String metricName, int value)` (static)
Increment a metric for an active trace.

**Parameters:**
- `traceName` (String): Name of the trace
- `metricName` (String): Name of the metric
- `value` (int): Value to increment by

**Example:**
```dart
await PerformanceUtils.startTrace('batch_processing');
// Process first batch
await PerformanceUtils.incrementMetric(
  'batch_processing',
  'batches_completed',
  1,
);
// Process second batch
await PerformanceUtils.incrementMetric(
  'batch_processing',
  'batches_completed',
  1,
);
await PerformanceUtils.stopTrace('batch_processing');
```

### Status Methods

#### `isEnabled` (static getter)
Check if performance monitoring is enabled.

**Returns:** bool - Whether performance monitoring is enabled

**Example:**
```dart
if (PerformanceUtils.isEnabled) {
  print('Performance monitoring is enabled');
}
```

#### `getStatus()` (static)
Get performance monitoring status for debugging.

**Returns:** Map<String, dynamic> - Status information

**Example:**
```dart
final status = PerformanceUtils.getStatus();
print('Performance monitoring status: $status');
```

#### `printStatus()` (static)
Print performance monitoring status.

**Example:**
```dart
PerformanceUtils.printStatus();
```

## Usage Patterns

### Basic Performance Monitoring

```dart
// Create a singleton instance
final performance = PerformanceUtils();

// Time an operation
performance.startOperation('load_data');
await loadData();
final duration = performance.endOperation('load_data');

// Track memory usage
performance.trackMemoryUsage('image_cache', calculateCacheSize());

// Generate a report
print(performance.getPerformanceReport());
```

### Advanced Performance Tracking

```dart
// Track a function with attributes
final result = await PerformanceUtils.track(
  'fetch_user_data',
  () => userRepository.fetchUserData(),
  attributes: {'user_id': '123'},
);

// Track API calls
final userData = await PerformanceUtils.trackApiCall(
  '/api/users/123',
  () => api.getUser(123),
);

// Track database operations
final songs = await PerformanceUtils.trackDatabaseOperation(
  'query_songs',
  () => songsDao.getAllSongs(),
);

// Track app startup
void main() async {
  await PerformanceUtils.trackAppStartup();
  runApp(MyApp());
}

// Complete app startup tracking
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PerformanceUtils.completeAppStartup();
  });
}
```

### Custom Traces

```dart
// Manual trace control
await PerformanceUtils.startTrace('complex_operation');

// First step
await step1();
await PerformanceUtils.setMetric('complex_operation', 'step1_items', 10);

// Second step
await step2();
await PerformanceUtils.setMetric('complex_operation', 'step2_items', 20);

// Complete the trace
await PerformanceUtils.stopTrace(
  'complex_operation',
  attributes: {'result': 'success'},
);
```

## Best Practices

1. **Use appropriate tracking level** - Basic for simple timing, Advanced for detailed analytics
2. **Add meaningful attributes** - Include context information in attributes
3. **Track important user flows** - Focus on critical paths like startup, login, and main features
4. **Monitor memory usage** - Track memory for image caches, large data structures
5. **Use custom traces for complex operations** - Break down multi-step processes
6. **Add performance tracking to widget builds** - Use `trackRebuild` to identify excessive rebuilds
7. **Generate periodic reports** - Use `getPerformanceReport()` to analyze trends
8. **Disable in production when needed** - Use `setEnabled(false)` for production if overhead is a concern

## Integration with Performance Service

The PerformanceUtils class integrates with the app's PerformanceService for advanced analytics:

```dart
// PerformanceUtils automatically uses the registered service
serviceLocator.registerSingleton<PerformanceService>(
  FirebasePerformanceService(),
);

// All tracking methods will now use Firebase Performance
await PerformanceUtils.trackApiCall(...);
await PerformanceUtils.trackDataLoad(...);
```

This ensures that all performance tracking is automatically sent to your analytics service when available.