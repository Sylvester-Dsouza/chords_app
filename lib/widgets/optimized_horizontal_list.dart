import 'package:flutter/material.dart';

/// A widget that optimizes rendering of horizontal lists by using const constructors
/// and minimizing rebuilds.
class OptimizedHorizontalList extends StatelessWidget {
  final List<Widget> children;
  final double height;
  final EdgeInsetsGeometry padding;

  const OptimizedHorizontalList({
    super.key,
    required this.children,
    this.height = 220,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        // Use builder pattern for better performance with large lists
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}
