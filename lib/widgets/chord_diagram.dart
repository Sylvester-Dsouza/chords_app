import 'package:flutter/material.dart';
import '../config/theme.dart';

class ChordDiagram extends StatelessWidget {
  final String chordName;

  const ChordDiagram({
    super.key,
    required this.chordName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(70),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Guitar chord diagram (simplified)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 1, height: 8, color: Colors.grey.withAlpha(150)),
                  Container(width: 1, height: 8, color: Colors.grey.withAlpha(150)),
                  Container(width: 1, height: 8, color: Colors.grey.withAlpha(150)),
                  Container(width: 1, height: 8, color: Colors.grey.withAlpha(150)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 1, height: 1, color: Colors.transparent),
                  Container(width: 1, height: 1, color: Colors.transparent),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 1, height: 8, color: Colors.grey.withAlpha(150)),
                  Container(width: 1, height: 8, color: Colors.grey.withAlpha(150)),
                  Container(width: 1, height: 8, color: Colors.grey.withAlpha(150)),
                  Container(width: 1, height: 8, color: Colors.grey.withAlpha(150)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(width: 1, height: 1, color: Colors.transparent),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 1, height: 1, color: Colors.transparent),
                  Container(width: 1, height: 1, color: Colors.transparent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          chordName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
