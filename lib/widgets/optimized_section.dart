import 'package:flutter/material.dart';

/// A widget that optimizes rendering of sections in the app by only rebuilding
/// when its data changes, not when the parent rebuilds.
class OptimizedSection extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback? onSeeMorePressed;

  const OptimizedSection({
    super.key,
    required this.title,
    required this.content,
    this.onSeeMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        content,
      ],
    );
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
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onSeeMorePressed != null)
            TextButton(
              onPressed: onSeeMorePressed,
              child: const Text(
                'See more',
                style: TextStyle(
                  color: Color(0xFFFFC701),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
