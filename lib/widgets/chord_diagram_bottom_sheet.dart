import 'package:flutter/material.dart';
import 'package:flutter_guitar_chord/flutter_guitar_chord.dart';
import 'package:guitar_chord_library/guitar_chord_library.dart';

class ChordDiagramBottomSheet extends StatefulWidget {
  final String chordName;

  const ChordDiagramBottomSheet({
    super.key,
    required this.chordName,
  });

  @override
  State<ChordDiagramBottomSheet> createState() => _ChordDiagramBottomSheetState();
}

class _ChordDiagramBottomSheetState extends State<ChordDiagramBottomSheet> {
  final PageController _pageController = PageController(initialPage: 0);
  List<Map<String, dynamic>> _chordVariations = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentVariationIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadChordData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadChordData() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Parse the chord name to get the root note and type
      final chordParts = _parseChordName(widget.chordName);
      final rootNote = chordParts['rootNote'];
      final chordType = chordParts['chordType'];

      if (rootNote == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not parse chord: ${widget.chordName}';
        });
        return;
      }

      // Get the guitar instrument from the library
      final instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);

      // Get all positions for this chord
      final chordPositions = instrument.getChordPositions(rootNote, chordType ?? 'major');

      if (chordPositions == null || chordPositions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No chord data found for ${widget.chordName}';
        });
        return;
      }

      // Create variations with different base frets
      final variations = <Map<String, dynamic>>[];

      // Add all available positions
      for (var position in chordPositions) {
        variations.add({
          'baseFret': position.baseFret,
          'frets': position.frets,
          'fingers': position.fingers,
        });
      }

      setState(() {
        _chordVariations = variations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading chord data: $e';
      });
    }
  }

  // Helper method to parse chord name into root note and chord type
  Map<String, String?> _parseChordName(String chordName) {
    // Common chord types and their mappings
    final chordTypeMap = {
      '': 'major',
      'maj': 'major',
      'min': 'minor',
      'm': 'minor',
      '7': 'dominant7',
      'maj7': 'major7',
      'm7': 'minor7',
      'dim': 'diminished',
      'aug': 'augmented',
      'sus2': 'sus2',
      'sus4': 'sus4',
      '6': 'major6',
      'm6': 'minor6',
      '9': 'dominant9',
      'maj9': 'major9',
      'm9': 'minor9',
      'add9': 'add9',
      '5': 'power',
    };

    // Regular expression to match root note and chord type
    final regex = RegExp(r'^([A-G][#b]?)(.*)$');
    final match = regex.firstMatch(chordName);

    if (match == null) {
      return {'rootNote': null, 'chordType': null};
    }

    final rootNote = match.group(1)!;
    final chordTypeSuffix = match.group(2) ?? '';

    // Map the chord type suffix to the library's expected format
    final chordType = chordTypeMap[chordTypeSuffix] ?? 'major';

    return {'rootNote': rootNote, 'chordType': chordType};
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35, // Slightly more compact
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Chord name
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              widget.chordName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Chord diagram
          Expanded(
            child: _buildChordDiagram(),
          ),

          // Position indicator and navigation row
          if (_chordVariations.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                    onPressed: _currentVariationIndex > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    color: _currentVariationIndex > 0 ? Colors.white : Colors.grey[700],
                  ),
                  Text(
                    '${_currentVariationIndex + 1} of ${_chordVariations.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    onPressed: _currentVariationIndex < _chordVariations.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    color: _currentVariationIndex < _chordVariations.length - 1
                        ? Colors.white
                        : Colors.grey[700],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChordDiagram() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            _errorMessage,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_chordVariations.isEmpty) {
      return const Center(
        child: Text(
          'No chord variations available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // PageView for swiping between variations
    return PageView.builder(
      controller: _pageController,
      itemCount: _chordVariations.length,
      onPageChanged: (index) {
        setState(() {
          _currentVariationIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final variation = _chordVariations[index];
        return Center(
          child: SizedBox(
            height: 160,
            child: FlutterGuitarChord(
              chordName: widget.chordName,
              baseFret: variation['baseFret'],
              frets: variation['frets'],
              fingers: variation['fingers'],
              totalString: 6,
              labelColor: Colors.white, // White label
              tabForegroundColor: Colors.black, // Black text for finger numbers
              tabBackgroundColor: Theme.of(context).colorScheme.primary, // Theme primary color for finger dots
              barColor: Colors.white, // White bar
              stringColor: Colors.white, // White strings
              firstFrameColor: Colors.white, // White first frame
              mutedColor: Colors.white, // White X and O symbols
            ),
          ),
        );
      },
    );
  }
}
