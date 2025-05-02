import 'package:flutter/material.dart';
import 'dart:developer' as developer;

/// A utility class for monitoring and optimizing app performance.
class PerformanceMonitor {
  // Singleton instance
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // Performance tracking
  final Map<String, Stopwatch> _stopwatches = {};
  final Map<String, List<Duration>> _operationTimes = {};
  final Map<String, int> _operationCounts = {};
  
  // Memory tracking
  final Map<String, int> _memoryUsage = {};
  
  // Configuration
  bool _isEnabled = true;
  bool _logToConsole = true;
  
  // Enable or disable performance monitoring
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  // Set whether to log to console
  void setLogToConsole(bool logToConsole) {
    _logToConsole = logToConsole;
  }
  
  // Start timing an operation
  void startOperation(String operationName) {
    if (!_isEnabled) return;
    
    final stopwatch = Stopwatch()..start();
    _stopwatches[operationName] = stopwatch;
    
    if (_logToConsole) {
      debugPrint('⏱️ Started operation: $operationName');
    }
  }
  
  // End timing an operation
  Duration endOperation(String operationName) {
    if (!_isEnabled || !_stopwatches.containsKey(operationName)) {
      return Duration.zero;
    }
    
    final stopwatch = _stopwatches[operationName]!;
    stopwatch.stop();
    final duration = stopwatch.elapsed;
    
    // Record operation time
    if (!_operationTimes.containsKey(operationName)) {
      _operationTimes[operationName] = [];
    }
    _operationTimes[operationName]!.add(duration);
    
    // Increment operation count
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
    
    // Remove stopwatch
    _stopwatches.remove(operationName);
    
    if (_logToConsole) {
      debugPrint('⏱️ Completed operation: $operationName in ${_formatDuration(duration)}');
    }
    
    return duration;
  }
  
  // Track memory usage
  void trackMemoryUsage(String tag, int bytes) {
    if (!_isEnabled) return;
    
    _memoryUsage[tag] = bytes;
    
    if (_logToConsole) {
      debugPrint('🧠 Memory usage for $tag: ${_formatBytes(bytes)}');
    }
  }
  
  // Get performance report
  String getPerformanceReport() {
    if (!_isEnabled) return 'Performance monitoring is disabled';
    
    final buffer = StringBuffer();
    buffer.writeln('📊 Performance Report 📊');
    buffer.writeln('------------------------');
    
    // Operation times
    buffer.writeln('Operation Times:');
    _operationTimes.forEach((operation, times) {
      if (times.isEmpty) return;
      
      final avgTime = times.reduce((a, b) => a + b) ~/ times.length;
      final minTime = times.reduce((a, b) => a < b ? a : b);
      final maxTime = times.reduce((a, b) => a > b ? a : b);
      
      buffer.writeln('  $operation:');
      buffer.writeln('    Count: ${times.length}');
      buffer.writeln('    Avg: ${_formatDuration(avgTime)}');
      buffer.writeln('    Min: ${_formatDuration(minTime)}');
      buffer.writeln('    Max: ${_formatDuration(maxTime)}');
    });
    
    // Memory usage
    buffer.writeln('\nMemory Usage:');
    _memoryUsage.forEach((tag, bytes) {
      buffer.writeln('  $tag: ${_formatBytes(bytes)}');
    });
    
    return buffer.toString();
  }
  
  // Log performance report
  void logPerformanceReport() {
    if (!_isEnabled) return;
    
    final report = getPerformanceReport();
    
    if (_logToConsole) {
      debugPrint(report);
    }
    
    // Log to DevTools timeline
    developer.Timeline.instantSync('Performance Report', arguments: {
      'report': report,
    });
  }
  
  // Reset all performance data
  void reset() {
    _stopwatches.clear();
    _operationTimes.clear();
    _operationCounts.clear();
    _memoryUsage.clear();
  }
  
  // Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1) {
      return '${duration.inMicroseconds}μs';
    } else if (duration.inSeconds < 1) {
      return '${duration.inMilliseconds}ms';
    } else {
      return '${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')}s';
    }
  }
  
  // Format bytes for display
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
  
  // Track widget rebuilds
  static void trackRebuild(String widgetName) {
    if (!_instance._isEnabled) return;
    
    if (_instance._logToConsole) {
      debugPrint('🔄 Widget rebuilt: $widgetName');
    }
    
    // Increment rebuild count
    _instance._operationCounts['rebuild_$widgetName'] = 
        (_instance._operationCounts['rebuild_$widgetName'] ?? 0) + 1;
  }
}
