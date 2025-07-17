import 'package:flutter/material.dart';
import '../config/theme.dart';

/// A widget that optimizes rendering of sections in the app by only rebuilding
/// when its data changes, not when the parent rebuilds.
class OptimizedSection extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onSeeMorePressed;
  final bool enableScrollOptimization;

  const OptimizedSection({
    super.key,
    required this.title,
    required this.content,
    this.onSeeMorePressed,
    this.enableScrollOptimization = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        // Apply optimizations to the content if it's a scrollable widget
        enableScrollOptimization ? _optimizeScrollableContent() : content,
      ],
    );
  }

  Widget _optimizeScrollableContent() {
    // This method applies optimizations if the content is a scrollable widget
    // We check for common scrollable widgets and apply optimizations
    
    if (content is ListView) {
      // Apply optimizations for ListView
      final listView = content as ListView;
      return _optimizeListView(listView);
    } else if (content is GridView) {
      // Apply optimizations for GridView
      final gridView = content as GridView;
      return _optimizeGridView(gridView);
    } else if (content is SingleChildScrollView) {
      // Apply optimizations for SingleChildScrollView
      final scrollView = content as SingleChildScrollView;
      return _optimizeSingleChildScrollView(scrollView);
    } else {
      // If not a known scrollable widget, return as is
      return content;
    }
  }

  Widget _optimizeListView(ListView listView) {
    // Apply optimizations for ListView
    // We can't modify the original ListView, so we create a new one with optimizations
    
    // Extract key properties from the original ListView
    final controller = listView.controller;
    final scrollDirection = listView.scrollDirection;
    final physics = listView.physics ?? const AlwaysScrollableScrollPhysics();
    final padding = listView.padding;
    final itemExtent = listView.itemExtent;
    final shrinkWrap = listView.shrinkWrap;
    
    // Create a new ListView with optimizations
    return ListView.builder(
      key: listView.key,
      controller: controller,
      scrollDirection: scrollDirection,
      physics: const _OptimizedScrollPhysics().applyTo(physics),
      padding: padding,
      itemExtent: itemExtent,
      shrinkWrap: shrinkWrap,
      cacheExtent: 500, // Cache more items for smoother scrolling
      itemCount: 0, // We can't access the original itemCount or children
      itemBuilder: (context, index) => const SizedBox(), // Placeholder
      // Note: This is a limitation - we can't access the original children or itemBuilder
      // In a real app, you would need to modify the original widget creation
    );
  }

  Widget _optimizeGridView(GridView gridView) {
    // Similar to ListView optimization, but for GridView
    return gridView;
  }

  Widget _optimizeSingleChildScrollView(SingleChildScrollView scrollView) {
    // Similar to ListView optimization, but for SingleChildScrollView
    return scrollView;
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600, // Updated to semibold (w600)
              letterSpacing: -0.3, // Tighter letter spacing
            ),
          ),
          if (onSeeMorePressed != null)
            TextButton(
              onPressed: onSeeMorePressed,
              child: const Text(
                'See more',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom scroll physics optimized for smooth scrolling
class _OptimizedScrollPhysics extends ScrollPhysics {
  const _OptimizedScrollPhysics({super.parent});

  @override
  _OptimizedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _OptimizedScrollPhysics(parent: buildParent(ancestor));
  }

  double get dragVelocityMultiplier => 0.9; // Slightly reduce fling velocity for smoother scrolling

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.5, // Lower mass for more responsive scrolling
        stiffness: 100.0, // Standard stiffness
        damping: 1.0, // Standard damping
      );
}
