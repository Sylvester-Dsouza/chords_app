import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'image_cache_manager.dart';

/// Memory management service to monitor and optimize app memory usage
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _memoryMonitorTimer;
  bool _isMonitoring = false;
  
  // Memory thresholds (in MB) - Mobile-appropriate limits
  static const double _warningThreshold = 100.0; // 100MB warning
  static const double _criticalThreshold = 150.0; // 150MB critical
  static const double _emergencyThreshold = 200.0; // 200MB emergency
  
  // Callbacks for memory pressure
  final List<VoidCallback> _memoryPressureCallbacks = [];
  final List<VoidCallback> _criticalMemoryCallbacks = [];
  final List<VoidCallback> _emergencyMemoryCallbacks = [];

  /// Start monitoring memory usage
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _memoryMonitorTimer = Timer.periodic(
      const Duration(minutes: 2), // Check every 2 minutes to reduce overhead
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

  /// Add callback for emergency memory events
  void addEmergencyMemoryCallback(VoidCallback callback) {
    _emergencyMemoryCallbacks.add(callback);
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

      if (usedMemoryMB > _emergencyThreshold) {
        debugPrint('🆘 EMERGENCY memory usage: ${usedMemoryMB.toStringAsFixed(1)} MB - IMMEDIATE ACTION REQUIRED');
        _triggerEmergencyMemoryCallbacks();
      } else if (usedMemoryMB > _criticalThreshold) {
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

  /// Trigger emergency memory callbacks
  void _triggerEmergencyMemoryCallbacks() {
    for (final callback in _emergencyMemoryCallbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('Error in emergency memory callback: $e');
      }
    }
  }

  /// Force garbage collection and cleanup
  void forceCleanup() {
    debugPrint('🧹 Forcing memory cleanup...');

    // Use image cache manager for better cleanup
    try {
      ImageCacheManager().forceCleanup();
      debugPrint('🧹 Image cache manager cleanup completed');
    } catch (e) {
      debugPrint('Error during image cache cleanup: $e');
      // Fallback to direct cache clear
      try {
        PaintingBinding.instance.imageCache.clear();
        debugPrint('🧹 Fallback image cache clear completed');
      } catch (e2) {
        debugPrint('Error clearing image cache: $e2');
      }
    }

    // Trigger memory pressure callbacks
    _triggerMemoryPressureCallbacks();

    debugPrint('🧹 Memory cleanup completed');
  }

  /// Get current memory status for debugging
  Future<String> getMemoryStatus() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      if (memoryInfo == null) return 'Memory info unavailable';

      final usedMemoryMB = memoryInfo['usedMemory'] ?? 0.0;
      final imageCacheStats = ImageCacheManager().getCacheStats();

      String status = 'Normal';
      if (usedMemoryMB > _emergencyThreshold) {
        status = 'EMERGENCY';
      } else if (usedMemoryMB > _criticalThreshold) {
        status = 'CRITICAL';
      } else if (usedMemoryMB > _warningThreshold) {
        status = 'WARNING';
      }

      return '''
🧠 Memory Status: $status
📊 Used Memory: ${usedMemoryMB.toStringAsFixed(1)} MB
⚠️ Warning Threshold: ${_warningThreshold.toStringAsFixed(1)} MB
🚨 Critical Threshold: ${_criticalThreshold.toStringAsFixed(1)} MB
🆘 Emergency Threshold: ${_emergencyThreshold.toStringAsFixed(1)} MB
🖼️ Image Cache: ${imageCacheStats['currentSize']} objects, ${imageCacheStats['currentSizeMB'].toStringAsFixed(1)} MB
''';
    } catch (e) {
      return 'Error getting memory status: $e';
    }
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
