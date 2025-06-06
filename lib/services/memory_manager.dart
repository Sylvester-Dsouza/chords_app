import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Memory management service to monitor and optimize app memory usage
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _memoryMonitorTimer;
  bool _isMonitoring = false;
  
  // Memory thresholds (in MB)
  static const double _warningThreshold = 200.0; // 200MB
  static const double _criticalThreshold = 300.0; // 300MB
  
  // Callbacks for memory pressure
  final List<VoidCallback> _memoryPressureCallbacks = [];
  final List<VoidCallback> _criticalMemoryCallbacks = [];

  /// Start monitoring memory usage
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 30), // Check every 30 seconds
      (_) => _checkMemoryUsage(),
    );
    
    debugPrint('🧠 Memory monitoring started');
  }

  /// Stop monitoring memory usage
  void stopMonitoring() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;
    _isMonitoring = false;
    debugPrint('🧠 Memory monitoring stopped');
  }

  /// Add callback for memory pressure events
  void addMemoryPressureCallback(VoidCallback callback) {
    _memoryPressureCallbacks.add(callback);
  }

  /// Add callback for critical memory events
  void addCriticalMemoryCallback(VoidCallback callback) {
    _criticalMemoryCallbacks.add(callback);
  }

  /// Remove memory pressure callback
  void removeMemoryPressureCallback(VoidCallback callback) {
    _memoryPressureCallbacks.remove(callback);
  }

  /// Remove critical memory callback
  void removeCriticalMemoryCallback(VoidCallback callback) {
    _criticalMemoryCallbacks.remove(callback);
  }

  /// Check current memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      if (memoryInfo == null) return;

      final usedMemoryMB = memoryInfo['usedMemory'] ?? 0.0;
      
      debugPrint('🧠 Memory usage: ${usedMemoryMB.toStringAsFixed(1)} MB');

      if (usedMemoryMB > _criticalThreshold) {
        debugPrint('🚨 CRITICAL memory usage: ${usedMemoryMB.toStringAsFixed(1)} MB');
        _triggerCriticalMemoryCallbacks();
      } else if (usedMemoryMB > _warningThreshold) {
        debugPrint('⚠️ High memory usage: ${usedMemoryMB.toStringAsFixed(1)} MB');
        _triggerMemoryPressureCallbacks();
      }
    } catch (e) {
      debugPrint('Error checking memory usage: $e');
    }
  }

  /// Get memory information
  Future<Map<String, double>?> _getMemoryInfo() async {
    try {
      if (Platform.isAndroid) {
        // For Android, we can use ProcessInfo
        final info = ProcessInfo.currentRss;
        return {
          'usedMemory': info / (1024 * 1024), // Convert bytes to MB
        };
      } else if (Platform.isIOS) {
        // For iOS, we can use ProcessInfo
        final info = ProcessInfo.currentRss;
        return {
          'usedMemory': info / (1024 * 1024), // Convert bytes to MB
        };
      }
    } catch (e) {
      debugPrint('Error getting memory info: $e');
    }
    return null;
  }

  /// Trigger memory pressure callbacks
  void _triggerMemoryPressureCallbacks() {
    for (final callback in _memoryPressureCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in memory pressure callback: $e');
      }
    }
  }

  /// Trigger critical memory callbacks
  void _triggerCriticalMemoryCallbacks() {
    for (final callback in _criticalMemoryCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in critical memory callback: $e');
      }
    }
  }

  /// Force garbage collection and cleanup
  void forceCleanup() {
    debugPrint('🧹 Forcing memory cleanup...');
    
    // Clear image cache
    try {
      PaintingBinding.instance.imageCache.clear();
      debugPrint('🧹 Cleared image cache');
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }

    // Trigger memory pressure callbacks
    _triggerMemoryPressureCallbacks();
    
    debugPrint('🧹 Memory cleanup completed');
  }

  /// Get current memory usage as a string
  Future<String> getMemoryUsageString() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      if (memoryInfo == null) return 'Unknown';
      
      final usedMemoryMB = memoryInfo['usedMemory'] ?? 0.0;
      return '${usedMemoryMB.toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Dispose of the memory manager
  void dispose() {
    stopMonitoring();
    _memoryPressureCallbacks.clear();
    _criticalMemoryCallbacks.clear();
  }
}
