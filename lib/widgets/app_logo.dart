import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color color;
  final Color iconColor;

  const AppLogo({
    super.key,
    this.size = 80.0,
    this.color = const Color(0xFFFFC701), // Yellow accent color
    this.iconColor = const Color(0xFF121212), // Dark background
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51), // 0.2 opacity = 51/255
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          size: size * 0.6,
          color: iconColor,
        ),
      ),
    );
  }
}
