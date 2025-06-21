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
      debugPrint('🎸 Loading chord data for: $rootNote${chordType ?? 'major'} (original: ${widget.chordName})');
      debugPrint('🎸 Parsed chord parts: rootNote=$rootNote, chordType=$chordType');

      // Special debug for Cadd9
      if (widget.chordName.toLowerCase() == 'cadd9') {
        debugPrint('🔍 DEBUGGING CADD9 SPECIFICALLY:');
        debugPrint('   - Root note: "$rootNote"');
        debugPrint('   - Chord type: "$chordType"');

        // Test direct library call
        final testPositions = instrument.getChordPositions('C', 'add9');
        debugPrint('   - Direct C+add9 call: ${testPositions?.length ?? 0} positions');
        if (testPositions != null && testPositions.isNotEmpty) {
          debugPrint('   - First position: ${testPositions.first.frets}');
        }
      }

      var chordPositions = instrument.getChordPositions(rootNote, chordType ?? 'major');

      // If chord not found, try comprehensive fallbacks
      if (chordPositions == null || chordPositions.isEmpty) {
        debugPrint('🚨 Chord not found, trying fallbacks for: ${widget.chordName}');
        debugPrint('🚨 Original request: $rootNote + $chordType');

        // Special handling for add9 chords - they might not exist in library
        if (chordType == 'add9') {
          debugPrint('🎸 add9 chord not found, trying alternatives...');

          // Try major9 as fallback for add9
          chordPositions = instrument.getChordPositions(rootNote, 'maj9');
          if (chordPositions != null && chordPositions.isNotEmpty) {
            debugPrint('✅ Using maj9 as fallback for add9: ${chordPositions.length} positions found');
          } else {
            // Try 9 as fallback
            chordPositions = instrument.getChordPositions(rootNote, '9');
            if (chordPositions != null && chordPositions.isNotEmpty) {
              debugPrint('✅ Using 9 as fallback for add9: ${chordPositions.length} positions found');
            } else {
              // Try sus2 as it has similar sound
              chordPositions = instrument.getChordPositions(rootNote, 'sus2');
              if (chordPositions != null && chordPositions.isNotEmpty) {
                debugPrint('✅ Using sus2 as fallback for add9: ${chordPositions.length} positions found');
              }
            }
          }
        }

        // Handle slash chords - try the main chord without bass note
        if (chordParts['isSlashChord'] == 'true') {
          final mainChord = chordParts['mainChord'];
          final mainChordParts = _parseChordName(mainChord!);
          final mainRootNote = mainChordParts['rootNote'];
          final mainChordType = mainChordParts['chordType'];

          if (mainRootNote != null && mainChordType != null) {
            chordPositions = instrument.getChordPositions(mainRootNote, mainChordType);
            debugPrint('Trying main chord fallback for slash chord: $mainChord -> ${chordPositions?.length ?? 0} positions found');
          }
        }

        // Try sus -> sus4 fallback
        if ((chordPositions == null || chordPositions.isEmpty) && chordType == 'sus') {
          chordPositions = instrument.getChordPositions(rootNote, 'sus4');
          debugPrint('Trying sus4 fallback: ${chordPositions?.length ?? 0} positions found');
        }

        // Try removing complex suffixes and default to major
        if ((chordPositions == null || chordPositions.isEmpty) && chordType != 'major') {
          chordPositions = instrument.getChordPositions(rootNote, 'major');
          debugPrint('Trying major fallback: ${chordPositions?.length ?? 0} positions found');
        }

        // Try minor fallback for complex minor chords
        if ((chordPositions == null || chordPositions.isEmpty) && chordType?.contains('m') == true) {
          chordPositions = instrument.getChordPositions(rootNote, 'minor');
          debugPrint('Trying minor fallback: ${chordPositions?.length ?? 0} positions found');
        }

        // Try 7th fallback for complex 7th chords
        if ((chordPositions == null || chordPositions.isEmpty) && chordType?.contains('7') == true) {
          chordPositions = instrument.getChordPositions(rootNote, '7');
          debugPrint('Trying 7th fallback: ${chordPositions?.length ?? 0} positions found');
        }
      }

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
          // Provide helpful error message for slash chords
          if (chordParts['isSlashChord'] == 'true') {
            final mainChord = chordParts['mainChord'];
            final bassNote = chordParts['bassNote'];
            _errorMessage = 'Slash chord "$mainChord/$bassNote" not available.\n\nNote: Play $mainChord with $bassNote in the bass.';
          } else {
            _errorMessage = 'No chord data found for ${widget.chordName}${enharmonicEquivalent != null ? ' or $enharmonicEquivalent' : ''}.\n\nTry: ${widget.chordName}maj, ${widget.chordName}m, ${widget.chordName}7';
          }
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

      // Debug the final chord variations being displayed
      debugPrint('🎸 Final chord variations for ${widget.chordName}: ${variations.length} variations');
      for (int i = 0; i < variations.length; i++) {
        final variation = variations[i];
        debugPrint('   Variation $i: baseFret=${variation['baseFret']}, frets=${variation['frets']}, fingers=${variation['fingers']}');
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
    // Handle slash chords (e.g., C/E, Am/C, G7/B, Ab/C)
    if (chordName.contains('/')) {
      final parts = chordName.split('/');
      if (parts.length == 2) {
        final mainChord = parts[0].trim();
        final bassNote = parts[1].trim();

        debugPrint('🎸 Parsing slash chord: $mainChord over $bassNote');

        // For now, we'll try to find the main chord and ignore the bass note
        // since the guitar_chord_library has limited slash chord support
        final mainChordParts = _parseChordName(mainChord);

        // Check if the library has this specific slash chord
        final slashChordSuffix = '/$bassNote';
        final rootNote = mainChordParts['rootNote'];

        if (rootNote != null) {
          // Try to find if this slash chord exists in the library
          return {
            'rootNote': rootNote,
            'chordType': (mainChordParts['chordType'] ?? 'major') + slashChordSuffix,
            'enharmonicEquivalent': mainChordParts['enharmonicEquivalent'],
            'isSlashChord': 'true',
            'bassNote': bassNote,
            'mainChord': mainChord,
          };
        }
      }
    }

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

    // Complete chord types mapping based on guitar_chord_library dataset
    final chordTypeMap = {
      // Basic triads
      '': 'major',
      'maj': 'major',
      'min': 'minor',
      'm': 'minor',
      'dim': 'dim',
      'aug': 'aug',

      // Suspended chords
      'sus': 'sus4', // Default sus to sus4
      'sus2': 'sus2',
      'sus4': 'sus4',
      'sus2sus4': 'sus2sus4',

      // Seventh chords
      '7': '7',
      'maj7': 'maj7',
      'm7': 'm7',
      'dim7': 'dim7',
      'aug7': 'aug7',
      '7b5': '7b5',
      '7sus4': '7sus4',
      'm7b5': 'm7b5',
      'mmaj7': 'mmaj7',
      'mmaj7b5': 'mmaj7b5',

      // Ninth chords
      '9': '9',
      'maj9': 'maj9',
      'm9': 'm9',
      '9b5': '9b5',
      'aug9': 'aug9',
      '7b9': '7b9',
      '7#9': '7#9',
      'mmaj9': 'mmaj9',

      // Extended chords
      '11': '11',
      '9#11': '9#11',
      '13': '13',
      'maj11': 'maj11',
      'maj13': 'maj13',
      'm11': 'm11',
      'mmaj11': 'mmaj11',

      // Sixth chords
      '6': '6',
      'm6': 'm6',
      '69': '69',
      'm69': 'm69',

      // Add chords
      'add9': 'add9',
      'madd9': 'madd9',

      // Power chords
      '5': '5',

      // Slash chords (bass note inversions) - Based on guitar_chord_library dataset
      '/E': '/E', // First inversion
      '/F': '/F', // Bass note F
      '/G': '/G', // Bass note G
      '/B': '/B', // Bass note B
      '/C': '/C', // Bass note C
      '/D': '/D', // Bass note D
      '/A': '/A', // Bass note A

      // Altered chords
      'alt': 'alt',
      'maj7#5': 'maj7#5',

      // Additional common chord variations
      'add2': 'add9', // add2 is same as add9
      'add4': 'sus4', // add4 often treated as sus4
      '2': 'sus2', // Sometimes written as just "2"
      '4': 'sus4', // Sometimes written as just "4"

      // Diminished variations
      'o': 'dim', // Circle symbol alternative
      'o7': 'dim7', // Circle with 7
      '°': 'dim', // Degree symbol
      '°7': 'dim7', // Degree with 7

      // Half-diminished variations
      'ø': 'm7b5', // Half-diminished symbol
      'ø7': 'm7b5', // Half-diminished with 7
      '-7b5': 'm7b5', // Alternative notation

      // Augmented variations
      '+': 'aug', // Plus symbol
      '#5': 'aug', // Sharp 5
      'aug5': 'aug', // Augmented 5
      '+5': 'aug', // Plus 5

      // Power chord variations
      'no3': '5', // No third (power chord)

      // Major variations
      'M': 'major', // Capital M
      'M7': 'maj7', // Capital M7
      'Maj7': 'maj7', // Capital Maj7
      'MA7': 'maj7', // Capital MA7
      '△': 'maj7', // Triangle symbol
      '△7': 'maj7', // Triangle with 7

      // Minor variations
      '-': 'minor', // Dash for minor
      'mi': 'minor', // Short minor

      // Seventh variations
      'dom7': '7', // Dominant 7
      'dominant7': '7', // Full dominant 7

      // Extended chord variations
      'add11': '11', // Add 11
      'add13': '13', // Add 13
      '7add11': '11', // 7 add 11
      '7add13': '13', // 7 add 13

      // Jazz chord variations
      '6/9': '69', // Six nine
      '6add9': '69', // Six add nine
      'm6/9': 'm69', // Minor six nine
      'm6add9': 'm69', // Minor six add nine

      // Altered dominant variations
      '7alt': 'alt', // 7 altered
      '7#5': 'aug7', // 7 sharp 5
      '7+5': 'aug7', // 7 plus 5
      '7b13': '7b5', // 7 flat 13 (enharmonic with b5)
      '7#11': '7', // 7 sharp 11 (often just played as 7)

      // Complex alterations
      '7b5b9': '7b9', // Multiple alterations - use simpler version
      '7#5#9': '7#9', // Multiple alterations - use simpler version
      '7b5#9': '7#9', // Multiple alterations - use simpler version
      '7#5b9': '7b9', // Multiple alterations - use simpler version
    };

    // Regular expression to match root note and chord type
    final regex = RegExp(r'^([A-G][#b]?)(.*)$');
    final match = regex.firstMatch(chordName);

    debugPrint('🎸 Parsing chord: $chordName');
    if (match != null) {
      debugPrint('🎸 Root note: ${match.group(1)}');
      debugPrint('🎸 Chord suffix: "${match.group(2)}"');
    }

    if (match == null) {
      return {'rootNote': null, 'chordType': null};
    }

    final originalRootNote = match.group(1)!;
    final chordTypeSuffix = match.group(2) ?? '';

    // Map the chord type suffix to the library's expected format
    final chordType = chordTypeMap[chordTypeSuffix] ?? 'major';

    debugPrint('🎸 Chord suffix "$chordTypeSuffix" mapped to: "$chordType"');
    if (chordTypeSuffix.isNotEmpty && !chordTypeMap.containsKey(chordTypeSuffix)) {
      debugPrint('⚠️ WARNING: Chord suffix "$chordTypeSuffix" not found in mapping, using default "major"');
    }

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
