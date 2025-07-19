# Retry Service API Documentation

The RetryService provides a comprehensive retry mechanism with exponential backoff, circuit breaker pattern, and intelligent error handling for the Stuthi app.

## Overview

The RetryService is designed to handle transient failures gracefully by automatically retrying failed operations with configurable parameters. It integrates seamlessly with the app's error handling system and provides specialized retry strategies for different types of operations.

## Architecture

```
┌─────────────────────────────────────────┐
│              RetryService               │
├─────────────────────────────────────────┤
│  • executeWithRetry()                   │
│  • executeWithRetryResult()             │
│  • retryApiCall()                       │
│  • retryNetworkOperation()              │
│  • retryCacheOperation()                │
│  • executeFirstSuccessful()             │
│  • createCircuitBreaker()               │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│            ErrorHandler                 │
├─────────────────────────────────────────┤
│  • isRetryableError()                   │
│  • isNetworkError()                     │
│  • isAuthError()                        │
│  • getRetryDelay()                      │
└─────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────┐
│           CircuitBreaker                │
├─────────────────────────────────────────┤
│  • execute()                            │
│  • getState()                           │
│  • _onSuccess()                         │
│  • _onFailure()                         │
└─────────────────────────────────────────┘
```

## Core Methods

### executeWithRetry<T>()

The primary retry method that executes an operation with configurable retry logic.

```dart
static Future<T> executeWithRetry<T>(
  Future<T> Function() operation, {
  int maxAttempts = AppConstants.maxRetryAttempts,
  Duration? initialDelay,
  bool Function(dynamic error)? shouldRetry,
  String? context,
}) async
```

**Parameters:**
- `operation`: The async function to execute
- `maxAttempts`: Maximum number of retry attempts (default: 3)
- `initialDelay`: Custom initial delay (default: exponential backoff)
- `shouldRetry`: Custom retry condition function
- `context`: Description for logging purposes

**Returns:** The result of the successful operation

**Throws:** The last error if all attempts fail

**Example:**
```dart
final result = await RetryService.executeWithRetry(
  () => apiService.fetchSongs(),
  maxAttempts: 5,
  context: 'Fetching songs from API',
  shouldRetry: (error) => !ErrorHandler.isAuthError(error),
);
```

### executeWithRetryResult<T>()

Similar to `executeWithRetry` but returns a result object instead of throwing exceptions.

```dart
static Future<Map<String, dynamic>> executeWithRetryResult<T>(
  Future<T> Function() operation, {
  int maxAttempts = AppConstants.maxRetryAttempts,
  Duration? initialDelay,
  bool Function(dynamic error)? shouldRetry,
  String? context,
}) async
```

**Returns:** A standardized result object:
```dart
{
  'success': bool,
  'data': T?,           // Only present on success
  'message': String?,   // Error message on failure
  'timestamp': String,
}
```

**Example:**
```dart
final result = await RetryService.executeWithRetryResult(
  () => apiService.uploadFile(file),
  context: 'File upload',
);

if (result['success']) {
  print('Upload successful: ${result['data']}');
} else {
  print('Upload failed: ${result['message']}');
}
```

## Specialized Retry Methods

### retryApiCall<T>()

Optimized for API calls with authentication-aware retry logic.

```dart
static Future<T> retryApiCall<T>(
  Future<T> Function() apiCall, {
  String? endpoint,
  int maxAttempts = AppConstants.maxRetryAttempts,
}) async
```

**Features:**
- Automatically excludes authentication errors from retry
- Includes endpoint information in logging
- Uses standard retry configuration for API calls

**Example:**
```dart
final songs = await RetryService.retryApiCall(
  () => apiService.get('/songs'),
  endpoint: '/songs',
);
```

### retryNetworkOperation<T>()

Specialized for network operations with network-specific error handling.

```dart
static Future<T> retryNetworkOperation<T>(
  Future<T> Function() operation, {
  String? operationName,
  int maxAttempts = AppConstants.maxRetryAttempts,
}) async
```

**Features:**
- Only retries network-related errors
- Optimized for connectivity issues
- Suitable for file downloads, uploads, and network requests

**Example:**
```dart
final downloadResult = await RetryService.retryNetworkOperation(
  () => downloadManager.downloadFile(url),
  operationName: 'Song audio download',
);
```

### retryCacheOperation<T>()

Optimized for cache operations with reduced retry attempts and shorter delays.

```dart
static Future<T> retryCacheOperation<T>(
  Future<T> Function() operation, {
  String? operationName,
  int maxAttempts = 2,
}) async
```

