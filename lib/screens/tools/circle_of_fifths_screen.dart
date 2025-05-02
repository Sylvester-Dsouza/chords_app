import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../widgets/inner_screen_app_bar.dart';

class CircleOfFifthsScreen extends StatefulWidget {
  const CircleOfFifthsScreen({super.key});

  @override
  State<CircleOfFifthsScreen> createState() => _CircleOfFifthsScreenState();
}

class _CircleOfFifthsScreenState extends State<CircleOfFifthsScreen> {
  String _selectedKey = 'C';
  bool _showRelativeMinor = true;
  bool _showChords = true;
  
  final List<String> _majorKeys = ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'Db', 'Ab', 'Eb', 'Bb', 'F'];
  final List<String> _minorKeys = ['Am', 'Em', 'Bm', 'F#m', 'C#m', 'G#m', 'D#m', 'Bbm', 'Fm', 'Cm', 'Gm', 'Dm'];
  
  final Map<String, List<String>> _keyChords = {
    'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
    'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim'],
    'D': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim'],
    'A': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim'],
    'E': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim'],
    'B': ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim'],
    'F#': ['F#', 'G#m', 'A#m', 'B', 'C#', 'D#m', 'E#dim'],
    'Db': ['Db', 'Ebm', 'Fm', 'Gb', 'Ab', 'Bbm', 'Cdim'],
    'Ab': ['Ab', 'Bbm', 'Cm', 'Db', 'Eb', 'Fm', 'Gdim'],
    'Eb': ['Eb', 'Fm', 'Gm', 'Ab', 'Bb', 'Cm', 'Ddim'],
    'Bb': ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim'],
    'F': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Circle of Fifths',
      ),
      body: Column(
        children: [
          // Circle of Fifths visualization
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(24.0),
              child: CustomPaint(
                painter: CircleOfFifthsPainter(
                  selectedKey: _selectedKey,
                  showRelativeMinor: _showRelativeMinor,
                ),
                child: Container(),
              ),
            ),
          ),
          
          // Display options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToggleOption(
                  'Show Relative Minor',
                  _showRelativeMinor,
                  (value) {
                    setState(() {
                      _showRelativeMinor = value;
                    });
                  },
                ),
                _buildToggleOption(
                  'Show Chords',
                  _showChords,
                  (value) {
                    setState(() {
                      _showChords = value;
                    });
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Key information
          if (_showChords && _keyChords.containsKey(_selectedKey))
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
                  Text(
                    '$_selectedKey Major Key',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Diatonic Chords:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: _keyChords[_selectedKey]!.map((chord) {
                      final isRoot = chord == _selectedKey;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: isRoot ? const Color(0xFFFFC701).withOpacity(0.2) : const Color(0xFF333333),
                          borderRadius: BorderRadius.circular(4.0),
                          border: isRoot
                              ? Border.all(color: const Color(0xFFFFC701), width: 1.0)
                              : null,
                        ),
                        child: Text(
                          chord,
                          style: TextStyle(
                            color: isRoot ? const Color(0xFFFFC701) : Colors.white,
                            fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Common Progressions:',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildProgressionItem('I - IV - V', '${_keyChords[_selectedKey]![0]} - ${_keyChords[_selectedKey]![3]} - ${_keyChords[_selectedKey]![4]}'),
                  _buildProgressionItem('I - V - vi - IV', '${_keyChords[_selectedKey]![0]} - ${_keyChords[_selectedKey]![4]} - ${_keyChords[_selectedKey]![5]} - ${_keyChords[_selectedKey]![3]}'),
                  _buildProgressionItem('ii - V - I', '${_keyChords[_selectedKey]![1]} - ${_keyChords[_selectedKey]![4]} - ${_keyChords[_selectedKey]![0]}'),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildToggleOption(String label, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFFFC701),
        ),
      ],
    );
  }
  
  Widget _buildProgressionItem(String name, String chords) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 80,
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              chords,
              style: const TextStyle(
                color: Color(0xFFFFC701),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircleOfFifthsPainter extends CustomPainter {
  final String selectedKey;
  final bool showRelativeMinor;
  
  CircleOfFifthsPainter({
    required this.selectedKey,
    required this.showRelativeMinor,
  });
  
  final List<String> _majorKeys = ['C', 'G', 'D', 'A', 'E', 'B', 'F#', 'Db', 'Ab', 'Eb', 'Bb', 'F'];
  final List<String> _minorKeys = ['Am', 'Em', 'Bm', 'F#m', 'C#m', 'G#m', 'D#m', 'Bbm', 'Fm', 'Cm', 'Gm', 'Dm'];
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    
    final outerCirclePaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.fill;
    
    final innerCirclePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    
    final selectedSegmentPaint = Paint()
      ..color = const Color(0xFFFFC701).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw outer circle
    canvas.drawCircle(center, radius, outerCirclePaint);
    
    // Draw inner circle
    canvas.drawCircle(center, radius * 0.7, innerCirclePaint);
    
    // Draw segments
    final segmentAngle = 2 * math.pi / 12;
    
    for (int i = 0; i < 12; i++) {
      final startAngle = -math.pi / 2 + i * segmentAngle;
      final endAngle = startAngle + segmentAngle;
      
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        )
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle,
          false,
        )
        ..lineTo(center.dx, center.dy);
      
      // Highlight selected key segment
      if (_majorKeys[i] == selectedKey) {
        canvas.drawPath(path, selectedSegmentPaint);
      }
      
      // Draw segment divider lines
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(startAngle),
          center.dy + radius * math.sin(startAngle),
        ),
        linePaint,
      );
    }
    
    // Draw key labels
    final majorTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    
    final selectedMajorTextStyle = TextStyle(
      color: const Color(0xFFFFC701),
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    
    final minorTextStyle = TextStyle(
      color: Colors.grey,
      fontSize: 14,
    );
    
    final selectedMinorTextStyle = TextStyle(
      color: const Color(0xFFFFC701).withOpacity(0.7),
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
    
    for (int i = 0; i < 12; i++) {
      final angle = -math.pi / 2 + i * segmentAngle;
      
      // Major key position
      final majorKeyPos = Offset(
        center.dx + radius * 0.85 * math.cos(angle),
        center.dy + radius * 0.85 * math.sin(angle),
      );
      
      // Draw major key
      final majorTextSpan = TextSpan(
        text: _majorKeys[i],
        style: _majorKeys[i] == selectedKey ? selectedMajorTextStyle : majorTextStyle,
      );
      
      final majorTextPainter = TextPainter(
        text: majorTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      majorTextPainter.layout();
      majorTextPainter.paint(
        canvas,
        Offset(
          majorKeyPos.dx - majorTextPainter.width / 2,
          majorKeyPos.dy - majorTextPainter.height / 2,
        ),
      );
      
      // Draw relative minor key if enabled
      if (showRelativeMinor) {
        final minorKeyPos = Offset(
          center.dx + radius * 0.55 * math.cos(angle),
          center.dy + radius * 0.55 * math.sin(angle),
        );
        
        final minorTextSpan = TextSpan(
          text: _minorKeys[i],
          style: _majorKeys[i] == selectedKey ? selectedMinorTextStyle : minorTextStyle,
        );
        
        final minorTextPainter = TextPainter(
          text: minorTextSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        
        minorTextPainter.layout();
        minorTextPainter.paint(
          canvas,
          Offset(
            minorKeyPos.dx - minorTextPainter.width / 2,
            minorKeyPos.dy - minorTextPainter.height / 2,
          ),
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
