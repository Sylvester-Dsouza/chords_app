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
        debugPrint('Error loading image: $url - $error');
        return errorWidget ?? _defaultErrorWidget;
      },
      // Memory management options
      memCacheWidth: _calculateMemCacheSize(width),
      memCacheHeight: _calculateMemCacheSize(height),
      maxWidthDiskCache: 800, // Limit disk cache size
      maxHeightDiskCache: 800, // Limit disk cache size
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
        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
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
    
    // Get device pixel ratio (default to 2.0 if not available)
    final pixelRatio = WidgetsBinding.instance.window.devicePixelRatio;
    
    // Calculate size based on pixel ratio, with a maximum of 1000 pixels
    return (size * pixelRatio).round().clamp(0, 1000);
  }
}
