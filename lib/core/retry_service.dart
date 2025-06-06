import 'dart:async';
import 'package:flutter/foundation.dart';
import 'error_handler.dart';
import 'constants.dart';

/// Service for handling retries with exponential backoff
class RetryService {
  static final RetryService _instance = RetryService._internal();
  factory RetryService() => _instance;
  RetryService._internal();

  /// Execute a function with retry logic
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = AppConstants.maxRetryAttempts,
    Duration? initialDelay,
    bool Function(dynamic error)? shouldRetry,
    String? context,
  }) async {
    int attempt = 1;
    dynamic lastError;

    while (attempt <= maxAttempts) {
      try {
        if (EnvironmentConstants.enableLogging && context != null) {
          debugPrint('🔄 Attempting $context (attempt $attempt/$maxAttempts)');
        }

        final result = await operation();
        
        if (attempt > 1 && EnvironmentConstants.enableLogging && context != null) {
          debugPrint('✅ $context succeeded on attempt $attempt');
        }
        
        return result;
      } catch (error) {
        lastError = error;
        
        if (EnvironmentConstants.enableLogging && context != null) {
          debugPrint('❌ $context failed on attempt $attempt: $error');
        }

        // Check if we should retry this error
        final customShouldRetry = shouldRetry?.call(error) ?? ErrorHandler.isRetryableError(error);
        
        if (!customShouldRetry || attempt >= maxAttempts) {
          if (EnvironmentConstants.enableLogging && context != null) {
            debugPrint('🚫 Not retrying $context: ${!customShouldRetry ? 'not retryable' : 'max attempts reached'}');
          }
          rethrow;
        }

        // Calculate delay for next attempt
        final delay = initialDelay ?? ErrorHandler.getRetryDelay(attempt);
        
        if (EnvironmentConstants.enableLogging && context != null) {
          debugPrint('⏳ Retrying $context in ${delay.inSeconds}s...');
        }
        
        await Future.delayed(delay);
        attempt++;
      }
    }

    // This should never be reached, but just in case
    throw lastError ?? Exception('Unknown error in retry logic');
  }

  /// Execute with retry and return a result object instead of throwing
  static Future<Map<String, dynamic>> executeWithRetryResult<T>(
    Future<T> Function() operation, {
    int maxAttempts = AppConstants.maxRetryAttempts,
    Duration? initialDelay,
    bool Function(dynamic error)? shouldRetry,
    String? context,
  }) async {
    try {
      final result = await executeWithRetry(
        operation,
        maxAttempts: maxAttempts,
        initialDelay: initialDelay,
        shouldRetry: shouldRetry,
        context: context,
      );
      
      return ErrorHandler.createSuccessResult(result);
    } catch (error) {
      final message = ErrorHandler.handleErrorWithContext(context ?? 'Operation', error);
      return ErrorHandler.createErrorResult(message);
    }
  }

  /// Retry specifically for API calls
  static Future<T> retryApiCall<T>(
    Future<T> Function() apiCall, {
    String? endpoint,
    int maxAttempts = AppConstants.maxRetryAttempts,
  }) async {
    return executeWithRetry(
      apiCall,
      maxAttempts: maxAttempts,
      shouldRetry: (error) => ErrorHandler.isRetryableError(error) && !ErrorHandler.isAuthError(error),
      context: endpoint != null ? 'API call to $endpoint' : 'API call',
    );
  }

  /// Retry for network operations
  static Future<T> retryNetworkOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    int maxAttempts = AppConstants.maxRetryAttempts,
  }) async {
    return executeWithRetry(
      operation,
      maxAttempts: maxAttempts,
      shouldRetry: ErrorHandler.isNetworkError,
      context: operationName ?? 'Network operation',
    );
  }

  /// Retry for cache operations
  static Future<T> retryCacheOperation<T>(
    Future<T> Function() operation, {
    String? operationName,
    int maxAttempts = 2, // Fewer retries for cache operations
  }) async {
    return executeWithRetry(
      operation,
      maxAttempts: maxAttempts,
      initialDelay: const Duration(milliseconds: 100), // Shorter delay for cache
      shouldRetry: (error) {
        // Retry cache operations for most errors except auth
        return !ErrorHandler.isAuthError(error);
      },
      context: operationName ?? 'Cache operation',
    );
  }

  /// Execute multiple operations with retry, stopping on first success
  static Future<T> executeFirstSuccessful<T>(
    List<Future<T> Function()> operations, {
    String? context,
    int maxAttemptsPerOperation = 2,
  }) async {
    if (operations.isEmpty) {
      throw ArgumentError('Operations list cannot be empty');
    }

    dynamic lastError;
    
    for (int i = 0; i < operations.length; i++) {
      try {
        final result = await executeWithRetry(
          operations[i],
          maxAttempts: maxAttemptsPerOperation,
          context: context != null ? '$context (option ${i + 1})' : null,
        );
        return result;
      } catch (error) {
        lastError = error;
        if (EnvironmentConstants.enableLogging && context != null) {
          debugPrint('❌ $context option ${i + 1} failed: $error');
        }
      }
    }

    // All operations failed
    throw lastError ?? Exception('All operations failed');
  }

  /// Create a circuit breaker pattern for repeated failures
  static CircuitBreaker createCircuitBreaker({
    required String name,
    int failureThreshold = 5,
    Duration timeout = const Duration(minutes: 1),
  }) {
    return CircuitBreaker(
      name: name,
      failureThreshold: failureThreshold,
      timeout: timeout,
    );
  }
}

/// Circuit breaker implementation to prevent cascading failures
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  CircuitBreaker({
    required this.name,
    required this.failureThreshold,
    required this.timeout,
  });

  /// Execute operation through circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_isOpen) {
      if (_lastFailureTime != null && 
          DateTime.now().difference(_lastFailureTime!) > timeout) {
        // Try to close the circuit
        _reset();
        if (EnvironmentConstants.enableLogging) {
          debugPrint('🔄 Circuit breaker $name: Attempting to close');
        }
      } else {
        throw Exception('Circuit breaker $name is open. Service temporarily unavailable.');
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _isOpen = false;
    if (EnvironmentConstants.enableLogging) {
      debugPrint('✅ Circuit breaker $name: Operation succeeded');
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _isOpen = true;
      if (EnvironmentConstants.enableLogging) {
        debugPrint('🚫 Circuit breaker $name: Opened due to $_failureCount failures');
      }
    }
  }

  void _reset() {
    _failureCount = 0;
    _isOpen = false;
    _lastFailureTime = null;
  }

  /// Get current state
  Map<String, dynamic> getState() {
    return {
      'name': name,
      'isOpen': _isOpen,
      'failureCount': _failureCount,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
      'failureThreshold': failureThreshold,
      'timeout': timeout.inMilliseconds,
    };
  }
}
