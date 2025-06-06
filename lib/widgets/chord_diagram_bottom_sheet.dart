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
      final enharmonicEquivalent = chordParts['enharmonicEquivalent'];

      if (rootNote == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not parse chord: ${widget.chordName}';
        });
        return;
      }

      // Get the guitar instrument from the library
      final instrument = GuitarChordLibrary.instrument(InstrumentType.guitar);

      // Try to get chord positions with the original root note first
      debugPrint('Loading chord data for: $rootNote${chordType ?? 'major'} (original: ${widget.chordName})');
      var chordPositions = instrument.getChordPositions(rootNote, chordType ?? 'major');

      // If no positions found and we have an enharmonic equivalent, try that
      if ((chordPositions == null || chordPositions.isEmpty) && enharmonicEquivalent != null) {
        debugPrint('No chord data found for $rootNote, trying enharmonic equivalent: $enharmonicEquivalent');
        chordPositions = instrument.getChordPositions(enharmonicEquivalent, chordType ?? 'major');

        if (chordPositions != null && chordPositions.isNotEmpty) {
          debugPrint('Successfully found chord data using enharmonic equivalent: $enharmonicEquivalent');
        }
      } else if (chordPositions != null && chordPositions.isNotEmpty) {
        debugPrint('Successfully found chord data using original notation: $rootNote');
      }

      if (chordPositions == null || chordPositions.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No chord data found for ${widget.chordName}${enharmonicEquivalent != null ? ' or $enharmonicEquivalent' : ''}';
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
    // Enharmonic equivalents mapping - ensures both sharp and flat notations work
    final enharmonicMap = {
      // Flats to sharps (library might prefer sharps)
      'Db': 'C#',
      'Eb': 'D#',
      'Gb': 'F#',
      'Ab': 'G#',
      'Bb': 'A#',
      // Sharps to flats (fallback if library prefers flats)
      'C#': 'Db',
      'D#': 'Eb',
      'F#': 'Gb',
      'G#': 'Ab',
      'A#': 'Bb',
    };

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

    final originalRootNote = match.group(1)!;
    final chordTypeSuffix = match.group(2) ?? '';

    // Map the chord type suffix to the library's expected format
    final chordType = chordTypeMap[chordTypeSuffix] ?? 'major';

    // Return both original and enharmonic equivalent for fallback
    return {
      'rootNote': originalRootNote,
      'chordType': chordType,
      'enharmonicEquivalent': enharmonicMap[originalRootNote],
    };
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and safe area
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    // Calculate available height considering safe areas and system navigation
    final availableHeight = screenHeight - safeAreaBottom - viewInsetsBottom;

    // Calculate responsive height (between 45% and 75% of available height)
    final minHeight = availableHeight * 0.45;
    final maxHeight = availableHeight * 0.75;
    final preferredHeight = availableHeight * 0.6;

    // Use the preferred height, but constrain it within min/max bounds
    final bottomSheetHeight = preferredHeight.clamp(minHeight, maxHeight);

    return Container(
      height: bottomSheetHeight,
      width: screenWidth,
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
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          // Chord name
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0), // Increased padding
            child: Text(
              widget.chordName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32, // Increased from 24 to 32 for bigger text
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
              padding: EdgeInsets.only(
                bottom: 20.0 + safeAreaBottom, // Add safe area bottom padding
                top: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24), // Increased icon size
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
                  const SizedBox(width: 16), // Added spacing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentVariationIndex + 1} of ${_chordVariations.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16, // Increased font size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Added spacing
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24), // Increased icon size
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
            height: 235, // Reduced by 5px from 240 to 235
            width: 195, // Reduced by 5px from 200 to 195
            child: Transform.scale(
              scale: 1.2, // Increased from 0.9 to 1.2 for larger scale
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
          ),
        );
      },
    );
  }
}
