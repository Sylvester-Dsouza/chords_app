import 'dart:async';
import 'package:flutter/foundation.dart';
import 'constants.dart';

/// Performance monitoring service for tracking app performance
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, Duration> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  final List<PerformanceMetric> _metrics = [];

  /// Start timing an operation
  void startOperation(String operationName) {
    if (!EnvironmentConstants.enablePerformanceMonitoring) return;
    
    _operationStartTimes[operationName] = DateTime.now();
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
    
    if (EnvironmentConstants.enableLogging) {
      debugPrint('⏱️ Started: $operationName');
    }
  }

  /// End timing an operation and record the duration
  Duration? endOperation(String operationName) {
    if (!EnvironmentConstants.enablePerformanceMonitoring) return null;
    
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      if (EnvironmentConstants.enableLogging) {
        debugPrint('⚠️ No start time found for operation: $operationName');
      }
      return null;
    }

    final duration = DateTime.now().difference(startTime);
    _operationDurations[operationName] = duration;
    
    // Record metric
    _metrics.add(PerformanceMetric(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
    ));

    // Keep only recent metrics to prevent memory bloat - Reduced for mobile
    if (_metrics.length > 100) {
      _metrics.removeRange(0, _metrics.length - 100);
    }

    if (EnvironmentConstants.enableLogging) {
      debugPrint('✅ Completed: $operationName in ${duration.inMilliseconds}ms');
    }

    // Log slow operations
    if (duration.inMilliseconds > 1000) {
      debugPrint('🐌 Slow operation detected: $operationName took ${duration.inMilliseconds}ms');
    }

    return duration;
  }

  /// Time an async operation
  Future<T> timeOperation<T>(String operationName, Future<T> Function() operation) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Time a synchronous operation
  T timeSync<T>(String operationName, T Function() operation) {
    startOperation(operationName);
    try {
      final result = operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{};
    
    for (final operationName in _operationDurations.keys) {
      final duration = _operationDurations[operationName];
      final count = _operationCounts[operationName] ?? 0;
      
      stats[operationName] = {
        'lastDuration': duration?.inMilliseconds,
        'count': count,
        'averageDuration': _calculateAverageDuration(operationName),
      };
    }
    
    return stats;
  }

  /// Calculate average duration for an operation
  double? _calculateAverageDuration(String operationName) {
    final relevantMetrics = _metrics
        .where((metric) => metric.operationName == operationName)
        .toList();
    
    if (relevantMetrics.isEmpty) return null;
    
    final totalMs = relevantMetrics
        .map((metric) => metric.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return totalMs / relevantMetrics.length;
  }

  /// Get slow operations (operations that took longer than threshold)
  List<PerformanceMetric> getSlowOperations({Duration threshold = const Duration(seconds: 1)}) {
    return _metrics
        .where((metric) => metric.duration > threshold)
        .toList()
      ..sort((a, b) => b.duration.compareTo(a.duration));
  }

  /// Get recent metrics
  List<PerformanceMetric> getRecentMetrics({int limit = 50}) {
    final sortedMetrics = List<PerformanceMetric>.from(_metrics)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return sortedMetrics.take(limit).toList();
  }

  /// Clear all metrics
  void clearMetrics() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _operationCounts.clear();
    _metrics.clear();
    
    if (EnvironmentConstants.enableLogging) {
      debugPrint('🧹 Performance metrics cleared');
    }
  }

  /// Log performance summary
  void logSummary() {
    if (!EnvironmentConstants.enableLogging) return;
    
    debugPrint('📊 Performance Summary:');
    final stats = getStatistics();
    
    for (final entry in stats.entries) {
      final operationName = entry.key;
      final data = entry.value as Map<String, dynamic>;
      
      debugPrint('  $operationName:');
      debugPrint('    Last: ${data['lastDuration']}ms');
      debugPrint('    Count: ${data['count']}');
      debugPrint('    Average: ${data['averageDuration']?.toStringAsFixed(1)}ms');
    }
    
    final slowOps = getSlowOperations();
    if (slowOps.isNotEmpty) {
      debugPrint('🐌 Slow operations:');
      for (final metric in slowOps.take(5)) {
        debugPrint('  ${metric.operationName}: ${metric.duration.inMilliseconds}ms');
      }
    }
  }

  /// Monitor memory usage (basic implementation)
  void logMemoryUsage(String context) {
    if (!EnvironmentConstants.enableMemoryMonitoring) return;
    
    // Note: Detailed memory monitoring would require platform-specific implementation
    if (EnvironmentConstants.enableLogging) {
      debugPrint('💾 Memory check at $context');
    }
  }

  /// Check if operation is consistently slow
  bool isOperationSlow(String operationName, {Duration threshold = const Duration(milliseconds: 500)}) {
    final recentMetrics = _metrics
        .where((metric) => 
            metric.operationName == operationName &&
            DateTime.now().difference(metric.timestamp) < const Duration(minutes: 5))
        .toList();
    
    if (recentMetrics.length < 3) return false;
    
    final slowCount = recentMetrics
        .where((metric) => metric.duration > threshold)
        .length;
    
    return slowCount / recentMetrics.length > 0.7; // 70% of operations are slow
  }

  /// Get performance recommendations
  List<String> getRecommendations() {
    final recommendations = <String>[];
    
    final stats = getStatistics();
    for (final entry in stats.entries) {
      final operationName = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final avgDuration = data['averageDuration'] as double?;
      
      if (avgDuration != null) {
        if (avgDuration > 2000) {
          recommendations.add('$operationName is very slow (${avgDuration.toStringAsFixed(0)}ms avg). Consider optimization.');
        } else if (avgDuration > 1000) {
          recommendations.add('$operationName is slow (${avgDuration.toStringAsFixed(0)}ms avg). Monitor for improvements.');
        }
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Performance looks good! 🚀');
    }
    
    return recommendations;
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;

  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'operationName': operationName,
      'duration': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PerformanceMetric(operation: $operationName, duration: ${duration.inMilliseconds}ms, timestamp: $timestamp)';
  }
}

/// Extension for easy performance monitoring
extension PerformanceMonitorExtension<T> on Future<T> Function() {
  /// Time this async function
  Future<T> timed(String operationName) {
    return PerformanceMonitor().timeOperation(operationName, this);
  }
}

extension PerformanceMonitorSyncExtension<T> on T Function() {
  /// Time this synchronous function
  T timed(String operationName) {
    return PerformanceMonitor().timeSync(operationName, this);
  }
}
