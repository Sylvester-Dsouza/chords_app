import 'package:flutter/material.dart';

class SongPlaceholder extends StatelessWidget {
  final double size;

  const SongPlaceholder({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(50),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(
        child: Icon(
          Icons.music_note,
          color: primaryColor,
        ),
      ),
    );
  }
}
