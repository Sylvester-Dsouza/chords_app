import 'package:flutter/material.dart';
import '../../widgets/inner_screen_app_bar.dart';

class ChordLibraryScreen extends StatefulWidget {
  const ChordLibraryScreen({super.key});

  @override
  State<ChordLibraryScreen> createState() => _ChordLibraryScreenState();
}

class _ChordLibraryScreenState extends State<ChordLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedChordType = 'Major';
  String _selectedKey = 'C';
  
  final List<String> _instruments = ['Guitar', 'Ukulele', 'Piano'];
  final List<String> _chordTypes = ['Major', 'Minor', '7th', 'm7', 'maj7', 'sus2', 'sus4', 'dim', 'aug'];
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
        title: 'Chord Library',
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
          
          // Chord selector
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
                
                // Chord type selector
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
                          value: _selectedChordType,
                          onChanged: (value) {
                            setState(() {
                              _selectedChordType = value!;
                            });
                          },
                          items: _chordTypes.map((type) {
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
          
          // Chord display
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Guitar tab
                _buildGuitarChordView(),
                
                // Ukulele tab
                _buildUkuleleChordView(),
                
                // Piano tab
                _buildPianoChordView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGuitarChordView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chord name
          Text(
            '$_selectedKey $_selectedChordType',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Guitar fretboard
          Container(
            width: 280,
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: const Color(0xFF333333),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Simplified guitar chord diagram
                CustomPaint(
                  size: const Size(240, 280),
                  painter: GuitarChordPainter(
                    key: _selectedKey,
                    chordType: _selectedChordType,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Chord variations
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildVariationButton('1', true),
              _buildVariationButton('2', false),
              _buildVariationButton('3', false),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildUkuleleChordView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chord name
          Text(
            '$_selectedKey $_selectedChordType',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Ukulele fretboard
          Container(
            width: 240,
            height: 280,
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
                'Ukulele Chord Diagram',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPianoChordView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chord name
          Text(
            '$_selectedKey $_selectedChordType',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Piano keyboard
          Container(
            width: 300,
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
                'Piano Chord Diagram',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVariationButton(String variation, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          // Would update the selected variation
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
              variation,
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
}

class GuitarChordPainter extends CustomPainter {
  final String key;
  final String chordType;
  
  GuitarChordPainter({required this.key, required this.chordType});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final dotPaint = Paint()
      ..color = const Color(0xFFFFC701)
      ..style = PaintingStyle.fill;
    
    final textPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final width = size.width;
    final height = size.height;
    
    final fretWidth = width;
    final fretHeight = height / 5;
    
    // Draw frets
    for (int i = 0; i <= 5; i++) {
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
    
    // Draw finger positions (simplified example for C major)
    if (key == 'C' && chordType == 'Major') {
      // 1st string, 0 fret (open)
      // 2nd string, 1st fret
      canvas.drawCircle(
        Offset(stringSpacing, fretHeight / 2),
        fretHeight / 3,
        dotPaint,
      );
      
      // 3rd string, 0 fret (open)
      // 4th string, 2nd fret
      canvas.drawCircle(
        Offset(3 * stringSpacing, 1.5 * fretHeight),
        fretHeight / 3,
        dotPaint,
      );
      
      // 5th string, 3rd fret
      canvas.drawCircle(
        Offset(4 * stringSpacing, 2.5 * fretHeight),
        fretHeight / 3,
        dotPaint,
      );
      
      // 6th string, x (not played)
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: fretHeight / 2,
        fontWeight: FontWeight.bold,
      );
      
      final textSpan = TextSpan(
        text: 'X',
        style: textStyle,
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(5 * stringSpacing - textPainter.width / 2, -fretHeight / 2),
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
