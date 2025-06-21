import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Global image cache manager to prevent memory leaks
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  Timer? _cleanupTimer;
  bool _isInitialized = false;

  // Mobile-optimized cache limits for memory efficiency
  static const int _maxCacheObjects = 25; // Further reduced for mobile
  static const int _maxCacheSize = 20 * 1024 * 1024; // 20MB max cache size

  /// Initialize the image cache manager
  void initialize() {
    if (_isInitialized) return;

    _configureImageCache();
    _startPeriodicCleanup();
    _isInitialized = true;

    debugPrint('🖼️ Image cache manager initialized with aggressive limits');
  }

  /// Configure Flutter's image cache with memory-efficient settings
  void _configureImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Set aggressive cache limits
    imageCache.maximumSize = _maxCacheObjects;
    imageCache.maximumSizeBytes = _maxCacheSize;
    
    debugPrint('🖼️ Image cache configured: $_maxCacheObjects objects, ${_maxCacheSize ~/ (1024 * 1024)}MB');
  }

  /// Start periodic cache cleanup
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 10), // Clean every 10 minutes to reduce overhead
      (_) => performCleanup(),
    );
  }

  /// Perform image cache cleanup
  void performCleanup() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final beforeCount = imageCache.currentSize;
      final beforeSize = imageCache.currentSizeBytes;

      // Clear cache if it's getting too large
      if (imageCache.currentSizeBytes > _maxCacheSize * 0.8) {
        imageCache.clear();
        debugPrint('🧹 Image cache cleared due to size limit');

        // Also try to clear network cache if it's getting large
        try {
          DefaultCacheManager().emptyCache();
          debugPrint('🧹 Network cache also cleared');
        } catch (e) {
          debugPrint('⚠️ Could not clear network cache: $e');
        }
      } else {
        // Evict least recently used images
        imageCache.clearLiveImages();
        debugPrint('🧹 Image cache live images cleared');
      }

      final afterCount = imageCache.currentSize;
      final afterSize = imageCache.currentSizeBytes;

      debugPrint('🖼️ Image cache cleanup: $beforeCount→$afterCount objects, ${beforeSize ~/ (1024 * 1024)}→${afterSize ~/ (1024 * 1024)}MB');
    } catch (e) {
      debugPrint('❌ Error during image cache cleanup: $e');
    }
  }

  /// Force immediate cache cleanup
  void forceCleanup() {
    try {
      // Clear Flutter's image cache
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clear();
      debugPrint('🧹 Flutter image cache cleared');

      // Clear cached network image cache
      try {
        DefaultCacheManager().emptyCache();
        debugPrint('🧹 Network image cache cleared');
      } catch (cacheError) {
        debugPrint('⚠️ Could not clear network cache: $cacheError');
        // This is not critical, continue
      }

      debugPrint('🧹 Forced image cache cleanup completed');
    } catch (e) {
      debugPrint('❌ Error during forced image cache cleanup: $e');
      // If everything fails, try basic cleanup
      try {
        PaintingBinding.instance.imageCache.clear();
        debugPrint('🧹 Fallback: Basic Flutter image cache cleared');
      } catch (e2) {
        debugPrint('❌ Critical error: Cannot clear any image cache: $e2');
      }
    }
  }

  /// Get current cache statistics
  Map<String, dynamic> getCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    return {
      'currentSize': imageCache.currentSize,
      'maximumSize': imageCache.maximumSize,
      'currentSizeBytes': imageCache.currentSizeBytes,
      'maximumSizeBytes': imageCache.maximumSizeBytes,
      'currentSizeMB': imageCache.currentSizeBytes / (1024 * 1024),
      'maximumSizeMB': imageCache.maximumSizeBytes / (1024 * 1024),
    };
  }

  /// Check if cache is near limits
  bool isNearLimit() {
    final imageCache = PaintingBinding.instance.imageCache;
    final sizeRatio = imageCache.currentSizeBytes / imageCache.maximumSizeBytes;
    final countRatio = imageCache.currentSize / imageCache.maximumSize;
    
    return sizeRatio > 0.8 || countRatio > 0.8;
  }

  /// Dispose the manager
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _isInitialized = false;
    debugPrint('🖼️ Image cache manager disposed');
  }
}
