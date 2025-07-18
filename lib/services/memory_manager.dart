import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'image_cache_manager.dart';

/// Memory management service to monitor and optimize app memory usage
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _memoryMonitorTimer;
  bool _isMonitoring = false;
  
  // Memory thresholds (in MB) - Optimized for modern devices with 2GB+ RAM
  static const double _warningThreshold = 500.0; // 500MB warning
  static const double _criticalThreshold = 800.0; // 800MB critical
  static const double _emergencyThreshold = 1200.0; // 1200MB emergency - only for true emergencies
  
  // Callbacks for memory pressure
  final List<VoidCallback> _memoryPressureCallbacks = [];
  final List<VoidCallback> _criticalMemoryCallbacks = [];
  final List<VoidCallback> _emergencyMemoryCallbacks = [];

  /// Start monitoring memory usage
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _memoryMonitorTimer = Timer.periodic(
      const Duration(minutes: 5), // Check every 5 minutes to reduce overhead and prevent aggressive cleanup
      (_) => _checkMemoryUsage(),
    );

    debugPrint('🧠 Memory monitoring started with conservative thresholds');
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
        debugPrint('🆘 EMERGENCY memory pressure - conservative cleanup only');
        _triggerEmergencyMemoryCallbacks();
      } else if (usedMemoryMB > _criticalThreshold) {
        debugPrint('🚨 CRITICAL memory usage: ${usedMemoryMB.toStringAsFixed(1)} MB - monitoring closely');
        // Only trigger critical callbacks, don't clear caches aggressively
        _triggerCriticalMemoryCallbacks();
      } else if (usedMemoryMB > _warningThreshold) {
        debugPrint('⚠️ High memory usage: ${usedMemoryMB.toStringAsFixed(1)} MB - normal operation');
        // Just log warning, don't trigger cleanup for normal high usage
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

  /// Force garbage collection and cleanup - CONSERVATIVE approach
  void forceCleanup() {
    debugPrint('🧹 Conservative memory cleanup - preserving user experience...');

    // Only perform minimal cleanup to avoid blank screens
    try {
      // Use gentle cleanup instead of aggressive clearing
      ImageCacheManager().performCleanup();
      debugPrint('🧹 Conservative image cache cleanup completed');
    } catch (e) {
      debugPrint('Error during conservative image cache cleanup: $e');
      // Don't fallback to aggressive clearing - preserve user experience
    }

    // Only trigger memory pressure callbacks in true emergency
    debugPrint('🧹 Conservative memory cleanup completed - user experience preserved');
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
