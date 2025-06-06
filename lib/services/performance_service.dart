import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants.dart';

/// Comprehensive Firebase Performance Monitoring service
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  FirebasePerformance? _performance;
  bool _isInitialized = false;
  bool _isEnabled = false;

  // Active traces
  final Map<String, Trace> _activeTraces = {};

  /// Initialize Firebase Performance Monitoring
  Future<void> initialize() async {
    debugPrint('🚀 Initializing Firebase Performance Monitoring...');

    try {
      // Initialize if Firebase is available
      if (Firebase.apps.isNotEmpty) {
        _performance = FirebasePerformance.instance;

        // Enable performance monitoring (with timeout)
        await _performance!.setPerformanceCollectionEnabled(true)
            .timeout(const Duration(seconds: 5));

        _isEnabled = true;
        _isInitialized = true;

        debugPrint('✅ Firebase Performance Monitoring initialized successfully');

        // Start automatic app performance tracking (non-blocking)
        _startAppPerformanceTracking();

      } else {
        debugPrint('⚠️ Firebase not available - Performance Monitoring disabled');
        _isEnabled = false;
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('❌ Failed to initialize Firebase Performance Monitoring: $e');
      // Don't block app startup - just disable performance monitoring
      _isEnabled = false;
      _isInitialized = true;
    }
  }

  /// Start automatic app performance tracking
  void _startAppPerformanceTracking() {
    if (!_isEnabled) return;

    // Track app startup time
    startTrace('app_startup');
    
    // Track memory usage periodically
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _trackMemoryUsage();
    });
  }

  /// Start a custom trace
  Future<void> startTrace(String traceName) async {
    if (!_isEnabled || _performance == null) {
      debugPrint('📊 Performance Monitoring Disabled - Trace: $traceName');
      return;
    }

    try {
      if (_activeTraces.containsKey(traceName)) {
        debugPrint('⚠️ Trace $traceName already active');
        return;
      }

      final trace = _performance!.newTrace(traceName);
      await trace.start().timeout(const Duration(seconds: 2));
      _activeTraces[traceName] = trace;

      debugPrint('✅ Started Firebase Performance trace: $traceName');
    } catch (e) {
      debugPrint('❌ Failed to start trace $traceName: $e');
      // Don't block execution - just skip this trace
    }
  }

  /// Stop a custom trace
  Future<void> stopTrace(String traceName, {Map<String, String>? attributes}) async {
    if (!_isEnabled || _performance == null) {
      debugPrint('📊 Performance Monitoring Disabled - Stop Trace: $traceName');
      return;
    }

    try {
      final trace = _activeTraces.remove(traceName);
      if (trace == null) {
        debugPrint('⚠️ Trace $traceName not found');
        return;
      }

      // Add custom attributes
      if (attributes != null) {
        for (final entry in attributes.entries) {
          try {
            trace.putAttribute(entry.key, entry.value);
          } catch (e) {
            debugPrint('⚠️ Failed to set attribute ${entry.key}: $e');
          }
        }
      }

      await trace.stop().timeout(const Duration(seconds: 2));

      debugPrint('✅ Stopped Firebase Performance trace: $traceName (attributes: ${attributes?.length ?? 0})');
    } catch (e) {
      debugPrint('❌ Failed to stop trace $traceName: $e');
      // Don't block execution - just skip this trace
    }
  }

  /// Increment a metric for an active trace
  Future<void> incrementMetric(String traceName, String metricName, int value) async {
    if (!_isEnabled || _performance == null) return;

    try {
      final trace = _activeTraces[traceName];
      if (trace == null) {
        debugPrint('⚠️ Trace $traceName not found for metric $metricName');
        return;
      }

      trace.incrementMetric(metricName, value);

      if (EnvironmentConstants.enableLogging) {
        debugPrint('📊 Incremented metric $metricName by $value for trace $traceName');
      }
    } catch (e) {
      debugPrint('❌ Failed to increment metric $metricName: $e');
    }
  }

  /// Set a metric value for an active trace
  Future<void> setMetric(String traceName, String metricName, int value) async {
    if (!_isEnabled || _performance == null) return;

    try {
      final trace = _activeTraces[traceName];
      if (trace == null) {
        debugPrint('⚠️ Trace $traceName not found for metric $metricName');
        return;
      }

      trace.setMetric(metricName, value);

      if (EnvironmentConstants.enableLogging) {
        debugPrint('📊 Set metric $metricName to $value for trace $traceName');
      }
    } catch (e) {
      debugPrint('❌ Failed to set metric $metricName: $e');
    }
  }

  /// Track API call performance
  Future<T> trackApiCall<T>(
    String endpoint,
    Future<T> Function() apiCall, {
    Map<String, String>? attributes,
  }) async {
    final traceName = 'api_call_${endpoint.replaceAll('/', '_')}';
    
    await startTrace(traceName);
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await apiCall();
      
      stopwatch.stop();
      
      await setMetric(traceName, 'response_time_ms', stopwatch.elapsedMilliseconds);
      await stopTrace(traceName, attributes: {
        'endpoint': endpoint,
        'status': 'success',
        ...?attributes,
      });
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      await setMetric(traceName, 'response_time_ms', stopwatch.elapsedMilliseconds);
      await stopTrace(traceName, attributes: {
        'endpoint': endpoint,
        'status': 'error',
        'error': e.toString(),
        ...?attributes,
      });
      
      rethrow;
    }
  }

  /// Track screen loading performance
  Future<void> trackScreenLoad(String screenName, Duration loadTime) async {
    final traceName = 'screen_load_$screenName';
    
    await startTrace(traceName);
    await setMetric(traceName, 'load_time_ms', loadTime.inMilliseconds);
    await stopTrace(traceName, attributes: {
      'screen_name': screenName,
      'load_time_category': _getLoadTimeCategory(loadTime),
    });
  }

  /// Track audio/media performance
  Future<void> trackMediaOperation(
    String operation,
    String mediaType,
    Duration duration, {
    Map<String, String>? attributes,
  }) async {
    final traceName = 'media_${operation}_$mediaType';
    
    await startTrace(traceName);
    await setMetric(traceName, 'operation_time_ms', duration.inMilliseconds);
    await stopTrace(traceName, attributes: {
      'operation': operation,
      'media_type': mediaType,
      'performance_category': _getPerformanceCategory(duration),
      ...?attributes,
    });
  }

  /// Track memory usage
  void _trackMemoryUsage() {
    // This is a placeholder - actual memory tracking would require platform-specific code
    if (kDebugMode) {
      debugPrint('📊 Tracking memory usage...');
    }
  }

  /// Get load time category for analysis
  String _getLoadTimeCategory(Duration duration) {
    if (duration.inMilliseconds < 500) return 'fast';
    if (duration.inMilliseconds < 1000) return 'medium';
    if (duration.inMilliseconds < 2000) return 'slow';
    return 'very_slow';
  }

  /// Get performance category for analysis
  String _getPerformanceCategory(Duration duration) {
    if (duration.inMilliseconds < 100) return 'excellent';
    if (duration.inMilliseconds < 500) return 'good';
    if (duration.inMilliseconds < 1000) return 'fair';
    return 'poor';
  }

  /// Track user interaction performance
  Future<void> trackUserInteraction(String interaction, Duration responseTime) async {
    final traceName = 'user_interaction_$interaction';
    
    await startTrace(traceName);
    await setMetric(traceName, 'response_time_ms', responseTime.inMilliseconds);
    await stopTrace(traceName, attributes: {
      'interaction': interaction,
      'responsiveness': _getResponsivenessCategory(responseTime),
    });
  }

  /// Get responsiveness category
  String _getResponsivenessCategory(Duration duration) {
    if (duration.inMilliseconds < 16) return 'smooth'; // 60fps
    if (duration.inMilliseconds < 33) return 'acceptable'; // 30fps
    if (duration.inMilliseconds < 100) return 'noticeable';
    return 'janky';
  }

  /// Check if Performance Monitoring is enabled
  bool get isEnabled => _isEnabled && _isInitialized;

  /// Get Performance instance (for advanced usage)
  FirebasePerformance? get instance => _performance;

  /// Get performance monitoring status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'isEnabled': _isEnabled,
      'isInitialized': _isInitialized,
      'hasFirebaseApps': Firebase.apps.isNotEmpty,
      'activeTraces': _activeTraces.keys.toList(),
      'activeTracesCount': _activeTraces.length,
    };
  }

  /// Print current status for debugging
  void printStatus() {
    final status = getStatus();
    debugPrint('🔍 Firebase Performance Status:');
    debugPrint('  - Enabled: ${status['isEnabled']}');
    debugPrint('  - Initialized: ${status['isInitialized']}');
    debugPrint('  - Firebase Apps: ${status['hasFirebaseApps']}');
    debugPrint('  - Active Traces: ${status['activeTracesCount']}');
    if (status['activeTracesCount'] > 0) {
      debugPrint('  - Trace Names: ${status['activeTraces']}');
    }
  }

  /// Dispose the service
  void dispose() {
    // Stop all active traces
    for (final trace in _activeTraces.values) {
      try {
        trace.stop();
      } catch (e) {
        debugPrint('❌ Error stopping trace during dispose: $e');
      }
    }
    _activeTraces.clear();
    
    _isEnabled = false;
    _isInitialized = false;
    _performance = null;
    
    debugPrint('✅ Performance Service disposed');
  }
}
