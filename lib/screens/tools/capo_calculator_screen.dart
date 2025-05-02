import 'package:flutter/material.dart';
import '../../widgets/inner_screen_app_bar.dart';

class CapoCalculatorScreen extends StatefulWidget {
  const CapoCalculatorScreen({super.key});

  @override
  State<CapoCalculatorScreen> createState() => _CapoCalculatorScreenState();
}

class _CapoCalculatorScreenState extends State<CapoCalculatorScreen> {
  int _capoPosition = 0;
  String _originalKey = 'C';
  String _resultKey = 'C';
  
  final List<String> _keys = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final List<String> _chordProgressions = [
    'C - G - Am - F',
    'G - D - Em - C',
    'D - A - Bm - G',
    'A - E - F#m - D',
  ];
  
  final Map<String, List<String>> _commonChords = {
    'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
    'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim'],
    'D': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim'],
    'A': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim'],
    'E': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim'],
  };

  @override
  void initState() {
    super.initState();
    _updateResultKey();
  }
  
  void _updateResultKey() {
    final originalKeyIndex = _keys.indexOf(_originalKey);
    final resultKeyIndex = (originalKeyIndex - _capoPosition) % 12;
    setState(() {
      _resultKey = _keys[resultKeyIndex < 0 ? resultKeyIndex + 12 : resultKeyIndex];
    });
  }
  
  String _transposeChord(String chord) {
    // Basic chord transposition logic
    final rootNote = chord.replaceAll(RegExp(r'[^A-G#b]'), '');
    final suffix = chord.replaceAll(RegExp(r'[A-G#b]'), '');
    
    final rootIndex = _keys.indexOf(rootNote);
    if (rootIndex == -1) return chord; // Not a valid chord
    
    final newRootIndex = (rootIndex - _capoPosition) % 12;
    final newRoot = _keys[newRootIndex < 0 ? newRootIndex + 12 : newRootIndex];
    
    return newRoot + suffix;
  }
  
  String _transposeProgression(String progression) {
    final chords = progression.split(' - ');
    final transposedChords = chords.map((chord) => _transposeChord(chord)).toList();
    return transposedChords.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Capo Calculator',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Capo visualization
            Container(
              margin: const EdgeInsets.all(24.0),
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Stack(
                children: [
                  // Guitar neck
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GuitarNeckPainter(capoPosition: _capoPosition),
                    ),
                  ),
                  
                  // Capo position indicator
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Capo on fret $_capoPosition',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Capo position slider
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Capo Position',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Fret $_capoPosition',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _capoPosition.toDouble(),
                    min: 0,
                    max: 12,
                    divisions: 12,
                    activeColor: const Color(0xFFFFC701),
                    inactiveColor: const Color(0xFF333333),
                    onChanged: (value) {
                      setState(() {
                        _capoPosition = value.round();
                        _updateResultKey();
                      });
                    },
                  ),
                ],
              ),
            ),
            
            // Key selector
            Container(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Original Key',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF333333),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButton<String>(
                            value: _originalKey,
                            onChanged: (value) {
                              setState(() {
                                _originalKey = value!;
                                _updateResultKey();
                              });
                            },
                            items: _keys.map((key) {
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Text(key),
                              );
                            }).toList(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            dropdownColor: const Color(0xFF333333),
                            underline: Container(),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                            isExpanded: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Key (with capo)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color(0xFFFFC701),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _resultKey,
                              style: const TextStyle(
                                color: Color(0xFFFFC701),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Chord conversion
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chord Conversion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Play these chords with capo:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Only show if we have common chords for the selected key
                  if (_commonChords.containsKey(_originalKey))
                    Column(
                      children: _commonChords[_originalKey]!.map((chord) {
                        final transposedChord = _transposeChord(chord);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                chord,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.grey,
                                size: 16,
                              ),
                              Text(
                                transposedChord,
                                style: const TextStyle(
                                  color: Color(0xFFFFC701),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            
            // Common progressions
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Common Progressions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Column(
                    children: _chordProgressions.map((progression) {
                      final transposedProgression = _transposeProgression(progression);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              progression,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              transposedProgression,
                              style: const TextStyle(
                                color: Color(0xFFFFC701),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(color: Color(0xFF333333)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class GuitarNeckPainter extends CustomPainter {
  final int capoPosition;
  
  GuitarNeckPainter({required this.capoPosition});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.brown.shade800
      ..style = PaintingStyle.fill;
    
    final fretPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final capoPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    final width = size.width;
    final height = size.height;
    
    // Draw neck
    canvas.drawRect(
      Rect.fromLTWH(0, height / 4, width, height / 2),
      paint,
    );
    
    // Draw frets
    final fretSpacing = width / 13;
    for (int i = 0; i <= 12; i++) {
      canvas.drawLine(
        Offset(i * fretSpacing, height / 4),
        Offset(i * fretSpacing, height * 3 / 4),
        fretPaint,
      );
    }
    
    // Draw capo
    if (capoPosition > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          (capoPosition - 0.5) * fretSpacing,
          height / 4 - 10,
          fretSpacing,
          height / 2 + 20,
        ),
        capoPaint,
      );
    }
    
    // Draw fret markers
    final markerPositions = [3, 5, 7, 9, 12];
    for (final position in markerPositions) {
      if (position == 12) {
        // Double dot at 12th fret
        canvas.drawCircle(
          Offset(position * fretSpacing - fretSpacing / 2, height / 4 - 20),
          5,
          fretPaint,
        );
        canvas.drawCircle(
          Offset(position * fretSpacing - fretSpacing / 2, height * 3 / 4 + 20),
          5,
          fretPaint,
        );
      } else {
        // Single dot
        canvas.drawCircle(
          Offset(position * fretSpacing - fretSpacing / 2, height / 2),
          5,
          fretPaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
