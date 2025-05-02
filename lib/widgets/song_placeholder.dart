import 'package:flutter/material.dart';

class SongPlaceholder extends StatelessWidget {
  final double size;

  const SongPlaceholder({
    super.key,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC701).withAlpha(50),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note,
          color: Color(0xFFFFC701),
        ),
      ),
    );
  }
}
