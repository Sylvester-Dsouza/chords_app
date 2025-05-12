import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final Color? unratedColor;
  final bool showRating;
  final MainAxisAlignment alignment;
  final bool allowHalfRating;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 24.0,
    this.color,
    this.unratedColor,
    this.showRating = false,
    this.alignment = MainAxisAlignment.start,
    this.allowHalfRating = true,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? Theme.of(context).colorScheme.primary;
    final emptyColor = unratedColor ?? Colors.grey.shade400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            if (allowHalfRating) {
              // For half-star ratings
              if (index < rating.floor()) {
                // Full star
                return Icon(Icons.star, color: starColor, size: size);
              } else if (index == rating.floor() && rating % 1 > 0) {
                // Half star
                return Icon(Icons.star_half, color: starColor, size: size);
              } else {
                // Empty star
                return Icon(Icons.star_border, color: emptyColor, size: size);
              }
            } else {
              // For whole-star ratings only
              return Icon(
                index < rating.round() ? Icons.star : Icons.star_border,
                color: index < rating.round() ? starColor : emptyColor,
                size: size,
              );
            }
          }),
        ),
        if (showRating) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.75,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final int initialRating;
  final Function(int) onRatingChanged;
  final double size;
  final Color? color;
  final Color? unratedColor;
  final bool showLabel;
  final MainAxisAlignment alignment;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.size = 36.0,
    this.color,
    this.unratedColor,
    this.showLabel = true,
    this.alignment = MainAxisAlignment.center,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  void didUpdateWidget(InteractiveStarRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      setState(() {
        _currentRating = widget.initialRating;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final starColor = widget.color ?? Theme.of(context).colorScheme.primary;
    final emptyColor = widget.unratedColor ?? Colors.grey.shade400;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.alignment,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentRating = starValue;
                });
                widget.onRatingChanged(_currentRating);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  starValue <= _currentRating ? Icons.star : Icons.star_border,
                  color: starValue <= _currentRating ? starColor : emptyColor,
                  size: widget.size,
                ),
              ),
            );
          }),
        ),
        if (widget.showLabel && _currentRating > 0) ...[
          const SizedBox(height: 8),
          Text(
            _getRatingLabel(_currentRating),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
