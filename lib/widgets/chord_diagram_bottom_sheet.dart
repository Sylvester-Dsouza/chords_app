import 'package:flutter/material.dart';
import 'package:flutter_guitar_chord/flutter_guitar_chord.dart';
import 'package:guitar_chord_library/guitar_chord_library.dart';


import '../config/theme.dart';
import '../models/chord_instrument.dart';

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
  ChordInstrument _selectedInstrument = ChordInstrument.guitar;

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

    // Handle piano chords differently
    if (_selectedInstrument == ChordInstrument.piano) {
      setState(() {
        _isLoading = false;
        // Piano chords will be handled by the piano diagram widget
      });
      return;
    }

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

      // Get the instrument from the library based on selection
      final instrumentType = _selectedInstrument == ChordInstrument.ukulele
          ? InstrumentType.ukulele
          : InstrumentType.guitar;
      final instrument = GuitarChordLibrary.instrument(instrumentType);

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
        color: AppTheme.surface,
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
              color: AppTheme.textSecondary,
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          // Chord name
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              widget.chordName,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Instrument selection tabs
          _buildInstrumentTabs(),

          // Chord diagram
          Expanded(
            child: _buildChordDiagram(),
          ),

          // Add bottom spacing when no variations (single chord) or for piano
          if (_chordVariations.length <= 1 || _selectedInstrument == ChordInstrument.piano)
            SizedBox(height: 32.0 + safeAreaBottom),

          // Position indicator and navigation row (hide for piano or when only 1 variation)
          if (_chordVariations.length > 1 && _selectedInstrument != ChordInstrument.piano)
            Padding(
              padding: EdgeInsets.only(
                bottom: 32.0 + safeAreaBottom, // Increased bottom padding for better spacing
                top: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary, size: 24),
                    onPressed: _currentVariationIndex > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    color: _currentVariationIndex > 0 ? AppTheme.textPrimary : AppTheme.textTertiary,
                  ),
                  const SizedBox(width: 16), // Added spacing
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentVariationIndex + 1} of ${_chordVariations.length}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16, // Increased font size
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Added spacing
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: AppTheme.textPrimary, size: 24),
                    onPressed: _currentVariationIndex < _chordVariations.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    color: _currentVariationIndex < _chordVariations.length - 1
                        ? AppTheme.textPrimary
                        : AppTheme.textTertiary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstrumentTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: ChordInstrument.values.map((instrument) {
          final isSelected = _selectedInstrument == instrument;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedInstrument = instrument;
                  _loadChordData(); // Reload chord data for new instrument
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  children: [
                    Text(
                      instrument.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      instrument.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_off,
                color: AppTheme.textSecondary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Chord not available',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_chordVariations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note_outlined,
              color: AppTheme.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No chord variations available',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try switching to a different instrument',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show different diagrams based on selected instrument
    if (_selectedInstrument == ChordInstrument.piano) {
      return _buildPianoDiagram();
    } else {
      return _buildStringInstrumentDiagram();
    }
  }

  Widget _buildStringInstrumentDiagram() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _chordVariations.length,
      physics: const BouncingScrollPhysics(), // Better scroll physics
      pageSnapping: true, // Ensure pages snap properly
      allowImplicitScrolling: true, // Allow better gesture handling
      onPageChanged: (index) {
        setState(() {
          _currentVariationIndex = index;
        });
      },
      itemBuilder: (context, index) {
        final variation = _chordVariations[index];
        final stringCount = _selectedInstrument.stringCount ?? 6;

        return Center(
          child: SizedBox(
            height: 235,
            width: 195,
            child: Transform.scale(
              scale: 1.2,
              child: FlutterGuitarChord(
                chordName: widget.chordName,
                baseFret: variation['baseFret'],
                frets: variation['frets'],
                fingers: variation['fingers'],
                totalString: stringCount,
                labelColor: AppTheme.textPrimary,
                tabForegroundColor: AppTheme.background,
                tabBackgroundColor: Theme.of(context).colorScheme.primary,
                barColor: AppTheme.textPrimary,
                stringColor: AppTheme.textPrimary,
                firstFrameColor: AppTheme.textPrimary,
                mutedColor: AppTheme.textPrimary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPianoDiagram() {
    // Get piano chord notes for the current chord
    final pianoNotes = _getPianoChordNotes(widget.chordName);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chord name for piano
          Text(
            '${widget.chordName} Piano',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Piano keyboard - smaller size
          Container(
            height: 120, // Reduced from 200 to 120
            width: 280,  // Reduced from 350 to 280
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildHighlightedPiano(pianoNotes),
          ),

          const SizedBox(height: 16),

          // Show the chord notes
          if (pianoNotes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Notes: ${pianoNotes.join(' - ')}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Instructions
          Text(
            'Highlighted keys show the ${widget.chordName} chord',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a custom piano with highlighted chord notes
  Widget _buildHighlightedPiano(List<String> chordNotes) {
    return CustomPaint(
      size: const Size(280, 120),
      painter: PianoChordPainter(
        chordNotes: chordNotes,
        chordName: widget.chordName,
      ),
    );
  }

  /// Get piano chord notes for a given chord name
  List<String> _getPianoChordNotes(String chordName) {
    // Parse chord name to get root note and chord type
    final cleanChordName = chordName.replaceAll(RegExp(r'[/\s].*'), '').trim();

    // Extract root note and chord type
    String rootNote = '';
    String chordType = '';

    if (cleanChordName.length >= 2 && (cleanChordName[1] == '#' || cleanChordName[1] == 'b')) {
      rootNote = cleanChordName.substring(0, 2);
      chordType = cleanChordName.substring(2);
    } else if (cleanChordName.isNotEmpty) {
      rootNote = cleanChordName.substring(0, 1);
      chordType = cleanChordName.substring(1);
    }

    // Get chord intervals based on chord type
    final intervals = _getChordIntervals(chordType);

    // Build chord notes
    final List<String> chordNotes = [];
    for (final interval in intervals) {
      final note = _transposeNote(rootNote, interval);
      if (note.isNotEmpty) {
        chordNotes.add(note);
      }
    }

    return chordNotes;
  }

  /// Get chord intervals for different chord types
  List<int> _getChordIntervals(String chordType) {
    switch (chordType.toLowerCase()) {
      case '': case 'maj': case 'major':
        return [0, 4, 7]; // Major triad
      case 'm': case 'min': case 'minor':
        return [0, 3, 7]; // Minor triad
      case '7': case 'dom7':
        return [0, 4, 7, 10]; // Dominant 7th
      case 'maj7': case 'major7':
        return [0, 4, 7, 11]; // Major 7th
      case 'm7': case 'min7': case 'minor7':
        return [0, 3, 7, 10]; // Minor 7th
      case 'dim': case 'diminished':
        return [0, 3, 6]; // Diminished triad
      case 'aug': case 'augmented': case '+':
        return [0, 4, 8]; // Augmented triad
      case 'sus2':
        return [0, 2, 7]; // Suspended 2nd
      case 'sus4':
        return [0, 5, 7]; // Suspended 4th
      case '6':
        return [0, 4, 7, 9]; // Major 6th
      case 'm6':
        return [0, 3, 7, 9]; // Minor 6th
      case '9':
        return [0, 4, 7, 10, 14]; // Dominant 9th
      case 'maj9':
        return [0, 4, 7, 11, 14]; // Major 9th
      case 'm9':
        return [0, 3, 7, 10, 14]; // Minor 9th
      default:
        return [0, 4, 7]; // Default to major triad
    }
  }

  /// Transpose a note by semitones
  String _transposeNote(String rootNote, int semitones) {
    final notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

    // Normalize root note
    String normalizedRoot = rootNote.toUpperCase();
    if (normalizedRoot.contains('B')) {
      // Convert flat notes to sharp equivalents
      normalizedRoot = normalizedRoot.replaceAll('DB', 'C#')
          .replaceAll('EB', 'D#')
          .replaceAll('GB', 'F#')
          .replaceAll('AB', 'G#')
          .replaceAll('BB', 'A#');
    }

    final rootIndex = notes.indexOf(normalizedRoot);
    if (rootIndex == -1) return '';

    final newIndex = (rootIndex + semitones) % 12;
    return notes[newIndex];
  }
}

/// Custom painter for piano keyboard with highlighted chord notes
class PianoChordPainter extends CustomPainter {
  final List<String> chordNotes;
  final String chordName;

  PianoChordPainter({
    required this.chordNotes,
    required this.chordName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final double keyWidth = size.width / 7; // 7 white keys (C to B)
    final double keyHeight = size.height;
    final double blackKeyWidth = keyWidth * 0.6;
    final double blackKeyHeight = keyHeight * 0.6;

    // Define white and black key positions
    final whiteKeys = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
    final blackKeys = ['C#', 'D#', '', 'F#', 'G#', 'A#', '']; // Empty strings for no black key

    // Draw white keys
    for (int i = 0; i < whiteKeys.length; i++) {
      final key = whiteKeys[i];
      final isHighlighted = chordNotes.contains(key);

      // Key rectangle
      final keyRect = Rect.fromLTWH(
        i * keyWidth,
        0,
        keyWidth,
        keyHeight,
      );

      // Fill color
      paint.color = isHighlighted ? AppTheme.primary : Colors.white;
      canvas.drawRect(keyRect, paint);

      // Border
      paint.color = Colors.black;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1;
      canvas.drawRect(keyRect, paint);
      paint.style = PaintingStyle.fill;

      // Key label
      if (isHighlighted) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            keyRect.center.dx - textPainter.width / 2,
            keyRect.bottom - textPainter.height - 8,
          ),
        );
      }
    }

    // Draw black keys
    for (int i = 0; i < blackKeys.length; i++) {
      final key = blackKeys[i];
      if (key.isEmpty) continue; // Skip positions without black keys

      final isHighlighted = chordNotes.contains(key);

      // Black key position (offset to center between white keys)
      final blackKeyX = (i + 1) * keyWidth - blackKeyWidth / 2;

      final keyRect = Rect.fromLTWH(
        blackKeyX,
        0,
        blackKeyWidth,
        blackKeyHeight,
      );

      // Fill color
      paint.color = isHighlighted ? AppTheme.primary : Colors.black;
      canvas.drawRect(keyRect, paint);

      // Border for highlighted black keys
      if (isHighlighted) {
        paint.color = Colors.white;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawRect(keyRect, paint);
        paint.style = PaintingStyle.fill;

        // Key label
        final textPainter = TextPainter(
          text: TextSpan(
            text: key,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            keyRect.center.dx - textPainter.width / 2,
            keyRect.bottom - textPainter.height - 4,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! PianoChordPainter ||
        oldDelegate.chordNotes != chordNotes ||
        oldDelegate.chordName != chordName;
  }
}
