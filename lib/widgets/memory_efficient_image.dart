import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A memory-efficient image widget that properly handles loading, errors,
/// and memory management to prevent memory leaks.
class MemoryEfficientImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color backgroundColor;
  final bool useHero;
  final String? heroTag;

  const MemoryEfficientImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor = const Color(0xFF1E1E1E),
    this.useHero = false,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // If no image URL, show placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildContainer(
        child: _defaultErrorWidget,
      );
    }

    // Build the image widget
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder,
      errorWidget: (context, url, error) {
        // Log the error but don't throw exceptions
        debugPrint('Error loading image: $url - $error');

        // Handle different types of errors gracefully
        if (error.toString().contains('400') ||
            error.toString().contains('404') ||
            error.toString().contains('HttpException')) {
          debugPrint('HTTP error for image: $url, using fallback');
        }

        return errorWidget ?? _defaultErrorWidget;
      },
      // Enhanced memory management for persistent caching
      memCacheWidth: _calculateMemCacheSize(width),
      memCacheHeight: _calculateMemCacheSize(height),
      maxWidthDiskCache: _calculateDiskCacheSize(width), // Dynamic based on image size
      maxHeightDiskCache: _calculateDiskCacheSize(height), // Dynamic based on image size
      // Enable persistent disk caching for better performance
      useOldImageOnUrlChange: true, // Prevent blank screens during loading
      // Add cache key for better memory management
      cacheKey: _generateCacheKey(imageUrl!, width, height),
    );

    // Apply border radius if needed
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    // Apply hero animation if needed
    if (useHero && heroTag != null) {
      imageWidget = Hero(
        tag: heroTag!,
        child: imageWidget,
      );
    }

    return _buildContainer(child: imageWidget);
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: child,
    );
  }

  Widget get _defaultPlaceholder => Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    ),
  );

  Widget get _defaultErrorWidget => Center(
    child: Icon(
      Icons.image_not_supported,
      color: Colors.grey[600],
      size: 24,
    ),
  );

  // Calculate appropriate memory cache size based on device pixel ratio
  int? _calculateMemCacheSize(double? size) {
    if (size == null) return null;

    // Handle infinity values
    if (size.isInfinite || size.isNaN) {
      return 200; // Default size for memory efficiency
    }

    // Get device pixel ratio (default to 2.0 if not available)
    final pixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    // Calculate size based on pixel ratio, with higher maximum for persistent caching
    return (size * pixelRatio).round().clamp(0, 1000); // Increased to 1000 for better image quality
  }

  // Calculate appropriate disk cache size for better image quality
  int? _calculateDiskCacheSize(double? size) {
    if (size == null) return null;

    // Handle infinity values
    if (size.isInfinite || size.isNaN) {
      return 400; // Default size for disk cache
    }

    // Enhanced disk cache sizes for persistent storage and better quality
    if (size >= 250) {
      return 1200; // Very high quality for collection images
    } else if (size >= 150) {
      return 800; // High quality for medium images
    } else {
      return 600; // Good quality for smaller images
    }
  }

  // Generate cache key for better memory management
  String _generateCacheKey(String url, double? width, double? height) {
    final w = width?.round() ?? 0;
    final h = height?.round() ?? 0;
    return '${url}_${w}x$h';
  }
}
