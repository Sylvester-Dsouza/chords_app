import 'package:flutter/material.dart';
import '../config/theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? iconColor;

  const AppLogo({
    super.key,
    this.size = 80.0,
    this.color,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme colors if not provided
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    final themeIconColor = iconColor ?? Theme.of(context).colorScheme.onPrimary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: themeColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.background.withAlpha(51),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: size * 0.6,
          color: themeIconColor,
        ),
      ),
    );
  }
}
