import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../core/crashlytics_service.dart';

/// Utility class for wrapping operations with error tracking
class ErrorWrapper {
  static CrashlyticsService get _crashlytics =>
      serviceLocator.crashlyticsService;

  /// Wrap an async operation with error tracking
  static Future<T?> wrapAsync<T>(
    Future<T> Function() operation, {
    String? operationName,
    Map<String, dynamic>? context,
    T? fallbackValue,
    bool logErrors = true,
    bool reportToCrashlytics = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await operation();

      // Record performance if operation was slow
      if (stopwatch.elapsedMilliseconds > 2000) {
        await _crashlytics.recordPerformanceIssue(
          operationName ?? 'async_operation',
          stopwatch.elapsed,
          performanceData: context,
        );
      }

      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();

      if (logErrors && kDebugMode) {
        debugPrint('🐛 Error in ${operationName ?? 'async operation'}: $error');
      }

      if (reportToCrashlytics) {
        await _crashlytics.recordError(
          error,
          stackTrace,
          context: {
            'operation_name': operationName ?? 'async_operation',
            'operation_duration_ms': stopwatch.elapsedMilliseconds,
            ...?context,
          },
          reason: 'Async operation failed: ${operationName ?? 'unknown'}',
        );
      }

      return fallbackValue;
    } finally {
      stopwatch.stop();
    }
  }

  /// Wrap a synchronous operation with error tracking
  static T? wrapSync<T>(
    T Function() operation, {
    String? operationName,
    Map<String, dynamic>? context,
    T? fallbackValue,
    bool logErrors = true,
    bool reportToCrashlytics = true,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      stopwatch.stop();

      // Record performance if operation was slow
      if (stopwatch.elapsedMilliseconds > 1000) {
        _crashlytics.recordPerformanceIssue(
          operationName ?? 'sync_operation',
          stopwatch.elapsed,
          performanceData: context,
        );
      }

      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();

      if (logErrors && kDebugMode) {
        debugPrint('🐛 Error in ${operationName ?? 'sync operation'}: $error');
      }

      if (reportToCrashlytics) {
        _crashlytics.recordError(
          error,
          stackTrace,
          context: {
            'operation_name': operationName ?? 'sync_operation',
            'operation_duration_ms': stopwatch.elapsedMilliseconds,
            ...?context,
          },
          reason: 'Sync operation failed: ${operationName ?? 'unknown'}',
        );
      }

      return fallbackValue;
    }
  }

  /// Wrap an API call with specific error tracking
  static Future<T?> wrapApiCall<T>(
    Future<T> Function() apiCall, {
    required String endpoint,
    Map<String, dynamic>? requestData,
    T? fallbackValue,
    bool logErrors = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await apiCall();
      stopwatch.stop();

      // Log successful API calls that are slow
      if (stopwatch.elapsedMilliseconds > 3000) {
        await _crashlytics.logEvent('slow_api_call', {
          'endpoint': endpoint,
          'duration_ms': stopwatch.elapsedMilliseconds,
          'status': 'success',
        });
      }

      return result;
    } catch (error, stackTrace) {
      stopwatch.stop();

      if (logErrors && kDebugMode) {
        debugPrint('🌐 API Error for $endpoint: $error');
        debugPrint('Stack trace: $stackTrace');
      }

      // Extract status code if available
      int? statusCode;
      if (error.toString().contains('status code')) {
        final match = RegExp(r'status code (\d+)').firstMatch(error.toString());
        if (match != null) {
          statusCode = int.tryParse(match.group(1) ?? '');
        }
      }

      await _crashlytics.recordApiError(
        endpoint,
        statusCode,
        error,
        requestData: requestData,
      );

      return fallbackValue;
    }
  }

  /// Wrap navigation operations with error tracking
  static Future<T?> wrapNavigation<T>(
    Future<T> Function() navigationOperation, {
    required String route,
    Map<String, dynamic>? routeArguments,
    T? fallbackValue,
    bool logErrors = true,
  }) async {
    try {
      return await navigationOperation();
    } catch (error, stackTrace) {
      if (logErrors && kDebugMode) {
        debugPrint('🧭 Navigation Error for $route: $error');
        debugPrint('Stack trace: $stackTrace');
      }

      await _crashlytics.recordNavigationError(
        route,
        error,
        routeArguments: routeArguments,
      );

      return fallbackValue;
    }
  }

