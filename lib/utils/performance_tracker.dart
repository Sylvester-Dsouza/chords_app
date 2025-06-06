import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/service_locator.dart';
import '../services/performance_service.dart';

/// Helper class for easy performance tracking throughout the app
class PerformanceTracker {
  static PerformanceService? get _performanceService {
    try {
      return serviceLocator.performanceService;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Performance service not available: $e');
      }
      return null;
    }
  }

  /// Track a function execution time
  static Future<T> track<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    final service = _performanceService;
    if (service == null) {
      // If performance service is not available, just run the operation
      return await operation();
    }

    final stopwatch = Stopwatch()..start();

    try {
      await service.startTrace(operationName);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to start trace: $e');
    }

    try {
      final result = await operation();

      stopwatch.stop();
      try {
        await service.setMetric(operationName, 'execution_time_ms', stopwatch.elapsedMilliseconds);
        await service.stopTrace(operationName, attributes: {
          'status': 'success',
          'execution_time_category': _getExecutionTimeCategory(stopwatch.elapsed),
          ...?attributes,
        });
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Failed to complete trace: $e');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      try {
        await service.setMetric(operationName, 'execution_time_ms', stopwatch.elapsedMilliseconds);
        await service.stopTrace(operationName, attributes: {
          'status': 'error',
          'error': e.toString(),
          'execution_time_category': _getExecutionTimeCategory(stopwatch.elapsed),
          ...?attributes,
        });
      } catch (traceError) {
        if (kDebugMode) debugPrint('⚠️ Failed to complete error trace: $traceError');
      }

      rethrow;
    }
  }

  /// Track API calls
  static Future<T> trackApiCall<T>(
    String endpoint,
    Future<T> Function() apiCall, {
    Map<String, String>? attributes,
  }) async {
    final service = _performanceService;
    if (service == null) {
      return await apiCall();
    }
    try {
      return await service.trackApiCall(endpoint, apiCall, attributes: attributes);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ API tracking failed: $e');
      return await apiCall();
    }
  }

  /// Track screen loading
  static Future<void> trackScreenLoad(String screenName, Duration loadTime) async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.trackScreenLoad(screenName, loadTime);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Screen load tracking failed: $e');
    }
  }

  /// Track user interactions
  static Future<void> trackUserInteraction(String interaction) async {
    final service = _performanceService;
    if (service == null) return;

    final stopwatch = Stopwatch()..start();

    // This would typically be called after the interaction completes
    // For now, we'll simulate a quick interaction
    await Future.delayed(const Duration(milliseconds: 1));

    stopwatch.stop();
    try {
      await service.trackUserInteraction(interaction, stopwatch.elapsed);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ User interaction tracking failed: $e');
    }
  }

  /// Track audio/media operations
  static Future<void> trackMediaOperation(
    String operation,
    String mediaType,
    Duration duration, {
    Map<String, String>? attributes,
  }) async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.trackMediaOperation(operation, mediaType, duration, attributes: attributes);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Media operation tracking failed: $e');
    }
  }

  /// Track database operations
  static Future<T> trackDatabaseOperation<T>(
    String operation,
    Future<T> Function() dbOperation, {
    Map<String, String>? attributes,
  }) async {
    return track('db_$operation', dbOperation, attributes: {
      'operation_type': 'database',
      'db_operation': operation,
      ...?attributes,
    });
  }

  /// Track cache operations
  static Future<T> trackCacheOperation<T>(
    String operation,
    Future<T> Function() cacheOperation, {
    Map<String, String>? attributes,
  }) async {
    return track('cache_$operation', cacheOperation, attributes: {
      'operation_type': 'cache',
      'cache_operation': operation,
      ...?attributes,
    });
  }

  /// Track navigation performance
  static Future<void> trackNavigation(String fromScreen, String toScreen, Duration navigationTime) async {
    await track('navigation_${fromScreen}_to_$toScreen', () async {
      await Future.delayed(navigationTime);
    }, attributes: {
      'from_screen': fromScreen,
      'to_screen': toScreen,
      'navigation_type': 'screen_transition',
    });
  }

  /// Track app startup phases
  static Future<void> trackAppStartup() async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.startTrace('app_startup');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ App startup tracking failed: $e');
    }
  }

  static Future<void> completeAppStartup({Map<String, String>? attributes}) async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.stopTrace('app_startup', attributes: attributes);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ App startup completion tracking failed: $e');
    }
  }

  /// Track login performance
  static Future<T> trackLogin<T>(
    String loginMethod,
    Future<T> Function() loginOperation,
  ) async {
    return track('login_$loginMethod', loginOperation, attributes: {
      'login_method': loginMethod,
      'operation_type': 'authentication',
    });
  }

  /// Track data loading performance
  static Future<T> trackDataLoad<T>(
    String dataType,
    Future<T> Function() loadOperation, {
    int? itemCount,
    Map<String, String>? attributes,
  }) async {
    final result = await track('data_load_$dataType', loadOperation, attributes: {
      'data_type': dataType,
      'operation_type': 'data_loading',
      if (itemCount != null) 'item_count': itemCount.toString(),
      ...?attributes,
    });

    // Set item count metric if provided
    if (itemCount != null) {
      final service = _performanceService;
      if (service != null) {
        try {
          await service.setMetric('data_load_$dataType', 'items_loaded', itemCount);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Failed to set metric: $e');
        }
      }
    }

    return result;
  }

  /// Track search performance
  static Future<T> trackSearch<T>(
    String searchType,
    String query,
    Future<T> Function() searchOperation, {
    int? resultCount,
  }) async {
    final result = await track('search_$searchType', searchOperation, attributes: {
      'search_type': searchType,
      'query_length': query.length.toString(),
      'operation_type': 'search',
      if (resultCount != null) 'result_count': resultCount.toString(),
    });

    // Set result count metric if provided
    if (resultCount != null) {
      final service = _performanceService;
      if (service != null) {
        try {
          await service.setMetric('search_$searchType', 'results_found', resultCount);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Failed to set metric: $e');
        }
      }
    }

    return result;
  }

  /// Track file operations
  static Future<T> trackFileOperation<T>(
    String operation,
    String fileType,
    Future<T> Function() fileOperation, {
    int? fileSizeBytes,
    Map<String, String>? attributes,
  }) async {
    final result = await track('file_${operation}_$fileType', fileOperation, attributes: {
      'file_operation': operation,
      'file_type': fileType,
      'operation_type': 'file_io',
      if (fileSizeBytes != null) 'file_size_category': _getFileSizeCategory(fileSizeBytes),
      ...?attributes,
    });

    // Set file size metric if provided
    if (fileSizeBytes != null) {
      final service = _performanceService;
      if (service != null) {
        try {
          await service.setMetric('file_${operation}_$fileType', 'file_size_bytes', fileSizeBytes);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Failed to set metric: $e');
        }
      }
    }

    return result;
  }

  /// Track image loading performance
  static Future<void> trackImageLoad(String imageUrl, Duration loadTime, {int? imageSizeBytes}) async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.trackMediaOperation('load', 'image', loadTime, attributes: {
        'image_url': imageUrl,
        'operation_type': 'image_loading',
        if (imageSizeBytes != null) 'image_size_category': _getFileSizeCategory(imageSizeBytes),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Image load tracking failed: $e');
    }
  }

  /// Get execution time category for analysis
  static String _getExecutionTimeCategory(Duration duration) {
    if (duration.inMilliseconds < 100) return 'very_fast';
    if (duration.inMilliseconds < 500) return 'fast';
    if (duration.inMilliseconds < 1000) return 'medium';
    if (duration.inMilliseconds < 2000) return 'slow';
    return 'very_slow';
  }

  /// Get file size category for analysis
  static String _getFileSizeCategory(int bytes) {
    if (bytes < 1024) return 'tiny'; // < 1KB
    if (bytes < 1024 * 1024) return 'small'; // < 1MB
    if (bytes < 10 * 1024 * 1024) return 'medium'; // < 10MB
    if (bytes < 100 * 1024 * 1024) return 'large'; // < 100MB
    return 'very_large'; // >= 100MB
  }

  /// Start a custom trace (for manual control)
  static Future<void> startTrace(String traceName) async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.startTrace(traceName);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to start trace: $e');
    }
  }

  /// Stop a custom trace (for manual control)
  static Future<void> stopTrace(String traceName, {Map<String, String>? attributes}) async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.stopTrace(traceName, attributes: attributes);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to stop trace: $e');
    }
  }

  /// Set a metric for an active trace
  static Future<void> setMetric(String traceName, String metricName, int value) async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.setMetric(traceName, metricName, value);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to set metric: $e');
    }
  }

  /// Increment a metric for an active trace
  static Future<void> incrementMetric(String traceName, String metricName, int value) async {
    final service = _performanceService;
    if (service == null) return;
    try {
      await service.incrementMetric(traceName, metricName, value);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to increment metric: $e');
    }
  }

  /// Check if performance monitoring is enabled
  static bool get isEnabled => _performanceService?.isEnabled ?? false;

  /// Get performance monitoring status for debugging
  static Map<String, dynamic> getStatus() {
    final service = _performanceService;
    if (service == null) {
      return {
        'available': false,
        'error': 'Performance service not available',
      };
    }
    return service.getStatus();
  }

  /// Print performance monitoring status
  static void printStatus() {
    final service = _performanceService;
    if (service == null) {
      debugPrint('🔍 Performance Tracker: Service not available');
      return;
    }
    service.printStatus();
  }
}
