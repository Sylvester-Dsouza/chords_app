import 'package:flutter/material.dart';
import '../../widgets/inner_screen_app_bar.dart';

class ScaleExplorerScreen extends StatefulWidget {
  const ScaleExplorerScreen({super.key});

  @override
  State<ScaleExplorerScreen> createState() => _ScaleExplorerScreenState();
}

class _ScaleExplorerScreenState extends State<ScaleExplorerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedScaleType = 'Major';
  String _selectedKey = 'C';
  
  final List<String> _instruments = ['Guitar', 'Piano'];
  final List<String> _scaleTypes = ['Major', 'Minor', 'Pentatonic Major', 'Pentatonic Minor', 'Blues', 'Dorian', 'Phrygian', 'Lydian', 'Mixolydian', 'Locrian'];
  final List<String> _keys = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _instruments.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: const InnerScreenAppBar(
        title: 'Scale Explorer',
      ),
      body: Column(
        children: [
          // Instrument tabs
          Container(
            color: const Color(0xFF1E1E1E),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFFFC701),
              labelColor: const Color(0xFFFFC701),
              unselectedLabelColor: Colors.white,
              tabs: _instruments.map((instrument) => Tab(text: instrument)).toList(),
            ),
          ),
          
          // Scale selector
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Key selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Key',
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
                          value: _selectedKey,
                          onChanged: (value) {
                            setState(() {
                              _selectedKey = value!;
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
                
                // Scale type selector
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type',
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
                          value: _selectedScaleType,
                          onChanged: (value) {
                            setState(() {
                              _selectedScaleType = value!;
                            });
                          },
                          items: _scaleTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
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
              ],
            ),
          ),
          
          // Scale display
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Guitar tab
                _buildGuitarScaleView(),
                
                // Piano tab
                _buildPianoScaleView(),
              ],
            ),
          ),
          
          // Scale notes
          Container(
            padding: const EdgeInsets.all(16.0),
            color: const Color(0xFF1E1E1E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scale Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getScaleNotes(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGuitarScaleView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scale name
          Text(
            '$_selectedKey $_selectedScaleType Scale',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Guitar fretboard
          Container(
            width: 320,
            height: 240,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1.0,
              ),
            ),
            child: CustomPaint(
              size: const Size(320, 240),
              painter: GuitarScalePainter(
                key: _selectedKey,
                scaleType: _selectedScaleType,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Position selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Position:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              _buildPositionButton('1', true),
              _buildPositionButton('2', false),
              _buildPositionButton('3', false),
              _buildPositionButton('4', false),
              _buildPositionButton('5', false),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPianoScaleView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Scale name
          Text(
            '$_selectedKey $_selectedScaleType Scale',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Piano keyboard
          Container(
            width: 320,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1.0,
              ),
            ),
            child: const Center(
              child: Text(
                'Piano Scale Diagram',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Octave selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Octave:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              _buildPositionButton('1', false),
              _buildPositionButton('2', true),
              _buildPositionButton('3', false),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPositionButton(String position, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: InkWell(
        onTap: () {
          // Would update the selected position
        },
        borderRadius: BorderRadius.circular(4.0),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFC701) : const Color(0xFF333333),
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: Center(
            child: Text(
              position,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  String _getScaleNotes() {
    // Simplified example for C Major scale
    if (_selectedKey == 'C' && _selectedScaleType == 'Major') {
      return 'C - D - E - F - G - A - B - C';
    } else if (_selectedKey == 'C' && _selectedScaleType == 'Minor') {
      return 'C - D - Eb - F - G - Ab - Bb - C';
    } else if (_selectedKey == 'C' && _selectedScaleType == 'Pentatonic Major') {
      return 'C - D - E - G - A - C';
    } else if (_selectedKey == 'C' && _selectedScaleType == 'Pentatonic Minor') {
      return 'C - Eb - F - G - Bb - C';
    } else if (_selectedKey == 'C' && _selectedScaleType == 'Blues') {
      return 'C - Eb - F - F# - G - Bb - C';
    }
    
    // Default placeholder
    return '$_selectedKey $_selectedScaleType scale notes';
  }
}

class GuitarScalePainter extends CustomPainter {
  final String key;
  final String scaleType;
  
  GuitarScalePainter({required this.key, required this.scaleType});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final dotPaint = Paint()
      ..color = const Color(0xFFFFC701)
      ..style = PaintingStyle.fill;
    
    final rootDotPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    final width = size.width;
    final height = size.height;
    
    final fretWidth = width;
    final fretHeight = height / 6;
    
    // Draw frets
    for (int i = 0; i <= 12; i++) {
      canvas.drawLine(
        Offset(0, i * fretHeight),
        Offset(width, i * fretHeight),
        paint,
      );
    }
    
    // Draw strings
    final stringSpacing = width / 6;
    for (int i = 0; i <= 5; i++) {
      canvas.drawLine(
        Offset(i * stringSpacing, 0),
        Offset(i * stringSpacing, height),
        paint,
      );
    }
    
    // Draw fret markers
    final markerPositions = [3, 5, 7, 9, 12];
    for (final position in markerPositions) {
      if (position == 12) {
        // Double dot at 12th fret
        canvas.drawCircle(
          Offset(width / 3, position * fretHeight - fretHeight / 2),
          fretHeight / 8,
          paint,
        );
        canvas.drawCircle(
          Offset(2 * width / 3, position * fretHeight - fretHeight / 2),
          fretHeight / 8,
          paint,
        );
      } else {
        // Single dot
        canvas.drawCircle(
          Offset(width / 2, position * fretHeight - fretHeight / 2),
          fretHeight / 8,
          paint,
        );
      }
    }
    
    // Draw scale notes (simplified example for C Major scale, first position)
    if (key == 'C' && scaleType == 'Major') {
      // Root notes (C)
      canvas.drawCircle(
        Offset(5 * stringSpacing, 3 * fretHeight - fretHeight / 2),
        fretHeight / 3,
        rootDotPaint,
      );
      canvas.drawCircle(
        Offset(2 * stringSpacing, 5 * fretHeight - fretHeight / 2),
        fretHeight / 3,
        rootDotPaint,
      );
      
      // Other scale notes
      final notePositions = [
        [3, 2], // D on 3rd string, 2nd fret
        [3, 4], // E on 3rd string, 4th fret
        [4, 2], // F on 4th string, 2nd fret
        [4, 4], // G on 4th string, 4th fret
        [5, 2], // A on 5th string, 2nd fret
        [5, 4], // B on 5th string, 4th fret
      ];
      
      for (final position in notePositions) {
        canvas.drawCircle(
          Offset(position[0] * stringSpacing, position[1] * fretHeight - fretHeight / 2),
          fretHeight / 3,
          dotPaint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