  /// Wrap media operations with error tracking
  static Future<T?> wrapMediaOperation<T>(
    Future<T> Function() mediaOperation, {
    required String mediaType,
    required String mediaUrl,
    Map<String, dynamic>? mediaInfo,
    T? fallbackValue,
    bool logErrors = true,
  }) async {
    try {
      return await mediaOperation();
    } catch (error, stackTrace) {
      if (logErrors && kDebugMode) {
        debugPrint('🎵 Media Error for $mediaType: $error');
        debugPrint('Stack trace: $stackTrace');
      }

      await _crashlytics.recordMediaError(
        mediaType,
        mediaUrl,
        error,
        mediaInfo: mediaInfo,
      );

      return fallbackValue;
    }
  }

  /// Wrap widget build operations with error tracking
  static Widget wrapWidget(
    Widget Function() builder, {
    String? widgetName,
    Map<String, dynamic>? context,
    Widget? fallbackWidget,
  }) {
    try {
      return builder();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          '🎨 Widget Error in ${widgetName ?? 'unknown widget'}: $error',
        );
      }

      _crashlytics.recordError(
        error,
        stackTrace,
        context: {
          'widget_name': widgetName ?? 'unknown_widget',
          'error_type': 'widget_build_error',
          ...?context,
        },
        reason: 'Widget build failed: ${widgetName ?? 'unknown'}',
      );

      return fallbackWidget ?? const SizedBox.shrink();
    }
  }

  /// Wrap stream operations with error tracking
  static Stream<T> wrapStream<T>(
    Stream<T> stream, {
    String? streamName,
    Map<String, dynamic>? context,
    bool logErrors = true,
  }) {
    return stream.handleError((Object error, StackTrace stackTrace) {
      if (logErrors && kDebugMode) {
        debugPrint(
          '🌊 Stream Error in ${streamName ?? 'unknown stream'}: $error',
        );
      }

      _crashlytics.recordError(
        error,
        stackTrace,
        context: {
          'stream_name': streamName ?? 'unknown_stream',
          'error_type': 'stream_error',
          ...?context,
        },
        reason: 'Stream error: ${streamName ?? 'unknown'}',
      );
    });
  }

  /// Record a custom event for tracking
  static Future<void> logEvent(
    String eventName,
    Map<String, dynamic> parameters,
  ) async {
    await _crashlytics.logEvent(eventName, parameters);
  }

  /// Record user action for tracking
  static Future<void> logUserAction(
    String action, {
    String? screen,
    Map<String, dynamic>? additionalData,
  }) async {
    await _crashlytics.logEvent('user_action', {
      'action': action,
      'screen': screen ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Record app lifecycle events
  static Future<void> logAppLifecycle(
    String event, {
    Map<String, dynamic>? additionalData,
  }) async {
    await _crashlytics.logEvent('app_lifecycle', {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }
}

/// Extension methods for easier error wrapping
extension FutureErrorWrapper<T> on Future<T> {
  /// Wrap this future with error tracking
  Future<T?> withErrorTracking({
    String? operationName,
    Map<String, dynamic>? context,
    T? fallbackValue,
    bool logErrors = true,
    bool reportToCrashlytics = true,
  }) {
    return ErrorWrapper.wrapAsync(
      () => this,
      operationName: operationName,
      context: context,
      fallbackValue: fallbackValue,
      logErrors: logErrors,
      reportToCrashlytics: reportToCrashlytics,
    );
  }
}

extension StreamErrorWrapper<T> on Stream<T> {
  /// Wrap this stream with error tracking
  Stream<T> withErrorTracking({
    String? streamName,
    Map<String, dynamic>? context,
    bool logErrors = true,
  }) {
    return ErrorWrapper.wrapStream(
      this,
      streamName: streamName,
      context: context,
      logErrors: logErrors,
    );
  }
}