**Features:**
- Fewer retry attempts (default: 2)
- Shorter initial delay (100ms)
- Excludes authentication errors
- Optimized for local storage operations

**Example:**
```dart
final cachedData = await RetryService.retryCacheOperation(
  () => cacheService.get('songs'),
  operationName: 'Cache retrieval',
);
```

### executeFirstSuccessful<T>()

Executes multiple operations in sequence, returning the result of the first successful one.

```dart
static Future<T> executeFirstSuccessful<T>(
  List<Future<T> Function()> operations, {
  String? context,
  int maxAttemptsPerOperation = 2,
}) async
```

**Use Cases:**
- Fallback mechanisms (primary API → backup API → cache)
- Multiple data sources
- Service redundancy

**Example:**
```dart
final songs = await RetryService.executeFirstSuccessful([
  () => primaryApiService.getSongs(),
  () => backupApiService.getSongs(),
  () => cacheService.getCachedSongs(),
], context: 'Fetching songs with fallback');
```

## Circuit Breaker Pattern

### createCircuitBreaker()

Creates a circuit breaker to prevent cascading failures.

```dart
static CircuitBreaker createCircuitBreaker({
  required String name,
  int failureThreshold = 5,
  Duration timeout = const Duration(minutes: 1),
})
```

**Parameters:**
- `name`: Identifier for the circuit breaker
- `failureThreshold`: Number of failures before opening the circuit
- `timeout`: Time to wait before attempting to close the circuit

### CircuitBreaker Class

```dart
class CircuitBreaker {
  Future<T> execute<T>(Future<T> Function() operation) async
  Map<String, dynamic> getState()
}
```

**States:**
- **Closed**: Normal operation, requests pass through
- **Open**: Circuit is open, requests fail immediately
- **Half-Open**: Testing if service has recovered

**Example:**
```dart
final circuitBreaker = RetryService.createCircuitBreaker(
  name: 'API Service',
  failureThreshold: 3,
  timeout: Duration(seconds: 30),
);

try {
  final result = await circuitBreaker.execute(
    () => apiService.criticalOperation(),
  );
} catch (e) {
  if (e.toString().contains('Circuit breaker')) {
    // Handle circuit breaker open state
    showOfflineMode();
  }
}
```

## Configuration

### Default Values

```dart
// From AppConstants
static const int maxRetryAttempts = 3;
static const Duration apiTimeout = Duration(seconds: 30);
static const Duration connectionTimeout = Duration(seconds: 15);
```

### Retry Delays

The service uses exponential backoff by default:
- Attempt 1: 1 second
- Attempt 2: 2 seconds  
- Attempt 3: 4 seconds
- Attempt 4: 8 seconds
- Maximum: 30 seconds

## Error Handling Integration

### Retryable Errors

The service automatically determines which errors are retryable:

**Network Errors:**
- Connection timeouts
- Send/receive timeouts
- Connection errors
- Socket exceptions

**HTTP Errors:**
- 429 (Too Many Requests)
- 500 (Internal Server Error)
- 502 (Bad Gateway)
- 503 (Service Unavailable)
- 504 (Gateway Timeout)

**Non-Retryable Errors:**
- 401 (Unauthorized)
- 403 (Forbidden)
- 400 (Bad Request)
- 404 (Not Found)
- 422 (Unprocessable Entity)

### Custom Retry Logic

You can provide custom retry logic:

```dart
await RetryService.executeWithRetry(
  () => someOperation(),
  shouldRetry: (error) {
    // Custom logic
    if (error is SpecificException) {
      return error.isRetryable;
    }
    return ErrorHandler.isRetryableError(error);
  },
);
```

## Logging and Monitoring

### Debug Logging

When `EnvironmentConstants.enableLogging` is true, the service provides detailed logs:

```
🔄 Attempting API call to /songs (attempt 1/3)
❌ API call to /songs failed on attempt 1: Connection timeout
⏳ Retrying API call to /songs in 1s...
🔄 Attempting API call to /songs (attempt 2/3)
✅ API call to /songs succeeded on attempt 2
```

### Circuit Breaker Logging

```
🚫 Circuit breaker API Service: Opened due to 5 failures
🔄 Circuit breaker API Service: Attempting to close
✅ Circuit breaker API Service: Operation succeeded
```

## Best Practices

### 1. Use Appropriate Retry Methods

```dart
// ✅ Good: Use specialized methods
await RetryService.retryApiCall(() => api.getData());
await RetryService.retryCacheOperation(() => cache.get(key));

// ❌ Avoid: Generic retry for everything
await RetryService.executeWithRetry(() => api.getData());
```

