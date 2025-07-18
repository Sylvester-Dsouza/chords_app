import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';


/// Global image cache manager to prevent memory leaks
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  Timer? _cleanupTimer;
  bool _isInitialized = false;

  // Optimized cache limits for modern devices with persistent caching
  static const int _maxCacheObjects = 200; // Increased for better user experience
  static const int _maxCacheSize = 100 * 1024 * 1024; // 100MB max cache size for persistent image storage

  /// Initialize the image cache manager
  void initialize() {
    if (_isInitialized) return;

    _configureImageCache();
    _startPeriodicCleanup();
    _isInitialized = true;

    debugPrint('🖼️ Image cache manager initialized with persistent caching limits');
  }

  /// Configure Flutter's image cache with memory-efficient settings
  void _configureImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    // Set aggressive cache limits
    imageCache.maximumSize = _maxCacheObjects;
    imageCache.maximumSizeBytes = _maxCacheSize;
    
    debugPrint('🖼️ Image cache configured for persistent storage: $_maxCacheObjects objects, ${_maxCacheSize ~/ (1024 * 1024)}MB');
  }

  /// Start periodic cache cleanup - CONSERVATIVE approach
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 30), // Clean every 30 minutes to preserve cache and reduce overhead
      (_) => performCleanup(),
    );
  }

  /// Perform CONSERVATIVE image cache cleanup - preserve user experience
  void performCleanup() {
    try {
      final imageCache = PaintingBinding.instance.imageCache;
      final beforeCount = imageCache.currentSize;
      final beforeSize = imageCache.currentSizeBytes;

      // Only clear cache if it's REALLY getting too large (90% of limit)
      if (imageCache.currentSizeBytes > _maxCacheSize * 0.9) {
        // Only clear live images, not the entire cache to prevent blank screens
        imageCache.clearLiveImages();
        debugPrint('🧹 Conservative cleanup: cleared live images only to preserve cached images');
      } else {
        // Just log status, don't clear anything unless necessary
        debugPrint('🖼️ Image cache healthy: $beforeCount objects, ${beforeSize ~/ (1024 * 1024)}MB - no cleanup needed');
        return;
      }

      final afterCount = imageCache.currentSize;
      final afterSize = imageCache.currentSizeBytes;

      debugPrint('🖼️ Conservative image cache cleanup: $beforeCount→$afterCount objects, ${beforeSize ~/ (1024 * 1024)}→${afterSize ~/ (1024 * 1024)}MB');
    } catch (e) {
      debugPrint('❌ Error during conservative image cache cleanup: $e');
    }
  }

  /// Emergency cache cleanup - ONLY for true emergencies to prevent blank screens
  void forceCleanup() {
    try {
      debugPrint('🆘 EMERGENCY image cache cleanup - preserving user experience...');

      // Only clear live images, not the entire cache to prevent blank screens
      final imageCache = PaintingBinding.instance.imageCache;
      imageCache.clearLiveImages();
      debugPrint('🧹 Emergency: cleared live images only, preserved cached images');

      // Don't clear network cache aggressively - this causes blank screens
      debugPrint('🧹 Emergency cleanup completed - user experience preserved');
    } catch (e) {
      debugPrint('❌ Error during emergency cleanup: $e');
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