### 2. Provide Context for Debugging

```dart
// ✅ Good: Descriptive context
await RetryService.executeWithRetry(
  () => uploadService.uploadImage(file),
  context: 'Profile image upload',
);

// ❌ Avoid: No context
await RetryService.executeWithRetry(() => uploadService.uploadImage(file));
```

### 3. Handle Circuit Breaker States

```dart
try {
  final result = await circuitBreaker.execute(() => operation());
} catch (e) {
  if (e.toString().contains('Circuit breaker')) {
    // Provide alternative functionality
    return getCachedData();
  }
  rethrow;
}
```

### 4. Use Result Objects for UI Operations

```dart
// ✅ Good: Handle both success and failure
final result = await RetryService.executeWithRetryResult(
  () => apiService.updateProfile(data),
);

if (result['success']) {
  showSuccessMessage();
} else {
  showErrorDialog(result['message']);
}
```

### 5. Configure Appropriate Timeouts

```dart
// ✅ Good: Shorter timeouts for cache operations
await RetryService.retryCacheOperation(
  () => cache.get(key),
  maxAttempts: 2,
);

// ✅ Good: More attempts for critical operations
await RetryService.retryApiCall(
  () => paymentService.processPayment(data),
  maxAttempts: 5,
);
```

## Integration Examples

### Service Layer Integration

```dart
class SongService {
  Future<List<Song>> fetchSongs() async {
    return await RetryService.retryApiCall(
      () => _apiService.get('/songs'),
      endpoint: '/songs',
    );
  }
  
  Future<void> cacheSongs(List<Song> songs) async {
    await RetryService.retryCacheOperation(
      () => _cacheService.store('songs', songs),
      operationName: 'Songs cache storage',
    );
  }
}
```

### UI Integration

```dart
class SongListProvider extends ChangeNotifier {
  Future<void> loadSongs() async {
    final result = await RetryService.executeWithRetryResult(
      () => _songService.fetchSongs(),
      context: 'Loading songs for home screen',
    );
    
    if (result['success']) {
      _songs = result['data'];
      notifyListeners();
    } else {
      _error = result['message'];
      notifyListeners();
    }
  }
}
```

### Fallback Strategy

```dart
Future<List<Song>> getSongsWithFallback() async {
  return await RetryService.executeFirstSuccessful([
    // Try primary API
    () => primaryApi.getSongs(),
    // Try backup API
    () => backupApi.getSongs(),
    // Use cached data
    () => cacheService.getCachedSongs(),
    // Use default songs
    () => Future.value(getDefaultSongs()),
  ], context: 'Songs with complete fallback chain');
}
```

## Performance Considerations

### Memory Usage
- Circuit breakers maintain minimal state
- No persistent storage of retry attempts
- Automatic cleanup of completed operations

### Network Efficiency
- Exponential backoff prevents server overload
- Circuit breakers prevent unnecessary requests
- Intelligent error classification reduces redundant retries

### Battery Optimization
- Shorter delays for cache operations
- Circuit breakers prevent battery drain from repeated failures
- Configurable timeouts prevent long-running operations

## Troubleshooting

### Common Issues

1. **Infinite Retries**
   - Check `maxAttempts` configuration
   - Verify `shouldRetry` logic
   - Ensure errors are properly classified

2. **Circuit Breaker Always Open**
   - Check `failureThreshold` setting
   - Verify underlying service health
   - Monitor circuit breaker state with `getState()`

3. **Slow Performance**
   - Reduce `maxAttempts` for non-critical operations
   - Use shorter timeouts for cache operations
   - Implement circuit breakers for failing services

### Debug Information

```dart
// Get circuit breaker state
final state = circuitBreaker.getState();
print('Circuit breaker state: $state');

// Enable detailed logging
// Set EnvironmentConstants.enableLogging = true
```

## Migration Guide

### From Direct API Calls

```dart
// Before
try {
  final result = await apiService.getData();
  return result;
} catch (e) {
  throw e;
}

// After
return await RetryService.retryApiCall(
  () => apiService.getData(),
  endpoint: '/data',
);
```

### From Manual Retry Logic

```dart
// Before
int attempts = 0;
while (attempts < 3) {
  try {
    return await operation();
  } catch (e) {
    attempts++;
    if (attempts >= 3) rethrow;
    await Future.delayed(Duration(seconds: attempts));
  }
}

// After
return await RetryService.executeWithRetry(
  () => operation(),
  maxAttempts: 3,
);
```

This comprehensive retry system ensures robust error handling and improved user experience by automatically recovering from transient failures while preventing cascading failures through circuit breaker patterns.